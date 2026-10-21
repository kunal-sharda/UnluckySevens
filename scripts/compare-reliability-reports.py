#!/usr/bin/env python3
"""Compare explicitly attributed reports from one coordinated checkpoint. Never infer delivery from a send callback."""
import argparse
import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import sys
import time

MAX_BYTES = 64 * 1024
HEX = re.compile(r'[0-9a-f]{64}\Z')
CANDIDATE = re.compile(r'[0-9a-f]{40}(?:[0-9a-f]{24})?\Z')
ACTIONS = {'invite', 'join', 'reconcile', 'setup', 'roll', 'build', 'trade', 'discard', 'robber',
           'developmentCard', 'endTurn', 'lifecycle', 'reopen', 'recovery', 'publication'}
BOUNDARIES = {'eligibility', 'encoding', 'localHandoff', 'stateSelection', 'recovery'}
OUTCOMES = {'observed', 'accepted', 'rejected', 'unavailable', 'failed'}
TRIGGERS = {'viewDidLoad', 'didSelect', 'didReceive', 'selectionPoll', 'reload'}


def exact_keys(value, required, optional=frozenset()):
    if not isinstance(value, dict) or not required <= value.keys() or value.keys() - required - optional:
        raise ValueError('Report contains missing or unapproved fields.')


def digest(value):
    if not isinstance(value, str) or not HEX.fullmatch(value):
        raise ValueError('Invalid correlation digest.')


def load_report(path):
    with Path(path).open('rb') as handle:
        raw = handle.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise ValueError('Report exceeds the size limit.')
    def reject_constant(_):
        raise ValueError('Non-finite JSON number.')
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('Duplicate JSON key.')
            result[key] = value
        return result
    value = json.loads(raw, parse_constant=reject_constant, object_pairs_hook=unique_object)
    exact_keys(value, {'schemaVersion', 'metadata', 'game', 'records'})
    if type(value['schemaVersion']) is not int or value['schemaVersion'] != 2:
        raise ValueError('Unsupported report version.')
    exact_keys(value['metadata'], {'version', 'build', 'candidate', 'configuration', 'osVersion'})
    if any(not isinstance(x, str) or not x or len(x) > 256 for x in value['metadata'].values()):
        raise ValueError('Invalid report metadata.')
    exact_keys(value['game'], {'digest'})
    digest(value['game']['digest'])
    records = value['records']
    if not isinstance(records, list) or len(records) > 128:
        raise ValueError('Invalid record count.')
    previous_sequence = -1
    previous_time = -math.inf
    for record in records:
        exact_keys(record, {'sequence', 'timestamp', 'observation'})
        sequence, timestamp = record['sequence'], record['timestamp']
        if type(sequence) is not int or not previous_sequence < sequence < 2**64 - 1:
            raise ValueError('Invalid record sequence.')
        if type(timestamp) not in (int, float) or not math.isfinite(timestamp) or timestamp < previous_time:
            raise ValueError('Invalid record timestamp.')
        previous_sequence, previous_time = sequence, timestamp
        observation = record['observation']
        exact_keys(observation, {'game', 'revision', 'action', 'boundary', 'outcome', 'actorMembership'},
                   {'stateDigest', 'trigger', 'sessionPresent'})
        if observation['game'] != value['game']:
            raise ValueError('Report includes an unrelated game.')
        if type(observation['revision']) is not int or not 0 <= observation['revision'] < 2**64:
            raise ValueError('Invalid revision.')
        if observation['action'] not in ACTIONS or observation['boundary'] not in BOUNDARIES or observation['outcome'] not in OUTCOMES:
            raise ValueError('Unapproved observation category.')
        if observation['actorMembership'] not in {'joined', 'notInRoster', 'unavailable'}:
            raise ValueError('Invalid membership category.')
        if 'stateDigest' in observation:
            digest(observation['stateDigest'])
        if 'trigger' in observation and observation['trigger'] not in TRIGGERS:
            raise ValueError('Invalid trigger.')
        if 'sessionPresent' in observation and type(observation['sessionPresent']) is not bool:
            raise ValueError('Invalid session observation.')
    # Canonical content fingerprint rejects renamed/reformatted copies as well.
    fingerprint = hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    return value, fingerprint


