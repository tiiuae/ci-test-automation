# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Associate debug evidence with the Robot calls that produced it."""

from collections import defaultdict, deque
from datetime import datetime
from html import unescape
from pathlib import PurePosixPath
import re
import shlex
from urllib.parse import unquote, urljoin, urlsplit

from report_output import redact


FILE_TOKEN = re.compile(
    r"""[^\s<>"']+\.(?:jpe?g|png|mkv|mp4|wav|txt|log|json|csv)(?=$|[\s<>"'),;])""", re.I
)
DEBUG_CONTEXT = re.compile(
    r"debug|diagnostic|journal|dmesg|not running services|service.*status", re.I
)
DEBUG_COMMAND = re.compile(
    r"\bjournalctl\b|\bdmesg\b|\bsystemctl\s+(?:--\S+\s+)*(?:status|--failed)|\bcat\b.*\.(?:log|txt)\b",
    re.I,
)
ERROR_LINE = re.compile(
    r"\berror\b|\bfailed\b|segfault|segmentation fault|core dumped|permission denied|connection refused|"
    r"timed out|read-only file system|no space left|traceback|exception|killed process|\bfatal\b",
    re.I,
)
NOISE_LINE = re.compile(
    r"Kernel command line:|kernel: Command line:|fail2ban|Core Dump Socket|Errors collector initialized",
    re.I,
)


def log_time(line, reference):
    """Return a comparable wall-clock value, without assuming a timezone."""
    iso = re.search(r"\b(\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d)", line)
    if iso:
        return iso[1].replace(" ", "T")
    stamp = re.search(r"\b([A-Z][a-z]{2}\s+\d{1,2}\s+\d\d:\d\d:\d\d)\b", line)
    if stamp and reference:
        try:
            moment = datetime.strptime(
                reference[:4] + " " + stamp[1], "%Y %b %d %H:%M:%S"
            )
            return moment.isoformat()
        except ValueError:
            pass
    return ""


def select_debug_lines(text, reference="", limit=60):
    matches = deque(maxlen=limit)
    lines = text.splitlines() if isinstance(text, str) else text
    for number, line in enumerate(lines, 1):
        if ERROR_LINE.search(line) and not NOISE_LINE.search(line):
            matches.append(
                {
                    "line": number,
                    "text": redact(line.rstrip("\r\n"))[:1200],
                    "log_time": log_time(line, reference),
                }
            )
    return list(matches)


