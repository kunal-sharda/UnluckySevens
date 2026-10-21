#!/usr/bin/env python3
"""Bounded Messages driver. Start with read-only preflight, then probe/invite.

The remote phone remains human-operated. Reopen resumes from a successful invite
and an explicit operator join confirmation; it never sends. Installs target ONE
explicit device; it may replace TestFlight. Output stays private under output/.
"""
import argparse
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import plistlib
import signal
import subprocess
import sys
import uuid

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output' / 'physical-messages'
TESTS = {'probe': 'testProbeDedicatedConversation', 'invite': 'testPublishInvite',
         'inspect': 'testInspectDedicatedConversation',
         'reopen': 'testReopenJoinedLobby'}
STEPS = ('preflight', *TESTS)
SCREENSHOTS = {'probe': 'physical-probe-extension-open',
               'inspect': 'physical-conversation-inspected',
               'invite': 'physical-invite-control-tapped-receipt-unverified',
               'reopen': 'physical-reopened-joined-lobby'}


def installed_app_identity(data):
    apps = [a for a in data.get('result', {}).get('apps', [])
            if a.get('bundleIdentifier') == 'me.ksharda.games.unluckysevens']
    if len(apps) != 1 or any(not isinstance(apps[0].get(key), str) or not apps[0][key].strip()
                             for key in ('url', 'version', 'bundleVersion')):
        raise ValueError('Expected one installed game with a recorded installation path.')
    return {key: apps[0][key] for key in ('url', 'version', 'bundleVersion')}


def read_resume(path, config, label, remote_joined, inspect=False, occurrence=1, expected_count=1):
    if not remote_joined:
        raise ValueError('Reopen requires explicit operator confirmation of the phone join.')
    if not inspect and (not isinstance(label, str) or not label.strip() or len(label) > 256 or '\n' in label):
        raise ValueError('Reopen requires the exact joined-bubble accessibility label (1–256 characters).')
    if type(occurrence) is not int or type(expected_count) is not int or not 1 <= occurrence <= expected_count <= 20:
        raise ValueError("Bubble occurrence/count must satisfy 1 <= occurrence <= count <= 20.")
    if inspect and (occurrence, expected_count) != (1, 1):
        raise ValueError("Bubble occurrence selection applies only to reopen.")
    directory = Path(path).resolve()
    if not directory.is_relative_to(OUTPUT.resolve()) or directory == OUTPUT.resolve():
        raise ValueError('Invite run must be under the private physical-messages output directory.')
    report = json.loads((directory / 'report.json').read_text())
    if report.get('step') != 'invite' or report.get('status') != 'invite-control-tapped':
        raise ValueError('Reopen must follow a successful invite run; never resend automatically.')
    if report.get('device') != config['device']:
        raise ValueError('Reopen must use the same home device as the invite.')
    if not report.get('installed_app_identity'):
        raise ValueError('Invite predates installation-preserving coordination; start a fresh explicitly authorized invite.')
    app = directory / 'DerivedData' / 'Build' / 'Products' / 'Debug-iphoneos' / 'UnluckySevensApp.app'
    expected_hash = report.get('built_extension_sha256')
    if not isinstance(expected_hash, str) or len(expected_hash) != 64:
        raise ValueError('Invite run lacks its extension hash.')
    executable = app / 'PlugIns' / 'MessagesExtension.appex' / 'MessagesExtension'
    if not executable.is_file() or hashlib.sha256(executable.read_bytes()).hexdigest() != expected_hash:
        raise ValueError('Retained invite candidate is missing or differs from its recorded hash.')
    return {'invite_run': str(directory), 'join_bubble_label': label or '',
            'remote_join': 'operator-confirmed',
            'join_bubble_occurrence': occurrence, 'join_bubble_count': expected_count,
            'candidate_app': str(app), 'invite_extension_sha256': expected_hash,
            'installed_app_identity': report['installed_app_identity'],
            'invite_version': report.get('version'), 'invite_build': report.get('build')}


def read_config(path):
    value = json.loads(Path(path).read_text())
    required = {'device', 'team', 'conversation_row', 'conversation_header'}
    if set(value) != required or any(not isinstance(value[k], str) or not value[k].strip() for k in required):
        raise ValueError('Config requires exactly four nonempty strings: device, team, conversation_row, conversation_header.')
    # Destination/build-setting arguments must not introduce additional options.
    for key in ('device', 'team'):
        if not all(c.isalnum() or c == '-' for c in value[key]):
            raise ValueError(f'Invalid {key}.')
    return value


