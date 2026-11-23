#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

"""Read Ghaf nightly artifacts and generate a local, evidence-linked report."""

import argparse
from contextlib import contextmanager
import fcntl
from datetime import datetime, timezone
from html.parser import HTMLParser
import json
import re
from hashlib import sha256
from pathlib import Path
import sys
from time import perf_counter
from urllib.error import HTTPError, URLError
from urllib.parse import unquote, urljoin, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

from hw_diagnostics import DIAGNOSTIC_LIMIT, collect_hw_diagnostics
from report_output import print_text, redact, redact_data, write_json
from robot_evidence import PARSER_VERSION, extraction_fingerprint, file_hash, parse_robot
from html_report import render
from scoped_evidence import debug_findings, select_debug_lines
from ai_investigation import cleanup_supplementary, import_investigation, prepare_packet


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        if tag == "a":
            self.links.extend(value for key, value in attrs if key == "href" and value)


def contained_url(base, candidate):
    """Only follow descendants of the supplied artifact directory."""
    root, child = urlsplit(base), urlsplit(candidate)
    path = unquote(child.path)
    return (
        child.scheme == root.scheme
        and child.netloc == root.netloc
        and path.startswith(unquote(root.path))
        and not child.query
        and not child.fragment
        and not any(part in (".", "..") for part in path.split("/"))
        and "\\" not in path
        and "\x00" not in path
    )


class ArtifactRedirects(HTTPRedirectHandler):
    def __init__(self, base):
        self.base = base

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not contained_url(self.base, newurl):
            raise ValueError("Redirect outside artifact directory; verify access or OAuth proxy configuration")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


XML_LIMIT = 1024**3
TEXT_LIMIT = 8 * 1024**2


class Source:
    def __init__(self, base, cache):
        self.base = base
        self.cache = cache
        self.opener = build_opener(ArtifactRedirects(base))
        self.listings = 0
        self.downloaded_bytes = 0

    def get(self, url, listing=False, limit=None):
        if not contained_url(self.base, url):
            raise ValueError(f"URL outside artifact directory: {url}")
        relative = unquote(urlsplit(url).path)[len(unquote(urlsplit(self.base).path)) :]
        path = self.cache / relative
        if listing:
            path = path / ".listing.html"
        limit = limit or (XML_LIMIT if urlsplit(url).path.endswith(".xml") else TEXT_LIMIT)
        if path.is_file():
            if path.stat().st_size > limit:
                raise ValueError(f"Cached file exceeds size limit: {url}")
            return path
        request = Request(url, headers={"User-Agent": "ghaf-nightly-analysis/0.3"})
        with self.opener.open(request, timeout=45) as response:
            expected_size = int(response.headers.get("Content-Length", "0"))
            if expected_size > limit:
                raise ValueError(f"File exceeds {limit // 1024**2} MiB: {url}")
            if expected_size > 16 * 1024 * 1024:
                print_text(
                    f"    Downloading {expected_size / 1024**2:.1f} MiB: {relative}",
                    flush=True,
                )
            path.parent.mkdir(parents=True, exist_ok=True)
            partial = path.with_name(path.name + ".partial")
            try:
                size = 0
                with partial.open("wb") as output:
                    while chunk := response.read(1024 * 1024):
                        size += len(chunk)
                        if size > limit:
                            raise ValueError(f"File exceeds size limit: {url}")
                        output.write(chunk)
                        self.downloaded_bytes += len(chunk)
                if expected_size and size != expected_size:
                    raise ValueError(
                        f"Incomplete download: {url} ({size}/{expected_size} bytes)"
                    )
                partial.replace(path)
            finally:
                partial.unlink(missing_ok=True)
        return path

    def json(self, url):
        return json.loads(self.get(url).read_text())

    def links(self, url):
        self.listings += 1
        if self.listings > 2000:
            raise ValueError("Directory listing limit reached")
        parser = Links()
        parser.feed(self.get(url, listing=True).read_text())
        return sorted(
            {
                candidate
                for href in parser.links
                if contained_url(url, candidate := urljoin(url, href))
                and candidate != url
            }
        )

    def inventory(self, url, depth=0):
        if depth > 12:
            raise ValueError(f"Artifact directory depth limit reached: {url}")
        files = []
        for child in self.links(url):
            if child.endswith("/"):
                files.extend(self.inventory(child, depth + 1))
            else:
                files.append(child)
        return files


