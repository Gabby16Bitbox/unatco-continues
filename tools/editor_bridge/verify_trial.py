"""Exercise restoration/error cases in an isolated fake game installation."""
import asyncio
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import core
import trial


class RestorationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.bridge = root / 'bridge'
        self.bridge.mkdir()
        self.game = root / 'Revision'
        for name in ('Maps', 'System', 'Save/Current'):
            (self.game / name).mkdir(parents=True)
        self.project = root / 'project'
        (self.project / 'tools').mkdir(parents=True)
        (self.project / 'tools/shots.ps1').write_text('fixture')
        self.target = self.game / 'Maps/TrialMap.dx'
        self.target.write_bytes(b'original-game-map')
        self.selected = root / 'selected.dx'
        self.selected.write_bytes(b'private-edited-map')
        self.ini = self.game / 'System/RevisionUser.ini'
        (self.game / 'System/Revision.ini').write_text('[Core.System]\nPaths=../Maps/*.dx\n')
        self.ini.write_bytes(b'[User]\r\nOriginal=\xe8\r\n')
        for name in ('UCShots.ini', 'RevisionUCShots.ini'):
            (self.game / 'System' / name).write_bytes(b'old-' + name.encode())
        (self.game / 'Save/Current/preexisting.dxs').write_bytes(b'keep-player-state')
        self.map_hash = core.sha(self.target)
        self.ini_hash = core.sha(self.ini)
        self.save_hashes = trial.directory_hashes(self.game / 'Save/Current')
        self.patches = [patch.object(core, 'HERE', self.bridge), patch.object(core, 'REVISION', self.game),
                        patch.object(core, 'PROJECT', self.project), patch.object(trial, 'TRIALS', self.bridge / 'trials'),
                        patch.object(trial, 'LOCK', self.bridge / 'game-trial.lock'),
                        patch.object(core, 'workspace', return_value=(root, {'map_name': 'TrialMap'}, self.selected)),
                        patch.object(core, 'status', return_value={'source_changed': False}),
                        patch.object(trial, 'game_state', return_value={'games': []})]
        for mocked in self.patches:
            mocked.start()

    def tearDown(self):
        for mocked in reversed(self.patches):
            mocked.stop()
        self.temp.cleanup()

    def photographer(self, folder, request):
        self.assertEqual(core.sha(self.target), core.sha(self.selected))
        self.assertTrue((folder / 'SavedCurrent/preexisting.dxs').exists())
        self.ini.write_bytes(b'game-updated-preferences')
        for name in ('UCShots.ini', 'RevisionUCShots.ini'):
            (self.game / 'System' / name).unlink()
        current = self.game / 'Save/Current'
        current.mkdir()
        (current / 'trial.dxs').write_bytes(b'temporary')
        (self.game / 'System/Revision.log').write_text('Log: LoadMap: TrialMap\nUCShot fine\n')
        image = self.project / 'shots/fixture/photo.png'
        image.parent.mkdir(parents=True)
        image.write_bytes(b'photo-fixture')
        return {'success': True, 'output': [str(image)]}

    def assert_restored(self):
        self.assertEqual(core.sha(self.target), self.map_hash)
        self.assertEqual(core.sha(self.ini), self.ini_hash)
        self.assertEqual(trial.directory_hashes(self.game / 'Save/Current'), self.save_hashes)
        for name in ('UCShots.ini', 'RevisionUCShots.ini'):
            self.assertEqual((self.game / 'System' / name).read_bytes(), b'old-' + name.encode())
        self.assertFalse(trial.LOCK.exists())

    def test_success_restores_map_settings_and_full_temporary_save(self):
        with patch.object(trial, 'run_photographer', side_effect=self.photographer):
            report = trial.try_game('fixture', ['test;view'])
        self.assertEqual(report['status'], 'passed')
        self.assertTrue(report['restored'])
        self.assertEqual(len(report['photos']), 1)
        self.assert_restored()
        self.assertTrue(list(trial.TRIALS.rglob('generated-Current-*')))

    def test_failure_after_install_still_restores(self):
        def failing(folder, request):
            self.photographer(folder, request)
            raise RuntimeError('photographer failed')
        with patch.object(trial, 'run_photographer', side_effect=failing):
            with self.assertRaisesRegex(ValueError, 'Report:'):
                trial.try_game('fixture', ['test;view'])
        self.assert_restored()

    def test_timeout_still_restores(self):
        with patch.object(trial, 'run_photographer', side_effect=subprocess.TimeoutExpired('fixture', 1)):
            with self.assertRaises(ValueError):
                trial.try_game('fixture', ['test;view'])
        self.assert_restored()

    def test_incomplete_photography_is_failure_and_restores(self):
        def incomplete(folder, request):
            data = self.photographer(folder, request)
            data['output'] = []
            return data
        with patch.object(trial, 'run_photographer', side_effect=incomplete):
            with self.assertRaisesRegex(ValueError, 'Incomplete'):
                trial.try_game('fixture', ['test;view'])
        self.assert_restored()

    def test_concurrent_map_change_is_preserved_and_recovery_is_guarded(self):
        def changed(folder, request):
            data = self.photographer(folder, request)
            self.target.write_bytes(b'other-authors-new-map')
            return data
        with patch.object(trial, 'run_photographer', side_effect=changed):
            with self.assertRaisesRegex(ValueError, 'recovery'):
                trial.try_game('fixture', ['test;view'])
        self.assertEqual(self.target.read_bytes(), b'other-authors-new-map')
        identity = trial.LOCK.read_text()
        with self.assertRaisesRegex(ValueError, 'changed during'):
            trial.recover(identity)
        self.target.write_bytes(self.selected.read_bytes())
        report = trial.recover(identity)
        self.assertEqual(report['status'], 'recovered')
        self.assert_restored()
        trial.recover(identity)  # Idempotent after a completed restore.

    def test_open_game_is_refused_before_file_changes(self):
        with patch.object(trial, 'game_state', return_value={'games': [{'name': 'Revision.exe', 'pid': 123}]}):
            with self.assertRaisesRegex(ValueError, 'Close'):
                trial.try_game('fixture', ['test;view'])
        self.assert_restored()

    def test_override_map_is_used_before_vanilla_copy(self):
        override = self.game / 'UnatcoMaps'
        override.mkdir()
        (override / 'TrialMap.dx').write_bytes(b'mod-override')
        (self.game / 'System/Revision.ini').write_text('[Core.System]\nPaths=../UnatcoMaps/*.dx\nPaths=../Maps/*.dx\n')
        self.assertEqual(trial.resolve_game_map('TrialMap'), override / 'TrialMap.dx')

    def test_missing_requested_actor_is_failure_and_restores(self):
        with patch.object(trial, 'run_photographer', side_effect=self.photographer):
            with self.assertRaisesRegex(ValueError, 'not found'):
                trial.try_game('fixture', ['position;where;Missing', 'test;view'])
        self.assert_restored()

    def test_game_hash_guard_is_refused_before_install(self):
        with self.assertRaisesRegex(ValueError, 'SHA256 changed'):
            trial.try_game('fixture', ['test;view'], expected_game_sha256='0' * 64)
        self.assert_restored()

    def test_no_original_temporary_save_remains_absent(self):
        current = self.game / 'Save/Current'
        (current / 'preexisting.dxs').unlink()
        current.rmdir()
        self.save_hashes = None
        def fresh(folder, request):
            self.ini.write_bytes(b'changed')
            current.mkdir()
            (current / 'fresh.dxs').write_bytes(b'generated')
            (self.game / 'System/Revision.log').write_text('Log: LoadMap: TrialMap\nUCShot segui SomeTag a 1,2,3 stato None\nUCShot fine\n')
            return {'success': True, 'output': []}
        with patch.object(trial, 'run_photographer', side_effect=fresh):
            report = trial.try_game('fixture', ['where;where;SomeTag'])
        self.assertTrue(report['restored'])
        self.assert_restored()


