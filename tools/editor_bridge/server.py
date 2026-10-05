"""Deus Ex UE1 bridge, using the official MCP Python SDK over stdio."""
from typing import Any, Literal
from mcp.server.fastmcp import FastMCP
from mcp.types import ToolAnnotations

import core
import engine
import trial
import editor
import geometry

mcp = FastMCP('Deus Ex UE1 Map Bridge', instructions=(
    'Work on private map copies. Start with maps, checkout and search_objects. '
    'Property changes need the current SHA256 and previous serialized value. '
    'Use {"unset":true} only for an absent override. Plan, review the diff, then apply. '
    'Property tools only write private copies. try_map temporarily installs a private map, '
    'calls the existing photographer and restores the original map/settings/save state. '
    'It refuses an open game. No tool operates the active editor. '
    'native_editor_check audits an isolated SDK load-save-reload without selecting a version. '
    'inspect_mover, plan_mover_changes and apply_mover_plan support native translations '
    'and convex dynamic mover scaling. No static world BSP or global lighting rebuild. '
    'undo_property_changes restores the previous version for either type of plan. '
    'runtime_snapshot loads a fresh private map in the native engine, not the active player session.'))
READ = ToolAnnotations(readOnlyHint=True, destructiveHint=False, openWorldHint=False)
WRITE = ToolAnnotations(readOnlyHint=False, destructiveHint=False, openWorldHint=False)


@mcp.tool(annotations=READ)
def maps() -> dict:
    """List maps available in the project and Revision; project versions take precedence."""
    return {'maps': core.catalog()}


@mcp.tool(annotations=WRITE)
def checkout(map_name: str) -> dict:
    """Create an immutable original and private editable workspace for a map."""
    return core.create_workspace(map_name)


@mcp.tool(annotations=READ)
def workspace_status(workspace: str) -> dict:
    """Get current map SHA256, version and concurrent changes to its source."""
    return core.status(workspace)


@mcp.tool(annotations=READ)
def search_objects(workspace: str, query: str = '', class_name: str = '',
                   z_min: float | None = None, z_max: float | None = None,
                   offset: int = 0, limit: int = 60, near: list[float] | None = None) -> dict:
    """Search saved actors; near=[X,Y,Z,RADIUS] filters a 3D sphere and sorts by distance."""
    return core.list_objects(workspace, query, class_name, z_min, z_max, offset, limit, near)


@mcp.tool(annotations=READ)
def inspect_object(workspace: str, actor: str) -> dict:
    """Read exact saved actor properties, types and relevant mod source locations."""
    return core.get_object(workspace, actor)


@mcp.tool(annotations=READ)
def event_links(workspace: str, actor: str) -> dict:
    """Find saved Tag/Event targets and triggers for an actor."""
    return core.links(workspace, actor)


@mcp.tool(annotations=READ)
def mod_source(query: str) -> dict:
    """Locate matching mod definitions, including actors created only at runtime."""
    return {'hits': core.source_hits(query)}


@mcp.tool(annotations=WRITE)
def plan_property_changes(workspace: str, expected_sha256: str, changes: list[dict[str, Any]]) -> dict:
    """Plan actor changes: each needs actor, property, expected and value. Returns a diff."""
    return core.plan_patch(workspace, expected_sha256, changes)


@mcp.tool(annotations=WRITE)
def apply_property_plan(workspace: str, plan: str) -> dict:
    """Apply a reviewed plan to a new private version, verifying unrelated exports."""
    return core.apply_plan(workspace, plan)


@mcp.tool(annotations=WRITE)
def undo_property_changes(workspace: str, expected_sha256: str) -> dict:
    """Undo either a property or native mover plan to the exact previous private bytes."""
    return core.undo(workspace, expected_sha256)


@mcp.tool(annotations=WRITE)
def map_preview(workspace: str, include_runtime: bool = False) -> dict:
    """Create a local interactive HTML plan with geometry and selectable actors."""
    folder, _, current = core.workspace(workspace)
    runtime = folder / 'runtime-snapshot.json' if include_runtime else None
    if runtime:
        import json
        data = json.loads(runtime.read_text(encoding='utf-8'))
        if data['map_sha256'] != core.sha(current):
            raise ValueError('Runtime snapshot is stale; regenerate it')
    return core.create_preview(workspace, runtime)


@mcp.tool(annotations=WRITE)
def runtime_snapshot(workspace: str, mode: Literal['plain', 'hk_setup'] = 'plain') -> dict:
    """Load a private fresh map in Deus Ex. hk_setup previews explicit HK mod setup."""
    return engine.snapshot(workspace, mode)


@mcp.tool(annotations=WRITE)
def try_map(workspace: str, shots: list[str], setup: str = '',
            start_map: str = '01_NYC_UNATCOIsland', delay: float = 6,
            timeout: int = 300, width: int = 1600,
            expected_sha256: str | None = None,
            expected_game_sha256: str | None = None) -> dict:
    """Temporarily try a private map in-game via shots.ps1, restoring original files afterward.

    shots uses existing actions: label;cam;x;y;z;lookX;lookY;lookZ, label;view,
    label;player;x;y;z;yaw;pitch, label;torch;1, label;follow;Tag,
    label;where;Tag, label;wait;seconds, label;console;command.
    Returns photo paths, actor position log and a backup/restoration report.
    """
    return trial.try_game(workspace, shots, setup, start_map, delay, timeout, width,
                          expected_sha256, expected_game_sha256)


@mcp.tool(annotations=WRITE)
def native_editor_check(workspace: str, expected_sha256: str) -> dict:
    """Check a private SDK load-save-reload cycle, geometry, lighting and native T3D.

    Diagnostic output only: never selects a new version or touches the active UnrealEd.
    """
    return editor.check(workspace, expected_sha256)


@mcp.tool(annotations=READ)
def inspect_mover(workspace: str, actor: str) -> dict:
    """Inspect mover local bounds, pivot, convexity, lighting and supported operations."""
    return geometry.inspect(workspace, actor)


@mcp.tool(annotations=WRITE)
def plan_mover_changes(workspace: str, expected_sha256: str, operations: list[dict[str, Any]]) -> dict:
    """Stage a verified native mover recipe without selecting its output.

    translate: actor, operation, expected_location=[X,Y,Z], delta=[X,Y,Z].
    scale: actor, operation, expected_bounds=[minXYZ,maxXYZ], factors=[X,Y,Z].
    Scaling requires a closed convex, unshared dynamic mover without baked lighting.
    Returns the concrete diff and checks for geometry, keyframes and preserved lights.
    """
    return geometry.plan(workspace, expected_sha256, operations)


@mcp.tool(annotations=WRITE)
def apply_mover_plan(workspace: str, plan: str) -> dict:
    """Select the validated native output as a new private version; refuses stale plans."""
    return geometry.apply(workspace, plan)


@mcp.tool(annotations=WRITE)
def recover_map_trial(trial_id: str) -> dict:
    """Recover an interrupted trial after the game is closed. Refuses concurrent map changes."""
    return trial.recover(trial_id)


if __name__ == '__main__':
    mcp.run(transport='stdio')