def collect(source):
    started = perf_counter()
    parser_fingerprint = extraction_fingerprint()
    report = {
        "schema_version": 2,
        "analyzer_version": "0.3",
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source_url": source.base,
        "analysis_mode": "Observed facts and optional imported AI assessments",
        "performance": {"xml_parsed": 0, "xml_cache_hits": 0, "parse_seconds": 0},
        "targets": [],
        "gaps": [],
    }
    report["scope_notes"] = [
        "Only published artifact results are examined; the expected nightly scope is not verified."
    ]
    failures = (
        HTTPError,
        URLError,
        OSError,
        ValueError,
        TypeError,
        KeyError,
        AttributeError,
    )
    try:
        targets = [
            url
            for url in source.links(source.base)
            if url.endswith("/")
            and unquote(urlsplit(url).path)
            .rstrip("/")
            .split("/")[-1]
            .startswith("packages.")
        ]
    except failures as error:
        report["gaps"].append(f"Cannot list nightly: {error}")
        return redact_data(report)
    if not targets:
        report["gaps"].append("No build target directories found.")
    for index, target_url in enumerate(targets, 1):
        name = unquote(urlsplit(target_url).path).rstrip("/").split("/")[-1]
        print_text(f"[{index}/{len(targets)}] {name}", flush=True)
        try:
            if urljoin(target_url, "test-results.json") not in source.links(target_url):
                continue  # No published HW result; do not infer whether testing was scheduled.
        except failures as error:
            report["gaps"].append(f"Cannot list target {name}: {error}")
            continue
        target = {
            "name": name,
            "url": target_url,
            "manifest": {},
            "runs": [],
            "gaps": [],
            "not_run_reason": None,
        }
        report["targets"].append(target)
        try:
            target["manifest"] = source.json(urljoin(target_url, "manifest.json"))
        except failures as error:
            target["gaps"].append(f"Manifest unavailable: {error}")
        try:
            entries = source.json(urljoin(target_url, "test-results.json"))["tests"]
        except HTTPError as error:
            if error.code == 404:
                target["not_run_reason"] = "Published test-results.json could not be downloaded."
                target["gaps"].append(target["not_run_reason"])
            else:
                target["gaps"].append(f"Cannot read test results: {error}")
            continue
        except failures as error:
            target["gaps"].append(f"Cannot read test results: {error}")
            target["not_run_reason"] = (
                "HW results could not be read; execution status and reason are unknown."
            )
            continue
        if not isinstance(entries, list):
            target["gaps"].append("Invalid test-results.json: tests must be a list.")
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                target["gaps"].append("Invalid HW run entry.")
                continue
            run = {
                "metadata": entry,
                "phases": [],
                "evidence": [],
                "diagnostics": [],
                "gaps": [],
            }
            target["runs"].append(run)
            print_text(
                f"  {entry.get('id', 'unknown')} ({entry.get('status', 'UNKNOWN')})",
                flush=True,
            )
            if entry.get("status") == "SKIPPED":
                # Jenkins records scheduling skips without Robot artifacts.
                continue
            try:
                relative = entry.get("artifacts")
                if not isinstance(relative, str) or not relative.startswith(
                    "test-results/"
                ):
                    raise ValueError("Missing or invalid HW artifact path")
                run_url = urljoin(target_url, relative.rstrip("/") + "/")
                if not contained_url(target_url, run_url):
                    raise ValueError("HW artifact path outside target")
                files = source.inventory(run_url)
                run["evidence"] = [
                    {"name": unquote(url[len(run_url) :]), "url": url} for url in files
                ]
                xmls = [
                    url for url in files if urlsplit(url).path.endswith("/output.xml")
                ]
                for xml_url in xmls:
                    try:
                        path = source.get(xml_url)
                        stat = path.stat()
                        key = [
                            PARSER_VERSION,
                            parser_fingerprint,
                            stat.st_size,
                            stat.st_mtime_ns,
                            xml_url,
                            sha256("\n".join(files).encode()).hexdigest(),
                        ]
                        cached_path = path.with_name(".analysis.json")
                        cached = None
                        if cached_path.is_file():
                            try:
                                cached = json.loads(cached_path.read_text())
                            except (ValueError, OSError):
                                pass
                        if cached and cached.get("key") == key:
                            phase = cached["phase"]
                            report["performance"]["xml_cache_hits"] += 1
                        else:
                            began = perf_counter()
                            phase = parse_robot(path, xml_url, files)
                            report["performance"]["parse_seconds"] += (
                                perf_counter() - began
                            )
                            report["performance"]["xml_parsed"] += 1
                            partial = cached_path.with_suffix(".partial")
                            write_json(partial, {"key": key, "phase": phase})
                            partial.replace(cached_path)
                        run["phases"].append(phase)
                        if not phase["log_url"]:
                            run["gaps"].append(f"No companion log.html for {xml_url}")
                    except Exception as error:
                        # One corrupt Robot output must not hide other phases/configurations.
                        run["gaps"].append(
                            f"Cannot parse {xml_url}: {type(error).__name__}: {error}"
                        )
                if not xmls and entry.get("status") != "SKIPPED":
                    run["gaps"].append(
                        "No Robot output.xml found; test outcome is not known from artifacts."
                    )
                # Read only text artifacts traced to a failed test or its suite
                # fixture. Unrelated run files are never used as diagnostic evidence.
                text_cache = {}
                for phase in run["phases"]:
                    for test in phase["tests"]:
                        if test["status"] != "FAIL":
                            continue
                        artifacts = test.get("artifacts", []) + test.get(
                            "shared_artifacts", []
                        )
                        texts = [
                            item
                            for item in artifacts
                            if Path(urlsplit(item["url"]).path).suffix.lower()
                            in (".txt", ".log", ".json")
                        ]
                        if len(texts) > 12:
                            run["gaps"].append(
                                f"Text evidence limited to 12 files for {test['name']}"
                            )
                        for artifact in texts[:12]:
                            url = artifact["url"]
                            try:
                                # Syslog timestamps use only the reference year.
                                cache_key = (url, test["start_time"][:4])
                                if cache_key not in text_cache:
                                    path = source.get(url, limit=DIAGNOSTIC_LIMIT)
                                    with path.open(errors="replace") as stream:
                                        lines = select_debug_lines(stream, test["start_time"])
                                    text_cache[cache_key] = (lines, file_hash(path))
                                lines, digest = text_cache[cache_key]
                                artifact["sha256"] = digest
                                origin = dict(artifact["origin"], url=url)
                                artifact["log_observations"] = [
                                    {
                                        "origin": origin,
                                        "command": "Archived text diagnostic",
                                        "lines": lines,
                                    }
                                ]
                            except failures as error:
                                note = f"Cannot read related diagnostic {url}: {error}"
                                if note not in run["gaps"]:
                                    run["gaps"].append(note)
                        test.pop("analysis", None)
                        test["debug_findings"] = debug_findings(test)
                if entry.get("status") != "SKIPPED" and not any(
                    phase["tests"] for phase in run["phases"]
                ):
                    run["gaps"].append(
                        "No test cases could be extracted for this HW run."
                    )
            except failures as error:
                run["gaps"].append(f"Cannot collect HW run: {error}")
            collect_hw_diagnostics(source, run)
    if not report["targets"]:
        report["gaps"].append("No published HW test-results.json was found in the artifact directories.")
    report["performance"]["elapsed_seconds"] = round(perf_counter() - started, 3)
    report["performance"]["downloaded_bytes"] = source.downloaded_bytes
    return redact_data(report)


