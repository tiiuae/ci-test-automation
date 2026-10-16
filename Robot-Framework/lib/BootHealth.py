# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

import csv
import os
import re
import shutil
from datetime import datetime

import matplotlib.pyplot as plt


class BootHealth:
    def __init__(self, device, data_dir, plot_dir, statistics):
        self.device = device
        self.data_dir = data_dir
        self.plot_dir = plot_dir
        self.statistics = statistics
        self.full_boot_logs = {}

    def find_saved_serial_log(self, directory, build_id, minimum_lines=200):
        if not os.path.isdir(directory):
            return ""
        valid_logs = sorted(
            os.path.join(directory, name)
            for name in os.listdir(directory)
            if name.startswith(f"{build_id}_Verify_booting")
            and name.endswith(".txt")
            and self._has_minimum_lines(os.path.join(directory, name), minimum_lines)
        )
        return valid_logs[0] if valid_logs else ""

    @staticmethod
    def _has_minimum_lines(file_path, minimum_lines):
        with open(file_path, encoding="utf-8", errors="replace") as log_file:
            return sum(1 for _ in log_file) >= minimum_lines

    def analyze_boot_log_file(self, file_path, gap_limit=10, source=None, timestamp_boundary=None):
        with open(file_path, encoding="utf-8", errors="replace") as serial_file:
            report = self._analyze_boot_lines(
                source or file_path,
                serial_file,
                gap_limit,
                timestamp_boundary,
                capture_path=file_path if source else "",
            )
        if source in ("journalctl -b", "dmesg"):
            self.full_boot_logs[source] = ("file", file_path)
        return report

    def analyze_boot_log(self, source, output, gap_limit=10, timestamp_boundary=None):
        if source in ("journalctl -b", "dmesg"):
            self.full_boot_logs[source] = ("text", output)
        return self._analyze_boot_lines(
            source, output.splitlines(), gap_limit, timestamp_boundary
        )

    @staticmethod
    def _parse_log_timestamp(value):
        timestamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
        # Serial capture timestamps have no offset and use the Robot host's local timezone.
        return timestamp.astimezone() if timestamp.tzinfo is None else timestamp

    @staticmethod
    def _analyze_boot_lines(
        source, lines, gap_limit, timestamp_boundary=None, capture_path=""
    ):

        critical_pattern = [
            "FAIL",
            "FAILED",
            "emergency mode",
            "kernel panic"
        ]
        low_priority_error_pattern = [
            "ERROR"
        ]
        timeout_pattern = [
            "timeout",
            "timed out"
        ]
        critical_lines = {}
        low_priority_lines = {}
        issue_texts = {}
        gap_contexts = {}
        previous_timestamp = None
        previous_line_number = None
        previous_line = None
        timestamp_pattern = re.compile(
            r"^\[?(\d{4}-\d\d-\d\d[ T]\d\d:\d\d:\d\d"
            r"(?:[.,]\d+)?(?:Z|[+-]\d\d(?::?\d\d)?)?)"
        )
        boundary = (
            BootHealth._parse_log_timestamp(timestamp_boundary)
            if timestamp_boundary
            else None
        )

        for line_number, line in enumerate(lines, start=1):
            clean_line = line.rstrip()
            match = timestamp_pattern.match(clean_line)
            if match:
                timestamp = BootHealth._parse_log_timestamp(match.group(1))
                before_boundary = boundary is None or timestamp <= boundary
                if before_boundary and previous_timestamp is not None:
                    gap = (timestamp - previous_timestamp).total_seconds()
                    if gap_limit is not None and gap > gap_limit:
                        critical_lines.setdefault(line_number, {})["timestamp_gaps"] = 1
                        gap_contexts[line_number] = (
                            previous_line_number,
                            previous_line,
                        )
                if before_boundary:
                    previous_timestamp = timestamp
                    previous_line_number = line_number
                    previous_line = clean_line

            if any(
                re.search(rf"\b{re.escape(pattern)}\b", clean_line)
                for pattern in critical_pattern
            ):
                critical_lines.setdefault(line_number, {})["errors"] = 1
            low_priority_issues = low_priority_lines.setdefault(line_number, {})
            if any(
                re.search(rf"\b{re.escape(pattern)}\b", clean_line)
                for pattern in low_priority_error_pattern
            ):
                low_priority_issues["errors"] = 1
            if any(
                re.search(re.escape(pattern), clean_line, re.IGNORECASE)
                for pattern in timeout_pattern
            ):
                low_priority_issues["timeouts"] = 1
            if not low_priority_issues:
                low_priority_lines.pop(line_number)
            if line_number in critical_lines or line_number in low_priority_lines:
                issue_texts[line_number] = clean_line

        critical_titles = {
            "errors": "Critical error",
            "timestamp_gaps": "Too high timestamp gap",
        }
        low_priority_titles = {"errors": "Error", "timeouts": "Timeout"}
        critical_details = BootHealth._format_issue_lines(
            issue_texts, critical_lines, critical_titles, gap_contexts
        )
        low_priority_details = BootHealth._format_issue_lines(
            issue_texts, low_priority_lines, low_priority_titles
        )
        critical_summary = BootHealth._format_issue_summary(
            critical_lines, critical_titles
        )
        low_priority_summary = BootHealth._format_issue_summary(
            low_priority_lines, low_priority_titles
        )
        return {
            "file": source,
            "capture_path": capture_path,
            "critical_details": critical_details,
            "critical_summary": critical_summary,
            "has_critical_issues": bool(critical_lines),
            "low_priority_details": low_priority_details,
            "low_priority_summary": low_priority_summary,
            "has_low_priority_issues": bool(low_priority_lines),
        }

    @staticmethod
    def _format_issue_lines(issue_texts, issue_lines, titles, gap_contexts=None):
        entries = []
        for line_number in sorted(issue_lines):
            counts = issue_lines[line_number]
            for category, title in titles.items():
                if not counts.get(category):
                    continue
                if category == "timestamp_gaps" and gap_contexts and line_number in gap_contexts:
                    previous_line_number, previous_line = gap_contexts[line_number]
                    entries.append(
                        f"{title}\n"
                        f"Line numbers: {previous_line_number}-{line_number}\n"
                        f"{previous_line_number}: {previous_line}\n"
                        f"{line_number}: {issue_texts[line_number]}"
                    )
                else:
                    entries.append(
                        f"{title}\nLine number: {line_number}\n{issue_texts[line_number]}"
                    )
        return "\n\n".join(entries)

    @staticmethod
    def _format_issue_summary(issue_lines, titles):
        return ", ".join(
            title
            for category, title in titles.items()
            if any(line.get(category) for line in issue_lines.values())
        )

    def save_boot_log_issue_report(self, report, directory, build_id, priority):
        if priority == "critical":
            has_issues = report["has_critical_issues"]
            details = report["critical_details"]
        else:
            has_issues = report["has_low_priority_issues"]
            details = report["low_priority_details"]
        if not has_issues:
            return ""

        os.makedirs(directory, exist_ok=True)
        build = re.sub(r"[^A-Za-z0-9_.-]+", "_", build_id).strip("_")
        if os.path.dirname(report["file"]):
            source_label = "serial_output"
        else:
            source_label = os.path.splitext(os.path.basename(report["file"]))[0]
            if build and source_label.startswith(f"{build}_"):
                source_label = source_label[len(build) + 1 :]
        source = re.sub(r"[^A-Za-z0-9_.-]+", "_", source_label).strip("_")
        filename = f"{build}_{source}_{priority}_boot_health.txt" if build else (
            f"{source}_{priority}_boot_health.txt"
        )
        path = os.path.join(directory, filename)
        with open(path, "w", encoding="utf-8") as report_file:
            report_file.write(f"{details}\n")
        return path

    def save_full_boot_log(self, source, directory, build_id):
        if source not in self.full_boot_logs:
            return ""

        os.makedirs(directory, exist_ok=True)
        source_name = re.sub(r"[^A-Za-z0-9_.-]+", "_", source).strip("_")
        build = re.sub(r"[^A-Za-z0-9_.-]+", "_", build_id).strip("_")
        filename = (
            f"{build}_{source_name}_full_boot_log.txt"
            if build
            else f"{source_name}_full_boot_log.txt"
        )
        path = os.path.join(directory, filename)
        source_type, source_content = self.full_boot_logs[source]
        if source_type == "file":
            shutil.copyfile(source_content, path)
        else:
            with open(path, "w", encoding="utf-8") as log_file:
                log_file.write(source_content)
                log_file.write("\n")
        return path

    def plot_boot_time_data_without_saving(
        self,
        test_name,
        current_response_to_ping,
        relative_threshold,
        absolute_limit,
    ):
        csv_path = os.path.join(self.data_dir, f"{self.device}_{test_name}.csv")
        commits = []
        ping_times = []

        if os.path.exists(csv_path):
            with open(csv_path, newline="", encoding="utf-8") as csv_file:
                for row in csv.reader(csv_file):
                    if len(row) < 3 or row[-1] != self.device:
                        continue
                    commits.append(row[0])
                    ping_times.append(float(row[1]))

        commits.append("current")
        ping_times.append(float(current_response_to_ping))

        statistics_path = os.path.join(
            self.data_dir, "statistics", f"{self.device}_{test_name}_statistics.csv"
        )
        history_statistics = []
        if os.path.exists(statistics_path):
            with open(statistics_path, newline="", encoding="utf-8") as csv_file:
                history_statistics = list(csv.DictReader(csv_file))

        current_statistics = self.statistics.analyze_data_series(
            ping_times, relative_threshold
        )
        needs_std_baseline = (
            isinstance(relative_threshold, str) and relative_threshold.endswith("std")
        )
        has_relative_baseline = len(ping_times) - 1 >= (2 if needs_std_baseline else 1)
        if not has_relative_baseline:
            current_statistics["flag"] = 0

        upper = [
            float(row["upper_marginal"])
            for row in history_statistics
            if row.get("upper_marginal")
        ]
        lower = [
            float(row["lower_marginal"])
            for row in history_statistics
            if row.get("lower_marginal")
        ]
        if len(upper) == len(ping_times) - 1 and has_relative_baseline:
            upper.append(current_statistics["upper_marginal"])
            lower.append(current_statistics["lower_marginal"])
        elif has_relative_baseline:
            upper = [current_statistics["upper_marginal"]] * len(ping_times)
            lower = [current_statistics["lower_marginal"]] * len(ping_times)
        else:
            upper = []
            lower = []

        os.makedirs(self.plot_dir, exist_ok=True)
        figure, axis = plt.subplots(1, 1, figsize=(20, 10))
        axis.plot(commits, ping_times, marker="o", linestyle="-", color="b", label="response to ping")
        if upper:
            axis.plot(commits, upper, linestyle="dotted", color="darkorange", label="relative upper margin")
            axis.plot(commits, lower, linestyle="dotted", color="darkorange", label="relative lower margin")
        axis.axhline(absolute_limit, color="crimson", linestyle="--", label="absolute limit")
        axis.set_title("Response to ping")
        axis.set_ylabel("seconds")
        axis.grid(True)
        axis.tick_params(axis="x", labelrotation=90)
        axis.legend()
        figure.suptitle(f"{test_name}\nDevice: {self.device}")
        figure.tight_layout()
        figure.savefig(os.path.join(self.plot_dir, f"{self.device}_{test_name}.png"))
        plt.close(figure)
        return {"response_to_ping": current_statistics}
