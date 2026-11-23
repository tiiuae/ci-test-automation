# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Detailed facts/AI report and a short HTML summary."""

from collections import Counter, defaultdict
from datetime import datetime
from html import escape
from pathlib import Path, PurePosixPath
import json
import re
from urllib.parse import urlsplit

from jinja2 import Environment, FileSystemLoader, StrictUndefined, select_autoescape
from markupsafe import Markup

from report_output import redact, redact_data, write_html, write_json
from factual_report import collection_notices, evidence_linker, recorded_outcome, refresh_facts
from robot_evidence import short_error
from ai_investigation import attach_investigation


def error_excerpt(message):
    """Keep the actual assertion/command error ahead of the interpretation."""
    primary = re.split(r"\s+Also keyword teardown failed:", message, maxsplit=1)[
        0
    ].strip()
    primary = re.sub(
        r"^Keyword .+? failed after retrying .+? The last error was:\s*",
        "",
        primary,
        flags=re.DOTALL,
    )
    # Command wrappers repeat the command, return code and assertion. The stderr
    # line carries the useful error, while the full message remains expandable.
    stderr = re.search(r"^Error: (.+)", primary, flags=re.MULTILINE)
    if stderr and stderr[1].strip():
        primary = stderr[1].strip()
    return short_error(primary)


def link(url, text):
    safe = (
        url
        if isinstance(url, str) and (
            urlsplit(url).scheme in ("http", "https")
            or (urlsplit(url).scheme == "file" and not urlsplit(url).netloc)
            or re.fullmatch(r"investigation-evidence/[a-f0-9]{64}\.txt", url)
        )
        else ""
    )
    if not safe:
        return Markup(escape(str(text)) + " (URL unavailable)")
    return Markup(f'<a href="{escape(safe, quote=True)}">{escape(str(text))}</a>')


def display_name(metadata):
    raw = metadata.get("target", metadata.get("id", "Unknown configuration"))
    name = next(
        (
            label
            for pattern, label in (
                ("lenovo-x1", "Lenovo X1"),
                ("system76-darp", "Darter Pro"),
                ("orin-agx64", "Orin AGX64"),
                ("orin-agx", "Orin AGX"),
                ("orin-nx", "Orin NX"),
            )
            if pattern in raw
        ),
        raw.split("@")[0],
    )
    variants = []
    if "storeDisk" in raw:
        variants.append("storeDisk")
    if "installer" in raw:
        variants.append("installer")
    if "from-x86_64" in raw:
        variants.append("cross-compiled")
    if metadata.get("secureboot"):
        variants.append("Secure Boot")
    return name + (" · " + " · ".join(variants) if variants else "")


def render(report, output, link=link, without_ai=False):
    redact_data(report)
    refresh_facts(report)
    link = evidence_linker(report, link)
    attach_investigation(report, output, without_ai=without_ai)
    totals = Counter()
    gaps = list(report["gaps"])
    issue_runs = []
    for target in report["targets"]:
        gaps.extend(f"{target['name']}: {gap}" for gap in target["gaps"])
        for run in target["runs"]:
            gaps.extend(
                f"{display_name(run['metadata'])}: {gap}" for gap in run["gaps"]
            )
            failures, skipped, dependent = [], [], Counter()
            for phase in run["phases"]:
                totals.update(phase["counts"])
                for test in phase["tests"]:
                    if test["status"] == "FAIL":
                        if (
                            not test.get("failure_points")
                            and short_error(test["message"]) == "Not executed after the run was interrupted"
                        ):
                            dependent["Execution stopped"] += 1
                        elif not test.get("fixture_dependencies") or test.get("failure_points"):
                            # Unknown relationships remain individual failures.
                            failures.append((test, phase))
                        else:
                            dependent["Parent suite fixture"] += 1
                    elif test["status"] in ("SKIP", "NOT RUN"):
                        skipped.append(test)
            if (
                any(p["suite_failures"] or p["execution_errors"] for p in run["phases"])
                or failures
                or skipped
                or dependent
                or run["gaps"]
                or run["metadata"].get("status") not in ("SUCCESS",)
            ):
                issue_runs.append((target, run, failures, skipped, dependent))
    report["counts"] = dict(totals)
    report["collection_notes"] = gaps
    scope_notes, global_gaps = collection_notices(report)
    report["scope_notes"] = scope_notes
    report["collection_gaps"] = global_gaps + gaps[len(report["gaps"]):]
    stamp = re.search(r"/(\d{8})_", report["source_url"])
    date = (
        datetime.strptime(stamp[1], "%Y%m%d").strftime("%d %b %Y")
        if stamp
        else "Nightly"
    )
    configurations = []
    for target, run, failures, skipped, dependent in issue_runs:
        groups = defaultdict(list)
        for test in skipped:
            known = re.search(r"Known issue:\s*([A-Z]+-\d+)", test["message"])
            reason = (
                f"Marked SKIP for known issue {known[1]}"
                if known else short_error(test["message"]) or "No skip reason recorded"
            )
            groups[reason].append(test)
        status = run["metadata"].get("status")
        show_summary = bool(
            failures or dependent or run["gaps"]
            or any(p["suite_failures"] or any(e["level"] != "WARN" for e in p["execution_errors"])
                   for p in run["phases"])
            or status != "SUCCESS"
        )
        configurations.append({
            "target": target, "run": run, "title": display_name(run["metadata"]),
            "failures": [test for test, _ in failures], "skip_groups": groups,
            "dependent": dependent, "has_tests": any(p["tests"] for p in run["phases"]),
            "show_summary": show_summary,
        })
    context = {
        "report": report, "date": date, "configurations": configurations,
        "missing": [t for t in report["targets"] if t.get("not_run_reason")],
        "link": link,
    }
    environment = Environment(
        loader=FileSystemLoader(Path(__file__).with_name("templates")),
        autoescape=select_autoescape(["html"]),
        undefined=StrictUndefined,
        trim_blocks=True,
        lstrip_blocks=True,
    )
    environment.filters.update(
        error_excerpt=error_excerpt, short_error=short_error, redact=redact,
        summary_excerpt=lambda value: " ".join(value.split())[:320],
        basename=lambda value: PurePosixPath(value).name,
        provenance=lambda item: json.dumps({"sha256": item["sha256"], **item["provenance"]}, indent=2),
    )
    environment.globals["recorded_outcome"] = recorded_outcome
    for filename in ("report.html", "summary.html"):
        write_html(output / filename, environment.get_template(filename), context)
    write_json(output / "analysis.json", report)
