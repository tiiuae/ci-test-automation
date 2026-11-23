<!--
SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Findings JSON, schema versions 1 and 2

Follow [AI_ANALYSIS.md](AI_ANALYSIS.md) to investigate the selected run. Save
UTF-8 findings JSON outside Git, usually
`<run-directory>/ai-investigation.draft.json` (at most 2 MiB).

## Document fields

| Field | Contract |
| --- | --- |
| `schema_version` | Integer `1` for existing findings, or `2` for supplementary evidence. |
| `source_url` | Exact value from `investigation-input.json`, including trailing slash. |
| `input_digest` | Exact value from that packet; do not calculate a replacement to bypass stale-input validation. |
| `analyst` | Nonempty text, at most 200 characters. |
| `created_at` | ISO 8601 timestamp with explicit timezone, at most 100 characters. Use the actual investigation time. |
| `supplementary_evidence` | Optional array in version 2; see below. |
| `cases` | Nonempty array of reviewed cases. Partial coverage is allowed; unknown and duplicate IDs are rejected. |

A case ID identifies an occurrence by XML URL and Robot test ID. Copy it from the
packet; do not derive it from a name or testcase tag. The current importer accepts
only the packet's test candidates, not standalone suite/pre-Robot records.
When the packet has no cases, do not create findings or submit an empty array.

The input digest covers source hashes and extracted evidence, including traces,
failure locations, retry attempts and diagnostic observations. Report timing,
rendered fact descriptions and attached AI assessments are excluded. Changes to
extracted evidence invalidate old findings even when source file hashes stay the
same. Prepare a fresh packet and review affected conclusions when the digest changes.

## Case fields

| Field | Contract |
| --- | --- |
| `case_id` | Exact supported candidate ID from the packet. |
| `finding` | Concise observed failure/conclusion; nonempty text. |
| `explanation` | Evidence-based reasoning; explicitly distinguish observations and hypotheses. Nonempty text. |
| `category` | One of `test`, `product`, `infrastructure`, `hardware`, `undetermined`. |
| `confidence` | One of `low`, `medium`, `high`; qualify the claim in the explanation. |
| `recommendation` | Nonempty text giving a concrete next check/action. |
| `limitations` | Required array of strings; use `[]` only if no relevant limitations are known. |
| `evidence` | Nonempty array of objects with `observation` and either `url` or `evidence_id`. |
| `source_refs` | Optional array of objects with nonempty `url`, `revision` and `note`. |
| `summary` | Optional nonempty single-line text, at most 320 characters. No publication is triggered. |

Unless specified otherwise, required text is limited to 12,000 characters and
URLs to 10,000. Category expresses attribution, not original test status.
`source_refs[].revision` must be exactly 40 hexadecimal characters.
Use the documented fields; unknown fields are not an extension mechanism and
are not guaranteed to be validated or displayed. No field changes source status.

## Citation rules

Remote `evidence[].url` must be HTTP(S), with a hostname and without embedded credentials.
Copy the original collected URL, not a rewritten presentation link. Accepted
URLs come from that case's test/phase XML, failure points, trace/suite trace,
artifacts/shared artifacts and their origins, or debug observation origins in
`analysis.json`. An exact Robot anchor under this test's `phase.log_url` is also
accepted: the test ID itself or a descendant such as `#s1-t1-k1`.
Do not guess anchors or cite an unrelated case's URL.

`observation` states what that source records, with a timestamp, keyword or line
reference when available. A URL passing validation does not prove the claim.
The validator does not fetch links or verify the observation's truth.

`source_refs` are HTTPS source links pinned to a full commit SHA: `revision` must
appear in the URL path. Verify repository, file and executed revision yourself;
this syntactic validation does not establish that Jenkins executed that source.
Use `note` to explain its relevance and any revision uncertainty.

Register local investigator excerpts as supplementary evidence below. Arbitrary
external URLs are not accepted as case citations. A provenance source URL records
where an investigator queried; it is not itself accepted as case evidence.

## Supplementary evidence (version 2)

