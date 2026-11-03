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
JSON_FENCE = re.compile(r'```json\s*\n(.*?)\n\s*```', re.DOTALL)


class AIHelperExamples(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.module = self.lua.execute(MODULE.read_text(encoding='utf-8'))
        self.layout = json.loads(LAYOUT.read_text(encoding='utf-8'))
        self.catalog = json.loads(CATALOG.read_text(encoding='utf-8'))

    def instructions(self, path):
        text = path.read_text(encoding='utf-8')
        blocks = JSON_FENCE.findall(text)
        self.assertEqual(len(blocks), 5, f'{path}: expected only the five merge-example JSON blocks')
        return [json.loads(block) for block in blocks]

    def apply(self, instruction):
        layout, catalog = copy.deepcopy(self.layout), copy.deepcopy(self.catalog)
        self.assertEqual(set(instruction) - {'layoutEdits', 'wheelAdds', 'intentAdds'}, set())
        for edit in instruction.get('layoutEdits', []):
            wheel, slot = edit['wheel'], edit['slot']
            layout['wheels'][wheel][slot] = copy.deepcopy(edit['value'])
        for wheel, slots in instruction.get('wheelAdds', {}).items():
            self.assertNotIn(wheel, layout['wheels'])
            layout['wheels'][wheel] = copy.deepcopy(slots)
        for intent, record in instruction.get('intentAdds', {}).items():
            self.assertNotIn(intent, catalog['intents'])
            catalog['intents'][intent] = copy.deepcopy(record)
        return layout, catalog

    def validate(self, layout, catalog):
        return self.module.validateText(json.dumps(layout), json.dumps(catalog))

    def test_all_documented_merge_examples(self):
        for helper in HELPERS:
            with self.subTest(helper=helper.name):
                examples = self.instructions(helper)
                for index, instruction in enumerate(examples):
                    with self.subTest(example=index + 1):
                        layout, catalog = self.apply(instruction)
                        result = self.validate(layout, catalog)
                        # Check observable slot values, including the prescribed zero-based indices.
                        if index == 0:
                            slot = layout['wheels']['extras'][2]
                            self.assertEqual(slot, {'label': 'Middle mouse', 'hotkey': 258,
                                                    'delayMs': 100, 'holdMs': 50})
                            self.assertEqual(result.wheels.data.extras.data[3].data.hotkey, 258)
                        elif index == 1:
                            slot = layout['wheels']['extras'][4]
                            self.assertEqual(slot, {'label': 'Wait here (blue)', 'intent': 'wait_here',
                                                    'action': {'name': 'WaitHere', 'args': {}},
                                                    'color': '#465f78'})
                            self.assertIsNotNone(catalog['intents']['wait_here'].get('complianceNarration'))
                            self.assertEqual(result.wheels.data.extras.data[5].data.intent, 'wait_here')
                        elif index == 2:
                            slot = layout['wheels']['extras'][5]
                            self.assertEqual(slot, {'label': 'Quick signals', 'submenu': 'quick'})
                            self.assertEqual(layout['wheels']['quick'], [
                                {'label': 'Greet', 'intent': 'greet'},
                                {'label': 'Thanks', 'intent': 'thanks'},
                                {'label': 'Farewell', 'intent': 'farewell'},
                                None, None, None, None, None, None, None,
                                {'label': 'Back', 'control': 'back'}, None,
                            ])
                            self.assertEqual(result.wheels.data.extras.data[6].data.submenu, 'quick')
                        elif index == 3:
                            slot = layout['wheels']['extras'][6]
                            self.assertEqual(slot, {'label': 'Salute', 'intent': 'salute'})
                            self.assertEqual(catalog['intents']['salute'], {
                                'narration': 'raises a hand in salute',
                                'notification': 'salutes',
                                'targetedNotification': 'salutes {target}',
                            })
                            self.assertEqual(result.wheels.data.extras.data[7].data.intent, 'salute')
                        else:
                            slot = layout['wheels']['main'][9]
                            self.assertEqual(slot, {'label': 'Yes please', 'intent': 'confirm',
                                                    'color': '#465f78'})
                            self.assertEqual(result.wheels.data.main.data[10].data.intent, 'confirm')

    def test_invalid_example_edits_report_validator_diagnostics(self):
        examples = self.instructions(HELPERS[0])

        layout, catalog = self.apply(examples[4])
        layout['wheels']['main'][9]['color'] = 'blue'
        with self.assertRaisesRegex(LuaError, r'wheels\.main\[10\]\.color: expected #rrggbb'):
            self.validate(layout, catalog)

        layout, catalog = self.apply(examples[0])
        layout['wheels']['extras'][2] = {'label': 'Salute', 'intent': 'greet', 'raw': True}
        with self.assertRaisesRegex(LuaError, r'wheels\.extras\[3\]\.raw: only valid for hotkey entries'):
            self.validate(layout, catalog)

        layout, catalog = self.apply(examples[1])
        del catalog['intents']['wait_here']['complianceNarration']
        with self.assertRaisesRegex(LuaError, 'complianceNarration is required for hybrid actions'):
            self.validate(layout, catalog)

        layout, catalog = self.apply(examples[2])
        layout['wheels']['extras'][5]['submenu'] = 'missing_wheel'
        with self.assertRaisesRegex(LuaError, r'wheels\.extras\[6\]\.submenu: unknown wheel'):
            self.validate(layout, catalog)

        layout, catalog = self.apply(examples[3])
        catalog['intents']['salute']['notification'] += '.'
        with self.assertRaisesRegex(LuaError, r'intents\.salute\.notification: omit the final period'):
            self.validate(layout, catalog)

if __name__ == '__main__':
    unittest.main()
