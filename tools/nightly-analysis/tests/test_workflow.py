# SPDX-FileCopyrightText: 2026 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0

from contextlib import redirect_stderr, redirect_stdout
from io import BytesIO, StringIO
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from robot.api import TestSuite

sys.path.insert(0, str(Path(__file__).parents[1]))
import nightly_analyze as analyzer


class ArtifactWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.output = self.root / 'result'
        self.url = 'https://ci.example/artifacts/nightly/20261119_200004332-commit_' + 'a' * 40 + '/'
        self.target = self.url + 'packages.device/'
        self.run_url = self.target + 'test-results/device/'
        self.phase_url = self.run_url + 'regression/'
        self.files = {
            self.target + 'manifest.json': b'{}',
            self.target + 'test-results.json': json.dumps({'tests': [{
                'id': 'device', 'status': 'FAILURE', 'artifacts': 'test-results/device',
                'job': {'url': 'https://ci.example/job/ghaf-hw-test/42/', 'result': 'FAILURE'},
            }]}).encode(),
        }
        self.requests = []
        self.robot()
        self.network = patch('urllib.request.OpenerDirector.open', side_effect=self.fetch)
        self.network.start()
        self.addCleanup(self.network.stop)

    def robot(self, metadata=None):
        suite = TestSuite('Saved regression')
        if metadata:
            suite.metadata.update(metadata)
        suite.tests.create('Pass').body.create_keyword('No Operation')
        suite.tests.create('Failure').body.create_keyword('Fail', args=['Original failure <unsafe>'])
        xml = self.root / 'output.xml'
        suite.run(output=str(xml), log=None, report=None, stdout=StringIO())
        self.files[self.phase_url + 'output.xml'] = xml.read_bytes()
        self.files[self.phase_url + 'log.html'] = b'Saved companion log'

    def fetch(self, request, timeout):
        url = request.full_url
        self.requests.append(url)
        self.assertTrue(url.startswith(self.url), 'Unexpected external service request: ' + url)
        if url in self.files:
            content = self.files[url]
        elif url.endswith('/'):
            children = set()
            for item in self.files:
                if item.startswith(url):
                    remaining = item[len(url):]
                    child, separator, _ = remaining.partition('/')
                    children.add(child + ('/' if separator else ''))
            content = ''.join(f'<a href="{child}">{child}</a>' for child in sorted(children)).encode()
        else:
            raise analyzer.HTTPError(url, 404, 'Not Found', {}, None)
        response = BytesIO(content)
        response.headers = {'Content-Length': str(len(content))}
        return response

    def cli(self, *args, explicit_output=True):
        argv = ['nightly-analyze', *(['--output', str(self.output)] if explicit_output else []), *map(str, args)]
        with patch.object(sys, 'argv', argv), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
            return analyzer.main()

    def report(self):
        return json.loads((self.output / 'analysis.json').read_text())

    def test_artifacts_facts_cache_and_two_html_reports(self):
        self.assertEqual(self.cli('--url', self.url, '--without-ai'), 0)
        report = self.report()
        self.assertEqual(report['counts'], {'PASS': 1, 'FAIL': 1})
        self.assertEqual(report['performance']['xml_parsed'], 1)
        self.assertTrue(report['scope_notes'])
        self.assertEqual(report['collection_gaps'], [])
        for name in ('report.html', 'summary.html'):
            html = (self.output / name).read_text()
            self.assertIn('Original failure &lt;unsafe&gt;', html)
            self.assertNotIn('<unsafe>', html)
            self.assertNotIn('Python rule', html)
        self.assertFalse((self.output / 'slack.html').exists())
        self.assertFalse((self.output / 'summary.txt').exists())
        self.assertNotIn('Nightly scope unverified', (self.output / 'summary.html').read_text())
        self.assertNotIn('analysis', report['targets'][0]['runs'][0]['phases'][0]['tests'][1])
        self.requests.clear()
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertEqual(self.requests, [])
        self.assertEqual(self.report()['performance']['xml_cache_hits'], 1)
        self.assertEqual(self.cli('--prepare-investigation'), 0)
        packet = json.loads((self.output / 'investigation-input.json').read_text())
        self.assertEqual(len(packet['cases']), 1)
        self.assertEqual(self.requests, [])

    def test_secrets_are_masked_in_all_robot_exports_and_originals_are_preserved(self):
        from read_robot_context import read_context

        secret = "synthetic-private-value"
        environment = patch.dict('os.environ', {'JIRA_TOKEN': secret})
        environment.start()
        self.addCleanup(environment.stop)
        suite = TestSuite("Secret masking")
        suite.metadata["PASSWORD"] = secret
        suite.resource.keywords.create("Save debug log").body.create_keyword(
            "Log", args=[f"ERROR: sshpass -p '{secret}' failed"],
        )
        test = suite.tests.create("Failure")
        test.body.create_keyword("Save debug log")
        test.body.create_keyword("Fail", args=[f"nmcli connection up wifi password {secret}"])
        suite.tests.create("Skipped").body.create_keyword(
            "Skip", args=[f"--password {secret}"],
        )
        xml = self.root / 'secrets.xml'
        suite.run(output=str(xml), log=None, report=None, stdout=StringIO())
        original = xml.read_bytes()
        self.files[self.phase_url + 'output.xml'] = original
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertEqual(self.cli('--prepare-investigation'), 0)
        exports = [self.output / name for name in ('report.html', 'summary.html', 'analysis.json')]
        exports += list((self.output / 'investigation-cases').glob('*.json'))
        exports += [self.output / 'investigation-input.json']
        exports += list((self.output / 'cache').rglob('.analysis.json'))
        for path in exports:
            with self.subTest(path=path.name):
                self.assertNotIn(secret, path.read_text())
        context = read_context(xml, 's1-t1')
        self.assertNotIn(secret, json.dumps(context))
        self.assertIn('[redacted]', json.dumps(context))
        cached = self.output / 'cache/packages.device/test-results/device/regression/output.xml'
        self.assertEqual(cached.read_bytes(), original)
        self.assertIn(secret.encode(), original)

    def test_skipped_hw_run_is_visible_in_summary(self):
        self.files[self.target + 'test-results.json'] = json.dumps({'tests': [{
            'id': 'device', 'status': 'SKIPPED', 'reason': 'Disabled for maintenance',
        }]}).encode()
        self.assertEqual(self.cli('--url', self.url), 0)
        summary = (self.output / 'summary.html').read_text()
        self.assertIn('HW run skipped: Disabled for maintenance', summary)
        self.assertNotIn('No failures or incomplete checks', summary)

    def test_prepare_packet_succeeds_with_collection_gaps(self):
        self.files[self.run_url + 'boot/output.xml'] = b'broken'
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertTrue(self.report()['collection_gaps'])
        for name in ('report.html', 'summary.html'):
            self.assertTrue((self.output / name).is_file())
        self.assertEqual(self.cli('--render-only'), 0)
        self.assertTrue(self.report()['collection_gaps'])
        self.assertEqual(self.cli('--prepare-investigation'), 0)
        self.assertTrue((self.output / 'investigation-input.json').is_file())

    def test_parser_change_reprocesses_cached_xml_without_downloads(self):
        self.assertEqual(self.cli('--url', self.url, '--without-ai'), 0)
        self.requests.clear()
        with patch.object(analyzer, 'extraction_fingerprint', return_value='updated-parser'):
            self.assertEqual(self.cli('--url', self.url, '--without-ai'), 0)
        self.assertEqual(self.requests, [])
        self.assertEqual(self.report()['performance']['xml_cache_hits'], 0)
        self.assertEqual(self.report()['performance']['xml_parsed'], 1)
        self.assertEqual(self.report()['counts'], {'PASS': 1, 'FAIL': 1})

    def test_published_upstream_metadata_names_default_directory(self):
        self.robot({'UPSTREAM_PROJECT': 'ghaf-nightly', 'UPSTREAM_BUILD_ID': '789'})
        with patch.object(analyzer, 'default_output', return_value=self.output):
            self.assertEqual(self.cli('--url', self.url, explicit_output=False), 0)
        self.output = self.output.with_name('nightly-789')
        self.assertEqual(self.report()['upstream'], {'project': 'ghaf-nightly', 'build': '789'})
        self.assertIn('Nightly build #789', (self.output / 'report.html').read_text())
        self.assertEqual(analyzer.default_output(self.url).parts[-2:], ('2026-11-19', '200004332'))
        self.requests.clear()
        with patch.object(analyzer, 'default_output', return_value=self.root / 'result'):
            self.assertEqual(self.cli('--url', self.url, explicit_output=False), 0)
        self.assertEqual(self.requests, [])
        self.assertEqual(self.report()['performance']['xml_cache_hits'], 1)
        self.assertFalse((self.root / 'result').exists())

    def test_numbered_conflict_keeps_timestamp_output(self):
        self.robot({'UPSTREAM_PROJECT': 'ghaf-nightly', 'UPSTREAM_BUILD_ID': '789'})
        numbered = self.output.with_name('nightly-789')
        numbered.mkdir()
        (numbered / 'source.json').write_text('{"url": "https://other.example/"}')
        with patch.object(analyzer, 'default_output', return_value=self.output):
            self.assertEqual(self.cli('--url', self.url, explicit_output=False), 0)
        self.assertTrue((self.output / 'report.html').is_file())
        self.assertFalse((numbered / 'report.html').exists())

    def test_source_identity_is_not_redacted_and_cache_is_reused(self):
        with patch.dict('os.environ', {'JIRA_TOKEN': '20261119_200004332-commit_' + 'a' * 40}):
            self.assertEqual(self.cli('--url', self.url), 0)
            self.assertEqual(json.loads((self.output / 'source.json').read_text())['url'], self.url)
            self.requests.clear()
            self.assertEqual(self.cli('--url', self.url), 0)
            self.assertEqual(self.requests, [])
            self.assertEqual(self.cli('--render-only'), 0)

    def test_only_published_hw_results_are_collected_without_pipeline_lookup(self):
        self.files[self.url + 'packages.build-only/manifest.json'] = b'{}'
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertEqual(len(self.report()['targets']), 1)
        self.assertFalse(any('github' in request or '/job/' in request for request in self.requests))

    def test_one_corrupt_phase_does_not_hide_another_and_changed_cache_is_reparsed(self):
        self.files[self.run_url + 'boot/output.xml'] = b'broken'
        self.files[self.run_url + 'boot/log.html'] = b'log'
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertEqual(self.report()['counts'], {'PASS': 1, 'FAIL': 1})
        self.assertIn('Cannot parse', str(self.report()['collection_gaps']))
        xml = self.output / 'cache/packages.device/test-results/device/regression/output.xml'
        xml.write_text('changed and invalid')
        self.assertEqual(self.cli('--url', self.url), 0)
        self.assertEqual(self.report()['performance']['xml_cache_hits'], 0)

    def test_artifact_flash_console_is_read_without_jenkins_or_fake_tests(self):
        self.files.pop(self.phase_url + 'output.xml')
        self.files.pop(self.phase_url + 'log.html')
        self.files[self.run_url + 'console.log'] = (
            b'[Pipeline] { (Flash)\nERROR: Image verification failed\n[Pipeline] }\nPASSWORD=hidden\n'
        )
        self.assertEqual(self.cli('--url', self.url), 0)
        report = self.report()
        self.assertEqual(report['counts'], {})
        self.assertEqual(report['targets'][0]['runs'][0]['phases'], [])
        for name in ('report.html', 'summary.html'):
            html = (self.output / name).read_text()
            self.assertIn('Image verification failed', html)
            self.assertIn('stage: Flash', html)
            self.assertNotIn('PASSWORD=hidden', html)
        self.assertFalse(any('/job/' in url for url in self.requests))

    def test_shared_journal_above_eight_mib_is_collected(self):
        suite = TestSuite('Journal evidence')
        suite.tests.create('Failure').body.create_keyword('Fail', args=['Original failure'])
        suite.tests.create('Another failure').body.create_keyword('Fail', args=['Another failure'])
        suite.resource.keywords.create('Save suite log').body.create_keyword(
            'Log', args=['<a href="journal.txt">Journal</a>', 'html=True'],
        )
        suite.teardown.config(name='Save suite log')
        xml = self.root / 'journal-output.xml'
        suite.run(output=str(xml), log=None, report=None, stdout=StringIO())
        self.files[self.phase_url + 'output.xml'] = xml.read_bytes()
        content = b'padding\n' * (9 * 1024**2 // 8) + b'ERROR: diagnostic from a large journal\n'
        self.files[self.phase_url + 'journal.txt'] = content
        with patch.object(analyzer, 'select_debug_lines', wraps=analyzer.select_debug_lines) as select:
            self.assertEqual(self.cli('--url', self.url, '--without-ai'), 0)
        self.assertEqual(select.call_count, 1)
        self.assertTrue(select.call_args.args[0].closed)
        report = self.report()
        test = report['targets'][0]['runs'][0]['phases'][0]['tests'][0]
        journal = test['shared_artifacts'][0]
        self.assertTrue(journal['sha256'])
        self.assertIn('diagnostic from a large journal', str(journal['log_observations']))
        self.assertEqual(report['collection_gaps'], [])
        self.assertFalse(any('/job/' in url for url in self.requests))

    def test_fixed_xml_limit_accepts_large_existing_xml_and_rejects_oversized_download(self):
        source = analyzer.Source(self.url, self.output / 'cache')
        xml = source.cache / 'large/output.xml'
        xml.parent.mkdir(parents=True)
        with xml.open('wb') as stream:
            stream.truncate(429 * 1024**2)
        self.assertEqual(source.get(self.url + 'large/output.xml'), xml)
        response = BytesIO(b'not read')
        response.headers = {'Content-Length': str(1024**3 + 1)}
        with patch.object(source.opener, 'open', return_value=response):
            with self.assertRaisesRegex(ValueError, '1024 MiB'):
                source.get(self.url + 'oversized/output.xml')
        self.assertFalse((source.cache / 'oversized/output.xml').exists())

    def test_unsupported_sources_options_and_wrong_run_are_rejected(self):
        for args in (('--input', self.root), ('--source-type', 'bundle'), ('--offline',),
                     ('--refresh',), ('--reparse',), ('--max-file-mb', '100'),
                     ('--pipeline', 'pipeline.groovy'), ('--reports-root', self.root)):
            with self.subTest(args=args), self.assertRaises(SystemExit) as error:
                self.cli(*args)
            self.assertEqual(error.exception.code, 2)
        for url in ('https://ci.example/job/ghaf-nightly/1/', 'https://user:secret@ci.example/artifacts/'):
            with self.subTest(url=url):
                self.assertEqual(self.cli('--url', url), 1)
        self.cli('--url', self.url)
        self.assertEqual(self.cli('--url', self.url.replace('nightly/', 'other/')), 1)
        saved = self.report()
        saved['source_url'] = self.url.replace('nightly/', 'other/')
        (self.output / 'analysis.json').write_text(json.dumps(saved))
        self.assertEqual(self.cli('--render-only'), 1)

    def test_second_cli_on_same_output_fails_fast_and_lock_is_released(self):
        import subprocess

        self.assertEqual(self.cli('--url', self.url), 0)
        saved = (self.output / 'analysis.json').read_bytes()
        with analyzer.output_lock(self.output):
            blocked = subprocess.run(
                [sys.executable, str(Path(analyzer.__file__)), '--render-only', '--output', str(self.output)],
                capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(blocked.returncode, 1)
            self.assertIn('Another analyzer is using this output directory', blocked.stderr)
            self.assertEqual((self.output / 'analysis.json').read_bytes(), saved)
        self.assertEqual(self.cli('--render-only'), 0)

    def test_execution_errors_return_one_and_mask_stderr(self):
        for exception in (ValueError('https://h/?password=hunter2'), OSError('https://h/?password=hunter2')):
            stderr = StringIO()
            with patch.object(sys, 'argv', ['nightly-analyze', '--url', self.url]), \
                    patch.object(analyzer, 'reusable_output', side_effect=exception), redirect_stderr(stderr):
                self.assertEqual(analyzer.main(), 1)
            self.assertIn('error:', stderr.getvalue())
            self.assertNotIn('hunter2', stderr.getvalue())


if __name__ == '__main__':
    unittest.main()