Use `schema_version: 2` and add `supplementary_evidence` at document level. Save
UTF-8 excerpts beside the draft (or in a subdirectory); each `path` is relative
to the draft's directory. Absolute paths, traversal, symlinks escaping that
directory, missing files and mismatched SHA-256 are rejected. Up to 32 files,
at most 2 MiB each, are supported. Keep credentials out of excerpts and provenance;
see [Sensitive data](../README.md#sensitive-data) for the export filter's scope.
Original draft files remain unchanged. The importer copies excerpts into
`investigation-evidence/<sha256>.txt` and updates their paths and hashes to match
the exported bytes. `sha256_scope` is `redacted UTF-8 excerpt`; the original
unmasked digest is not exported. Keep these copies beside the reports.

Each record has these fields:

| Field | Contract |
| --- | --- |
| `id` | Unique 1–80 character identifier using letters, digits, `_` or `-`. |
| `path` | Relative path to the saved UTF-8 excerpt. |
| `sha256` | Full lowercase SHA-256 of the saved file bytes. |
| `case_ids` | Nonempty array of unique supported candidate IDs this evidence concerns. |
| `provenance` | Object with the required fields below. |

Provenance contains nonempty text `kind` (for example `loki`), `source` (HTTPS
endpoint without credentials), `query` (exact investigator query or retrieval
procedure), `device`, `vm`, and `limits` (ordering, limit, pagination, truncation,
coverage, errors or empty results). Use explicit text such as `unknown; ...` for
identity uncertainty and explain its impact in the finding's limitations.
`start`, `end`, and `retrieved_at` must be ISO 8601 timestamps with timezones;
`start <= end <= retrieved_at`. UTC is recommended. These are investigator-run
queries, not commands from the test log.

For example, a Loki record in `supplementary_evidence` can have:

```javascript
{
  "id": "loki-gui-1",
  "path": "agent-evidence/loki-gui.txt",
  "sha256": "<SHA-256 of the saved UTF-8 file>",
  "case_ids": ["<exact candidate ID>"],
  "provenance": {
    "kind": "loki",
    "source": "https://logs.example/loki/api/v1/query_range",
    "query": "{host=\"device-id\", vm=\"gui-vm\"}",
    "device": "device-id; verified against run metadata",
    "vm": "gui-vm",
    "start": "2026-11-19T11:58:00Z",
    "end": "2026-11-19T12:00:00Z",
    "retrieved_at": "2026-11-19T12:01:00Z",
    "limits": "Forward, limit 1000, one page; not truncated."
  }
}
```

Cite it in a listed case as `{"evidence_id": "loki-gui-1", "observation":
"At ... the saved excerpt records ..."}`. Do not also supply `url`.
Reports link the copied excerpts and display their provenance. Rerenders verify
the hashes; missing or modified copies disable the saved findings with a warning.
Validation checks provenance shape and file integrity. Verify actual device
identity, query execution, coverage and causality during investigation.

## Example

This is valid JSON with the required shape and a conservative unresolved finding.
Its synthetic identifiers and URLs must be replaced with exact values from your
packet and matching case. Replace the observation and reasoning after inspection;
copying this example unchanged will not validate against a real run.

```json
{
  "schema_version": 1,
  "source_url": "https://ci.example/artifacts/nightly/run/",
  "input_digest": "0000000000000000000000000000000000000000000000000000000000000000",
  "analyst": "Codex",
  "created_at": "2026-11-19T12:00:00Z",
  "cases": [
    {
      "case_id": "00000000000000000000",
      "finding": "The test records an explicit assertion failure.",
      "explanation": "Observed: Fail reports 'First failure'. This assertion alone does not establish the cause.",
      "category": "undetermined",
      "confidence": "low",
      "recommendation": "Inspect the preceding operation and device logs for why the expected condition was absent.",
      "evidence": [
        {
          "url": "https://ci.example/artifacts/nightly/run/phase/log.html#s1-t1",
          "observation": "The test's original error is 'First failure'."
        }
      ],
      "limitations": [
        "The assertion alone does not establish the underlying cause."
      ],
      "source_refs": [],
      "summary": "The assertion failed; the underlying cause remains unresolved."
    }
  ]
}
```

## Validation and local import

Use the same run directory that produced the packet:

```bash
NIGHTLY_OUTPUT=/tmp/my-selected-run
nix run .#nightly-analyze -- --output "$NIGHTLY_OUTPUT" --render-only \
  --investigation "$NIGHTLY_OUTPUT/ai-investigation.draft.json"
```

A successful import saves `ai-investigation.json` and regenerates the exports;
the current accepted findings are replaced. Reports label AI findings separately
and show partial coverage. Rerenders retain accepted findings; changed input
evidence prevents stale findings from applying. For evidence retention and cleanup,
see [Keep the output directory](../README.md#keep-the-output-directory).

On identity/digest rejection, verify the selected run and prepare a fresh packet
if its evidence changed, then review the affected conclusions again. On citation
rejection, inspect the original case record and the rules above. Do not edit the
validator, digest or source data merely to force acceptance. No import writes to
external services.
