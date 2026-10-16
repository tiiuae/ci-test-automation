# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

import csv
import os
import re
from datetime import datetime

import matplotlib.pyplot as plt


class BootHealth:
    def __init__(self, device, data_dir, plot_dir, statistics):
        self.device = device
        self.data_dir = data_dir
        self.plot_dir = plot_dir
        self.statistics = statistics

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

    def analyze_boot_log_file(self, file_path, gap_limit=10):
        with open(file_path, encoding="utf-8", errors="replace") as serial_file:
            return self._analyze_boot_lines(file_path, serial_file.readlines(), gap_limit)

    def analyze_boot_log(self, source, output, gap_limit=10):
        return self._analyze_boot_lines(source, output.splitlines(), gap_limit)

    @staticmethod
    def _analyze_boot_lines(source, lines, gap_limit):

        errors = []
        timeouts = []
        alerts = []
        gaps = []
        previous_timestamp = None
        timestamp_pattern = re.compile(
            r"^\[?(\d{4}-\d\d-\d\d[ T]\d\d:\d\d:\d\d(?:\.\d+)?)"
        )
        error_pattern = re.compile(
            r"\b(?:error|failed|failure|fail|panic)\b|emergency mode|dependency failed",
            re.IGNORECASE,
        )
        timeout_pattern = re.compile(
            r"timeout|timed out|start operation timed out|a start job is running",
            re.IGNORECASE,
        )
        alert_pattern = re.compile(r"\b(?:warn|warning|degraded|watchdog)\b", re.IGNORECASE)

        for line_number, line in enumerate(lines, start=1):
            clean_line = line.rstrip()
            match = timestamp_pattern.match(clean_line)
            if match:
                timestamp = datetime.fromisoformat(match.group(1))
                if previous_timestamp is not None:
                    gap = (timestamp - previous_timestamp).total_seconds()
                    if gap > gap_limit:
                        gaps.append(f"line {line_number}: {gap:.1f}s gap")
                previous_timestamp = timestamp

            safe_line = self._redact(clean_line)
            if timeout_pattern.search(clean_line):
                timeouts.append(f"line {line_number}: {safe_line}")
            elif error_pattern.search(clean_line):
                errors.append(f"line {line_number}: {safe_line}")
            elif alert_pattern.search(clean_line):
                alerts.append(f"line {line_number}: {safe_line}")

        summary = (
            f"errors={len(errors)}, timeouts={len(timeouts)}, alerts={len(alerts)}, "
            f"timestamp_gaps={len(gaps)}"
        )
        return {
            "file": source,
            "errors": errors,
            "timeouts": timeouts,
            "alerts": alerts,
            "gaps": gaps,
            "summary": summary,
            "has_issues": bool(errors or timeouts or alerts or gaps),
        }

    @staticmethod
    def _redact(line):
        return re.sub(
            r"(?i)(password|passphrase|secret|token)(\s*[:=]\s*)\S+",
            r"\1\2[REDACTED]",
            line,
        )

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
