"""Reject raster artwork before generating or compiling the mod payload."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class BuildArtwork(unittest.TestCase):
    @unittest.skipUnless(shutil.which('powershell') or shutil.which('pwsh'), 'PowerShell required')
    def test_raster_source_fails_before_generating_art(self):
        shell = shutil.which('powershell') or shutil.which('pwsh')
        script = Path(__file__).resolve().parents[1] / 'build/build.ps1'
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'build').mkdir()
            (root / 'media/src').mkdir(parents=True)
            shutil.copyfile(script, root / 'build/build.ps1')
            for image in ('<image/>', '<defs><image/></defs>'):
                with self.subTest(image=image):
                    (root / 'media/src/RadialUI.svg').write_text(
                        '<svg xmlns="http://www.w3.org/2000/svg">' + image + '</svg>', encoding='utf-8')
                    result = subprocess.run(
                        [shell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(root / 'build/build.ps1')],
                        capture_output=True, text=True, timeout=30)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('Source SVG contains <image>', result.stdout + result.stderr)
                    self.assertFalse((root / 'PlayerSignals').exists(), 'Invalid source produced output')