def configure_xctestrun(data, config, step, resume=None):
    targets = []
    if 'TestConfigurations' in data:
        for configuration in data['TestConfigurations']:
            targets.extend(configuration.get('TestTargets', []))
    else:
        targets = [v for k, v in data.items() if k != '__xctestrun_metadata__' and isinstance(v, dict)]
    matches = [t for t in targets if t.get('BlueprintName') == 'UnluckySevensUITests'
               or 'UnluckySevensUITests' in t.get('TestBundlePath', '')]
    if len(matches) != 1:
        raise ValueError('Expected exactly one UI test target in xctestrun.')
    target = matches[0]
    target.setdefault('EnvironmentVariables', {}).update({
        'ULS_PHYSICAL_ENABLED': '1',
        'ULS_PHYSICAL_ALLOW_SEND': '1' if step == 'invite' else '0',
        'ULS_PHYSICAL_CONVERSATION_ROW': config['conversation_row'],
        'ULS_PHYSICAL_CONVERSATION_HEADER': config['conversation_header'],
        'ULS_PHYSICAL_JOIN_BUBBLE_LABEL': resume['join_bubble_label'] if resume else '',
        'ULS_PHYSICAL_JOIN_BUBBLE_OCCURRENCE': str(resume.get('join_bubble_occurrence', 1)) if resume else '1',
        'ULS_PHYSICAL_JOIN_BUBBLE_COUNT': str(resume.get('join_bubble_count', 1)) if resume else '1',
    })
    # xcodebuild.xctestrun's documented destination-artifacts mode prevents
    # implicit target reinstallation. The driver installs the runner explicitly;
    # a continuation must leave the already-installed game untouched.
    for key in ('TestBundlePath', 'TestHostPath', 'UITargetAppPath', 'DependentProductPaths'):
        target.pop(key, None)
    target.update(UseDestinationArtifacts=True,
                  TestHostBundleIdentifier='me.ksharda.games.unluckysevens.uitests.xctrunner',
                  TestBundleDestinationRelativePath='__TESTHOST__/PlugIns/UnluckySevensUITests.xctest',
                  UITargetAppBundleIdentifier='me.ksharda.games.unluckysevens')
    return data


def verify_results(summary, tests, step):
    if any(summary.get(k) != v for k, v in {
        'result': 'Passed', 'totalTestCount': 1, 'passedTests': 1,
        'failedTests': 0, 'skippedTests': 0, 'expectedFailures': 0,
    }.items()):
        raise ValueError('Expected one executed passing test; skipped/empty results cannot pass.')
    def walk(nodes):
        for node in nodes:
            yield node
            yield from walk(node.get('children', []))
    cases = [n for n in walk(tests.get('testNodes', [])) if n.get('nodeType') == 'Test Case']
    expected = 'PhysicalMessagesSmokeUITests/' + TESTS[step]
    if len(cases) != 1 or cases[0].get('result') != 'Passed' or cases[0].get('nodeIdentifier', '').removesuffix('()') != expected:
        raise ValueError('Selected physical test identity was not proven by xcresult.')


def execute(command, log, timeout=900):
    with log.open('w') as stream:
        process = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=timeout)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            raise RuntimeError(f'Command interrupted or timed out; see {log}')
    if code:
        raise RuntimeError(f'Command failed ({code}); see {log}. No automatic retry.')


def save(directory, report):
    (directory / 'report.json').write_text(json.dumps(report, indent=2) + '\n')