def validate_url(url):
    parsed = urlsplit(url)
    if (parsed.scheme not in ("http", "https") or not parsed.hostname
            or parsed.username or parsed.password or parsed.query or parsed.fragment
            or "/job/" in parsed.path
            or not contained_url(url.rstrip("/") + "/", url.rstrip("/") + "/")):
        raise ValueError("Supply a published artifacts HTTP(S) directory URL without credentials or traversal")
    return url.rstrip("/") + "/"


def default_output(url):
    name = unquote(urlsplit(url).path.rstrip("/").rsplit("/", 1)[-1])
    stamp = re.fullmatch(r"(\d{8})_(\d{9})-commit_[a-fA-F0-9]{40}", name)
    if not stamp:
        raise ValueError("Use --output when the artifacts URL has no recognized nightly date")
    day = datetime.strptime(stamp[1], "%Y%m%d").strftime("%Y-%m-%d")
    return Path.home() / "Reports" / "ghaf-nightly" / day / stamp[2]


def reusable_output(url):
    output = default_output(url).expanduser().resolve()
    matches = []
    for candidate in output.parent.glob("nightly-*/source.json"):
        try:
            if json.loads(candidate.read_text()).get("url") == url:
                matches.append(candidate.parent)
        except (OSError, ValueError, AttributeError):
            continue
    if len(matches) > 1:
        raise ValueError("Multiple saved directories match this URL; select one with --output")
    return matches[0] if matches else output