class ScopedEvidence:
    def __init__(self, xml_url, inventory):
        self.xml_url = xml_url
        self.log_url = urljoin(xml_url, "log.html")
        self.files = list(inventory)
        self.file_set = set(inventory)
        self.by_name = defaultdict(list)
        for url in inventory:
            self.by_name[PurePosixPath(unquote(urlsplit(url).path)).name].append(url)
        self.references = defaultdict(dict)
        self.owners = defaultdict(set)
        self.debug = defaultdict(lambda: deque(maxlen=160))
        self.limits = set()

    def origin(self, frames, time=""):
        keywords = [f for f in frames if f["element"].tag == "kw"]
        stage = (
            "teardown"
            if any(f["element"].get("type") == "TEARDOWN" for f in keywords)
            else "setup"
            if any(f["element"].get("type") == "SETUP" for f in keywords)
            else "body"
        )
        anchor = next((f["id"] for f in reversed(frames) if f.get("id")), None)
        return {
            "time": time,
            "stage": stage,
            "scope": frames[-1]["scope"],
            "context": [f["element"].get("name", "") for f in keywords],
            "url": f"{self.log_url}#{anchor}"
            if self.log_url in self.file_set and anchor
            else self.xml_url,
        }

    def resolve(self, token):
        token = unquote(unescape(token)).strip(" \t\n'\"")
        if token.startswith("to="):
            token = token[3:]
        if "${" in token or "@{" in token:
            return None
        path = urlsplit(token).path
        name = PurePosixPath(path).name
        if name.lower() in (
            "screenshot.jpeg",
            "screenshot.png",
            "log.html",
            "report.html",
            "output.xml",
            "result.json",
        ):
            return None  # Mutable scratch images and run-level reports are not test evidence.
        candidates = self.by_name.get(name, [])
        if "/Robot-Framework/" in path:
            suffix = path[path.index("/Robot-Framework/") :]
            exact = [
                url
                for url in candidates
                if unquote(urlsplit(url).path).endswith(suffix)
            ]
            if (
                not exact
                and str(PurePosixPath(suffix).parent) == "/Robot-Framework/test-suites"
            ):
                # ghaf_robot_test moves top-level outputs into the phase folder.
                phase = PurePosixPath(urlsplit(self.xml_url).path).parent.name
                archived = str(PurePosixPath(suffix).parent / phase / name)
                exact = [
                    url
                    for url in candidates
                    if unquote(urlsplit(url).path).endswith(archived)
                ]
            candidates = exact
        elif path.startswith(("./", "../")):
            resolved = urljoin(self.xml_url, token)
            candidates = [url for url in candidates if url == resolved]
        elif "/outputs/" in path:
            suffix = path[path.index("/outputs/") :]
            candidates = [
                url
                for url in candidates
                if unquote(urlsplit(url).path).endswith(suffix)
            ]
        if len(candidates) != 1 or "/outputs/icons/" in unquote(candidates[0]):
            return None
        return candidates[0]

    def reference(self, scope, token, origin, relation):
        url = self.resolve(token)
        if not url:
            return
        self.owners[url].add(scope)
        previous = self.references[scope].get(url)
        if previous and previous["relation"] == "downloaded/copied by this scope":
            return
        self.references[scope][url] = {
            "name": unquote(urlsplit(url).path).split("/Robot-Framework/")[-1],
            "url": url,
            "relation": relation,
            "origin": origin,
        }

    def message(self, element, frames):
        scope = frames[-1]["scope"]
        if not scope:
            return
        text = unescape(element.text or "")
        origin = self.origin(frames, element.get("time", element.get("timestamp", "")))
        names = origin["context"]
        # Resolve producer messages, never filenames from directory listings or
        # unrelated read operations inside a broadly named wrapper.
        arrow = re.search(r"['\"]([^'\"]+)['\"]\s*->\s*['\"]([^'\"]+)['\"]", text)
        if arrow and any(
            name.lower() in ("get file", "copy file", "copy files") for name in names
        ):
            self.reference(scope, arrow[2], origin, "downloaded/copied by this scope")
        saved = re.search(r"Saving debug screenshot\s+(\S+)", text)
        if saved:
            self.reference(scope, saved[1], origin, "saved screenshot")
        if text.startswith("Starting process:"):
            try:
                args = shlex.split(text.split("\n", 1)[-1])
                if (
                    args
                    and PurePosixPath(args[0]).name in ("cp", "mv")
                    and len(args) >= 3
                ):
                    self.reference(
                        scope, args[-1], origin, "downloaded/copied by this scope"
                    )
            except ValueError:
                pass
        producers = any(
            re.search(
                r"write advanced testlog|save.*(?:log|screenshot)|capture.*screenshot|get diff images",
                name,
                re.I,
            )
            for name in names
        )
        if producers:
            tokens = re.findall(r"""(?:href|src)=["']([^"']+)["']""", text)
            if any(name.lower() == "get diff images" for name in names) and re.match(
                r"\$\{[^}]+\} = ", text
            ):
                tokens.append(text.split(" = ", 1)[-1].strip())
            for token in tokens:
                self.reference(scope, token, origin, "saved/linked by debug wrapper")

        command = re.search(r"Executing command '(.*)'\.", text, re.S)
        if command:
            for frame in reversed(frames):
                if frame["element"].tag == "kw" and frame["element"].get(
                    "name", ""
                ).lower() in ("run command", "execute command"):
                    frame["command"] = command[1]
        active_command = next(
            (f["command"] for f in reversed(frames) if f.get("command")), ""
        )
        if DEBUG_CONTEXT.search(" / ".join(names)) or DEBUG_COMMAND.search(
            active_command
        ):
            findings = select_debug_lines(text, origin["time"])
            if findings:
                if len(self.debug[scope]) == 160:
                    self.limits.add(scope)
                self.debug[scope].append(
                    {
                        "origin": origin,
                        "command": active_command[:500],
                        "lines": findings,
                    }
                )

    def keyword(self, element, frames):
        status = element.find("status")
        scope = frames[-1]["scope"]
        if not scope or status is None or status.get("status") != "PASS":
            return
        name = element.get("name", "").lower()
        args = [arg.text or "" for arg in element.findall("arg")]
        token = None
        if name in ("get file", "copy file") and len(args) >= 2:
            token = args[1]
        elif (
            name
            in (
                "write advanced testlog",
                "create file",
                "append to file",
                "capture page screenshot",
            )
            and args
        ):
            token = args[0]
        if token:
            self.reference(
                scope,
                token,
                self.origin(frames, status.get("start", "")),
                "saved by keyword",
            )

    def artifacts(self, scope):
        return [
            item
            for url, item in self.references.get(scope, {}).items()
            if len(self.owners[url]) == 1
        ]

    def discard_debug(self, scope):
        self.debug.pop(scope, None)


