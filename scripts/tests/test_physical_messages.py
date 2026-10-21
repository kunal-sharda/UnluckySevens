import contextlib
import importlib.util
import io
import hashlib
import plistlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('physical', Path(__file__).parents[1] / 'run-physical-messages.py')
physical = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(physical)


class PhysicalDriverTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = dict(device='DEVICE-ID', team='TEAM123', conversation_row='Dedicated Test', conversation_header='Dedicated Test')

    def test_configuration_is_explicit(self):
        path = self.root / 'config.json'
        for value in ({}, {**self.config, 'device': 'x,platform=iOS Simulator'}, {**self.config, 'conversation_header': ''}):
            path.write_text(json.dumps(value))
            with self.assertRaises(ValueError):
                physical.read_config(path)
        path.write_text(json.dumps(self.config))
        self.assertEqual(physical.read_config(path), self.config)

    def test_preflight_queries_only_apps_without_build_install_or_send(self):
        calls = []
        def fake(command, log, timeout):
            calls.append(command)
            self.assertEqual(timeout, 25)
            self.assertEqual(command[:5], ['xcrun', 'devicectl', 'device', 'info', 'apps'])
            Path(command[command.index('--json-output') + 1]).write_text(json.dumps({'result': {'apps': [{
                'bundleIdentifier': 'me.ksharda.games.unluckysevens', 'url': 'file:///test/app/',
                'version': '1.0', 'bundleVersion': '8'}]}}))
        with patch.object(physical, 'OUTPUT', self.root / 'runs'), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(physical.run(self.config, 'preflight', fake), 0)
        self.assertEqual(len(calls), 1)
        report = json.loads(next((self.root / 'runs').glob('*/report.json')).read_text())
        self.assertEqual(report['status'], 'device-app-query-passed')
        for key in ('distribution', 'candidate_equivalence', 'ui_readiness', 'recipient_receipt', 'canonical_agreement'):
            self.assertEqual(report[key], 'unverified')
        self.assertFalse(report['installs'])
        self.assertFalse(report['sends'])

    def test_preflight_missing_app_or_timeout_stops_without_retry(self):
        for failure in ('missing', 'timeout', 'malformed'):
            calls = []
            def fake(command, log, timeout):
                calls.append(command)
                if failure == 'timeout':
                    raise RuntimeError('Timed out')
                Path(command[command.index('--json-output') + 1]).write_text(
                    '{}' if failure == 'missing' else 'not JSON')
            output = self.root / failure
            with patch.object(physical, 'OUTPUT', output), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                self.assertEqual(physical.run(self.config, 'preflight', fake), 1)
            self.assertEqual(len(calls), 1)
            report = json.loads(next(output.glob('*/report.json')).read_text())
            self.assertEqual(report['status'], 'blocked-or-failed')

    def test_preflight_cli_needs_no_install_permission_and_rejects_send_flags(self):
        path = self.root / 'config.json'
        path.write_text(json.dumps(self.config))
        base = ['--config', str(path), '--step', 'preflight', '--execute']
        with patch.object(physical, 'run', return_value=0) as run:
            self.assertEqual(physical.main(base), 0)
            run.assert_called_once_with(self.config, 'preflight', resume=None)
        for flag in ('--allow-send', '--allow-development-install'):
            with patch.object(physical, 'run') as run, contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit):
                    physical.main(base + [flag])
                run.assert_not_called()

    def test_xctestrun_injects_only_test_runner_environment(self):
        for data in ({'UITests': {'BlueprintName': 'UnluckySevensUITests'}},
                     {'TestConfigurations': [{'TestTargets': [{'BlueprintName': 'UnluckySevensUITests'}]}]}):
            physical.configure_xctestrun(data, self.config, 'probe')
            text = json.dumps(data)
            self.assertIn('ULS_PHYSICAL_ENABLED', text)
            self.assertIn('"ULS_PHYSICAL_ALLOW_SEND": "0"', text)
            self.assertNotIn('UITargetAppEnvironmentVariables', text)

    def test_missing_or_duplicate_test_target_rejected(self):
        for targets in ([], [{'BlueprintName': 'UnluckySevensUITests'}] * 2):
            with self.assertRaises(ValueError):
                physical.configure_xctestrun({'TestConfigurations': [{'TestTargets': targets}]}, self.config, 'invite')

    def test_preflight_failure_never_installs_or_sends(self):
        calls = []
        def fail(command, *args):
            calls.append(command)
            raise RuntimeError('device locked')
        with patch.object(physical, 'OUTPUT', self.root), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(physical.run(self.config, 'invite', fail), 1)
        self.assertEqual(len(calls), 1)
        self.assertIn('info', calls[0])
        report = json.loads(next(self.root.glob('*/report.json')).read_text())
        self.assertEqual(report['canonical_agreement'], 'unverified')
        self.assertEqual(report['status'], 'blocked-or-failed')

    def test_skipped_empty_or_wrong_test_never_passes(self):
        summary = dict(result='Passed', totalTestCount=1, passedTests=1, failedTests=0, skippedTests=0, expectedFailures=0)
        tests = {'testNodes': [{'nodeType': 'Test Case', 'nodeIdentifier': 'PhysicalMessagesSmokeUITests/testProbeDedicatedConversation()', 'result': 'Passed'}]}
        physical.verify_results(summary, tests, 'probe')
        for change in ({'skippedTests': 1}, {'totalTestCount': 0}, {'passedTests': 0}, {'result': 'Failed'}):
            with self.assertRaises(ValueError):
                physical.verify_results({**summary, **change}, tests, 'probe')
        with self.assertRaises(ValueError):
            physical.verify_results(summary, tests, 'invite')

    def test_preview_does_not_execute_and_send_requires_flag(self):
        path = self.root / 'config.json'
        path.write_text(json.dumps(self.config))
        with patch.object(physical, 'run') as run, contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(physical.main(['--config', str(path)]), 0)
            with self.assertRaises(SystemExit):
                physical.main(['--config', str(path), '--step', 'invite', '--execute', '--allow-development-install'])
            run.assert_not_called()

    def test_reopen_requires_successful_same_device_invite_and_remote_confirmation(self):
        directory = self.root / 'invite'
        directory.mkdir()
        report = dict(step='invite', status='invite-control-tapped', device='DEVICE-ID', version='1.0', build='8')
        report['installed_app_identity'] = {'url': 'file:///installed/app/', 'version': '1.0', 'bundleVersion': '8'}
        executable = directory / 'DerivedData/Build/Products/Debug-iphoneos/UnluckySevensApp.app/PlugIns/MessagesExtension.appex/MessagesExtension'
        executable.parent.mkdir(parents=True)
        executable.write_bytes(b'original invite candidate')
        report['built_extension_sha256'] = hashlib.sha256(executable.read_bytes()).hexdigest()
        path = directory / 'report.json'
        path.write_text(json.dumps(report))
        with patch.object(physical, 'OUTPUT', self.root):
            resume = physical.read_resume(directory, self.config, 'Unlucky Sevens: Guest Joined, 1 image', True)
            self.assertEqual(resume['remote_join'], 'operator-confirmed')
            selected = physical.read_resume(directory, self.config, 'Exact Joined', True, occurrence=2, expected_count=2)
            data = {'UITests': {'BlueprintName': 'UnluckySevensUITests'}}
            physical.configure_xctestrun(data, self.config, 'reopen', selected)
            env = data['UITests']['EnvironmentVariables']
            self.assertEqual(env['ULS_PHYSICAL_JOIN_BUBBLE_OCCURRENCE'], '2')
            self.assertEqual(env['ULS_PHYSICAL_JOIN_BUBBLE_COUNT'], '2')
            for occurrence, count in [(0, 2), (3, 2), (1, 21), (True, 1), (1, '2')]:
                with self.assertRaises(ValueError):
                    physical.read_resume(directory, self.config, 'Exact Joined', True, occurrence=occurrence, expected_count=count)
            with self.assertRaises(ValueError):
                physical.read_resume(directory, self.config, None, True, inspect=True, occurrence=2, expected_count=2)
            inspection = physical.read_resume(directory, self.config, None, True, inspect=True)
            self.assertEqual(inspection['join_bubble_label'], '')
            for label, confirmed in [('', True), ('x' * 257, True), ('line\nbreak', True), ('Joined', False), (None, True)]:
                with self.assertRaises(ValueError):
                    physical.read_resume(directory, self.config, label, confirmed)
            for change in ({'step': 'probe'}, {'status': 'blocked-or-failed'}, {'device': 'OTHER'}, {'installed_app_identity': None}, {'built_extension_sha256': '0' * 64}, {'built_extension_sha256': None}):
                path.write_text(json.dumps({**report, **change}))
                with self.assertRaises(ValueError):
                    physical.read_resume(directory, self.config, 'Joined', True)
            with self.assertRaises(ValueError):
                physical.read_resume(self.root.parent, self.config, 'Joined', True)

    def test_reopen_cannot_enable_sending(self):
        data = {'UITests': {'BlueprintName': 'UnluckySevensUITests', 'DependentProductPaths': [
            '__TESTROOT__/Debug-iphoneos/UnluckySevensApp.app',
            '__TESTROOT__/Debug-iphoneos/UnluckySevensUITests-Runner.app']}}
        physical.configure_xctestrun(data, self.config, 'reopen', {
            'join_bubble_label': 'Exact Joined', 'candidate_app': '/retained/UnluckySevensApp.app'})
        env = data['UITests']['EnvironmentVariables']
        self.assertEqual(env['ULS_PHYSICAL_ALLOW_SEND'], '0')
        self.assertEqual(env['ULS_PHYSICAL_JOIN_BUBBLE_LABEL'], 'Exact Joined')
        self.assertTrue(data['UITests']['UseDestinationArtifacts'])
        self.assertNotIn('UITargetAppPath', data['UITests'])
        self.assertNotIn('DependentProductPaths', data['UITests'])
        self.assertEqual(data['UITests']['UITargetAppBundleIdentifier'], 'me.ksharda.games.unluckysevens')
        with self.assertRaises(ValueError):
            physical.run(self.config, 'reopen')
        with self.assertRaises(ValueError):
            physical.run(self.config, 'inspect')
        physical.configure_xctestrun(data, self.config, 'inspect', {
            'join_bubble_label': '', 'candidate_app': '/retained/UnluckySevensApp.app'})
        self.assertEqual(data['UITests']['EnvironmentVariables']['ULS_PHYSICAL_ALLOW_SEND'], '0')

    def test_installation_identity_requires_exact_one_app(self):
        app = {'bundleIdentifier': 'me.ksharda.games.unluckysevens', 'url': 'file:///one/app/', 'version': '1.0', 'bundleVersion': '8'}
        identity = physical.installed_app_identity({'result': {'apps': [app]}})
        self.assertEqual(identity['url'], app['url'])
        for apps in ([], [app, app], [{**app, 'url': ''}]):
            with self.assertRaises(ValueError):
                physical.installed_app_identity({'result': {'apps': apps}})

    def test_resume_installs_only_runner_and_rejects_changed_installation(self):
        app = self.root / 'retained' / 'UnluckySevensApp.app'
        executable = app / 'PlugIns/MessagesExtension.appex/MessagesExtension'
        executable.parent.mkdir(parents=True)
        executable.write_bytes(b'candidate')
        (app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'me.ksharda.games.unluckysevens',
            'CFBundleShortVersionString': '1.0', 'CFBundleVersion': '8'}))
        identity = {'url': 'file:///same/app/', 'version': '1.0', 'bundleVersion': '8'}
        resume = {'candidate_app': str(app), 'invite_extension_sha256': hashlib.sha256(b'candidate').hexdigest(),
                  'invite_version': '1.0', 'invite_build': '8', 'join_bubble_label': 'Exact Joined',
                  'installed_app_identity': identity}
        calls = []
        def fake(command, log, timeout=900):
            calls.append(command)
            if 'apps' in command:
                path = Path(command[command.index('--json-output') + 1])
                path.write_text(json.dumps({'result': {'apps': [{**identity, 'bundleIdentifier': 'me.ksharda.games.unluckysevens'}]}}))
            if 'build-for-testing' in command:
                products = Path(command[command.index('-derivedDataPath') + 1]) / 'Build/Products'
                products.mkdir(parents=True)
                (products / 'test.xctestrun').write_bytes(plistlib.dumps({'UITests': {'BlueprintName': 'UnluckySevensUITests'}}))
            if 'test-without-building' in command:
                raise RuntimeError('Stop after installation assertions')
        with patch.object(physical, 'OUTPUT', self.root / 'runs'), contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(physical.run(self.config, 'reopen', fake, resume), 1)
            installs = [c for c in calls if 'install' in c]
            self.assertEqual(len(installs), 1)
            self.assertTrue(installs[0][-3].endswith('UnluckySevensUITests-Runner.app'))
            calls.clear()
            changed = {**resume, 'installed_app_identity': {**identity, 'url': 'file:///other/app/'}}
            self.assertEqual(physical.run(self.config, 'reopen', fake, changed), 1)
            self.assertEqual(len(calls), 1)