async def check_mcp():
    params = StdioServerParameters(command=sys.executable, args=[str(core.HERE / 'server.py')])
    async with stdio_client(params) as (reader, writer):
        async with ClientSession(reader, writer) as client:
            await client.initialize()
            tools = (await client.list_tools()).tools
            assert {'try_map', 'recover_map_trial'} <= {t.name for t in tools}
            workspace = 'bf57e56c3c5b4b828b8c2c716ae48bf4'
            actor = core.get_object(workspace, 'Light16')['actor']
            center = actor['location']
            result = await client.call_tool('search_objects', {'workspace': workspace, 'near': [*center, 0]})
            assert not result.isError
            data = result.structuredContent or json.loads(result.content[0].text)
            assert any(a['name'] == 'Light16' and a['distance'] == 0 for a in data['objects'])
            for invalid in ([*center, -1], [0, 1], [*center, float('inf')]):
                try:
                    core.list_objects(workspace, near=invalid)
                except ValueError:
                    pass
                else:
                    raise AssertionError('Invalid spatial filter accepted')
            guarded = await client.call_tool('try_map', {'workspace': workspace, 'shots': ['bad\n;view']})
            assert guarded.isError
            result = dict(tools=len(tools), spatial_search_passed=True, invalid_near_rejected=3,
                          try_validation_passed=True, mcp_stdio_handshake_passed=True,
                          note='SDK connection verified; this does not prove an existing app session is connected')
            core.save(core.HERE / 'trial-mcp-verification.json', result)
            print(json.dumps(result))


if __name__ == '__main__':
    result = unittest.TextTestRunner(verbosity=2).run(unittest.defaultTestLoader.loadTestsFromTestCase(RestorationTests))
    if not result.wasSuccessful():
        raise SystemExit(1)
    asyncio.run(check_mcp())
