# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Bounded Robot XML extraction, exact Robot anchors, and evidence-led analysis."""

from collections import Counter, defaultdict, deque
from datetime import datetime, timedelta
from hashlib import file_digest, sha256
from io import BytesIO
from pathlib import Path, PurePosixPath
import re
import xml.etree.ElementTree as ET
from urllib.parse import urljoin, urlsplit

from robot import __version__ as robot_version
from robot.api import ExecutionResult
from robot.result import Keyword
from report_output import redact, redact_data
from scoped_evidence import ScopedEvidence, debug_findings


# Version the extracted schema; implementation changes also invalidate the cache automatically.
PARSER_VERSION = 8
TRACE_LIMIT = 4000
STEP_LIMIT = 1000
BODY_TAGS = {
    "kw",
    "for",
    "iter",
    "while",
    "group",
    "return",
    "break",
    "continue",
    "error",
}


def file_hash(path):
    with path.open("rb") as stream:
        return file_digest(stream, "sha256").hexdigest()


def extraction_fingerprint():
    """Invalidate cached extraction when its implementation or Robot changes."""
    digest = sha256(robot_version.encode())
    for filename in ("robot_evidence.py", "scoped_evidence.py", "report_output.py"):
        digest.update(Path(__file__).with_name(filename).read_bytes())
    return digest.hexdigest()


def children(node):
    result = []
    if getattr(node, "has_setup", False):
        result.append(node.setup)
    result.extend(getattr(node, "body", ()))
    if getattr(node, "has_teardown", False):
        result.append(node.teardown)
    return result


def failed_keywords(node):
    if getattr(node, "status", None) != "FAIL":
        return []
    failures = [leaf for child in children(node) for leaf in failed_keywords(child)]
    return failures or ([node] if isinstance(node, Keyword) else [])


def short_error(message):
    primary = message.split("\n\nAlso keyword teardown failed:", 1)[0].strip()
    if "No open connection" in primary:
        return (
            "No open connection in teardown"
            if "teardown" in message.lower()
            else "No open connection"
        )
    if "Test execution stopped due to a fatal error" in primary:
        return "Not executed after the run was interrupted"
    if primary.startswith("Parent suite"):
        return "Affected by parent suite setup/teardown failure"
    primary = re.sub(r"^Keyword teardown failed:\s*|^Teardown failed:\s*", "", primary)
    primary = re.sub(r"\s+", " ", primary)
    return primary if len(primary) <= 320 else primary[:317] + "..."