def run(config, step, executor=execute, resume=None):
    if step not in STEPS:
        raise ValueError('Unknown physical step.')
    if step in ('inspect', 'reopen') and resume is None:
        raise ValueError('Reopen needs a validated invite run and phone-join checkpoint.')
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with (OUTPUT / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        directory = OUTPUT / (datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8])
        directory.mkdir(mode=0o700)
        report = {'step': step, 'status': 'running',
                  'distribution': 'unverified' if step == 'preflight' else 'development',
                  'recipient_receipt': 'unverified', 'canonical_agreement': 'unverified',
                  'device': config['device'], 'automatic_retries': 0}
        if resume:
            report.update(resume)
            report['recipient_receipt'] = 'operator-confirmed'
            report['candidate_equivalence'] = 'retained-invite-app'
        save(directory, report)
        print(f'Private evidence: {directory}', flush=True)
        try:
            # Read-only preflight before any build/install. Availability failure stops.
            executor(['xcrun', 'devicectl', 'device', 'info', 'apps', '--device', config['device'],
                      '--json-output', str(directory / 'apps-before.json'), '--timeout', '15'], directory / 'preflight.log', 25)
            if step == 'preflight':
                report.update(
                    status='device-app-query-passed',
                    installed_app_identity=installed_app_identity(json.loads((directory / 'apps-before.json').read_text())),
                    ui_readiness='unverified', candidate_equivalence='unverified',
                    installs=False, sends=False)
                save(directory, report)
                print('Device app query passed. UI readiness, signing, candidate equivalence and distribution remain unverified.')
                return 0
            if resume and installed_app_identity(json.loads((directory / 'apps-before.json').read_text())) != resume['installed_app_identity']:
                raise ValueError('Game installation changed after invite; refusing to infer identity continuity.')
            executor(['bash', './scripts/gen.sh'], directory / 'generation.log')
            derived = directory / 'DerivedData'
            executor(['xcodebuild', '-workspace', 'UnluckySevens.xcworkspace', '-scheme', 'UnluckySevens',
                      '-configuration', 'Debug', '-destination', 'platform=iOS,id=' + config['device'],
                      '-derivedDataPath', str(derived), 'DEVELOPMENT_TEAM=' + config['team'],
                      'build-for-testing'], directory / 'build.log')
            products = derived / 'Build' / 'Products'
            paths = list(products.glob('*.xctestrun'))
            if len(paths) != 1:
                raise ValueError('Expected exactly one generated xctestrun.')
            # Keep the customized file beside the original: __TESTROOT__ is relative.
            original = paths[0]
            target = original.with_name('physical-session.xctestrun')
            data = configure_xctestrun(plistlib.loads(original.read_bytes()), config, step, resume)
            target.write_bytes(plistlib.dumps(data))
            app = Path(resume['candidate_app']) if resume else products / 'Debug-iphoneos' / 'UnluckySevensApp.app'
            info = plistlib.loads((app / 'Info.plist').read_bytes())
            if info.get('CFBundleIdentifier') != 'me.ksharda.games.unluckysevens':
                raise ValueError('Unexpected app bundle identity.')
            if resume and (info['CFBundleShortVersionString'], info['CFBundleVersion']) != (resume['invite_version'], resume['invite_build']):
                raise ValueError('Reopen build identity differs from the invite; stop for candidate review.')
            executable = app / 'PlugIns' / 'MessagesExtension.appex' / 'MessagesExtension'
            if resume and hashlib.sha256(executable.read_bytes()).hexdigest() != resume['invite_extension_sha256']:
                raise ValueError('Retained invite candidate changed during preparation; stopping before installation.')
            report.update(version=info['CFBundleShortVersionString'], build=info['CFBundleVersion'],
                          built_extension_sha256=hashlib.sha256(executable.read_bytes()).hexdigest())
            save(directory, report)
            if not resume:
                executor(['xcrun', 'devicectl', 'device', 'install', 'app', '--device', config['device'], str(app),
                          '--timeout', '60'], directory / 'install.log', 75)
                executor(['xcrun', 'devicectl', 'device', 'info', 'apps', '--device', config['device'],
                          '--json-output', str(directory / 'apps-installed.json'), '--timeout', '15'], directory / 'installed-app.log', 25)
                report['installed_app_identity'] = installed_app_identity(json.loads((directory / 'apps-installed.json').read_text()))
                save(directory, report)
            else:
                report['game_installation'] = 'preserved-no-reinstall'
                save(directory, report)
            runner = products / 'Debug-iphoneos' / 'UnluckySevensUITests-Runner.app'
            executor(['xcrun', 'devicectl', 'device', 'install', 'app', '--device', config['device'], str(runner),
                      '--timeout', '60'], directory / 'runner-install.log', 75)
            executor(['xcodebuild', 'test-without-building', '-xctestrun', str(target),
                      '-destination', 'platform=iOS,id=' + config['device'],
                      '-only-testing:UnluckySevensUITests/PhysicalMessagesSmokeUITests/' + TESTS[step],
                      '-parallel-testing-enabled', 'NO',
                      '-resultBundlePath', str(directory / 'result.xcresult')], directory / 'test.log', 180)
            for kind in ('summary', 'tests'):
                executor(['xcrun', 'xcresulttool', 'get', 'test-results', kind,
                          '--path', str(directory / 'result.xcresult')], directory / (kind + '.json'), 30)
            verify_results(json.loads((directory / 'summary.json').read_text()),
                           json.loads((directory / 'tests.json').read_text()), step)
            executor(['xcrun', 'xcresulttool', 'export', 'attachments',
                      '--path', str(directory / 'result.xcresult'), '--output-path', str(directory / 'attachments')],
                     directory / 'attachments.log', 30)
            manifest = json.loads((directory / 'attachments' / 'manifest.json').read_text())
            name = SCREENSHOTS[step]
            attachments = [a for entry in manifest for a in entry.get('attachments', [])
                           if name in a.get('suggestedHumanReadableName', '')]
            if len(attachments) != 1:
                raise ValueError('Expected named physical-step screenshot.')
            screenshot = directory / 'attachments' / attachments[0]['exportedFileName']
            if not screenshot.is_file() or screenshot.stat().st_size == 0:
                raise ValueError('Missing physical-step screenshot bytes.')
            if step == 'inspect':
                records = [a for entry in manifest for a in entry.get('attachments', [])
                           if 'physical-visible-game-links' in a.get('suggestedHumanReadableName', '')]
                if len(records) != 1:
                    raise ValueError('Expected one visible game-link attachment.')
                report['visible_game_links'] = json.loads((directory / 'attachments' / records[0]['exportedFileName']).read_text())
            if step == 'reopen':
                diagnostics = [a for entry in manifest for a in entry.get('attachments', [])
                               if 'physical-reopened-lobby-state' in a.get('suggestedHumanReadableName', '')]
                if len(diagnostics) != 1:
                    raise ValueError('Expected one reopened-lobby diagnostic attachment.')
                fields = json.loads((directory / 'attachments' / diagnostics[0]['exportedFileName']).read_text())
                if set(fields) != {'game', 'rev', 'phase', 'hash'} or fields['phase'] != 'lobby' or int(fields['rev']) < 1:
                    raise ValueError('Invalid reopened-lobby evidence.')
                if any(not isinstance(fields[k], str) or not fields[k] or fields[k] == '-' for k in ('game', 'hash')):
                    raise ValueError('Missing reopened game identity/hash.')
                report['home_lobby'] = fields
            report['status'] = {'probe': 'probe-passed', 'invite': 'invite-control-tapped',
                                'inspect': 'conversation-inspected',
                                'reopen': 'home-reopen-passed'}[step]
        except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
            report.update(status='blocked-or-failed', reason=str(error))
            save(directory, report)
            print(str(error), file=sys.stderr)
            return 1
        save(directory, report)
        return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', required=True, help='Private JSON config; see device runbook')
    parser.add_argument('--step', choices=STEPS, default='probe')
    parser.add_argument('--execute', action='store_true', help='Execute; otherwise preview only')
    parser.add_argument('--allow-development-install', action='store_true', help='Allow replacing the installed app on this explicit device')
    parser.add_argument('--allow-send', action='store_true', help='Allow one invite to the configured dedicated conversation')
    parser.add_argument('--resume-invite', help='Private successful invite-run directory for the no-send reopen step')
    parser.add_argument('--join-bubble-label', help='Exact accessibility label of the joined-game transcript link')
    parser.add_argument('--join-bubble-occurrence', type=int, default=1, help='Explicit one-based visible occurrence, top to bottom; default unique only')
    parser.add_argument('--join-bubble-count', type=int, default=1, help='Exact expected visible matching-link count from inspected evidence')
    parser.add_argument('--remote-joined', action='store_true', help='Operator confirms phone received/opened the invite and joined')
    args = parser.parse_args(argv)
    config = read_config(args.config)
    if args.step == 'preflight' and (args.allow_send or args.allow_development_install):
        parser.error('Preflight is read-only; install/send flags do not apply.')
    resume = None
    if args.step in ('inspect', 'reopen'):
        if not args.resume_invite:
            parser.error('Reopen requires --resume-invite.')
        resume = read_resume(args.resume_invite, config, args.join_bubble_label, args.remote_joined, inspect=args.step == 'inspect', occurrence=args.join_bubble_occurrence, expected_count=args.join_bubble_count)
    elif args.resume_invite or args.join_bubble_label or args.remote_joined or args.join_bubble_occurrence != 1 or args.join_bubble_count != 1:
        parser.error('Remote join options apply only to --step reopen.')
    if not args.execute:
        print(json.dumps({'step': args.step, 'execution': 'preview-only',
                          'installs': False if args.step in ('preflight', 'inspect', 'reopen') else 'development game on configured device',
                          'runner_install': args.step != 'preflight',
                          'sends': args.step == 'invite', 'test': TESTS.get(args.step)}, indent=2))
        return 0
    if args.step != 'preflight' and not args.allow_development_install:
        parser.error('Execution requires --allow-development-install (may replace TestFlight).')
    if args.step == 'invite' and not args.allow_send:
        parser.error('Invite requires --allow-send for the dedicated conversation.')
    return run(config, args.step, resume=resume)


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        sys.exit(2)
