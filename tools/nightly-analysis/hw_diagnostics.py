# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Recorded job errors for runs with no usable Robot results."""

from collections import deque
from hashlib import file_digest, sha256
import json
from io import StringIO
import re

from report_output import redact



DIAGNOSTIC_LIMIT = 64 * 1024 * 1024


def console_lines(stream):
    """Retain at most 4096 characters while consuming each physical line."""
    while chunk := stream.readline(4096):
        first = chunk
        while not chunk.endswith("\n"):
            chunk = stream.readline(4096)
            if not chunk:
                break
        yield first


def console_errors(text, url, digest):
    """Stage names come only from Pipeline markers, never from word matching."""
    stack, previous = [], deque(maxlen=2)
    flash, other = deque(maxlen=8), deque(maxlen=8)
    count, pending, context = 0, None, []
    stream = StringIO(text) if isinstance(text, str) else text
    lines = console_lines(stream) if hasattr(stream, "readline") else stream
    for number, raw in enumerate(lines, 1):
        raw = raw[:4096].rstrip("\r\n")
        if pending is not None:
            pending["text"] = redact("\n".join(context + [raw]))[:2400]
            pending = None
        line = re.sub(r"\x1b\[[0-9;]*m", "", raw)
        opening = re.search(r"\[Pipeline\] \{(?: \((.*?)\))?", line)
        if opening:
            stack.append(opening[1])
        stage = next((name for name in reversed(stack) if name), None)
        if re.search(r"\[Pipeline\] }", line) and stack:
            stack.pop()
        ignored = re.search(r"skipped due to earlier failure|\b0 (?:errors|failures)\b", line, re.I)
        if not ignored and re.search(
            r"\berror\s*:|\bfailed\b|\bexception\b|script returned exit code [1-9]", line, re.I
        ):
            pending = {
                "kind": "console_error", "stage": stage, "line": number,
                "url": url, "sha256": digest, "sha256_scope": "original artifact",
            }
            context = list(previous) + [raw]
            (flash if stage == "Flash" else other).append(pending)
            count += 1
        previous.append(raw)
    if pending is not None:
        pending["text"] = redact("\n".join(context))[:2400]
    # Keep explicit Flash-stage errors ahead of generic final exit-code messages.
    selected = sorted(list(flash) + list(other), key=lambda item: (item["stage"] != "Flash", -item["line"]))[:8]
    return sorted(selected, key=lambda item: item["line"]), count > len(selected)




def collect_hw_diagnostics(source, run):
    """Read only metadata and result/console files published in the selected artifacts."""
    if any(phase["tests"] for phase in run["phases"]) or run["metadata"].get("status") == "SKIPPED":
        return
    notes = run.setdefault("diagnostic_notes", [])
    files = run["evidence"]
    result = next((item for item in files if item["name"] == "result.json"), None)
    if result:
        try:
            path = source.get(result["url"], limit=1024 * 1024)
            data = json.loads(path.read_text())
            expected = run["metadata"]
            job = data.get("job", {}).get("url")
            expected_job = expected.get("job", {}).get("url")
            if ((expected_job and job and job != expected_job)
                    or data.get("id") != expected.get("id")):
                raise ValueError("result.json belongs to a different HW run")
            if (isinstance(data.get("reason"), str) and data["reason"]
                    and data["reason"] != expected.get("reason")):
                run["diagnostics"].append({
                    "kind": "result_error", "text": redact(data["reason"]), "url": result["url"],
                    "sha256": sha256(path.read_bytes()).hexdigest(), "sha256_scope": "original artifact",
                })
        except (OSError, ValueError, AttributeError) as error:
            notes.append("Cannot read job result metadata: " + type(error).__name__)
    archived = [item for item in files if item["name"] in ("console.log", "console.txt", "consoleText")]
    for item in archived[:2]:
        try:
            path = source.get(item["url"], limit=DIAGNOSTIC_LIMIT)
            with path.open("rb") as stream:
                digest = file_digest(stream, "sha256").hexdigest()
            with path.open(encoding="utf-8", errors="replace") as stream:
                findings, truncated = console_errors(stream, item["url"], digest)
        except (OSError, ValueError):
            notes.append(f"Archived Jenkins console is unavailable or exceeds {DIAGNOSTIC_LIMIT // 1024**2} MiB")
            continue
        run["diagnostics"].extend(findings)
        if findings:
            notes.append("Console excerpts may include handled errors; they do not establish the underlying cause")
        if truncated:
            notes.append("Console error excerpts are limited to eight records; inspect the full console")
    if not run["diagnostics"] and not run["metadata"].get("reason"):
        notes.append("No explicit job error was found in the available evidence")
