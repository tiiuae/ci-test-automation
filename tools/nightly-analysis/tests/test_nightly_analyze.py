# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

import importlib.util
from io import StringIO
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys

from robot.api import TestSuite
from robot.api import ExecutionResult
from robot import run as run_robot

sys.path.insert(0, str(Path(__file__).parents[1]))
spec = importlib.util.spec_from_file_location(
    "nightly_analyze", Path(__file__).parents[1] / "nightly_analyze.py"
)
analyzer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(analyzer)

class NightlyAnalysisTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.url = "https://ci.example/artifacts/nightly/run/"

    def robot_output(self, suite):
        path = self.root / "output.xml"
        suite.run(output=str(path), log=None, report=None, stdout=StringIO())
        return analyzer.parse_robot(
            path, self.url + "output.xml", [self.url + "log.html"]
        )

    def test_handled_failure_is_not_reported_as_final_failure(self):
        suite = TestSuite("Regression")
        test = suite.tests.create("OCR <script>alert(1)</script>")
        test.body.create_keyword(
            "Run Keyword And Ignore Error", args=["Fail", "handled"]
        )
        test.body.create_keyword("Fail", args=["Actual failure <unsafe>"])
        passing = suite.tests.create("Handled failure passes")
        passing.body.create_keyword(
            "Run Keyword And Ignore Error", args=["Fail", "handled"]
        )
        phase = self.robot_output(suite)
        self.assertEqual(phase["counts"], {"FAIL": 1, "PASS": 1})
        failure = phase["tests"][0]
        self.assertEqual(len(failure["failure_points"]), 1)
        self.assertIn("Actual failure", failure["failure_points"][0]["message"])
        self.assertNotIn("handled", failure["failure_points"][0]["message"])
        self.assertTrue(failure["failure_points"][0]["url"].endswith("#s1-t1-k2"))
        self.assertEqual(phase["tests"][1]["failure_points"], [])

    def test_suite_setup_failure_has_evidence_even_without_test_keyword(self):
        suite = TestSuite("Unavailable device")
        suite.setup.config(name="Fail", args=["Device unavailable"])
        suite.tests.create("Blocked test").body.create_keyword("No Operation")
        phase = self.robot_output(suite)
        self.assertEqual(phase["counts"]["FAIL"], 1)
        self.assertEqual(phase["suite_failures"][0]["stage"], "setup")
        self.assertIn("Device unavailable", phase["suite_failures"][0]["message"])

    def test_trace_keeps_renamed_steps_and_nested_calls_without_arguments(self):
        for name in ("Switch To VM", "Select Guest", "select_guest"):
            with self.subTest(name=name):
                suite = TestSuite("Regression")
                suite.resource.keywords.create(name).body.create_keyword("No Operation")
                test = suite.tests.create("Failure")
                test.setup.config(name="No Operation")
                test.body.create_keyword(name)
                test.body.create_keyword("Fail", args=["Actual failure"])
                test.teardown.config(name="No Operation")
                events = self.robot_output(suite)["tests"][0]["trace"]
                keywords = [e for e in events if e["kind"] == "keyword"]
                self.assertIn(name, [e["name"] for e in keywords])
                self.assertTrue(any(e["context"] == [name, "No Operation"] for e in keywords))
                self.assertEqual(sum(e["name"] == "No Operation" for e in keywords), 3)
                self.assertTrue(all(e["args"] == [] for e in keywords))

    def test_nested_loop_cannot_evict_scenario_steps(self):
        suite = TestSuite("Regression")
        wrapper = suite.resource.keywords.create("Prepare Guest")
        wrapper.body.create_keyword("No Operation")
        busy = suite.resource.keywords.create("Busy Operation")
        for _ in range(20):
            busy.body.create_keyword("No Operation")
        test = suite.tests.create("Failure")
        test.body.create_keyword("Prepare Guest")
        test.body.create_keyword("Busy Operation")
        test.body.create_keyword("Fail", args=["Actual failure"])
        with patch("robot_evidence.TRACE_LIMIT", 5):
            phase = self.robot_output(suite)
        events = phase["tests"][0]["trace"]
        self.assertIn("Prepare Guest", [e.get("name") for e in events])
        self.assertIn("Busy Operation", [e.get("name") for e in events])
        self.assertIn("s1-t1", phase["trace_truncated"])
        self.assertEqual(phase["tests"][0]["failure_points"][0]["message"], "Actual failure")

    def test_urls_cannot_escape_artifact_directory(self):
        for path in (
            "https://other.example/file",
            self.url + "../secret",
            self.url + "%2e%2e/secret",
            self.url + "a%2f..%2fsecret",
            "javascript:alert(1)",
            self.url + "?sort=name",
            self.url + "a%5cb",
        ):
            with self.subTest(path=path):
                self.assertFalse(analyzer.contained_url(self.url, path))
        self.assertTrue(analyzer.contained_url(self.url, self.url + "phase/output.xml"))

    def test_compaction_preserves_if_try_and_loop_keyword_anchors(self):
        case = self.root / "control.robot"
        case.write_text("""*** Test Cases ***
Anchors
    IF    ${True}
        No Operation
    ELSE IF    ${False}
        No Operation
    ELSE
        No Operation
    END
    TRY
        Fail    Handled
    EXCEPT
        No Operation
    END
    FOR    ${i}    IN RANGE    2
        IF    ${i} == 0
            No Operation
        ELSE
            Fail    Actual failure
        END
    END
""")
        path = self.root / "output.xml"
        run_robot(str(case), output=str(path), log=None, report=None, stdout=StringIO())
        from robot_evidence import failed_keywords

        original = ExecutionResult(str(path))
        expected = [kw.id for kw in failed_keywords(original.suite.tests[0])]
        phase = analyzer.parse_robot(
            path, self.url + "output.xml", [self.url + "log.html"]
        )
        self.assertEqual(
            [p["id"] for p in phase["tests"][0]["failure_points"]], expected
        )
        self.assertEqual(phase["counts"], {"FAIL": 1})

    def test_html_reports_omit_successful_runs_and_short_traceback_noise(self):
        suite = TestSuite("Failed check")
        suite.tests.create("Feature failed").body.create_keyword(
            "Fail", args=["Primary timeout"]
        )
        phase = self.robot_output(suite)
        phase["tests"][0]["message"] += (
            "\nAlso keyword teardown failed:\nValueError: None cannot be converted to integer"
        )
        failed_run = {
            "metadata": {
                "id": "Darter",
                "target": "system76-darp11",
                "status": "FAILURE",
            },
            "phases": [phase],
            "gaps": [],
            "evidence": [],
            "diagnostics": [],
        }
        passed_run = {
            "metadata": {"id": "Success should be hidden", "status": "SUCCESS"},
            "phases": [
                {
                    "xml_url": self.url + "passing/output.xml",
                    "execution_errors": [],
                    "tests": [{"id": "s1-t1", "status": "PASS", "name": "Successful feature"}],
                    "counts": {"PASS": 1},
                    "suite_failures": [],
                }
            ],
            "gaps": [],
            "evidence": [],
        }
        report = {
            "source_url": self.url,
            "gaps": [],
            "targets": [
                {
                    "name": "Target",
                    "url": self.url,
                    "manifest": {},
                    "gaps": [],
                    "runs": [failed_run, passed_run],
                }
            ],
        }
        analyzer.render(report, self.root)
        summary = (self.root / "summary.html").read_text()
        detailed = (self.root / "report.html").read_text()
        self.assertNotIn("ValueError", summary)
        self.assertIn("ValueError", detailed)
        for html in (summary, detailed):
            self.assertNotIn("Success should be hidden", html)
            self.assertNotIn("Successful feature", html)
            self.assertIn("Darter Pro", html)

    def test_known_test_skip_is_only_in_detailed_report(self):
        suite = TestSuite("Known skip")
        suite.tests.create("Skipped device check").body.create_keyword(
            "Skip", args=["Known issue: SSRCSP-7997"]
        )
        phase = self.robot_output(suite)
        report = {
            "source_url": self.url,
            "gaps": [],
            "targets": [
                {
                    "name": "Target",
                    "url": self.url,
                    "manifest": {},
                    "gaps": [],
                    "runs": [
                        {
                            "metadata": {"id": "Device", "status": "SUCCESS"},
                            "phases": [phase],
                            "gaps": [],
                            "evidence": [],
                        }
                    ],
                }
            ],
        }
        analyzer.render(report, self.root)
        self.assertNotIn(
            "Skipped device check", (self.root / "summary.html").read_text()
        )
        self.assertNotIn("SSRCSP-7997", (self.root / "summary.html").read_text())
        self.assertIn("SSRCSP-7997", (self.root / "report.html").read_text())

    def test_files_and_debug_follow_test_wrappers_and_teardowns(self):
        case = self.root / "evidence.robot"
        case.write_text(
            r"""*** Settings ***
Suite Teardown    Save suite debug
*** Test Cases ***
First failure
    Save screenshot    first.jpeg
    Get Diff Images
    Write Advanced Testlog    collision.log
    Fail    First assertion
    [Teardown]    Collect debug logs    first.mkv
Second failure
    Save screenshot    second.jpeg
    Fail    Second assertion
    [Teardown]    Collect debug logs    second.mkv
*** Keywords ***
Save screenshot
    [Arguments]    ${name}
    Log    Saving debug screenshot ${name}
Collect debug logs
    [Arguments]    ${name}
    Save screen recording    ${name}
    Get File    mutable.log
    Log    LONGLOG
Save screen recording
    [Arguments]    ${name}
    Log    Directory listing contains first.mkv second.mkv unrelated.mkv
    Get File    ${name}
Get File
    [Arguments]    ${name}
    Log    '/remote/${name}' -> '/workspace/Robot-Framework/test-suites/outputs/gui/${name}'
Save suite debug
    Copy File
Copy File
    Log    '/tmp/jrnl.txt' -> '/workspace/Robot-Framework/test-suites/journal_suite.txt'
Get Diff Images
    Log    \${cropped} = /workspace/Robot-Framework/test-suites/outputs/gui/cropped 2026-11-02 12:00:00.png
Write Advanced Testlog
    [Arguments]    ${name}
    No Operation
""".replace(
                "LONGLOG",
                "padding " * 250
                + r"\nNov 02 21:00:00 gpu-vm service: Permission denied opening display",
            )
        )
        path = self.root / "output.xml"
        run_robot(str(case), output=str(path), log=None, report=None, stdout=StringIO())
        base = self.url + "Robot-Framework/test-suites/"
        inventory = [base + "regression/log.html"] + [
            base + "outputs/gui/" + name
            for name in (
                "first.jpeg",
                "second.jpeg",
                "first.mkv",
                "second.mkv",
                "unrelated.mkv",
                "mutable.log",
            )
        ]
        inventory += [
            base + "outputs/a/collision.log",
            base + "outputs/b/collision.log",
            base + "regression/journal_suite.txt",
            base + "outputs/gui/cropped%202026-11-02%2012%3A00%3A00.png",
        ]
        phase = analyzer.parse_robot(path, base + "regression/output.xml", inventory)
        first, second = phase["tests"]
        self.assertEqual(
            {a["url"].rsplit("/", 1)[-1] for a in first["artifacts"]},
            {"first.jpeg", "first.mkv", "cropped%202026-11-02%2012%3A00%3A00.png"},
        )
        self.assertEqual(
            {a["url"].rsplit("/", 1)[-1] for a in second["artifacts"]},
            {"second.jpeg", "second.mkv"},
        )
        self.assertTrue(
            any(a["origin"]["stage"] == "teardown" for a in first["artifacts"])
        )
        self.assertTrue(
            any(
                a["url"].endswith("/journal_suite.txt")
                for a in first["shared_artifacts"]
            )
        )
        self.assertIn(
            "Permission denied opening display",
            str(first["debug_findings"]),
        )
        self.assertTrue(
            all(
                f["origin"]["stage"] == "teardown"
                for f in first["debug_findings"]
            )
        )

    def test_debug_records_distinguish_old_errors_and_cleanup_side_effects(self):
        from scoped_evidence import debug_findings, select_debug_lines

        test = {
            "start_time": "2026-11-02T20:00:00",
            "end_time": "2026-11-02T20:03:00",
            "primary_points": [{"end": "2026-11-02T20:01:00"}],
        }
        lines = select_debug_lines(
            "Nov 02 19:00:00 gui-vm old.service: Permission denied before test\n"
            "Nov 02 20:00:50 gui-vm app: QXcb ERROR during workflow\n"
            "Nov 02 20:01:10 gui-vm app.service: Failed after cleanup began",
            test["start_time"],
        )
        test["debug_observations"] = [
            {
                "origin": {
                    "time": "2026-11-02T20:02:00",
                    "context": ["Collect debug"],
                    "stage": "teardown",
                    "url": self.url,
                },
                "lines": lines,
            }
        ]
        findings = debug_findings(test)
        by_text = {item["text"]: item["timing"] for item in findings}
        self.assertEqual(by_text[lines[0]["text"]], "earlier than test")
        self.assertTrue(by_text[lines[1]["text"]].startswith("during test"))
        self.assertTrue(by_text[lines[2]["text"]].startswith("after failure"))

    def test_shared_teardown_failure_is_grouped_in_reports(self):
        suite = TestSuite("Cleanup")
        suite.teardown.config(name="Fail", args=["Lost connection <unsafe>"])
        for name in ("Feature A", "Feature B"):
            suite.tests.create(name).body.create_keyword("No Operation")
        phase = self.robot_output(suite)
        self.assertEqual(phase["counts"], {"FAIL": 2})
        self.assertTrue(
            all(
                test["failure_origin"] == "Parent suite fixture"
                for test in phase["tests"]
            )
        )
        report = {
            "source_url": self.url,
            "generated_at": "test",
            "offline": True,
            "analysis_mode": "test",
            "gaps": [],
            "targets": [
                {
                    "name": "Target",
                    "url": self.url,
                    "manifest": {},
                    "gaps": [],
                    "runs": [
                        {
                            "metadata": {"id": "Device", "status": "FAILURE"},
                            "phases": [phase],
                            "gaps": [],
                            "evidence": [],
                            "diagnostics": [],
                        }
                    ],
                }
            ],
        }
        analyzer.render(report, self.root)
        html = (self.root / "report.html").read_text()
        self.assertIn("2 test statuses were affected", html)
        self.assertIn("&lt;unsafe&gt;", html)
        self.assertNotIn("<unsafe>", html)

if __name__ == "__main__":
    unittest.main()
