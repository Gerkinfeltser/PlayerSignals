"""Execute the shipped raw validator on LuaJIT; no Skyrim/native-container emulation."""
import json
from pathlib import Path
import unittest

from lupa.luajit21 import LuaRuntime, LuaError

MODULE = Path(__file__).resolve().parents[1] / 'PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua'


def minimal():
    return {'schemaVersion': 1, 'root': 'main', 'input': {'openKeyCode': 184},
            'wheels': {'main': [{'label': 'Yes', 'intent': 'confirm'}]}}


class ConfigValidation(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.module = self.lua.execute(MODULE.read_text(encoding='utf-8'))

    def parse(self, value):
        return self.module.validateText(json.dumps(value))

    def rejects(self, value):
        with self.assertRaises(LuaError):
            self.parse(value)

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
        self.assertEqual(self.module.validateText(json.dumps(config, ensure_ascii=False)).wheels.data['__metaInfo'].data[1].data.label, 'Héllo 😀')
        for invalid in (b'\xc0\xaf', b'\xed\xa0\x80', b'\xf4\x90\x80\x80', b'\xe2\x82'):
            text = json.dumps(minimal()).encode().replace(b'Yes', invalid)
            with self.subTest(invalid_utf8=invalid), self.assertRaises(LuaError):
                self.module.validateText(text)
        for text in ('{', '{"a":1,"a":2}', json.dumps(minimal()).replace('184', '184e0'),
                     json.dumps(minimal()).replace('184', '0184'), json.dumps(minimal()) + 'x',
                     json.dumps(minimal()).replace('Yes', r'\uD800'),
                     json.dumps(minimal()).replace('Yes', r'\u0000')):
            with self.subTest(text=text), self.assertRaises(LuaError):
                self.module.validateText(text)


if __name__ == '__main__':
    unittest.main()
