# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

from html.parser import HTMLParser
from io import StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest

from robot import run

sys.path.insert(0, str(Path(__file__).parents[1]))
from html_report import render
from factual_report import evidence_linker
from robot_evidence import parse_robot


class FactualReportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name)
        self.base = "https://archive.example/nightly/packages.device/"
        self.run_base = self.base + "test-results/device/"
        self.xml_url = self.run_base + "Robot-Framework/test-suites/regression/output.xml"
        self.job = "https://jenkins.example/job/ghaf-hw-test/123/"

    def collect(self, body, log=True):
        case = self.output / "fixture.robot"
        case.write_text(body)
        xml = self.output / "output.xml"
        run(str(case), output=str(xml), log=None, report=None, stdout=StringIO())
        phase = parse_robot(xml, self.xml_url, [self.xml_url.replace("output.xml", "log.html")] if log else [])
        self.report = {
            "source_url": self.base, "gaps": [],
            "targets": [{"name": "Target", "url": self.base, "manifest": {}, "gaps": [],
                         "runs": [{"metadata": {"id": "Device", "status": "FAILURE",
                                                "artifacts": "test-results/device", "job": {"url": self.job}},
                                   "phases": [phase], "gaps": []}]}],
        }
        return phase

    def test_interrupted_tests_are_grouped_without_hiding_the_fatal_failure(self):
        self.collect("""*** Test Cases ***
Fatal failure
    Fatal Error    Device stopped responding
Blocked one
    No Operation
Blocked two
    No Operation
""")
        render(self.report, self.output)
        summary = (self.output / "summary.html").read_text()
        self.assertIn("Device stopped responding", summary)
        self.assertIn("2 tests not executed after interruption", summary)
        self.assertNotIn(">Blocked one</a>", summary)
        self.assertNotIn(">Blocked two</a>", summary)

    def test_render_masks_sensitive_text_from_older_saved_analysis(self):
        phase = self.collect("""*** Test Cases ***
Failure
    Fail    Original error
""")
        secret = "synthetic-old-secret"
        phase["tests"][0]["message"] = f"ERROR: https://h/?password={secret}"
        phase["execution_errors"].append({"level": "ERROR", "message": f"https://h/?token={secret}"})
        render(self.report, self.output)
        for name in ("report.html", "summary.html", "analysis.json"):
            self.assertNotIn(secret, (self.output / name).read_text())

    def test_facts_and_job_links_preserve_identity_without_diagnosis_rules(self):
        phase = self.collect("""*** Test Cases ***
Brightness persists
    Should Be Equal    7758    67200
""")
        render(self.report, self.output)
        summary = (self.output / "summary.html").read_text()
        detail = (self.output / "report.html").read_text()
        self.assertNotIn("post-reboot", summary)
        self.assertNotIn("Persistence regression", summary)
        self.assertIn("Underlying cause is unknown", summary)
        self.assertNotIn("Python rule hypotheses", detail)
        self.assertIn(self.job + "artifact/Robot-Framework/test-suites/regression/log.html#s1-t1", summary)
        self.assertIn(self.job + "artifact/Robot-Framework/test-suites/regression/log.html#s1-t1",
                      (self.output / "summary.html").read_text())
        test = phase["tests"][0]
        self.assertEqual(test["url"], self.xml_url.replace("output.xml", "log.html") + "#s1-t1")
        self.assertEqual(test["facts"]["dependency_state"], "unknown")
        self.assertNotIn("analysis", test)
        self.assertEqual(test["facts"]["failure_points"][0]["stage"], "body")

    def test_templates_escape_data_once_and_preserve_link_attributes(self):
        phase = self.collect("""*** Test Cases ***
Failure
    Fail    Original error
""")
        payload = '<script>alert("x")</script> & "quotes"'
        url = 'https://example.test/log?q="quoted"&other=<value>'
        phase["tests"][0].update(name=payload, url=url)
        self.report["targets"][0]["runs"][0]["metadata"]["id"] = payload

        class Content(HTMLParser):
            def __init__(self):
                super().__init__()
                self.tags, self.links, self.text = [], [], []

            def handle_starttag(self, tag, attrs):
                self.tags.append(tag)
                if tag == "a":
                    self.links.append(dict(attrs).get("href"))

            def handle_data(self, data):
                self.text.append(data)

        render(self.report, self.output)
        for filename in ("report.html", "summary.html"):
            with self.subTest(filename=filename):
                content = Content()
                content.feed((self.output / filename).read_text())
                self.assertNotIn("script", content.tags)
                self.assertIn(payload, "".join(content.text))
                self.assertIn(url, content.links)

    def test_recovered_retry_attempts_and_all_test_statuses_survive_json(self):
        phase = self.collect("""*** Test Cases ***
Recovered
    Wait Until Keyword Succeeds    3x    0s    Eventually
Skipped
    Skip    Explicit reason
Failed
    Fail    Final error
*** Keywords ***
Eventually
    ${count}=    Get Variable Value    ${COUNT}    ${0}
    ${count}=    Evaluate    ${count} + 1
    Set Test Variable    ${COUNT}    ${count}
    Should Be True    ${count} >= 3
""")
        render(self.report, self.output)
        stored = json.loads((self.output / "analysis.json").read_text())
        tests = stored["targets"][0]["runs"][0]["phases"][0]["tests"]
        self.assertEqual([t["status"] for t in tests], ["PASS", "SKIP", "FAIL"])
        self.assertEqual([a["status"] for a in tests[0]["retry_attempts"]], ["FAIL", "FAIL", "PASS"])
        self.assertEqual([t["execution"]["sequence"] for t in tests], [1, 2, 3])
        self.assertIn("should be true", tests[0]["retry_attempts"][0]["message"])

    def test_shared_fixture_has_primary_error_and_structural_dependencies(self):
        phase = self.collect("""*** Settings ***
Suite Setup    Fail    Device unavailable
*** Test Cases ***
Blocked
    No Operation
""")
        render(self.report, self.output)
        self.assertEqual(phase["tests"][0]["fixture_dependencies"][0]["stage"], "setup")
        self.assertIn("Device unavailable", (self.output / "summary.html").read_text())
        self.assertIn("Device unavailable", (self.output / "summary.html").read_text())

    def test_independent_test_failure_is_retained_alongside_suite_teardown(self):
        phase = self.collect("""*** Settings ***
Suite Teardown    Fail    Shared cleanup failed
*** Test Cases ***
Independent
    Fail    Original assertion
""")
        render(self.report, self.output)
        self.assertEqual(phase["tests"][0]["failure_origin"], "Test or its fixture")
        for name in ("summary.html", "summary.html"):
            text = (self.output / name).read_text()
            self.assertIn("Original assertion", text)
            self.assertIn("Shared cleanup failed", text)

    def test_teardown_failure_order_does_not_imply_causal_dependency(self):
        phase = self.collect("""*** Test Cases ***
Independent cleanup
    Fail    First failure
    [Teardown]    Fail    No open connection.
""", log=False)
        render(self.report, self.output)
        facts = phase["tests"][0]["facts"]
        self.assertEqual(facts["dependency_state"], "unknown")
        self.assertEqual([p["stage"] for p in facts["failure_points"]], ["body", "teardown"])
        summary = (self.output / "summary.html").read_text()
        self.assertNotIn("Secondary:", summary)
        self.assertIn("Companion Robot log.html is unavailable", (self.output / "report.html").read_text())

    def test_legacy_grouping_is_not_trusted_without_extracted_dependencies(self):
        phase = self.collect("""*** Test Cases ***
Legacy case
    Fail    Parent suite says something
""")
        test = phase["tests"][0]
        test.pop("fixture_dependencies")
        test.pop("retry_attempts")
        test["failure_origin"] = "Parent suite fixture"
        render(self.report, self.output)
        self.assertIn("Legacy case", (self.output / "summary.html").read_text())
        self.assertIn("reprocess the XML", (self.output / "report.html").read_text())

    def test_repeated_names_and_execution_diagnostics_remain_visible(self):
        phase = self.collect("""*** Test Cases ***
Repeated
    Fail    First execution error
Repeated
    No Operation
""")
        render(self.report, self.output)
        self.assertEqual([t["status"] for t in phase["tests"]], ["FAIL", "PASS"])
        self.assertNotEqual(phase["tests"][0]["execution"], phase["tests"][1]["execution"])
        phase["tests"] = []
        phase["counts"] = {}
        phase["execution_errors"] = [{"level": "ERROR", "message": "Robot initialization diagnostic"}]
        self.report["targets"][0]["runs"][0]["metadata"]["status"] = "SUCCESS"
        render(self.report, self.output)
        for name in ("summary.html", "report.html", "summary.html"):
            self.assertIn("Robot initialization diagnostic", (self.output / name).read_text())
        self.assertEqual(self.report["counts"], {})

    def test_links_keep_encoded_paths_and_fall_back_without_run_metadata(self):
        self.collect("""*** Test Cases ***
Failure
    Fail    Error
""")
        resolve = evidence_linker(self.report, lambda url, text: url)
        original = self.run_base + "phase%20name/screen%20shot.png#s1-t1-k2"
        self.assertEqual(resolve(original, ""), self.job + "artifact/phase%20name/screen%20shot.png#s1-t1-k2")
        metadata = self.report["targets"][0]["runs"][0]["metadata"]
        metadata["artifacts"] = None
        self.assertEqual(evidence_linker(self.report, lambda url, text: url)(original, ""), original)
        metadata.pop("job")
        render(self.report, self.output)
        self.assertIn("HW build (URL unavailable)", (self.output / "report.html").read_text())

    def test_passing_run_with_warning_keeps_its_recorded_outcome(self):
        phase = self.collect("""*** Test Cases ***
Successful check
    No Operation
""")
        phase["execution_errors"] = [{"level": "WARN", "message": "Serial logs unavailable; using journal"}]
        self.report["targets"][0]["runs"][0]["metadata"]["status"] = "SUCCESS"
        render(self.report, self.output)
        detail = (self.output / "report.html").read_text()
        self.assertIn("Serial logs unavailable", detail)
        self.assertIn("1 PASS", detail)
        self.assertNotIn("No usable test outcome", detail)
        self.assertNotIn("Serial logs unavailable", (self.output / "summary.html").read_text())
        self.assertEqual(self.report["counts"], {"PASS": 1})



    def test_scope_uncertainty_stays_out_of_summary_but_actual_gaps_are_visible(self):
        self.collect("""*** Test Cases ***
Successful check
    No Operation
""")
        self.report["scope_notes"] = ["Only published results were examined."]
        render(self.report, self.output)
        self.assertIn("Nightly scope unverified", (self.output / "report.html").read_text())
        self.assertNotIn("Nightly scope unverified", (self.output / "summary.html").read_text())
        self.assertEqual(self.report["collection_gaps"], [])
        self.report["targets"][0]["runs"][0]["gaps"] = ["Missing companion log.html"]
        render(self.report, self.output)
        for name in ("report.html", "summary.html"):
            content = (self.output / name).read_text()
            self.assertIn("Artifact collection incomplete", content)
            self.assertIn("Missing companion log.html", content)


if __name__ == "__main__":
    unittest.main()
