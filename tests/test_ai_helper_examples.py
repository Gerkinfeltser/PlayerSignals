"""Exercise the JSON merge examples against the shipped pair and Lua validator."""
import copy
import json
from pathlib import Path
import re
import unittest

from lupa.luajit21 import LuaError, LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
LAYOUT = ROOT / 'PlayerSignals/SKSE/Plugins/PlayerSignals/layout.json'
CATALOG = ROOT / 'PlayerSignals/SKSE/Plugins/PlayerSignals/intents.json'
MODULE = ROOT / 'PlayerSignals/SKSE/Plugins/JCData/lua/PlayerSignals/config.lua'
HELPERS = (
    ROOT / 'PlayerSignals/PlayerSignals-AI-Helper.md',
    ROOT / 'PlayerSignals/SKSE/Plugins/SkyrimNet/external/phospheneoverdrive.playersignals/prompts/agent_playersignals_intent_helper.prompt',
)
EXAMPLE_MARKER = re.compile(r'<!-- example-json:([\w-]+) -->\s*```json\s*\n(.*?)\n\s*```', re.DOTALL)


class AIHelperExamples(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.module = self.lua.execute(MODULE.read_text(encoding='utf-8'))
        self.layout = json.loads(LAYOUT.read_text(encoding='utf-8'))
        self.catalog = json.loads(CATALOG.read_text(encoding='utf-8'))

    def instructions(self, path):
        text = path.read_text(encoding='utf-8')
        blocks = dict(EXAMPLE_MARKER.findall(text))
        self.assertEqual(set(blocks), {'1', '2', '3', '3-wheel', '4', '4-intent', '5'},
                         f'{path}: expected five marked examples and associated literal members')
        return {key: json.loads('{' + value + '}')['quick'] if key == '3-wheel' else json.loads(value)
                for key, value in blocks.items()}

    def apply(self, examples, index):
        layout, catalog = copy.deepcopy(self.layout), copy.deepcopy(self.catalog)
        locations = {1: ('extras', 2), 2: ('extras', 4), 3: ('main', 6),
                     4: ('extras', 6), 5: ('main', 9)}
        wheel, slot = locations[index]
        layout['wheels'][wheel][slot] = copy.deepcopy(examples[str(index)])
        if index == 3:
            layout['wheels']['quick'] = copy.deepcopy(examples['3-wheel'])
        if index == 4:
            catalog['intents']['salute'] = copy.deepcopy(examples['4-intent'])
        return layout, catalog

    def validate(self, layout, catalog):
        return self.module.validateText(json.dumps(layout), json.dumps(catalog))

    def test_all_documented_merge_examples(self):
        for helper in HELPERS:
            with self.subTest(helper=helper.name):
                examples = self.instructions(helper)
                for index in range(1, 6):
                    with self.subTest(example=index):
                        layout, catalog = self.apply(examples, index)
                        result = self.validate(layout, catalog)
                        wheel, slot = {1: ('extras', 2), 2: ('extras', 4), 3: ('main', 6),
                                       4: ('extras', 6), 5: ('main', 9)}[index]
                        self.assertIsNotNone(result.wheels.data[wheel].data[slot + 1])
                        if index == 3:
                            self.assertEqual(layout['wheels']['quick'][10], {'label': 'Back', 'control': 'back'})
                            self.assertEqual(layout['wheels']['quick'][2]['intent'], 'farewell')
                        elif index == 4:
                            self.assertEqual(catalog['intents']['salute']['notification'], 'salutes')
                        elif index == 5:
                            self.assertEqual(layout['wheels']['main'][9]['label'], 'Yes please')

    def test_invalid_example_edits_report_validator_diagnostics(self):
        examples = self.instructions(HELPERS[0])
        layout, catalog = self.apply(examples, 5)
        layout['wheels']['main'][9]['color'] = 'blue'
        with self.assertRaisesRegex(LuaError, r'wheels\.main\[10\]\.color: expected #rrggbb'):
            self.validate(layout, catalog)
        layout, catalog = self.apply(examples, 1)
        layout['wheels']['extras'][2] = {'label': 'Salute', 'intent': 'greet', 'raw': True}
        with self.assertRaisesRegex(LuaError, r'wheels\.extras\[3\]\.raw: only valid for hotkey entries'):
            self.validate(layout, catalog)
        layout, catalog = self.apply(examples, 2)
        del catalog['intents']['wait_here']['complianceNarration']
        with self.assertRaisesRegex(LuaError, 'complianceNarration is required for hybrid actions'):
            self.validate(layout, catalog)
        layout, catalog = self.apply(examples, 3)
        layout['wheels']['main'][6]['submenu'] = 'missing_wheel'
        with self.assertRaisesRegex(LuaError, r'wheels\.main\[7\]\.submenu: unknown wheel'):
            self.validate(layout, catalog)
        layout, catalog = self.apply(examples, 4)
        catalog['intents']['salute']['notification'] += '.'
        with self.assertRaisesRegex(LuaError, r'intents\.salute\.notification: omit the final period'):
            self.validate(layout, catalog)

if __name__ == '__main__':
    unittest.main()