def compact_xml(path, xml_url, inventory):
    """Prune successful bodies while streaming; preserve sibling placeholders/IDs.

    IF/TRY roots have no ID: their branch placeholders must stay in place because
    Robot flattens branches when numbering later siblings. The Robot API still
    parses the compact XML and supplies all final test/keyword anchors.
    """
    frames = []
    traces = defaultdict(lambda: deque(maxlen=TRACE_LIMIT))
    steps = defaultdict(lambda: deque(maxlen=STEP_LIMIT))
    truncated = set()
    retries = defaultdict(list)
    root = None
    scoped = ScopedEvidence(xml_url, inventory)
    for action, element in ET.iterparse(path, events=("start", "end")):
        if action == "start":
            if root is None:
                root = element
            element.attrib.update({key: redact(value) for key, value in element.attrib.items()})
            parent = frames[-1] if frames else None
            anchor = element.get("id")
            if parent and (element.tag in BODY_TAGS or element.tag == "branch"):
                owner = frames[-2] if element.tag == "branch" else parent
                owner["steps"] += 1
                anchor = f"{owner['id']}-k{owner['steps']}"
            scope = parent["scope"] if parent else None
            if element.tag == "test":
                scope = anchor
            elif element.tag == "kw" and parent and parent["element"].tag == "suite":
                scope = "suite:" + parent["id"]
            frames.append(
                {"element": element, "id": anchor, "steps": 0, "scope": scope}
            )
            continue
        if element.text:
            element.text = redact(element.text)
        frame = frames[-1]
        scope = frame["scope"]
        record = None
        if element.tag == "msg" and scope:
            scoped.message(element, frames)
            text = (element.text or "").strip()
            if element.get("level") in (
                "FAIL",
                "ERROR",
                "WARN",
            ):
                record = {
                    "kind": "message",
                    "time": element.get("time", element.get("timestamp", "")),
                    "text": text[:1200],
                    "level": element.get("level"),
                    "id": frames[-2]["id"],
                }
        status = (
            element.find("status")
            if element.tag in BODY_TAGS | {"test", "branch"}
            else None
        )
        if element.tag == "kw" and status is not None and scope:
            scoped.keyword(element, frames)
            parent = frames[-2]["element"]
            if parent.tag == "kw" and parent.get("name", "").lower() == "wait until keyword succeeds":
                retries[scope].append({
                    "wrapper_id": frames[-2]["id"], "id": frame["id"],
                    "name": element.get("name", ""), "status": status.get("status"),
                    "message": status.text or "", "start": status.get("start", status.get("starttime", "")),
                    "elapsed": status.get("elapsed", ""),
                })
            name = element.get("name", "")
            start = status.get("start", status.get("starttime", ""))
            end = status.get("endtime", "")
            if start and status.get("elapsed"):
                end = (
                    datetime.fromisoformat(start)
                    + timedelta(seconds=float(status.get("elapsed")))
                ).isoformat()
            record = {
                "kind": "keyword",
                "name": name,
                "status": status.get("status"),
                "start": start,
                "end": end,
                "time": start,
                "id": frame["id"],
                "args": [],
                "text": (status.text or "")[:1200],
            }
        if record and scope:
            record["context"] = [
                f["element"].get("name", "") for f in frames if f["element"].tag == "kw"
            ]
            # Preserve scenario steps separately so nested loops cannot evict them.
            top_level = element.tag == "kw" and frames[-2]["element"].tag in ("test", "suite")
            if record["kind"] == "keyword":
                record["scenario_step"] = top_level
            events = steps[scope] if top_level else traces[scope]
            if len(events) == events.maxlen:
                truncated.add(scope)
            events.append(record)
        if (
            element.tag == "test"
            and status is not None
            and status.get("status") != "FAIL"
        ):
            traces.pop(scope, None)
            steps.pop(scope, None)
            scoped.discard_debug(scope)
            # Test identities/counts remain; successful bodies are not needed.
            element[:] = [c for c in element if c.tag in ("status", "tag", "doc")]
        elif (
            status is not None
            and element.tag != "test"
            and status.get("status") != "FAIL"
        ):
            # Keep the body item's slot, args, and short direct messages.
            element[:] = [
                c for c in element if c.tag in ("status", "arg", "msg", "var")
            ]
        if element.tag in ("doc", "var") and frames[-2]["element"].tag != "iter":
            element.text = ""
        if element.tag == "msg" and element.text:
            element.text = element.text[:1200]
        frames.pop()
    for scope, events in steps.items():
        traces[scope] = list(events) + list(traces.get(scope, []))
    return BytesIO(ET.tostring(root, encoding="utf-8")), dict(traces), truncated, scoped, retries




