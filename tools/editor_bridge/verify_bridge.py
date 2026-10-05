"""Integration checks on private real maps, native engine and MCP stdio."""
import asyncio
from datetime import datetime
import json
import sys

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

import archive
import core
import engine


def rejected(action):
    try:
        action()
    except ValueError:
        return True
    raise AssertionError('Unsafe or stale operation was accepted')


async def check():
    start = core.create_workspace('06_HongKong_Helibase')
    identity = start['workspace']
    actor = core.get_object(identity, 'Light16')['actor']
    props = actor['properties']
    position = actor['location'].copy()
    position[0] += 16
    operations = [
        dict(actor='Light16', property='Location', expected=props['Location'], value=position),
        dict(actor='Light16', property='Tag', expected=props['Tag'], value='UCBridgeVerifiedLight'),
        dict(actor='Light16', property='Rotation', expected=archive.UNSET, value=[0, 4096, 0]),
        dict(actor='Light16', property='bHidden', expected=archive.UNSET, value=False),
        dict(actor='Light16', property='DrawScale', expected=archive.UNSET, value=1.125),
        dict(actor='Light16', property='LightBrightness', expected=props['LightBrightness'], value=45),
    ]
    plan = core.plan_patch(identity, start['sha256'], operations)
    rejected(lambda: core.plan_patch(identity, '0' * 64, operations))
    wrong = [dict(operations[0], expected=[0, 0, 0])]
    rejected(lambda: core.plan_patch(identity, start['sha256'], wrong))
    brush = core.list_objects(identity, class_name='Brush', limit=1)['objects'][0]
    rejected(lambda: core.plan_patch(identity, start['sha256'], [
        dict(actor=brush['name'], property='Location', expected=brush['location'], value=[0, 0, 0])]))
    rejected(lambda: core.plan_patch(identity, start['sha256'], [
        dict(actor='Light16', property='Level', expected=props['Level'], value='LevelInfo0')]))
    changed = core.apply_plan(identity, plan['plan'])
    rejected(lambda: core.apply_plan(identity, plan['plan']))
    native = engine.snapshot(identity, 'plain')
    runtime = json.loads(open(native['file'], encoding='utf-8').read())
    light = next(a for a in runtime['actors'] if a['name'] == 'Light16')
    assert archive.equal(light['location'], position), light
    assert light['tag'] == 'UCBridgeVerifiedLight', light
    assert light['rotation'] == [0, 4096, 0], light
    assert light['hidden'] is False, light
    restored = core.undo(identity, changed['sha256'])
    assert restored['sha256'] == start['sha256']
    hk = engine.snapshot(identity, 'hk_setup')
    runtime = json.loads(open(hk['file'], encoding='utf-8').read())
    staff = [a for a in runtime['actors'] if a['origin'] == 'runtime_spawned'
             and a['familiar_name'] and 'Inventory' not in a['class_name']]
    assert {'UCHKOfficer', 'UCHKGuard'} <= {a['tag'] for a in staff}, staff
    preview = core.create_preview(identity, core.workspace(identity)[0] / 'runtime-snapshot.json')

    parameters = StdioServerParameters(command=sys.executable,
                 args=[str(core.HERE / 'server.py')], cwd=str(core.HERE))
    async with stdio_client(parameters) as (read, write):
        async with ClientSession(read, write) as client:
            await client.initialize()
            tools = (await client.list_tools()).tools
            assert len(tools) == 18

            async def call(name, **arguments):
                result = await client.call_tool(name, arguments)
                assert not result.isError, result
                if result.structuredContent is not None:
                    return result.structuredContent
                return json.loads(result.content[0].text)

            maps = await call('maps')
            assert any(m['name'] == '06_HongKong_Helibase' for m in maps['maps'])
            inspected = await call('inspect_object', workspace=identity, actor='Light16')
            assert inspected['actor']['properties']['Tag'] == 'Light'
            await call('search_objects', workspace=identity, query='Light16')
            await call('event_links', workspace=identity, actor='Light16')
            await call('mod_source', query='OpenHelibase')
            mplan = await call('plan_property_changes', workspace=identity,
                              expected_sha256=restored['sha256'], changes=operations[:2])
            applied = await call('apply_property_plan', workspace=identity, plan=mplan['plan'])
            undone = await call('undo_property_changes', workspace=identity,
                                expected_sha256=applied['sha256'])
            assert undone['sha256'] == start['sha256']
            await call('workspace_status', workspace=identity)
            await call('map_preview', workspace=identity, include_runtime=True)
            hotel = await call('checkout', map_name='04_NYC_Hotel')
            hactors = await call('search_objects', workspace=hotel['workspace'], limit=1)
            assert hactors['total'] > 1000
    result = dict(passed=True, time=datetime.now().isoformat(), workspace=identity,
                  property_changes=6, preserved_exports=changed['preserved_exports'],
                  exact_undo=True, rejected_guards=5,
                  native_patch_loaded=True, native_actors=hk['count'],
                  runtime_spawned=hk['spawned'], runtime_staff=staff,
                  mcp_tools=[t.name for t in tools], mcp_roundtrip=True,
                  second_map_actors=hactors['total'], preview=preview['file'])
    core.save(core.HERE / 'verification.json', result)
    print(json.dumps(result, ensure_ascii=True, indent=2))


if __name__ == '__main__':
    asyncio.run(check())
