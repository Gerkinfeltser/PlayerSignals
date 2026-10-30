"""Execute the shipped raw validator on LuaJIT; no Skyrim/native-container emulation."""
import copy
import json
from pathlib import Path
import unittest

from lupa.luajit21 import LuaRuntime, LuaError

MODULE = Path(__file__).resolve().parents[1] / 'PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua'
CATALOG = Path(__file__).resolve().parents[1] / 'PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json'


def minimal():
    return {'schemaVersion': 1, 'root': 'main', 'input': {'openKeyCode': 184},
            'wheels': {'main': [{'label': 'Yes', 'intent': 'confirm'}]}}


class ConfigValidation(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.module = self.lua.execute(MODULE.read_text(encoding='utf-8'))
        self.catalog_text = CATALOG.read_text(encoding='utf-8')
        self.catalog = json.loads(self.catalog_text)

    def parse(self, value, catalog_text=None):
        if catalog_text is None:
            catalog_text = self.catalog_text
        return self.module.validateText(json.dumps(value), catalog_text)

    def rejects(self, value, catalog_text=None):
        with self.assertRaises(LuaError):
            self.parse(value, catalog_text)


    def test_wheel_payload_preserves_eight_slots_and_json_strings(self):
        slots = self.lua.table()
        expected = [None] * 8
        values = [
            ('quote " slash \\ pipe | controls \x00\x01\b\f\n\r\t end', 'intent_\\|"', 'intent'),
            ('café 雪 >', '', 'submenu'),
            ('{"intent":"metadata-like"}', 'drink_alcohol', 'action'),
            ('Back <', '', 'navigation'),
            ('Close', '', 'navigation'),
            ('tail', 'last', 'intent'),
        ]
        for index, value in zip((1, 3, 4, 6, 7, 8), values):
            slot = self.lua.table()
            slot['label'] = value[0]
            slot['kind'] = 'control' if value[2] == 'navigation' else value[2]
            if value[2] == 'action':
                slot['actionName'], slot['intent'] = value[1], 'offer_drink'
            else:
                slot['intent'] = value[1]
            slots[index] = slot
            expected[index - 1] = list(value)

        payload = self.module.wheelPayload(slots)
        self.assertEqual(json.loads(payload), expected)

    def test_action_slots_validate_metadata_and_event_pair(self):
        config = minimal()
        config['wheels']['main'] = [
            {'label': 'Drink', 'action': {'name': 'drink_alcohol', 'args': {'drinkName': ''}}}
        ]
        self.parse(config)
        config['wheels']['main'][0].update(event='both', intent='offer_drink')
        catalog = copy.deepcopy(self.catalog)
        catalog['intents']['offer_drink'] = copy.deepcopy(catalog['intents']['offer'])
        self.parse(config, json.dumps(catalog))

        for invalid in (
            {'label': 'Drink', 'action': {'args': {}}},
            {'label': 'Drink', 'action': {'name': 'x'}},
            {'label': 'Drink', 'action': {'name': '', 'args': {}}},
            {'label': 'Drink', 'action': {'name': 3, 'args': {}}},
            {'label': 'Drink', 'action': 'x'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': []}},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}, 'extra': True}},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'intent': 'confirm'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'control': 'close'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'submenu': 'main'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'event': 'both', 'intent': 'confirm', 'control': 'close'},
            {'label': 'Gesture', 'intent': 'confirm', 'event': 'both'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'event': 'both'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'event': 'bad', 'intent': 'confirm'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'event': 'both', 'intent': 'missing'},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'args': {}},
            {'label': 'Drink', 'action': {'name': 'x', 'args': {}}, 'unknown': True},
        ):
            with self.subTest(slot=invalid):
                config = minimal()
                config['wheels']['main'] = [invalid]
                self.rejects(config)

    def test_action_name_may_match_catalog_id_without_intent_resolution(self):
        config = minimal()
        config['wheels']['main'] = [
            {'label': 'Confirm action', 'action': {'name': 'confirm', 'args': {}}}
        ]
        self.parse(config)

    def test_action_argument_json_keeps_nested_values_and_number_tokens(self):
        layout = ('{"schemaVersion":1,"root":"main","input":{"openKeyCode":184},'
                  '"wheels":{"main":[{"label":"Action","action":{"name":"x","args":'
                  '{"big":900719925474099312345,"decimal":1.2300,"exponent":2E+10,'
                  '"unicode":"雪","truth":true,"nothing":null,"nested":[{"n":-0.25e-2}]}}}]}}')
        parsed = self.module.validateText(layout, self.catalog_text)
        args = '{"big":900719925474099312345,"decimal":1.2300,"exponent":2E+10,' \
               '"unicode":"雪","truth":true,"nothing":null,"nested":[{"n":-0.25e-2}]}'
        self.assertEqual(parsed.wheels.data.main.data[1].data.action.data.args.raw, args)

    def test_action_args_reject_wrong_containers_and_malformed_numbers(self):
        for args in (None, False, 0, 'object', []):
            config = minimal()
            config['wheels']['main'] = [{'label': 'Action', 'action': {'name': 'x', 'args': args}}]
            with self.subTest(args=args):
                self.rejects(config)
        for token in ('01', '1.', '1e', '1e+', '+1', '.5'):
            text = ('{"schemaVersion":1,"root":"main","input":{"openKeyCode":184},'
                    '"wheels":{"main":[{"label":"Action","action":{"name":"x","args":{"n":'
                    + token + '}}}]}}')
            with self.subTest(token=token), self.assertRaises(LuaError):
                self.module.validateText(text, self.catalog_text)

    def test_present_false_slot_kinds_are_rejected_with_slot_diagnostic(self):
        for kind in ('action', 'intent', 'submenu', 'control'):
            config = minimal()
            config['wheels']['main'] = [{'label': 'Invalid', kind: False}]
            with self.subTest(kind=kind), self.assertRaisesRegex(LuaError, r'wheels\.main\[1\]'):
                self.parse(config)

    def test_numeric_types_and_boundaries(self):
        for field in ('schemaVersion', 'openKeyCode'):
            for invalid in (True, False, 1.0, '1', None, 0, 256, -1):
                with self.subTest(field=field, invalid=invalid):
                    config = minimal()
                    if field == 'schemaVersion':
                        config[field] = invalid
                    else:
                        config['input'][field] = invalid
                    self.rejects(config)
        for key in (1, 255):
            config = minimal()
            config['input']['openKeyCode'] = key
            self.assertEqual(self.parse(config).input.data.openKeyCode, key)

    def test_disabled_slots_preserve_positions_and_labels_do_not_change_intent(self):
        config = minimal()
        config['wheels']['main'] = [None, {'label': '__reference|.root', 'intent': 'deny'}, None]
        slots = self.parse(config).wheels.data.main.data
        self.assertEqual(slots[2].data.intent, 'deny')
        self.assertEqual(slots[2].data.label, '__reference|.root')
        self.assertIsNone(slots[1].data)
        self.assertIsNone(slots[3].data)

    def test_all_wheels_are_validated_including_unreachable_cycles(self):
        config = minimal()
        config['wheels']['hidden'] = [{'label': 'Loop', 'submenu': 'hidden'}]
        self.rejects(config)
        config['wheels']['hidden'] = [{'label': 'Missing', 'submenu': 'absent'}]
        self.rejects(config)
        config['wheels']['hidden'] = [{'label': 'Unknown', 'intent': 'CONFIRM'}]
        self.rejects(config)

    def test_deep_acyclic_navigation_and_duplicate_intents_are_valid(self):
        config = minimal()
        for i in range(200):
            name = 'main' if i == 0 else str(i)
            config['wheels'][name] = [{'label': 'Next', 'submenu': str(i + 1)}]
        config['wheels']['200'] = [{'label': 'Yes', 'intent': 'confirm'},
                                   {'label': 'Also yes', 'intent': 'confirm'},
                                   {'label': 'Back', 'control': 'back'}]
        self.assertEqual(self.parse(config).wheels.data['200'].data[2].data.intent, 'confirm')
        config['wheels']['200'][2] = {'label': 'Cycle', 'submenu': 'main'}
        self.rejects(config)

    def test_slot_and_action_boundaries(self):
        for slots in ([], [None] * 9, [False], [{'label': '', 'intent': 'confirm'}],
                      [{'label': 'Yes'}], [{'label': 'Yes', 'intent': 'confirm', 'control': 'close'}],
                      [{'label': 'Yes', 'intent': None}], [{'label': 'No', 'control': 'exit'}],
                      [{'label': 'Yes', 'intent': 'confirm', 'text': 'extra'}]):
            with self.subTest(slots=slots):
                config = minimal()
                config['wheels']['main'] = slots
                self.rejects(config)
        config = minimal()
        config['wheels']['main'] = [None] * 8
        self.parse(config)

    def test_unknown_fields_and_wrong_containers(self):
        for config in ({}, [], {'schemaVersion': 1, 'root': 'main', 'input': [], 'wheels': {}},
                       dict(minimal(), extra=1), dict(minimal(), root='missing')):
            self.rejects(config)

    def test_exact_names_unicode_and_json_syntax(self):
        config = minimal()
        config['root'] = '__metaInfo'
        config['wheels'] = {'__metaInfo': [{'label': 'Héllo 😀', 'submenu': 'Main'}],
                            'Main': [{'label': 'Upper', 'intent': 'confirm'}],
                            'main': [{'label': 'Lower', 'intent': 'deny'}]}
        parsed = self.parse(config)
        self.assertEqual(parsed.wheels.data['__metaInfo'].data[1].data.label, 'Héllo 😀')
        self.assertEqual(parsed.wheels.data.Main.data[1].data.intent, 'confirm')
        self.assertEqual(parsed.wheels.data.main.data[1].data.intent, 'deny')
        self.assertEqual(self.module.validateText(json.dumps(config, ensure_ascii=False), self.catalog_text).wheels.data['__metaInfo'].data[1].data.label, 'Héllo 😀')
        for invalid in (b'\xc0\xaf', b'\xed\xa0\x80', b'\xf4\x90\x80\x80', b'\xe2\x82'):
            text = json.dumps(minimal()).encode().replace(b'Yes', invalid)
            with self.subTest(invalid_utf8=invalid), self.assertRaises(LuaError):
                self.module.validateText(text, self.catalog_text)
        for text in ('{', '{"a":1,"a":2}', json.dumps(minimal()).replace('184', '184e0'),
                     json.dumps(minimal()).replace('184', '0184'), json.dumps(minimal()) + 'x',
                     json.dumps(minimal()).replace('Yes', r'\uD800'),
                     json.dumps(minimal()).replace('Yes', r'\u0000')):
            with self.subTest(text=text), self.assertRaises(LuaError):
                self.module.validateText(text, self.catalog_text)

    def test_catalog_rejects_malformed_json_and_invalid_utf8(self):
        for text in ('{', '{"schemaVersion":1,"schemaVersion":1,"intents":{}}'):
            with self.subTest(text=text), self.assertRaises(LuaError):
                self.module.validateCatalogText(text)
        invalid_utf8 = self.catalog_text.encode('utf-8').replace(b'nods in agreement', b'\xc0\xaf', 1)
        with self.assertRaises(LuaError):
            self.module.validateCatalogText(invalid_utf8)

    def test_catalog_requires_schema_and_three_nonempty_string_fields(self):
        for field in ('schemaVersion', 'intents'):
            catalog = copy.deepcopy(self.catalog)
            del catalog[field]
            with self.subTest(missing=field), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))
        for field, invalid in (('schemaVersion', '1'), ('schemaVersion', False),
                               ('intents', []), ('intents', {}), ('intents', None)):
            catalog = copy.deepcopy(self.catalog)
            catalog[field] = invalid
            with self.subTest(field=field, invalid=invalid), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))

        for invalid in (None, False, [], 'record'):
            catalog = copy.deepcopy(self.catalog)
            catalog['intents']['confirm'] = invalid
            with self.subTest(record=invalid), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))
        for field in ('narration', 'notification', 'targetedNotification'):
            catalog = copy.deepcopy(self.catalog)
            del catalog['intents']['confirm'][field]
            with self.subTest(missing=field), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))
            for invalid in ('', None, False, 1, [], {}):
                catalog = copy.deepcopy(self.catalog)
                catalog['intents']['confirm'][field] = invalid
                with self.subTest(field=field, invalid=invalid), self.assertRaises(LuaError):
                    self.module.validateCatalogText(json.dumps(catalog))

    def test_catalog_requires_exactly_one_target_marker(self):
        for template in ('greets politely', 'greets {target} and {target}'):
            catalog = copy.deepcopy(self.catalog)
            catalog['intents']['confirm']['targetedNotification'] = template
            with self.subTest(template=template), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))

    def test_catalog_rejects_unsubstituted_target_markers(self):
        for field in ('narration', 'notification'):
            catalog = copy.deepcopy(self.catalog)
            catalog['intents']['greet'][field] += ' {target}'
            with self.subTest(field=field), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))

    def test_catalog_rejects_authored_terminal_periods(self):
        for field in ('narration', 'notification', 'targetedNotification'):
            for ending in ('.', '. \t'):
                catalog = copy.deepcopy(self.catalog)
                catalog['intents']['greet'][field] += ending
                with self.subTest(field=field, ending=ending), self.assertRaises(LuaError):
                    self.module.validateCatalogText(json.dumps(catalog))

    def test_catalog_rejects_invalid_ids_and_unknown_fields(self):
        for intent_id in ('Confirm', '_confirm', '1confirm', 'bad-id', 'café'):
            catalog = copy.deepcopy(self.catalog)
            catalog['intents'][intent_id] = copy.deepcopy(catalog['intents']['confirm'])
            with self.subTest(intent_id=intent_id), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog, ensure_ascii=False))
        for where in ('root', 'record'):
            catalog = copy.deepcopy(self.catalog)
            if where == 'root':
                catalog['extra'] = 1
            else:
                catalog['intents']['confirm']['extra'] = 1
            with self.subTest(where=where), self.assertRaises(LuaError):
                self.module.validateCatalogText(json.dumps(catalog))

    def test_unused_catalog_records_are_still_validated(self):
        catalog = copy.deepcopy(self.catalog)
        catalog['intents']['farewell']['targetedNotification'] = 'waves goodbye'
        self.rejects(minimal(), json.dumps(catalog))

    def test_custom_catalog_ids_work_and_missing_references_fail(self):
        catalog = copy.deepcopy(self.catalog)
        catalog['intents']['custom_signal2'] = {
            'narration': 'makes a custom signal',
            'notification': 'signals custom intent',
            'targetedNotification': 'signals to {target} in a custom way',
        }
        config = minimal()
        config['wheels']['main'][0]['intent'] = 'custom_signal2'
        self.rejects(config)
        self.assertEqual(
            self.parse(config, json.dumps(catalog)).wheels.data.main.data[1].data.intent,
            'custom_signal2',
        )
        reduced_catalog = {
            'schemaVersion': 1,
            'intents': {'custom_signal2': catalog['intents']['custom_signal2']},
        }
        self.rejects(minimal(), json.dumps(reduced_catalog))


if __name__ == '__main__':
    unittest.main()