def parse_robot(path, xml_url, inventory):
    compact, traces, truncated, scoped, retries = compact_xml(path, xml_url, inventory)
    result = ExecutionResult(compact)
    candidate = urljoin(xml_url, "log.html")
    log_url = candidate if candidate in inventory else None
    phase = {
        "xml_url": xml_url,
        "metadata": dict(result.suite.metadata),
        "sha256": file_hash(path),
        "log_url": log_url,
        "tests": [],
        "suite_failures": [],
        "execution_errors": [],
        "trace_truncated": sorted(truncated),
        "suite_retry_attempts": {
            scope: [dict(a, url=f"{log_url}#{a['id']}" if log_url else xml_url) for a in attempts]
            for scope, attempts in retries.items() if scope.startswith("suite:")
        },
    }

    def stage_of(node):
        while node is not None:
            stage = getattr(node, "type", "").lower()
            if stage in ("setup", "teardown"):
                return stage
            node = getattr(node, "parent", None)
        return "body"

    def points(node):
        return [
            {
                "name": kw.name,
                "stage": stage_of(kw),
                "id": kw.id,
                "message": kw.message,
                "start": kw.start_time.isoformat() if kw.start_time else "",
                "end": kw.end_time.isoformat() if kw.end_time else "",
                "url": f"{log_url}#{kw.id}" if log_url else xml_url,
            }
            for kw in failed_keywords(node)
        ]

    def trace(scope):
        return [
            dict(e, url=f"{log_url}#{e['id']}" if log_url and e.get("id") else xml_url)
            for e in sorted(traces.get(scope, []), key=lambda e: e.get("time", ""))
        ]

    for msg in result.errors.messages:
        phase["execution_errors"].append({"level": msg.level, "message": msg.message})

    def visit(suite, inherited=()):
        fixtures = list(inherited)
        for stage in ("setup", "teardown"):
            if (
                getattr(suite, f"has_{stage}", False)
                and getattr(suite, stage).status == "FAIL"
            ):
                kw = getattr(suite, stage)
                issue = {
                    "suite": suite.full_name,
                    "id": kw.id,
                    "stage": stage,
                    "message": kw.message,
                    "failure_points": points(kw),
                    "url": f"{log_url}#{kw.id}" if log_url else xml_url,
                    "retry_attempts": [
                        dict(a, url=f"{log_url}#{a['id']}" if log_url else xml_url)
                        for a in retries.get("suite:" + suite.id, [])
                        if a["wrapper_id"] == kw.id or a["wrapper_id"].startswith(kw.id + "-")
                    ],
                }
                phase["suite_failures"].append(issue)
                fixtures.append(issue)
        for t in suite.tests:
            message = t.message
            ancestors = []
            ancestor = suite
            while ancestor:
                ancestors.append("suite:" + ancestor.id)
                ancestor = ancestor.parent
            shared_artifacts = {
                item["url"]: dict(item, relation="shared suite diagnostic")
                for scope in ancestors
                for item in scoped.artifacts(scope)
                if PurePosixPath(urlsplit(item["url"]).path).suffix.lower()
                in (".log", ".txt", ".json")
            }
            entry = {
                "name": t.name,
                "full_name": t.full_name,
                "id": t.id,
                "status": t.status,
                "message": message,
                "tags": list(t.tags),
                "retry_attempts": [dict(a, url=f"{log_url}#{a['id']}" if log_url else xml_url)
                                   for a in retries.get(t.id, [])],
                "fixture_dependencies": [
                    {key: issue[key] for key in ("id", "suite", "stage", "url")}
                    for issue in fixtures
                ] if t.status == "FAIL" else [],
                "start_time": t.start_time.isoformat() if t.start_time else "",
                "end_time": t.end_time.isoformat() if t.end_time else "",
                "url": f"{log_url}#{t.id}" if log_url else xml_url,
                "failure_points": points(t) if t.status == "FAIL" else [],
                "failure_origin": (
                    "Parent suite fixture" if fixtures and not points(t) else "Test or its fixture"
                ) if t.status == "FAIL" else None,
                "trace": trace(t.id) if t.status == "FAIL" else [],
                "suite_trace": trace("suite:" + suite.id) if t.status == "FAIL" else [],
                "artifacts": scoped.artifacts(t.id) if t.status == "FAIL" else [],
                "shared_artifacts": list(shared_artifacts.values())
                if t.status == "FAIL"
                else [],
                "debug_observations": list(scoped.debug.get(t.id, []))
                if t.status == "FAIL"
                else [],
                "shared_debug_observations": [
                    observation
                    for scope in ancestors
                    for observation in scoped.debug.get(scope, [])
                ]
                if t.status == "FAIL"
                else [],
                "failure_signature": sha256(
                    (t.full_name + "\n" + re.sub(r"\b\d+\b", "<n>", message)).encode()
                ).hexdigest()[:20]
                if t.status == "FAIL"
                else None,
            }
            if t.status == "FAIL":
                roots = ([t.setup] if t.has_setup else []) + list(t.body)
                entry["primary_start"] = min(
                    (
                        node.start_time.isoformat()
                        for node in roots
                        if getattr(node, "status", None) == "FAIL" and node.start_time
                    ),
                    default=entry["start_time"],
                )
                entry["primary_points"] = [
                    point for node in roots for point in points(node)
                ]
                entry["debug_findings"] = debug_findings(entry)
            phase["tests"].append(entry)
        for child in suite.suites:
            visit(child, fixtures)

    visit(result.suite)
    phase["counts"] = dict(Counter(t["status"] for t in phase["tests"]))
    return redact_data(phase)