def compare(reports, *, candidate, version, build, revision, since, separate_accounts, now=None, allow_debug=False):
    if not separate_accounts:
        raise ValueError('Separate accounts require explicit operator attestation.')
    if not CANDIDATE.fullmatch(candidate) or revision < 0 or not math.isfinite(since):
        raise ValueError('A frozen candidate, expected revision and checkpoint time are required.')
    if not 2 <= len(reports) <= 4 or len({r[0] for r in reports}) != len(reports):
        raise ValueError('Supply two to four distinct participant roles.')
    now = time.time() if now is None else now
    if since > now or since < now - 24 * 60 * 60:
        raise ValueError('Checkpoint must be within the report retention window.')
    fingerprints, checkpoints, games = set(), [], set()
    for role, path in reports:
        if not re.fullmatch(r'[a-z][a-z0-9_-]{0,31}', role):
            raise ValueError('Use anonymous role labels, such as host and guest.')
        report, fingerprint = load_report(path)
        if fingerprint in fingerprints:
            raise ValueError('Duplicate report content cannot prove another participant.')
        fingerprints.add(fingerprint)
        metadata = report['metadata']
        expected_configuration = 'debug' if allow_debug else 'release'
        if any(metadata[k] != v for k, v in {'candidate': candidate, 'version': version, 'build': build,
                                           'configuration': expected_configuration}.items()):
            raise ValueError('Candidate/build/configuration mismatch or unfrozen candidate.')
        games.add(report['game']['digest'])
        selections = [r for r in report['records'] if r['observation']['boundary'] == 'stateSelection']
        if not selections:
            raise ValueError('Missing selected/received-state evidence; local handoff is insufficient.')
        latest = selections[-1]
        observation = latest['observation']
        if not since <= latest['timestamp'] <= now + 300:
            raise ValueError('Selected-state observation is stale or from an invalid clock.')
        if observation['outcome'] != 'accepted' or observation.get('trigger') not in TRIGGERS or observation.get('sessionPresent') is not True:
            raise ValueError('Latest decoded state was not confirmed active in a bound conversation.')
        if observation['actorMembership'] != 'joined' or 'stateDigest' not in observation:
            raise ValueError('Missing joined-player or canonical-state evidence.')
        checkpoints.append((observation['revision'], observation['stateDigest']))
    if len(games) != 1:
        raise ValueError('Reports refer to different games.')
    matched = len(set(checkpoints)) == 1 and checkpoints[0][0] == revision
    return {'status': 'matched' if matched else 'divergent-or-unexpected-revision',
            'participants': len(reports), 'expected_revision': revision,
            'separate_accounts': 'operator-attested', 'candidate_provenance': 'reported-metadata',
            'scope': 'selected-state checkpoint only; not all-message delivery or visual correctness'}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', action='append', required=True, metavar='ROLE=PATH')
    parser.add_argument('--candidate', required=True, help='Frozen source/candidate SHA embedded in every report')
    parser.add_argument('--version', required=True)
    parser.add_argument('--build', required=True)
    parser.add_argument('--revision', type=int, required=True)
    parser.add_argument('--since', required=True, help='Checkpoint start with timezone, e.g. 2026-09-22T14:00:00-07:00')
    parser.add_argument('--separate-accounts', action='store_true')
    parser.add_argument('--allow-debug', action='store_true', help='Compare Debug reports only; never claim TestFlight proof')
    args = parser.parse_args(argv)
    try:
        moment = datetime.datetime.fromisoformat(args.since.replace('Z', '+00:00'))
        if moment.tzinfo is None:
            raise ValueError('Checkpoint time needs an explicit timezone.')
        roles = []
        for value in args.report:
            role, separator, path = value.partition('=')
            if not separator or not path:
                raise ValueError('Reports must use ROLE=PATH.')
            roles.append((role, path))
        result = compare(roles, candidate=args.candidate, version=args.version, build=args.build,
                         revision=args.revision, since=moment.timestamp(), separate_accounts=args.separate_accounts,
                         allow_debug=args.allow_debug)
        print(json.dumps(result, indent=2))
        return 0 if result['status'] == 'matched' else 1
    except (ValueError, OSError, TypeError, KeyError) as error:
        # No raw report, path, or filesystem error enters the comparison output.
        reason = str(error) if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError) else 'Report could not be read or validated.'
        print(json.dumps({'status': 'unverified', 'reason': reason}))
        return 2


if __name__ == '__main__':
    sys.exit(main())
