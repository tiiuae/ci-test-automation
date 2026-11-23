<!--
SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Ghaf artifact report

Analyze a completed Ghaf nightly from its published artifacts directory URL.
Python collects Robot results and generates local reports. Codex investigates
failures and supplies findings for import. Nothing is published to external services.

## Run with Codex

From Codex in this repository:

```text
$analyze-ghaf-run <nightly artifacts URL>
```

The [repository skill](../../.agents/skills/analyze-ghaf-run/SKILL.md) collects the
selected run, investigates failures and returns links to both reports. It uses
only that run and relevant sources by default. To also compare available saved
runs, add `--use-local-history`; this is a skill option, not a CLI argument.

## Run the CLI

Run from the repository root with Nix `nix-command` and `flakes` enabled. Nix
provides the dependencies; the first invocation may download them.

```bash
nix run .#nightly-analyze -- --help

NIGHTLY_URL='https://ci-prod.vedenemo.dev/artifacts/ghaf-nightly/<run-directory>/'
NIGHTLY_OUTPUT=/tmp/my-selected-run
nix run .#nightly-analyze -- --url "$NIGHTLY_URL" --output "$NIGHTLY_OUTPUT" --without-ai
```

Replace the URL placeholder. Choose persistent storage outside the checkout when
keeping results. Without `--output`, results go under
`~/Reports/ghaf-nightly/<date>/`, using the published nightly number when available
or the artifact timestamp. Keep the absolute output path printed by the command.
Repeating collection for the same URL reuses its saved directory and cache.

Two reports are generated:

- `report.html`: original errors, setup/body/teardown, suite fixtures, recorded
  execution, evidence, skips, collection limits and applicable AI findings.
- `summary.html`: a short summary.

Results preserve Robot's recorded statuses and retry attempts. The execution
trace is bounded; inspect the linked original logs for complete context. Missing
or unreadable data is listed in the reports and `analysis.json` under
`collection_gaps`. Collection also reads published job results and console files
for failures before Robot starts. Images, video and HTML logs link to published
artifacts; save additional copies when retention is needed.

Exit codes:

- `0`: the operation completed, including reports with failed tests or collection gaps.
- `1`: an input, import or execution error; inspect stderr. Existing reports may be stale.
- `2`: an argument parsing error.

Only one CLI operation may use an output directory at a time. A concurrent
invocation fails immediately; the lock is released when the running process exits.

## Use saved results

Use the same output directory throughout the investigation:

```bash
# Update both reports from saved analysis.json.
nix run .#nightly-analyze -- --output "$NIGHTLY_OUTPUT" --render-only

# Show facts while preserving the accepted findings file.
nix run .#nightly-analyze -- --output "$NIGHTLY_OUTPUT" --render-only --without-ai

# Import a reviewed draft and update both reports.
nix run .#nightly-analyze -- --output "$NIGHTLY_OUTPUT" --render-only \
  --investigation "$NIGHTLY_OUTPUT/ai-investigation.draft.json"
```

For agent instructions and packet preparation, see [AI_ANALYSIS.md](docs/AI_ANALYSIS.md).
The [findings format](docs/investigation-format.md) defines accepted case IDs,
citations and supplementary evidence. Import validates the draft against the
collected run; changed input evidence prevents stale findings from applying.
Standalone suite/job failures remain visible in reports but have no importable test case IDs.

## Keep the output directory

| Path | Contents |
| --- | --- |
| `source.json` | Exact source URL used to identify and reuse the collection. |
| `analysis.json` | Saved facts and applicable AI findings used for rendering. |
| `cache/` | Original downloads and reusable extracted Robot data. |
| `investigation-input.json`, `investigation-cases/` | Packet prepared for the agent. |
| `ai-investigation.json` | Current accepted findings; each import replaces it. |
| `investigation-evidence/` | Hash-checked excerpt copies linked from findings and reports. |

Keep evidence beside the reports when moving them. Save findings separately if
you need earlier assessments. After a successful import and render, obsolete
evidence owned by the previous findings is removed. Untracked or modified files
and symlinks are preserved. Failed rendering keeps previous evidence; cleanup
errors produce a warning. Old copies left after a failed render remain for manual review.

Downloads are size-limited: 1 GiB per XML, 64 MiB per diagnostic log and 8 MiB for
other files, with smaller limits for some metadata. Exceeding a limit produces
a collection gap. Manage local cache retention as needed.

## Sensitive data

Tests and programs producing artifacts are responsible for keeping credentials
out of them. Generated exports provide limited additional masking:

- Exact `JENKINS_API_TOKEN` and `JIRA_TOKEN` values when set, and recognizable GitHub tokens.
- Structured secret fields such as `password`, `client_secret`, `access_token`, `api_key` and `Authorization`.
- Standard URL userinfo and secret query/fragment parameters, including percent-encoded parameter names.

The filter does not interpret shell commands, infer secrets in ordinary text or
recover malformed URL credentials. Raw downloads and `source.json` stay unchanged.
Masking runs before excerpt truncation. Strings over 2,097,152 characters are
replaced with a marker and a warning identifying the length and field location.
Review output directories before sharing; masking does not guarantee that arbitrary input is safe to publish.

## Development

`html_report.py` renders the Jinja2 templates in `templates/`. CSS is embedded so
each report is standalone. Re-render saved results to preview template changes.

```bash
nix develop --command python -m unittest discover -s tools/nightly-analysis/tests -v
git diff --check
```

Tests use generated Robot fixtures and mocked artifact responses. They do not
validate live Loki access or the availability of published artifacts.
