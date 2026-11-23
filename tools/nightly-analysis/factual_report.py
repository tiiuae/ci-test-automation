# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
"""Observed Robot failures, kept separate from rule and AI assessments."""

from collections import Counter
from urllib.parse import urljoin, urlsplit



def failure_facts(test, phase):
    points = test.get("failure_points", [])
    primary = test.get("primary_points", [])
    dependencies = test.get("fixture_dependencies", [])
    limitations = ["Underlying cause and dependencies on other tests are not established."]
    if not phase.get("log_url"):
        limitations.append("Companion Robot log.html is unavailable; links point to XML.")
    if test["id"] in phase.get("trace_truncated", []):
        limitations.append(
            "Context trace is limited to 1000 scenario steps and 4000 nested events; earlier events may be omitted."
        )
    if "retry_attempts" not in test:
        limitations.append("Retry attempts were not extracted by this parser version; reprocess the XML.")
    if "fixture_dependencies" not in test:
        limitations.append("Suite dependency links were not extracted; reprocess the XML to verify grouping.")
    locations = primary or points
    if locations:
        point = locations[0]
        description = f"Recorded failing operation: {point['name']} ({point.get('stage', 'stage unknown')})."
    elif dependencies:
        description = "Robot reports a shared suite fixture failure; see the linked fixture."
    else:
        description = "No failing keyword was recorded for this status."
    return {
        "status": test["status"], "message": test["message"],
        "description": description,
        "failure_points": points,
        "primary_points": primary,
        "fixture_dependencies": dependencies,
        "dependency_state": "suite fixture" if dependencies else "unknown",
        "timeline": test.get("trace", []),
        "limitations": limitations,
    }


def refresh_facts(report):
    """Also support render-only of older archives without trusting old interpretations."""
    report["analysis_mode"] = "Observed facts and optional imported AI assessments"
    for target in report["targets"]:
        for run in target["runs"]:
            for phase in run["phases"]:
                for sequence, test in enumerate(phase["tests"], 1):
                    # Each recorded execution remains separate, including repeated names.
                    test["execution"] = {"xml_url": phase["xml_url"], "test_id": test["id"], "sequence": sequence}
                    if test["status"] == "FAIL":
                        test["facts"] = failure_facts(test, phase)
                        test.pop("analysis", None)


def evidence_linker(report, link):
    """Use the executed job URL and the retained workspace-relative artifact path.

    Original artifact URLs stay in JSON for evidence identity and AI validation.
    Without job metadata the original evidence URL remains the only known source.
    """
    mappings = []
    for target in report["targets"]:
        for run in target["runs"]:
            metadata = run["metadata"]
            job = metadata.get("job", {}).get("url", "")
            relative = metadata.get("artifacts", "")
            if (urlsplit(job).scheme in ("http", "https")
                    and isinstance(relative, str) and relative.startswith("test-results/")):
                base = urljoin(target["url"], relative.rstrip("/") + "/")
                mappings.append((base, job.rstrip("/") + "/artifact/"))

    def linked(url, text):
        for original, published in mappings:
            if isinstance(url, str) and url.startswith(original):
                url = published + url[len(original):]
                break
        return link(url, text)

    return linked


def collection_notices(report):
    """Separate uncertainty about expected jobs from missing collected evidence."""
    provenance = (report.get("selection") or {}).get("provenance", {})
    limitation = provenance.get("limitation")
    scope, gaps = list(report.get("scope_notes", [])), []
    for note in report["gaps"]:
        if note == limitation or note.startswith((
            "No HW test plan is available.",
            "The saved HW plan has no executed-run provenance;",
        )):
            scope.append(note)
        else:
            gaps.append(note)
    return list(dict.fromkeys(scope)), gaps


def recorded_outcome(run):
    counts = Counter()
    for phase in run["phases"]:
        counts.update(phase["counts"])
    return "Recorded test results: " + ", ".join(f"{count} {status}" for status, count in counts.items()) + "."
