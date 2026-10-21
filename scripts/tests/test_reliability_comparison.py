import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location('comparison', Path(__file__).parents[1] / 'compare-reliability-reports.py')
comparison = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(comparison)


class ComparisonTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.base = {'schemaVersion': 2, 'metadata': {'version': '1.0', 'build': '9', 'candidate': 'a' * 40,
                     'configuration': 'release', 'osVersion': '26.0'}, 'game': {'digest': 'b' * 64}, 'records': [
                     {'sequence': 1, 'timestamp': 1000, 'observation': {'game': {'digest': 'b' * 64}, 'revision': 2,
                      'action': 'reopen', 'boundary': 'stateSelection', 'outcome': 'accepted', 'actorMembership': 'joined',
                      'stateDigest': 'c' * 64, 'trigger': 'didSelect', 'sessionPresent': True}}]}
        self.first = self.root / 'first.json'
        self.second = self.root / 'second.json'
        self.first.write_text(json.dumps(self.base))
        self.other = copy.deepcopy(self.base)
        self.other['records'][0]['timestamp'] = 1001
        self.write_other()

    def write_other(self):
        self.second.write_text(json.dumps(self.other))

    def compare(self, **changes):
        args = dict(candidate='a' * 40, version='1.0', build='9', revision=2, since=999,
                    separate_accounts=True, now=1002)
        args.update(changes)
        return comparison.compare([('host', self.first), ('guest', self.second)], **args)

    def test_matched_checkpoint_is_not_claimed_as_delivery_or_account_proof(self):
        result = self.compare()
        self.assertEqual(result['status'], 'matched')
        self.assertEqual(result['separate_accounts'], 'operator-attested')
        self.assertEqual(result['candidate_provenance'], 'reported-metadata')
        self.assertIn('not all-message delivery', result['scope'])

    def test_different_state_and_revision_do_not_pass(self):
        for field, value in [('stateDigest', 'd' * 64), ('revision', 3)]:
            self.other = copy.deepcopy(self.base)
            self.other['records'][0]['timestamp'] = 1001
            self.other['records'][0]['observation'][field] = value
            self.write_other()
            self.assertEqual(self.compare()['status'], 'divergent-or-unexpected-revision')
        self.assertNotEqual(self.compare(revision=4)['status'], 'matched')

    def test_sender_only_absent_stale_unjoined_and_unbound_evidence_is_unverified(self):
        for change in [{'boundary': 'localHandoff'}, {'outcome': 'observed'}, {'actorMembership': 'notInRoster'},
                       {'sessionPresent': False}, {'stateDigest': None}, {'trigger': 'fabricated'}]:
            self.other = copy.deepcopy(self.base)
            self.other['records'][0]['timestamp'] = 1001
            self.other['records'][0]['observation'].update(change)
            self.write_other()
            with self.assertRaises(ValueError):
                self.compare()
        self.other = copy.deepcopy(self.base)
        self.other['records'] = []
        self.write_other()
        with self.assertRaises(ValueError):
            self.compare()

    def test_missing_provenance_other_game_and_debug_are_rejected(self):
        for key, value in [('candidate', 'unfrozen'), ('build', '8'), ('configuration', 'debug')]:
            self.other = copy.deepcopy(self.base)
            self.other['metadata'][key] = value
            self.write_other()
            with self.assertRaises(ValueError):
                self.compare()
        self.other = copy.deepcopy(self.base)
        self.other['game'] = {'digest': 'd' * 64}
        self.other['records'][0]['observation']['game'] = self.other['game']
        self.write_other()
        with self.assertRaises(ValueError):
            self.compare()

    def test_duplicate_reformatted_report_and_missing_attestation_rejected(self):
        self.second.write_text(json.dumps(self.base, indent=4))
        with self.assertRaises(ValueError):
            self.compare()
        self.write_other()
        with self.assertRaises(ValueError):
            self.compare(separate_accounts=False)

    def test_private_unknown_fields_duplicate_keys_oversize_and_numbers_rejected(self):
        for text in [json.dumps({**self.base, 'hand': [1, 2]}),
                     json.dumps(self.base).replace('"sequence": 1', '"sequence": true'),
                     json.dumps(self.base).replace('"timestamp": 1000', '"timestamp": NaN'),
                     json.dumps(self.base).replace('"schemaVersion": 2', '"schemaVersion": 2, "schemaVersion": 2'),
                     ' ' * (comparison.MAX_BYTES + 1)]:
            self.second.write_text(text)
            with self.assertRaises(ValueError):
                comparison.load_report(self.second)

    def test_latest_unaccepted_observation_cannot_reuse_older_success(self):
        newer = copy.deepcopy(self.other['records'][0])
        newer['sequence'] = 2
        newer['timestamp'] = 1002
        newer['observation']['outcome'] = 'observed'
        self.other['records'].append(newer)
        self.write_other()
        with self.assertRaises(ValueError):
            self.compare()

    def test_checkpoint_time_is_required_and_fresh(self):
        for since in [1002, 1003, float('nan'), -90000]:
            with self.assertRaises(ValueError):
                self.compare(since=since)
        self.other['records'][0]['timestamp'] = 2000
        self.write_other()
        with self.assertRaises(ValueError):
            self.compare()
