# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

from copy import deepcopy
from contextlib import redirect_stdout, redirect_stderr
from datetime import datetime, timezone
from hashlib import sha256
import importlib.util
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from robot.api import TestSuite

sys.path.insert(0, str(Path(__file__).parents[1]))
from ai_investigation import attach_investigation, cases, import_investigation, input_digest, prepare_packet
from html_report import render
from robot_evidence import parse_robot
import nightly_analyze as analyzer


class AIInvestigationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name)
        self.url = "https://ci.example/artifacts/nightly/run/"
        suite = TestSuite("Regression")
        first = suite.tests.create("First failure")
        first.body.create_keyword(
            "Log", args=["padding " * 350 + "deep marker beyond the initial excerpt"]
        )
        first.body.create_keyword("Fail", args=["First failure"])
        suite.tests.create("Second failure").body.create_keyword(
            "Fail", args=["Second failure"]
        )
        suite.tests.create("Successful check").body.create_keyword("No Operation")
        self.xml = self.output / "output.xml"
        suite.run(output=str(self.xml), log=None, report=None, stdout=StringIO())
        phase = parse_robot(
            self.xml, self.url + "phase/output.xml", [self.url + "phase/log.html"]
        )
        self.report = {
            "schema_version": 2,
            "source_url": self.url,
            "gaps": [],
            "targets": [
                {
                    "name": "Target",
                    "url": self.url,
                    "manifest": {"source": {"revision": "a" * 40}},
                    "gaps": [],
                    "runs": [
                        {
                            "metadata": {"id": "Device", "status": "FAILURE"},
                            "phases": [phase],
                            "gaps": [],
                            "evidence": [],
                        }
                    ],
                }
            ],
        }
        cid, _, _, _, test = next(cases(self.report))
        self.document = {
            "schema_version": 1,
            "source_url": self.url,
            "input_digest": input_digest(self.report),
            "analyst": "Codex",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "cases": [
                {
                    "case_id": cid,
                    "finding": "Observed failure",
                    "explanation": "The assertion failed; the underlying cause remains unresolved.",
                    "category": "undetermined",
                    "confidence": "low",
                    "recommendation": "Inspect the linked assertion and preceding operation.",
                    "evidence": [
                        {
                            "url": test["url"],
                            "observation": "This test reports the first failed assertion.",
                        }
                    ],
                    "limitations": ["Cause has not been confirmed."],
                }
            ],
        }
        self.draft = self.output / "draft.json"

    def test_packet_has_portable_context_without_raw_paths(self):
        packet = json.loads(prepare_packet(self.report, self.output).read_text())
        self.assertNotIn(str(self.output), json.dumps(packet))
        for case in packet["cases"]:
            context = case["context"]
            self.assertNotIn("xml_path", context)
            self.assertNotIn("phase_cache_path", context)
            details = json.loads((self.output / context["case_path"]).read_text())
            self.assertEqual(details["context"], context)
        from read_robot_context import case_context
        (self.output / "analysis.json").write_text(json.dumps(self.report))
        xml, test_id = case_context(self.output, packet["cases"][0]["case_id"])
        self.assertTrue(xml.is_relative_to(self.output / "cache"))
        self.assertEqual(test_id, packet["cases"][0]["context"]["test_id"])

    def test_legacy_unmasked_evidence_is_not_linked(self):
        record = self.supplementary()
        raw = b"https://h/?password=hunter2"
        (self.output / record["path"]).write_bytes(raw)
        record["sha256"] = sha256(raw).hexdigest()
        (self.output / "ai-investigation.json").write_text(json.dumps(self.document))
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")
        self.assertNotIn('href="excerpt.txt"', (self.output / "report.html").read_text())
        self.assertIn("Reimport", self.report["ai_investigation"]["message"])

    def test_normalized_size_rejection_writes_no_evidence_or_partial(self):
        self.supplementary()
        with patch("ai_investigation.json_text", return_value="x" * (2 * 1024 * 1024 + 1)):
            with self.assertRaisesRegex(ValueError, "size limit"):
                import_investigation(self.save_draft(), self.report, self.output)
        self.assertFalse((self.output / "investigation-evidence").exists())
        self.assertFalse((self.output / "ai-investigation.partial").exists())

    def test_untrusted_digest_metadata_is_replaced(self):
        record = self.supplementary()
        record["original_sha256"] = "forged"
        record["sha256_scope"] = "forged"
        import_investigation(self.save_draft(), self.report, self.output)
        saved = json.loads((self.output / "ai-investigation.json").read_text())["supplementary_evidence"][0]
        self.assertNotIn("original_sha256", saved)
        self.assertEqual(saved["sha256_scope"], "redacted UTF-8 excerpt")

    def test_imported_findings_mask_credentials_before_saving_and_rendering(self):
        secret = "synthetic-ai-secret"
        self.document["cases"][0]["finding"] = f"Request failed: https://h/?password={secret}"
        self.save_draft()
        import_investigation(self.draft, self.report, self.output)
        render(self.report, self.output)
        for name in ("ai-investigation.json", "analysis.json", "report.html", "summary.html"):
            self.assertNotIn(secret, (self.output / name).read_text())
        self.assertEqual(self.report["ai_investigation"]["state"], "current")

    def test_summary_fallback_is_a_bounded_single_line(self):
        self.document["cases"][0]["finding"] = "Long finding\n" * 800
        self.save_draft()
        import_investigation(self.draft, self.report, self.output)
        render(self.report, self.output)
        summary = (self.output / "summary.html").read_text()
        summary = summary.split("AI assessment: ", 1)[1].split("</p>", 1)[0]
        self.assertLessEqual(len(summary), 320)
        self.assertNotIn("\n", summary)
        self.assertIn("Long finding", summary)

    def test_packet_keeps_successful_preparation_before_failure(self):
        test = self.report["targets"][0]["runs"][0]["phases"][0]["tests"][0]
        test["primary_start"] = "2026-11-22T10:00:02"
        test["trace"] = [
            {"name": "Prepare Guest", "time": "2026-11-22T10:00:01", "scenario_step": True},
            *[{"name": "Nested call", "time": "2026-11-22T10:00:01.500"}] * 20,
            {"name": "Failed Operation", "time": "2026-11-22T10:00:02"},
        ]
        packet = json.loads(prepare_packet(self.report, self.output).read_text())
        details = json.loads((self.output / packet["cases"][0]["context"]["case_path"]).read_text())
        self.assertEqual(
            [event["name"] for event in details["trace_excerpt"]],
            ["Prepare Guest", "Failed Operation"],
        )

    def save_draft(self, document=None):
        self.draft.write_text(json.dumps(document or self.document))
        return self.draft

    def test_packet_is_limited_to_primary_failures_and_digest_is_stable(self):
        path = prepare_packet(self.report, self.output)
        packet = json.loads(path.read_text())
        self.assertEqual(len(packet["cases"]), 2)
        self.assertNotIn("Successful check", path.read_text())
        before = input_digest(self.report)
        self.report["performance"] = {"elapsed_seconds": 900}
        self.report["generated_at"] = "later"
        render(self.report, self.output)
        self.assertEqual(input_digest(self.report), before)

    def test_documented_example_imports_with_packet_identity_and_case_evidence(self):
        reference = Path(__file__).parents[1] / "docs" / "investigation-format.md"
        example = reference.read_text().split("```json\n", 1)[1].split("```", 1)[0]
        document = json.loads(example)
        packet = json.loads(prepare_packet(self.report, self.output).read_text())
        document["source_url"] = packet["source_url"]
        document["input_digest"] = packet["input_digest"]
        document["cases"][0]["case_id"] = packet["cases"][0]["case_id"]
        document["cases"][0]["evidence"][0]["url"] = packet["cases"][0]["test_url"]
        import_investigation(self.save_draft(document), self.report, self.output)
        saved = json.loads((self.output / "ai-investigation.json").read_text())
        self.assertEqual(saved, document)

    def test_import_survives_rerender_and_preserves_baseline(self):
        self.document["cases"][0]["summary"] = (
            "The assertion failed; the cause is still unknown."
        )
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        saved = (self.output / "ai-investigation.json").read_bytes()
        fresh = deepcopy(self.report)
        fresh.pop("ai_investigation", None)
        render(fresh, self.output)
        self.assertEqual((self.output / "ai-investigation.json").read_bytes(), saved)
        self.assertEqual(fresh["ai_investigation"]["reviewed_cases"], 1)
        self.assertEqual(fresh["ai_investigation"]["total_cases"], 2)
        test = fresh["targets"][0]["runs"][0]["phases"][0]["tests"][0]
        self.assertNotIn("analysis", test)
        self.assertEqual(test["ai_assessment"]["finding"], "Observed failure")
        self.assertIn("1 of 2", (self.output / "report.html").read_text())
        for name in ("summary.html",):
            summary = (self.output / name).read_text()
            self.assertIn(self.document["cases"][0]["summary"], summary)
            self.assertIn("First failure", summary)
            self.assertNotIn("confidence", summary)
            self.assertNotIn(self.document["cases"][0]["explanation"], summary)
            self.assertNotIn("Successful check", summary)

    def test_legacy_summary_still_renders_and_new_summary_takes_precedence(self):
        case = self.document["cases"][0]
        case["slack_summary"] = "Previously saved short assessment."
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        self.assertIn(case["slack_summary"], (self.output / "summary.html").read_text())

        case["summary"] = "Updated short assessment."
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        summary = (self.output / "summary.html").read_text()
        self.assertIn(case["summary"], summary)
        self.assertNotIn(case["slack_summary"], summary)

    def test_changed_evidence_keeps_sidecar_but_disables_old_assessment(self):
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        before = (self.output / "ai-investigation.json").read_bytes()
        self.report["targets"][0]["runs"][0]["phases"][0]["sha256"] = "changed"
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")
        self.assertNotIn(
            "ai_assessment",
            self.report["targets"][0]["runs"][0]["phases"][0]["tests"][0],
        )
        self.assertEqual((self.output / "ai-investigation.json").read_bytes(), before)
        self.assertIn("stale", (self.output / "report.html").read_text())
        self.assertNotIn("Observed failure", (self.output / "summary.html").read_text())

    def test_changed_extracted_evidence_disables_old_assessment(self):
        baseline = deepcopy(self.report)
        fields = (
            "debug_findings", "trace", "suite_trace", "failure_points", "primary_points",
            "debug_observations", "shared_debug_observations", "retry_attempts",
        )
        for field in fields:
            with self.subTest(field=field):
                report = deepcopy(baseline)
                test = next(cases(report))[-1]
                test[field] = []
                before = input_digest(report)
                document = deepcopy(self.document)
                document["input_digest"] = before
                import_investigation(self.save_draft(document), report, self.output)
                attach_investigation(report, self.output)
                self.assertEqual(report["ai_investigation"]["state"], "current")
                test[field].append({"text": "Changed diagnostic evidence"})
                self.assertNotEqual(input_digest(report), before)
                attach_investigation(report, self.output)
                self.assertEqual(report["ai_investigation"]["state"], "not_applied")
                self.assertNotIn("ai_assessment", test)

    def test_changed_archived_observation_disables_old_assessment(self):
        test = next(cases(self.report))[-1]
        test["shared_artifacts"] = [{
            "url": self.url + "journal.txt", "sha256": "unchanged-original-hash",
            "name": "journal.txt", "relation": "shared suite diagnostic",
            "origin": {"url": test["url"], "stage": "teardown", "context": []},
            "log_observations": [{"lines": [{"text": "Original diagnostic", "line": 1}]}],
        }]
        self.document["input_digest"] = input_digest(self.report)
        import_investigation(self.save_draft(), self.report, self.output)
        test["shared_artifacts"][0]["log_observations"][0]["lines"][0]["text"] = "Changed diagnostic"
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")

    def test_foreign_cases_and_evidence_are_rejected_before_saving(self):
        variations = []
        for key, value in (
            ("source_url", "https://other.example/run/"),
            ("input_digest", "wrong"),
        ):
            item = deepcopy(self.document)
            item[key] = value
            variations.append(item)
        for value in (
            "https://other.example/unrelated.log",
            "javascript:alert(1)",
            self.url + "phase/log.html#s1-t99-k1",
        ):
            item = deepcopy(self.document)
            item["cases"][0]["evidence"][0]["url"] = value
            variations.append(item)
        item = deepcopy(self.document)
        item["cases"].append(deepcopy(item["cases"][0]))
        variations.append(item)
        for document in variations:
            with self.subTest(document=document):
                with self.assertRaises(ValueError):
                    import_investigation(
                        self.save_draft(document), self.report, self.output
                    )
                self.assertFalse((self.output / "ai-investigation.json").exists())


    def test_ai_text_is_escaped_and_malformed_saved_data_does_not_break_reports(self):
        self.document["cases"][0]["finding"] = "<script>alert(1)</script>"
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        html = (self.output / "report.html").read_text()
        self.assertNotIn("<script>", html)
        self.assertIn("&lt;script&gt;", html)
        (self.output / "ai-investigation.json").write_text("[]")
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")

    def test_reader_reaches_long_message_without_leaking_other_tests(self):
        path = Path(__file__).parents[1] / "read_robot_context.py"
        spec = importlib.util.spec_from_file_location("reader", path)
        reader = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(reader)
        output = reader.read_context(
            self.xml, "s1-t1", keyword="Log", contains="deep marker", max_chars=500
        )
        self.assertIn("deep marker", str(output))
        self.assertNotIn("Second failure", str(output))
        self.assertTrue(output["truncated"])
        self.assertGreater(output["messages"][0]["lines"][0]["character_offset"], 1200)
        with self.assertRaises(ValueError):
            reader.read_context(self.xml, "s1-t999")

    def supplementary(self):
        content = b'2026-11-19T11:59:00Z host=fixture vm=gui-vm explicit error\n'
        (self.output / "excerpt.txt").write_bytes(content)
        self.document["schema_version"] = 2
        self.document["supplementary_evidence"] = [{
            "id": "loki-1", "path": "excerpt.txt", "sha256": sha256(content).hexdigest(),
            "case_ids": [self.document["cases"][0]["case_id"]],
            "provenance": {
                "kind": "loki", "source": "https://logs.example/loki/api/v1/query_range",
                "query": '{host="fixture", vm="gui-vm"}', "device": "fixture", "vm": "gui-vm",
                "start": "2026-11-19T11:58:00Z", "end": "2026-11-19T12:00:00Z",
                "retrieved_at": "2026-11-19T12:01:00Z",
                "limits": "Forward, limit 100, one page, not truncated; synthetic fixture.",
            },
        }]
        self.document["cases"][0]["evidence"].append({
            "evidence_id": "loki-1", "observation": "Investigator query returned an explicit error.",
        })
        return self.document["supplementary_evidence"][0]

    def cli(self, *args):
        argv = ["nightly-analyze", "--output", str(self.output),
                *map(str, args)]
        with patch.object(sys, "argv", argv), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
            return analyzer.main()

    def test_cli_packet_import_factual_mode_and_restore_work_without_network(self):
        render(self.report, self.output)
        with patch("urllib.request.OpenerDirector.open", side_effect=AssertionError("network")):
            self.assertEqual(self.cli("--prepare-investigation"), 0)
            packet = json.loads((self.output / "investigation-input.json").read_text())
            self.document["input_digest"] = packet["input_digest"]
            self.document["cases"][0]["case_id"] = packet["cases"][0]["case_id"]
            record = self.supplementary()
            self.assertEqual(self.cli("--render-only", "--investigation", self.save_draft()), 0)
            accepted = (self.output / "ai-investigation.json").read_bytes()
            saved_record = json.loads(accepted)["supplementary_evidence"][0]
            self.assertEqual(saved_record["path"], "investigation-evidence/" + record["sha256"] + ".txt")
            self.assertEqual(saved_record["provenance"], record["provenance"])
            html = (self.output / "report.html").read_text()
            self.assertIn('href="' + saved_record["path"] + '"', html)
            self.assertIn("Agent evidence provenance", html)
            self.assertEqual(self.cli("--render-only", "--without-ai"), 0)
            self.assertEqual((self.output / "ai-investigation.json").read_bytes(), accepted)
            for name in ("report.html", "summary.html", "analysis.json"):
                self.assertNotIn("Observed failure", (self.output / name).read_text())
            self.assertEqual(self.cli("--render-only"), 0)
            self.assertIn("Observed failure", (self.output / "report.html").read_text())
            self.assertEqual(json.loads((self.output / "analysis.json").read_text())["counts"],
                             {"FAIL": 2, "PASS": 1})

    def test_supplementary_exports_mask_secrets_and_hash_the_exported_bytes(self):
        record = self.supplementary()
        secret = "synthetic-excerpt-secret"
        content = f"ERROR: https://u:{secret}@h/ failed\n".encode()
        original = self.output / record["path"]
        original.write_bytes(content)
        record["sha256"] = sha256(content).hexdigest()
        import_investigation(self.save_draft(), self.report, self.output)
        accepted = json.loads((self.output / "ai-investigation.json").read_text())
        saved = accepted["supplementary_evidence"][0]
        excerpt = (self.output / saved["path"]).read_bytes()
        self.assertNotIn(secret.encode(), excerpt)
        self.assertIn(b"[redacted]", excerpt)
        self.assertEqual(saved["sha256"], sha256(excerpt).hexdigest())
        self.assertNotIn("original_sha256", saved)
        self.assertEqual(saved["sha256_scope"], "redacted UTF-8 excerpt")
        self.assertEqual(original.read_bytes(), content)
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "current")

    def test_supplementary_validation_rejects_bad_provenance_paths_and_citations(self):
        self.supplementary()
        (self.output / "escape.txt").symlink_to("/etc/hosts")
        variants = []
        for field, value in (("path", "../outside.txt"), ("path", str(self.xml)),
                             ("sha256", "0" * 64), ("case_ids", ["foreign"]),
                             ("path", "missing.txt"), ("path", "escape.txt")):
            document = deepcopy(self.document)
            document["supplementary_evidence"][0][field] = value
            variants.append(document)
        for field, value in (("query", ""), ("device", ""), ("start", "yesterday"),
                             ("end", "2026-11-19T11:00:00Z"), ("limits", None),
                             ("source", "https://user:secret@logs.example/")):
            document = deepcopy(self.document)
            document["supplementary_evidence"][0]["provenance"][field] = value
            variants.append(document)
        document = deepcopy(self.document)
        document["cases"][0]["evidence"][-1]["evidence_id"] = "unknown"
        variants.append(document)
        document = deepcopy(self.document)
        document["cases"][0]["evidence"][-1]["url"] = "https://logs.example/arbitrary"
        variants.append(document)
        document = deepcopy(self.document)
        document["supplementary_evidence"] *= 2
        variants.append(document)
        document = deepcopy(self.document)
        document["supplementary_evidence"][0]["case_ids"] = [list(cases(self.report))[1][0]]
        variants.append(document)
        for document in variants:
            with self.subTest(document=document), self.assertRaises(ValueError):
                import_investigation(self.save_draft(document), self.report, self.output)
            self.assertFalse((self.output / "ai-investigation.json").exists())

    def test_supplementary_tampering_disables_findings_without_archiving_versions(self):
        self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        original = json.loads((self.output / "ai-investigation.json").read_text())
        excerpt = self.output / original["supplementary_evidence"][0]["path"]
        content = excerpt.read_bytes()
        self.document["cases"][0]["finding"] = "Revised finding"
        import_investigation(self.save_draft(), self.report, self.output)
        self.assertFalse((self.output / "investigation-history").exists())
        self.assertEqual(excerpt.read_bytes(), content)
        excerpt.write_text("changed")
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")
        self.assertIn("digest mismatch", (self.output / "report.html").read_text())
        self.assertNotIn("Revised finding", (self.output / "report.html").read_text())

    def test_rejected_supplementary_import_preserves_accepted_sidecar(self):
        record = self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        original = (self.output / "ai-investigation.json").read_bytes()
        accepted = json.loads(original)["supplementary_evidence"][0]
        excerpt = self.output / accepted["path"]
        original_excerpt = excerpt.read_bytes()
        record["sha256"] = "0" * 64
        with self.assertRaises(ValueError):
            import_investigation(self.save_draft(), self.report, self.output)
        self.assertEqual((self.output / "ai-investigation.json").read_bytes(), original)
        self.assertEqual(excerpt.read_bytes(), original_excerpt)
        self.assertFalse((self.output / "investigation-history").exists())

    def test_reimport_cleans_only_previous_owned_files_after_both_reports_are_saved(self):
        self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        directory = self.output / "investigation-evidence"
        unrelated = directory / "notes.txt"
        unrelated.write_text("Keep investigator notes")
        unowned = directory / ("e" * 64 + ".txt")
        unowned.write_text("User-managed file with a hash-shaped name")
        source = self.output / "excerpt.txt"
        link = directory / ("f" * 64 + ".txt")
        link.symlink_to(source)
        self.document.pop("supplementary_evidence")
        self.document["cases"][0]["evidence"].pop()
        self.assertEqual(self.cli("--render-only", "--investigation", self.save_draft()), 0)
        self.assertEqual(set(directory.iterdir()), {unrelated, unowned, link})
        self.assertTrue(source.is_file())

    def test_cleanup_failure_warns_after_saving_reports_and_cli_succeeds(self):
        self.supplementary()
        render(self.report, self.output)
        with patch("ai_investigation.prune_supplementary", side_effect=PermissionError("cleanup denied")), \
                patch("ai_investigation.print_text") as warning:
            self.assertEqual(self.cli("--render-only", "--investigation", self.save_draft()), 0)
        message = warning.call_args.args[0]
        self.assertIn("reports saved", message)
        self.assertIn("cleanup denied", message)
        self.assertEqual(json.loads((self.output / "analysis.json").read_text())["ai_investigation"]["state"],
                         "current")

    def test_failed_summary_render_keeps_previous_evidence_and_releases_cli_lock(self):
        from report_output import write_html

        record = self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        old = json.loads((self.output / "ai-investigation.json").read_text())["supplementary_evidence"][0]
        old_path = self.output / old["path"]
        old_summary = (self.output / "summary.html").read_bytes()
        content = b"A new investigator query returned different error details.\n"
        (self.output / record["path"]).write_bytes(content)
        record["sha256"] = sha256(content).hexdigest()

        def fail_summary(path, template, context):
            if path.name == "summary.html":
                raise OSError("Cannot write Summary report")
            write_html(path, template, context)

        with patch("html_report.write_html", side_effect=fail_summary):
            self.assertEqual(self.cli("--render-only", "--investigation", self.save_draft()), 1)
        self.assertTrue(old_path.is_file())
        self.assertEqual((self.output / "summary.html").read_bytes(), old_summary)
        current = json.loads((self.output / "ai-investigation.json").read_text())["supplementary_evidence"][0]
        self.assertNotEqual(current["path"], old["path"])
        self.assertTrue((self.output / current["path"]).is_file())
        self.assertEqual(self.cli("--render-only"), 0)
        self.assertTrue(old_path.is_file(), "A retry without import preserves untracked previous copies")

    def test_supplementary_directory_symlink_is_rejected_before_replacing_sidecar(self):
        self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        original = (self.output / "ai-investigation.json").read_bytes()
        directory = self.output / "investigation-evidence"
        moved = self.output / "moved-evidence"
        directory.rename(moved)
        directory.symlink_to(moved, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symlink"):
            import_investigation(self.save_draft(), self.report, self.output)
        self.assertEqual((self.output / "ai-investigation.json").read_bytes(), original)

    def test_changed_supplementary_files_survive_relocation(self):
        record = self.supplementary()
        import_investigation(self.save_draft(), self.report, self.output)
        original = json.loads((self.output / "ai-investigation.json").read_text())
        render(self.report, self.output)
        content = b"A later investigator query returned more context.\n"
        (self.output / record["path"]).write_bytes(content)
        record["sha256"] = sha256(content).hexdigest()
        self.assertEqual(self.cli("--render-only", "--investigation", self.save_draft()), 0)
        current = json.loads((self.output / "ai-investigation.json").read_text())
        self.assertNotEqual(original["supplementary_evidence"][0]["path"],
                            current["supplementary_evidence"][0]["path"])
        self.assertFalse((self.output / original["supplementary_evidence"][0]["path"]).exists())
        moved = self.output / "relocated"
        moved.mkdir()
        (self.output / "ai-investigation.json").rename(moved / "ai-investigation.json")
        (self.output / "investigation-evidence").rename(moved / "investigation-evidence")
        render(self.report, moved)
        self.assertEqual(self.report["ai_investigation"]["state"], "current")
        (moved / current["supplementary_evidence"][0]["path"]).unlink()
        render(self.report, moved)
        self.assertEqual(self.report["ai_investigation"]["state"], "not_applied")

    def test_optional_unrecognized_evidence_fields_do_not_break_rendering(self):
        self.document["cases"][0]["evidence"][0]["provenance"] = {"unrecognized": True}
        import_investigation(self.save_draft(), self.report, self.output)
        render(self.report, self.output)
        self.assertEqual(self.report["ai_investigation"]["state"], "current")

    def test_exact_collected_file_evidence_is_supported_but_other_files_are_rejected(self):
        test = next(cases(self.report))[-1]
        test["url"] = "file:///saved/phase/log.html#s1-t1"
        self.document["input_digest"] = input_digest(self.report)
        self.document["cases"][0]["evidence"][0]["url"] = test["url"]
        import_investigation(self.save_draft(), self.report, self.output)
        self.document["cases"][0]["evidence"][0]["url"] = "file:///unrelated.txt"
        with self.assertRaises(ValueError):
            import_investigation(self.save_draft(), self.report, self.output)

    def test_empty_candidates_prepare_without_fake_findings_and_conflicting_modes_fail(self):
        for _, _, _, _, test in list(cases(self.report)):
            test["status"] = "PASS"
        packet = json.loads(prepare_packet(self.report, self.output).read_text())
        self.assertEqual(packet["cases"], [])
        self.assertFalse(self.draft.exists())
        for args in (("--render-only", "--without-ai", "--investigation", self.draft),
                     ("--prepare-investigation", "--without-ai")):
            with self.assertRaises(SystemExit) as error:
                self.cli(*args)
            self.assertEqual(error.exception.code, 2)

    def test_replacement_keeps_only_current_findings(self):
        import_investigation(self.save_draft(), self.report, self.output)
        self.document["cases"][0]["finding"] = "Revised conclusion"
        import_investigation(self.save_draft(), self.report, self.output)
        self.assertEqual(json.loads((self.output / "ai-investigation.json").read_text()), self.document)
        self.assertFalse((self.output / "investigation-history").exists())


if __name__ == "__main__":
    unittest.main()
