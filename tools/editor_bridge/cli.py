"""JSON CLI for the same operations exposed by the MCP server."""
import argparse
import json
import sys
import subprocess
import struct
import core
import engine
import trial
import editor
import geometry


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('maps')
    checkout = commands.add_parser('checkout')
    checkout.add_argument('map_name')
    recovery = commands.add_parser('recover-try')
    recovery.add_argument('trial')
    for name in ('status', 'objects', 'inspect', 'links', 'plan', 'apply', 'undo', 'preview', 'snapshot', 'try', 'editor-check', 'inspect-mover', 'plan-movers', 'apply-movers'):
        child = commands.add_parser(name)
        child.add_argument('workspace')
        if name in ('inspect', 'links', 'inspect-mover'):
            child.add_argument('actor')
        elif name == 'objects':
            child.add_argument('--query', default='')
            child.add_argument('--class-name', default='')
            child.add_argument('--offset', type=int, default=0)
            child.add_argument('--limit', type=int, default=60)
            child.add_argument('--near', nargs=4, type=float, metavar=('X', 'Y', 'Z', 'RADIUS'))
            child.add_argument('--z-min', type=float)
            child.add_argument('--z-max', type=float)
        elif name in ('plan', 'plan-movers'):
            child.add_argument('sha256')
            child.add_argument('changes_file')
        elif name in ('apply', 'apply-movers'):
            child.add_argument('plan')
        elif name in ('undo', 'editor-check'):
            child.add_argument('sha256')
        elif name == 'preview':
            child.add_argument('--runtime', action='store_true')
        elif name == 'snapshot':
            child.add_argument('--mode', choices=('plain', 'hk_setup'), default='plain')
        elif name == 'try':
            actions = child.add_mutually_exclusive_group(required=True)
            actions.add_argument('--shot', action='append')
            actions.add_argument('--shots-file')
            child.add_argument('--setup', default='')
            child.add_argument('--start-map', default='01_NYC_UNATCOIsland')
            child.add_argument('--delay', type=float, default=6)
            child.add_argument('--timeout', type=int, default=300)
            child.add_argument('--width', type=int, default=1600)
            child.add_argument('--expected-sha256')
            child.add_argument('--expected-game-sha256')
    args = parser.parse_args()
    try:
        if args.command == 'maps':
            result = {'maps': core.catalog()}
        elif args.command == 'checkout':
            result = core.create_workspace(args.map_name)
        elif args.command == 'status':
            result = core.status(args.workspace)
        elif args.command == 'objects':
            result = core.list_objects(args.workspace, query=args.query, class_name=args.class_name,
                                       offset=args.offset, limit=args.limit, near=args.near,
                                       z_min=args.z_min, z_max=args.z_max)
        elif args.command == 'inspect':
            result = core.get_object(args.workspace, args.actor)
        elif args.command == 'inspect-mover':
            result = geometry.inspect(args.workspace, args.actor)
        elif args.command == 'links':
            result = core.links(args.workspace, args.actor)
        elif args.command == 'plan':
            with open(args.changes_file, encoding='utf-8') as stream:
                result = core.plan_patch(args.workspace, args.sha256, json.load(stream))
        elif args.command == 'plan-movers':
            with open(args.changes_file, encoding='utf-8-sig') as stream:
                result = geometry.plan(args.workspace, args.sha256, json.load(stream))
        elif args.command == 'apply':
            result = core.apply_plan(args.workspace, args.plan)
        elif args.command == 'apply-movers':
            result = geometry.apply(args.workspace, args.plan)
        elif args.command == 'undo':
            result = core.undo(args.workspace, args.sha256)
        elif args.command == 'editor-check':
            result = editor.check(args.workspace, args.sha256)
        elif args.command == 'preview':
            runtime = core.workspace(args.workspace)[0] / 'runtime-snapshot.json' if args.runtime else None
            if runtime and json.loads(runtime.read_text(encoding='utf-8'))['map_sha256'] != core.status(args.workspace)['sha256']:
                raise ValueError('Runtime snapshot is stale')
            result = core.create_preview(args.workspace, runtime)
        elif args.command == 'try':
            actions = args.shot
            if args.shots_file:
                with open(args.shots_file, encoding='utf-8-sig') as stream:
                    actions = json.load(stream)
            result = trial.try_game(args.workspace, actions, setup=args.setup, start_map=args.start_map,
                                    delay=args.delay, timeout=args.timeout, width=args.width,
                                    expected_sha256=args.expected_sha256,
                                    expected_game_sha256=args.expected_game_sha256)
        elif args.command == 'recover-try':
            result = trial.recover(args.trial)
        else:
            result = engine.snapshot(args.workspace, args.mode)
        print(json.dumps(result, ensure_ascii=True, indent=2))
    except (ValueError, OSError, KeyError, OverflowError, struct.error, subprocess.TimeoutExpired) as exc:
        print(json.dumps({'error': str(exc)}), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
