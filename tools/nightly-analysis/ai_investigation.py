# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Portable investigation packets and persistent, evidence-bound AI assessments.

This module never calls a model. An interactive agent supplies the sidecar.
Validation checks provenance/shape, not the truth of the supplied reasoning.
"""

from copy import deepcopy
from datetime import datetime, timezone
from hashlib import sha256
import json
import re
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import urldefrag, urlsplit

from report_output import json_text, print_text, redact, redact_data, save_evidence, write_json


def cases(report):
    for target in report["targets"]:
        for run in target["runs"]:
            for phase in run["phases"]:
                for test in phase["tests"]:
                    if (
                        test["status"] == "FAIL"
                        and test["failure_origin"] == "Test or its fixture"
                    ):
                        case_id = sha256(
                            (phase["xml_url"] + "\n" + test["id"]).encode()
                        ).hexdigest()[:20]
                        yield case_id, target, run, phase, test


def input_digest(report):
    inputs = {
        "source_url": report["source_url"],
        "selection": report.get("selection"),
        "gaps": report.get("gaps", []),
        "targets": [],
    }
    for target in report["targets"]:
        item = {
            "name": target["name"],
            "source": target["manifest"].get("source"),
            "gaps": target["gaps"],
            "runs": [],
        }
        for run in target["runs"]:
            phases = []
            for phase in run["phases"]:
                # Hash extracted evidence too: parser changes can alter observations
                # while the original XML/file hashes remain the same.
                tests = [
                    {key: value for key, value in test.items()
                     if key not in ("facts", "execution", "ai_assessment", "analysis")}
                    for test in phase["tests"]
                ]
                phases.append(dict(phase, tests=tests))
            item["runs"].append(
                {
                    "metadata": run["metadata"], "phases": phases, "gaps": run["gaps"],
                    "diagnostics": run.get("diagnostics", []),
                    "diagnostic_notes": run.get("diagnostic_notes", []),
                }
            )
        inputs["targets"].append(item)
    return sha256(
        json.dumps(inputs, sort_keys=True, ensure_ascii=False).encode()
    ).hexdigest()


def prepare_packet(report, output):
    report = redact_data(report)
    packet = {
        "schema_version": 1,
        "source_url": report["source_url"],
        "input_digest": input_digest(report),
        "prepared_at": datetime.now(timezone.utc).isoformat(),
        "collection_notes": report.get("collection_notes", []),
        "cases": [],
    }
    for case_id, target, run, phase, test in cases(report):
        trace = test.get("trace", [])
        start = test.get("primary_start", test["start_time"])
        preceding = [e for e in trace if e.get("time", "") < start]
        preceding_steps = [e for e in preceding if e.get("scenario_step")]
        selected = (preceding_steps or preceding)[-10:] + [e for e in trace if e.get("time", "") >= start]
        case_path = output / "investigation-cases" / (case_id + ".json")
        case_path.parent.mkdir(exist_ok=True)
        context = {
            "case_path": case_path.relative_to(output).as_posix(),
            "analysis_path": "analysis.json",
            "test_id": test["id"],
        }
        details = {
            "case_id": case_id,
            "target": target["name"],
            "configuration": run["metadata"],
            "ghaf_source": target["manifest"].get("source"),
            "test_id": test["id"],
            "test_name": test["full_name"],
            "test_url": test["url"],
            "original_error": test["message"],
            "start_time": test["start_time"],
            "end_time": test["end_time"],
            "failure_points": test["failure_points"],
            "trace_excerpt": selected[:35] + selected[-15:]
            if len(selected) > 50
            else selected,
            "debug_leads": test.get("debug_findings", [])[:8],
            "context": context,
        }
        for field in ("artifacts", "shared_artifacts"):
            details[field] = [
                {
                    key: artifact[key]
                    for key in ("name", "url", "relation", "origin", "sha256")
                    if key in artifact
                }
                for artifact in test.get(field, [])
            ]
        write_json(case_path, details)
        packet["cases"].append(
            {
                "case_id": case_id,
                "target": target["name"],
                "configuration_id": run["metadata"].get("id"),
                "test_name": test["full_name"],
                "test_url": test["url"],
                "error_excerpt": test["message"][:400],
                "context": context,
            }
        )
    path = output / "investigation-input.json"
    write_json(path, packet)
    return path


def known_urls(phase, test):
    urls = {test["url"], phase["xml_url"]}
    for item in (
        test.get("failure_points", [])
        + test.get("trace", [])
        + test.get("suite_trace", [])
    ):
        if item.get("url"):
            urls.add(item["url"])
    for item in test.get("artifacts", []) + test.get("shared_artifacts", []):
        urls.add(item["url"])
        urls.add(item["origin"]["url"])
    for item in test.get("debug_observations", []) + test.get(
        "shared_debug_observations", []
    ):
        urls.add(item["origin"]["url"])
    return urls


def required_text(item, key, limit=12000):
    if not isinstance(item, dict):
        raise ValueError("Investigation records must be objects")
    value = item.get(key)
    if not isinstance(value, str) or not value.strip() or len(value) > limit:
        raise ValueError(f"{key} must be nonempty text (at most {limit} characters)")
    return value


def validate(document, report, evidence_root=None):
    if not isinstance(document, dict):
        raise ValueError("AI investigation must be an object")
    if type(document.get("schema_version")) is not int or document["schema_version"] not in (1, 2):
        raise ValueError("Unsupported AI investigation schema")
    if document.get("source_url") != report["source_url"]:
        raise ValueError("AI investigation belongs to a different nightly")
    if document.get("input_digest") != input_digest(report):
        raise ValueError("AI investigation is stale: the input evidence changed")
    required_text(document, "analyst", 200)
    stamp = required_text(document, "created_at", 100)
    moment = datetime.fromisoformat(stamp.replace("Z", "+00:00"))
    if moment.tzinfo is None:
        raise ValueError("created_at needs an explicit timezone")
    records = document.get("cases")
    if not isinstance(records, list) or not records:
        raise ValueError("AI investigation needs at least one case")
    available = {cid: (phase, test) for cid, _, _, phase, test in cases(report)}
    supplementary = validate_supplementary(document, available, evidence_root)
    seen = set()
    for item in records:
        if not isinstance(item, dict):
            raise ValueError("AI case must be an object")
        cid = item.get("case_id")
        if not isinstance(cid, str) or cid not in available or cid in seen:
            raise ValueError(f"Unknown or duplicate case_id: {cid}")
        seen.add(cid)
        for field in ("finding", "explanation", "recommendation"):
            required_text(item, field)
        for field in ("summary", "slack_summary"):
            if field in item:
                summary = required_text(item, field, 320)
                if "\n" in summary or "\r" in summary:
                    raise ValueError(f"{field} must be a single line")
        if item.get("confidence") not in ("low", "medium", "high"):
            raise ValueError("confidence must be low, medium, or high")
        if item.get("category") not in (
            "test",
            "product",
            "infrastructure",
            "hardware",
            "undetermined",
        ):
            raise ValueError("Invalid investigation category")
        if not isinstance(item.get("limitations"), list) or not all(
            isinstance(v, str) for v in item["limitations"]
        ):
            raise ValueError("limitations must be a list of strings")
        evidence = item.get("evidence")
        if not isinstance(evidence, list) or not evidence:
            raise ValueError("Each AI case needs cited observations")
        phase, test = available[cid]
        urls = known_urls(phase, test)
        for observation in evidence:
            required_text(observation, "observation")
            if "evidence_id" in observation:
                eid = required_text(observation, "evidence_id", 80)
                if ("url" in observation or eid not in supplementary
                        or cid not in supplementary[eid][0]["case_ids"]):
                    raise ValueError("Supplementary evidence is not linked to this case or has an ambiguous URL")
                continue
            url = required_text(observation, "url", 10000)
            parsed = urlsplit(url)
            # Exact collected local URLs are allowed; arbitrary local files are not.
            if parsed.scheme == "file" and url in urls and not parsed.netloc:
                continue
            if (
                parsed.scheme not in ("http", "https")
                or not parsed.hostname
                or parsed.username
                or parsed.password
            ):
                raise ValueError("Evidence URL must be HTTP(S) without credentials")
            base, fragment = urldefrag(url)
            in_test = (
                base == phase.get("log_url")
                and (fragment == test["id"] or fragment.startswith(test["id"] + "-"))
                and re.fullmatch(r"[stk]\d+(?:-[stk]\d+)*", fragment)
            )
            if url not in urls and not in_test:
                raise ValueError(f"Evidence is not linked to this case: {url}")
        if not isinstance(item.get("source_refs", []), list):
            raise ValueError("source_refs must be a list")
        for reference in item.get("source_refs", []):
            url = required_text(reference, "url", 10000)
            revision = required_text(reference, "revision", 40)
            required_text(reference, "note")
            parsed = urlsplit(url)
            if (
                not re.fullmatch(r"[a-fA-F0-9]{40}", revision)
                or parsed.scheme != "https"
                or not parsed.netloc
                or parsed.username
                or parsed.password
                or revision not in parsed.path
            ):
                raise ValueError(
                    "Source references must be HTTPS links pinned to a full commit SHA"
                )
    return document


def import_investigation(path, report, output):
    """Accept findings; return previous evidence records for cleanup after rendering."""
    if path.stat().st_size > 2 * 1024 * 1024:
        raise ValueError("AI investigation exceeds 2 MiB")
    document = validate(json.loads(path.read_text()), report, path.parent)
    supplementary = validate_supplementary(
        document, {cid for cid, *_ in cases(report)}, path.parent
    )
    normalize_supplementary(supplementary)
    content = json_text(document).encode("utf-8")
    if len(content) > 2 * 1024 * 1024:
        raise ValueError("Normalized JSON export exceeds its size limit")
    save_supplementary(supplementary, output)
    target = output / "ai-investigation.json"
    previous = []
    if target.is_file() and not target.is_symlink() and target.stat().st_size <= 2 * 1024 * 1024:
        try:
            previous = json.loads(target.read_text()).get("supplementary_evidence", [])
        except (ValueError, AttributeError):
            pass
    partial = target.with_suffix(".partial")
    try:
        partial.write_bytes(content)
        partial.replace(target)
    finally:
        partial.unlink(missing_ok=True)
    return previous


def attach_investigation(report, output, without_ai=False):
    entries = list(cases(report))
    for target in report["targets"]:
        for run in target["runs"]:
            for phase in run["phases"]:
                for test in phase["tests"]:
                    test.pop("ai_assessment", None)
    report.pop("ai_investigation", None)
    if without_ai:
        return
    path = output / "ai-investigation.json"
    if not path.is_file():
        return
    try:
        if path.stat().st_size > 2 * 1024 * 1024:
            raise ValueError("AI investigation exceeds 2 MiB")
        document = validate(json.loads(path.read_text()), report, output)
        supplementary = validate_supplementary(document, {cid for cid, *_ in entries}, output)
        for _, content in supplementary.values():
            if redact(content.decode("utf-8")).encode("utf-8") != content:
                raise ValueError("Reimport findings to mask legacy supplementary evidence before linking it")
    except (OSError, ValueError, TypeError, KeyError) as error:
        report["ai_investigation"] = {"state": "not_applied", "message": str(error)}
        return
    supplementary = {item["id"]: item for item in document.get("supplementary_evidence", [])}
    indexed = {item["case_id"]: deepcopy(item) for item in document["cases"]}
    for item in indexed.values():
        for observation in item["evidence"]:
            if "evidence_id" in observation:
                record = supplementary[observation["evidence_id"]]
                observation["url"] = record["path"]
                observation["provenance"] = record["provenance"]
                observation["sha256"] = record["sha256"]
    for cid, _, _, _, test in entries:
        if cid in indexed:
            test["ai_assessment"] = indexed[cid]
    report["ai_investigation"] = {
        "state": "current",
        "analyst": document["analyst"],
        "created_at": document["created_at"],
        "reviewed_cases": len(indexed),
        "total_cases": len(entries),
        "coverage": "complete" if len(indexed) == len(entries) else "partial",
    }


def timestamp(record, key):
    value = datetime.fromisoformat(required_text(record, key).replace("Z", "+00:00"))
    if value.tzinfo is None:
        raise ValueError(f"Supplementary evidence {key} needs an explicit timezone")
    return value


def validate_supplementary(document, case_ids, root):
    records = document.get("supplementary_evidence", [])
    if not isinstance(records, list) or len(records) > 32:
        raise ValueError("supplementary_evidence must be an array of at most 32 records")
    if records and document["schema_version"] != 2:
        raise ValueError("Supplementary evidence requires schema_version 2")
    indexed = {}
    for record in records:
        if not isinstance(record, dict):
            raise ValueError("Supplementary evidence records must be objects")
        eid = required_text(record, "id")
        if not re.fullmatch(r"[A-Za-z0-9_-]{1,80}", eid) or eid in indexed:
            raise ValueError("Invalid or duplicate supplementary evidence id")
        owners = record.get("case_ids")
        if (not isinstance(owners, list) or not owners
                or any(not isinstance(cid, str) or cid not in case_ids for cid in owners)
                or len(set(owners)) != len(owners)):
            raise ValueError("Supplementary evidence needs unique known case_ids")
        provenance = record.get("provenance")
        if not isinstance(provenance, dict):
            raise ValueError("Supplementary evidence needs provenance")
        for key in ("kind", "query", "device", "vm", "limits"):
            required_text(provenance, key)
        source = urlsplit(required_text(provenance, "source"))
        if source.scheme != "https" or not source.hostname or source.username or source.password:
            raise ValueError("Supplementary source must be HTTPS without credentials")
        start, end = timestamp(provenance, "start"), timestamp(provenance, "end")
        retrieved = timestamp(provenance, "retrieved_at")
        if start > end or retrieved < end:
            raise ValueError("Supplementary evidence timestamps are out of order")
        relative = PurePosixPath(required_text(record, "path"))
        if relative.is_absolute() or ".." in relative.parts or "\\" in str(relative):
            raise ValueError("Supplementary path must stay inside the findings directory")
        if root is None:
            raise ValueError("Supplementary evidence needs a local findings directory")
        path = (Path(root) / str(relative)).resolve()
        if not path.is_relative_to(Path(root).resolve()) or not path.is_file():
            raise ValueError("Supplementary evidence file is missing or outside the findings directory")
        if path.stat().st_size > 2 * 1024 * 1024:
            raise ValueError("Supplementary evidence exceeds 2 MiB")
        content = path.read_bytes()
        if sha256(content).hexdigest() != required_text(record, "sha256"):
            raise ValueError("Supplementary evidence digest mismatch")
        try:
            content.decode("utf-8")
        except UnicodeDecodeError as error:
            raise ValueError("Supplementary evidence must be UTF-8 text") from error
        indexed[eid] = (record, content)
    return indexed


def normalize_supplementary(indexed):
    for record, content in indexed.values():
        digest = sha256(redact(content.decode("utf-8")).encode("utf-8")).hexdigest()
        record.pop("original_sha256", None)
        record.pop("sha256_scope", None)
        record["sha256"] = digest
        record["sha256_scope"] = "redacted UTF-8 excerpt"
        record["path"] = "investigation-evidence/" + digest + ".txt"


def save_supplementary(indexed, output):
    if (output / "investigation-evidence").is_symlink():
        raise ValueError("Supplementary evidence directory must not be a symlink")
    for record, content in indexed.values():
        save_evidence(output, content.decode("utf-8"))


def cleanup_supplementary(previous, output):
    """Best-effort cleanup after the caller has successfully rendered both reports."""
    try:
        document = json.loads((output / "ai-investigation.json").read_text())
        retained = {record["path"] for record in document.get("supplementary_evidence", [])}
        prune_supplementary(previous, retained, output)
    except (OSError, ValueError, TypeError, KeyError) as error:
        print_text(f"Warning: reports saved; obsolete evidence cleanup failed: {error}", file=sys.stderr)


def prune_supplementary(previous, retained, output):
    """Remove only obsolete files owned by the previous accepted sidecar."""
    directory = output / "investigation-evidence"
    if directory.is_symlink():
        raise ValueError("Supplementary evidence directory must not be a symlink")
    for record in previous if isinstance(previous, list) else []:
        relative = record.get("path") if isinstance(record, dict) else None
        if not isinstance(relative, str) or not re.fullmatch(r"investigation-evidence/[0-9a-f]{64}\.txt", relative):
            continue
        path = output / relative
        if (relative not in retained and path.is_file() and not path.is_symlink()
                and path.stem == record.get("sha256") and path.stat().st_size <= 2 * 1024 * 1024
                and sha256(path.read_bytes()).hexdigest() == record["sha256"]):
            path.unlink()
