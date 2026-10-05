"""Native/MCP mover integration, refusal guards, game comparison and exact undo."""
import argparse
import asyncio
import json
from pathlib import Path
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import core
import editor
import engine
import geometry
import trial


def data(result):
    assert not result.isError, result
    return result.structuredContent or json.loads(result.content[0].text)


async def main(in_game):
    state = core.create_workspace('06_HongKong_Helibase')
    identity = state['workspace']
    folder, _, _ = core.workspace(identity)
    if in_game:
        trial.require_closed()
    report = dict(passed=False, workspace=identity, original_sha256=state['sha256'], guards=[])
    core.save(core.HERE / 'geometry-verification.json', report)
    parameters = StdioServerParameters(command=sys.executable, args=[str(core.HERE / 'server.py')])
    try:
        async with stdio_client(parameters) as (read, write):
            async with ClientSession(read, write) as session:
                await session.initialize()
                names = {t.name for t in (await session.list_tools()).tools}
                assert len(names) == 18 and {'inspect_mover', 'plan_mover_changes', 'apply_mover_plan'} <= names
                report['mcp_tools'] = len(names)
                ceiling = data(await session.call_tool('inspect_mover', dict(workspace=identity, actor='UCWallSoffitto0')))
                door = data(await session.call_tool('inspect_mover', dict(workspace=identity, actor='DeusExMover14')))
                assert ceiling['scale_supported'] and not door['scale_supported']
                operations = [dict(actor=door['actor'], operation='translate',
                    expected_location=door['location'], delta=[32, 0, 0]),
                    dict(actor=ceiling['actor'], operation='scale',
                    expected_bounds=ceiling['local_bounds'], factors=[0.75, 1, 1])]
                bad_cases = [
                    ('stale hash', '0' * 64, operations),
                    ('static brush', state['sha256'], [dict(operations[0], actor='Brush0')]),
                    ('stale location', state['sha256'], [dict(operations[0], expected_location=[0, 0, 0])]),
                    ('negative scale', state['sha256'], [dict(operations[1], factors=[-1, 1, 1])]),
                    ('baked mover', state['sha256'], [dict(actor=door['actor'], operation='scale',
                        expected_bounds=door['local_bounds'], factors=[0.5, 1, 1])]),
                    ('concave mover', state['sha256'], [dict(actor='UCVanillaMacerie0', operation='scale',
                        expected_bounds=geometry.inspect(identity, 'UCVanillaMacerie0')['local_bounds'], factors=[0.5, 1, 1])]),
                    ('unknown field', state['sha256'], [dict(operations[0], console='LIGHT APPLY')]),
                ]
                runs = set((editor.LAB / 'runs').iterdir())
                for label, digest, invalid in bad_cases:
                    result = await session.call_tool('plan_mover_changes', dict(workspace=identity,
                        expected_sha256=digest, operations=invalid))
                    assert result.isError, label
                    report['guards'].append(label)
                assert set((editor.LAB / 'runs').iterdir()) == runs
                # UCCam compensates the game's behind-view offset with a 150-unit
                # proxy. Keep that proxy in front of BOTH door positions so the
                # game's camera collision trace cannot push one comparison inside.
                shots = ['soffitto;cam;-1080;-128;590;-1288;-128;642',
                         'porta;cam;-1610;-128;480;-1856;-160;448',
                         'posizione;where;UCWallSoffitto',
                         'ascensore;where;elevator_door',
                         'jc;player;-1120;-128;540;32768;8000',
                         'luce;torch;1',
                         'torcia;cam;-1080;-128;590;-1288;-128;642']
                if in_game:
                    baseline = data(await session.call_tool('try_map', dict(workspace=identity,
                        shots=shots, setup='UCDbgHeliDoor', timeout=120, expected_sha256=state['sha256'])))
                    assert baseline['restored'] and baseline['status'] == 'passed'
                    report['game_before'] = baseline
                plan = data(await session.call_tool('plan_mover_changes', dict(workspace=identity,
                    expected_sha256=state['sha256'], operations=operations)))
                assert plan['validation']['passed'] and plan['validation']['lighting_preserved']
                assert plan['validation']['changed_models'] == [ceiling['model']]
                assert core.status(identity)['sha256'] == state['sha256'], 'Plan selected output'
                report['native_report'] = plan['report_file']
                report['native_diff'] = plan['validation']['native_diff']
                report['models_checked'] = plan['validation']['models_checked']
                # Simulate independently altered plans without changing any shared package.
                saved_plan = folder / 'plans' / (plan['plan'] + '.json')
                for label, modified in (
                    ('altered staged hash', dict(plan, output_sha256='0' * 64)),
                    ('compiled dependency changed', dict(plan, compiled_packages={
                        **plan['compiled_packages'], 'UnatcoContinues.u': '0' * 64})),
                ):
                    core.save(saved_plan, modified)
                    refused = await session.call_tool('apply_mover_plan', dict(workspace=identity, plan=plan['plan']))
                    assert refused.isError, label
                    assert core.status(identity)['sha256'] == state['sha256']
                    report['guards'].append(label)
                core.save(saved_plan, plan)
                applied = data(await session.call_tool('apply_mover_plan', dict(workspace=identity, plan=plan['plan'])))
                assert applied['sha256'] == plan['output_sha256'] and applied['current_version'] == 1
                replay = await session.call_tool('apply_mover_plan', dict(workspace=identity, plan=plan['plan']))
                assert replay.isError
                report['guards'].append('stale plan replay')
                snapshot = data(await session.call_tool('runtime_snapshot', dict(workspace=identity)))
                native = json.loads(Path(snapshot['file']).read_text(encoding='utf-8'))
                native_door = next(a for a in native['actors'] if a['name'] == door['actor'])
                assert geometry.close(native_door['location'], [-1824, -160, 448])
                report['native_runtime_door'] = native_door
                report['snapshot_log'] = snapshot['log']
                if in_game:
                    after = data(await session.call_tool('try_map', dict(workspace=identity,
                        shots=shots, setup='UCDbgHeliDoor', timeout=120, expected_sha256=applied['sha256'])))
                    assert after['restored'] and after['status'] == 'passed'
                    report['game_after'] = after
                    assert any('elevator_door a -1824.' in position for position in after['actor_positions'])
                undone = data(await session.call_tool('undo_property_changes', dict(workspace=identity,
                    expected_sha256=applied['sha256'])))
                assert undone['sha256'] == state['sha256'] and undone['current_version'] == 0
                assert not undone['source_changed']
                report.update(passed=True, exact_undo=True, source_unchanged=True,
                    lighting_preserved=True, keyframes_preserved=True,
                    surface_planes_verified=True, game_tested=in_game)
    except BaseException as error:
        report['error'] = str(error)
        raise
    finally:
        selected = core.status(identity)
        if selected['current_version'] != 0:
            core.undo(identity, selected['sha256'])
        report['final_sha256'] = core.status(identity)['sha256']
        core.save(core.HERE / 'geometry-verification.json', report)
    print(json.dumps({k: v for k, v in report.items() if k not in ('game_before', 'game_after', 'native_runtime_door')}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game', action='store_true', help='Also run the existing photographer before/after; restores the installation')
    args = parser.parse_args()
    asyncio.run(main(args.game))
