# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

from io import StringIO
from pathlib import Path
import tempfile
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parents[1]))
from report_output import print_text, redact, redact_data, save_evidence, write_html, write_json
from hw_diagnostics import console_errors
from scoped_evidence import select_debug_lines


class RedactionTests(unittest.TestCase):
    def test_known_environment_secrets_are_replaced_in_any_text(self):
        for secret in ("synthetic-private-value", "it's a secret", "ab,cd;ef"):
            with self.subTest(secret=secret), patch.dict('os.environ', {'JIRA_TOKEN': secret}):
                for text in (f"ERROR: {secret}", f"curl -U admin:{secret} https://h",
                             f'password="{secret}"', f"https://u:{secret}@h/?token=another"):
                    masked = redact(text)
                    self.assertNotIn(secret, masked)
                    self.assertIn('[redacted]', masked)
                    self.assertEqual(redact(masked), masked)

    def test_recognizable_github_tokens_are_masked(self):
        for original, expected in (("failed ghp_private.token", "failed [redacted].token"),
                                   ("https://h/github_pat_private/file", "https://h/[redacted]/file")):
            self.assertEqual(redact(original), expected)
            self.assertEqual(redact(expected), expected)

    def test_standard_url_credentials_and_parameters(self):
        cases = (
            ("https://u:pw@h:443/path@tmp?q=a", "https://[redacted]@h:443/path@tmp?q=a"),
            ("ssh://u:p%2Fss@h/path", "ssh://[redacted]@h/path"),
            ("ftp://u:p%3Fss%23@h/path", "ftp://[redacted]@h/path"),
            ("https://ci/buildWithParameters?token=SECRET&job=a",
             "https://ci/buildWithParameters?token=[redacted]&job=a"),
            ("https://h/?password=one;two&job=a", "https://h/?password=[redacted]&job=a"),
            ("wss://h/?api_key=abc#password=def", "wss://h/?api_key=[redacted]#password=[redacted]"),
            ("https://h/?api%5Fkey=abc&job=a", "https://h/?api%5Fkey=[redacted]&job=a"),
            ("https://h/?token=one?two&job=a", "https://h/?token=[redacted]&job=a"),
            ("https://[redacted]@h/?token=new", "https://[redacted]@h/?token=[redacted]"),
        )
        for original, expected in cases:
            with self.subTest(original=original):
                self.assertEqual(redact(original), expected)
                self.assertEqual(redact(expected), expected)

    def test_plain_text_commands_and_workspace_links_are_preserved(self):
        # Arbitrary prose, shell arguments and malformed userinfo are outside the contract.
        for text in ("Boot test | PASS |", "No token found", "Waiting for password prompt",
                     "Authorization header is missing", "Pass criteria 1: ok",
                     "https://jenkins:443/job/x/ws/foo@tmp/a.xml", "https://example/path@tmp?q=a@b",
                     "docker run -p 8080:80 image", "ssh -p 22 host", "curl -oresult.txt https://h",
                     "curl https://h; printf -u public", "password = a b", 'password="first"second',
                     "https://u:pa/ss@host", "http://admin:p?ss@host/x", "http://admin:p#ss@host/x",
                     '{"msg": "password=abc", "x": 1}'):
            with self.subTest(text=text):
                self.assertEqual(redact(text), text)

    def test_structured_secret_fields_and_containers_are_replaced(self):
        for key in ("password", "client_secret", "access_token", "api-key", "Authorization", "SSHPASS"):
            for item in ("private", {"value": "private"}, ["private"]):
                with self.subTest(key=key, item=item):
                    self.assertEqual(redact_data({key: item}), {key: "[redacted]"})
        self.assertEqual(redact_data({"PASS": 4, "message": "No token found"}),
                         {"PASS": 4, "message": "No token found"})

    def test_container_types_markup_order_and_key_collisions(self):
        from markupsafe import Markup

        value = {"secret": {"nested": "private"}, "a": ("https://u:pw@h",),
                 "b": {"https://h/?token=abc"}, "html": Markup("<b>ghp_private</b>")}
        masked = redact_data(value)
        self.assertEqual(list(masked), ["secret", "a", "b", "html"])
        self.assertEqual(masked["secret"], "[redacted]")
        self.assertEqual(masked["a"], ("https://[redacted]@h",))
        self.assertEqual(masked["b"], {"https://h/?token=[redacted]"})
        self.assertIsInstance(masked["html"], Markup)
        self.assertEqual(masked["html"], "<b>[redacted]</b>")
        colliding = {"ghp_one": 1, "ghp_two": 2, "[redacted]#2": 3}
        masked = redact_data(colliding)
        self.assertEqual(list(masked.values()), [1, 2, 3])
        self.assertEqual(len(masked), 3)
        self.assertEqual(redact_data(masked.copy()), masked)

    def test_long_words_and_many_urls_finish_within_timeout(self):
        import subprocess

        module = Path(__file__).parents[1]
        script = ("from report_output import redact; "
                  "[redact(s) for s in ('a.-'*20000, 'a-'*20000, 'http://'*20000, "
                  "'a+'*1000000, 'ab+'*500000, 'ab1+'*500000, 'a-+'*500000, "
                  "'a'*20000 + ' https://h'*20000)]")
        subprocess.run([sys.executable, "-c", script], cwd=module, timeout=30, check=True)

    def test_oversized_fields_fail_closed_and_warn_without_source_text(self):
        with self.assertLogs("report_output", level="WARNING") as logged:
            result = redact_data({"message": "x" * (2 * 1024 * 1024 + 1)})
        for text in (logged.output[0], result["message"]):
            self.assertIn("2097153 characters", text)
            self.assertIn("$.message", text)
            self.assertNotIn("xxx", text)

    def test_long_console_line_is_masked_before_excerpt_truncation(self):
        selected, _ = console_errors(iter(["ERROR: https://h/?token=" + "x" * 1000000]), "url", "digest")
        self.assertLess(len(selected[0]["text"]), 2401)
        self.assertNotIn("xxx", selected[0]["text"])

    def test_export_boundaries_mask_supported_credentials(self):
        from contextlib import redirect_stdout
        from jinja2 import Environment

        secret = "synthetic-boundary-secret"
        messages = [f'https://u:{secret}@host/path', f'https://h/?token={secret}&job=a',
                    f'ftp://u:{secret}@host/path@tmp', 'ghp_synthetic_private', f'ERROR: {secret}']
        with tempfile.TemporaryDirectory() as directory, patch.dict('os.environ', {'JIRA_TOKEN': secret}):
            root = Path(directory)
            value = {"new_field": "\n".join(messages), "password": 12345}
            write_json(root / "new.json", value)
            write_html(root / "new.html", Environment(autoescape=True).from_string("{{ new_field }}"), value)
            relative, _ = save_evidence(root, "\n".join(messages))
            for name in ("new.json", "new.html", relative):
                content = (root / name).read_text()
                self.assertNotIn(secret, content)
                self.assertNotIn('ghp_synthetic_private', content)
                self.assertIn("[redacted]", content)
            self.assertNotIn("12345", (root / "new.json").read_text())
            output = StringIO()
            with redirect_stdout(output):
                print_text(f"ERROR: {secret}")
            self.assertNotIn(secret, output.getvalue())

    def test_console_stream_keeps_flash_priority_context_and_line_numbers(self):
        def lines():
            yield "[Pipeline] { (Flash)\n"
            yield "before flash\n"
            yield "ERROR: https://h/?token=synthetic-flash-secret\n"
            yield "after flash\n"
            yield "[Pipeline] }\n"
            for index in range(10000):
                yield f"ERROR: later failure {index}\n"

        selected, truncated = console_errors(lines(), "https://ci.example/console.log", "original-sha")
        self.assertTrue(truncated)
        self.assertEqual(len(selected), 8)
        self.assertEqual(selected[0]["stage"], "Flash")
        self.assertEqual(selected[0]["line"], 3)
        self.assertIn("before flash", selected[0]["text"])
        self.assertIn("after flash", selected[0]["text"])
        self.assertNotIn("synthetic-flash-secret", str(selected))
        self.assertEqual(selected[-1]["line"], 10005)
        self.assertEqual(selected[-1]["sha256_scope"], "original artifact")

    def test_debug_selection_masks_before_truncating_and_retains_line_numbers(self):
        secret = 'x' * 2000
        lines = StringIO(f'normal record\n2026-11-23T12:00:00 ERROR: https://h/?token={secret}\n')
        self.assertEqual(select_debug_lines(lines), [{
            'line': 2, 'text': '2026-11-23T12:00:00 ERROR: https://h/?token=[redacted]',
            'log_time': '2026-11-23T12:00:00',
        }])


if __name__ == '__main__':
    unittest.main()