def debug_findings(test):
    """Rank scoped observations; older journal errors are not promoted to causes."""
    observations = list(test.get("debug_observations", [])) + list(
        test.get("shared_debug_observations", [])
    )
    for artifact in test.get("artifacts", []) + test.get("shared_artifacts", []):
        if artifact.get("log_observations"):
            observations.extend(artifact["log_observations"])
    found = {}
    start, end = test["start_time"][:19], test["end_time"][:19]
    failure = min(
        (
            point["end"][:19]
            for point in test.get("primary_points", [])
            or test.get("failure_points", [])
            if point.get("end")
        ),
        default=end,
    )
    for observation in observations:
        for item in observation["lines"]:
            moment = item.get("log_time", "")
            when = (
                "earlier than test"
                if moment and moment < start
                else "after test"
                if moment and moment > end
                else "during test (clock alignment unverified)"
                if moment
                else "no source timestamp"
            )
            text = re.sub(r"^Output:\s*", "", item["text"])
            if moment and failure < moment <= end:
                when = "after failure (cleanup may affect this record)"
            if re.match(r"\$\{[^}]+\}(?:\[.*?\])? = (?:failed|False|None|\{|\[)", text):
                continue  # Assignment echoes add no evidence beyond the source record.
            if (
                not moment
                and re.search(r"loaded\s+failed\s+failed", text)
                and start <= observation["origin"].get("time", "")[:19] <= end
            ):
                when = "state captured during test"
            normalized = re.sub(
                r"\d{4}-\d\d-\d\d[T ]\d\d:\d\d:\d\d(?:\.\d+)?Z?|[A-Z][a-z]{2}\s+\d+\s+\d\d:\d\d:\d\d",
                "<time>",
                text,
            )
            normalized = re.sub(r"\b\d+\b", "<n>", normalized)
            key = (normalized, when)
            found.setdefault(
                key,
                {
                    "text": text,
                    "timing": when,
                    "log_time": moment,
                    "line": item["line"],
                    "origin": observation["origin"],
                    "command": observation.get("command", ""),
                },
            )

    def rank(item):
        timing = item["timing"]
        temporal = (
            0
            if timing.startswith(("during test", "state captured"))
            else 1
            if timing == "no source timestamp"
            else 2
            if timing.startswith("after")
            else 3
        )
        severity = (
            0
            if re.search(
                r"segfault|core dumped|permission denied|failed to start|connection refused|"
                r"no space left|QXcb|libva|EGL|GLX",
                item["text"],
                re.I,
            )
            else 1
        )
        distance = (
            abs(
                (
                    datetime.fromisoformat(item["log_time"])
                    - datetime.fromisoformat(end)
                ).total_seconds()
            )
            if item["log_time"] and end
            else float("inf")
        )
        return temporal, severity, distance

    ordered = sorted(found.values(), key=rank)
    return ordered[:24]