def published_upstream(report):
    identities = set()
    for target in report["targets"]:
        for run in target["runs"]:
            for phase in run["phases"]:
                metadata = {key.upper(): str(value) for key, value in phase.get("metadata", {}).items()}
                project, build = metadata.get("UPSTREAM_PROJECT", ""), metadata.get("UPSTREAM_BUILD_ID", "")
                if project.rsplit("/", 1)[-1] == "ghaf-nightly" and re.fullmatch(r"[0-9]+", build):
                    identities.add((project, build))
    if len(identities) == 1:
        project, build = identities.pop()
        report["upstream"] = {"project": project, "build": build}
    elif identities:
        report["gaps"].append("Published upstream build identifiers disagree; no nightly number was selected.")


@contextmanager
def output_lock(output):
    """Allow one CLI operation per output directory, including collection and render."""
    # Keep the file so all invocations lock the same inode, including after a rename.
    with (output / ".nightly-analyze.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError(f"Another analyzer is using this output directory: {output}") from None
        try:
            yield
        finally:
            fcntl.flock(lock, fcntl.LOCK_UN)


def analyze(args, output, url=None):
    previous_evidence = None
    source_path = output / "source.json"
    if url is None:
        report = redact_data(json.loads((output / "analysis.json").read_text()))
        if report.get("schema_version") != 2:
            raise ValueError("Unsupported saved analysis schema")
        if source_path.is_file() and redact(json.loads(source_path.read_text())["url"]) != report["source_url"]:
            raise ValueError("Saved analysis belongs to a different nightly")
        if args.prepare_investigation:
            print_text(f"Agent input: {prepare_packet(report, output)}")
            return 0
        if args.investigation:
            previous_evidence = import_investigation(args.investigation, report, output)
    else:
        if source_path.is_file() and json.loads(source_path.read_text())["url"] != url:
            raise ValueError("This output directory belongs to a different nightly")
        source_path.write_text(json.dumps({"schema_version": 1, "url": url}) + "\n", encoding="utf-8")
        report = collect(Source(url, output / "cache"))
        published_upstream(report)
        if not args.output and report.get("upstream"):
            numbered = output.with_name("nightly-" + report["upstream"]["build"])
            if numbered != output:
                if numbered.exists():
                    print_text(f"Warning: {numbered} already exists; keeping reports in {output}")
                else:
                    output.rename(numbered)
                    output = numbered
    render(report, output, without_ai=args.without_ai)
    if previous_evidence is not None:
        cleanup_supplementary(previous_evidence, output)
    print_text(f"Detailed report: {output / 'report.html'}")
    print_text(f"Summary HTML: {output / 'summary.html'}")
    print_text(f"Counts: {report['counts']}; collection gaps: {len(report['collection_gaps'])}")
    return 0


def main():
    parser = argparse.ArgumentParser(prog="nightly-analyze", description=__doc__)
    parser.add_argument("--url", help="Published nightly artifacts directory URL")
    parser.add_argument("--output", type=Path, help="Result directory; otherwise use nightly date and timestamp")
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--render-only", action="store_true", help="Render saved analysis without network or XML parsing")
    modes.add_argument("--prepare-investigation", action="store_true", help="Prepare the saved run for the agent")
    parser.add_argument("--investigation", type=Path, help="Import findings with --render-only")
    parser.add_argument(
        "--without-ai", action="store_true", help="Render facts while preserving the saved findings file"
    )
    args = parser.parse_args()
    if args.investigation and not args.render_only:
        parser.error("Use --investigation with --render-only")
    if args.without_ai and (args.investigation or args.prepare_investigation):
        parser.error("--without-ai cannot be combined with --investigation or --prepare-investigation")
    try:
        saved_mode = args.render_only or args.prepare_investigation
        url = None
        if saved_mode:
            if not args.output or args.url:
                raise ValueError("Saved operations require --output and do not accept --url")
            output = args.output.expanduser().resolve()
        else:
            if not args.url:
                raise ValueError("--url is required for collection")
            url = validate_url(args.url)
            output = (args.output or reusable_output(url)).expanduser().resolve()
            output.mkdir(parents=True, exist_ok=True)
        with output_lock(output):
            return analyze(args, output, url)
    except (OSError, ValueError, TypeError, KeyError) as error:
        print_text(f"{parser.prog}: error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
