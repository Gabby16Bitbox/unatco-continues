"""Verify native editor diagnostics and cold snapshot preparation on private copies."""
import asyncio
import json
import sys
import uuid

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import core
import editor
import engine


async def main():
    state = core.create_workspace('04_NYC_Hotel')
    original_lab = engine.LAB
    engine.LAB = editor.LAB / ('cold-snapshot-' + uuid.uuid4().hex)
    try:
        prepared = engine.prepare_lab()
        build = json.loads((engine.LAB / 'build.json').read_text())
        assert build['source_sha256'] == core.sha(core.HERE / 'engine_src/UCMapBridge/Classes/UCBridgeSnapshot.uc')
        assert (engine.LAB / 'UCMapBridge/Classes/UCBridgeSnapshot.uc').exists()
        assert engine.prepare_lab() == prepared
    finally:
        engine.LAB = original_lab
    runs_before = set((editor.LAB / 'runs').iterdir())
    try:
        editor.check(state['workspace'], '0' * 64)
        raise AssertionError('Stale SHA accepted')
    except ValueError as error:
        assert 'SHA256 changed' in str(error)
    assert set((editor.LAB / 'runs').iterdir()) == runs_before
    parameters = StdioServerParameters(command=sys.executable, args=[str(core.HERE / 'server.py')])
    async with stdio_client(parameters) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            names = [tool.name for tool in (await session.list_tools()).tools]
            assert len(names) == 18 and 'native_editor_check' in names
            result = await session.call_tool('native_editor_check', dict(
                workspace=state['workspace'], expected_sha256=state['sha256']))
            assert not result.isError, result
            report = result.structuredContent or json.loads(result.content[0].text)
            assert report['passed'] and report['native_text_preserved']
            assert report['game_actor_names_preserved'] and report['lighting_preserved']
            assert not report['changed_models'] and not report['workspace_version_selected']
    after = core.status(state['workspace'])
    assert after['sha256'] == state['sha256'] and after['current_version'] == 0
    assert not after['source_changed']
    result = dict(passed=True, hotel_mcp_report=report['report_file'],
        tools=18, workspace_unchanged=True, source_unchanged=True,
        stale_hash_guard=True, cold_snapshot_compile=True,
        note='Independent SDK client verified; not proof of a live Claude Desktop connection')
    core.save(core.HERE / 'editor-verification.json', result)
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    asyncio.run(main())
