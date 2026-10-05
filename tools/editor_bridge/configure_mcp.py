"""Register this tested local server in Claude Code, preserving existing settings."""
from datetime import datetime
import json
from pathlib import Path
import uuid
import core


def register(destination, entry, label):
    for _ in range(3):
        original = destination.read_bytes() if destination.exists() else b'{}'
        settings = json.loads(original.decode('utf-8-sig'))
        servers = settings.setdefault('mcpServers', {})
        existing = servers.get('deus-ex-map-bridge')
        if existing and existing != entry:
            raise ValueError('A different server already uses this name; no settings changed')
        if existing == entry:
            return dict(configured=True, changed=False, file=str(destination), server='deus-ex-map-bridge')
        servers['deus-ex-map-bridge'] = entry
        # Claude may update usage metadata while running. Retry rather than overwrite a new version.
        if destination.exists() and destination.read_bytes() != original:
            continue
        backup_folder = core.HERE / 'config-backups'
        backup_folder.mkdir(exist_ok=True)
        backup = backup_folder / (label + '-' + datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:8] + '.json')
        backup.write_bytes(original)
        temporary = destination.with_name(destination.name + '.bridge-' + uuid.uuid4().hex + '.tmp')
        temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        if destination.exists() and destination.read_bytes() != original:
            temporary.unlink()
            continue
        temporary.replace(destination)
        loaded = json.loads(destination.read_text(encoding='utf-8'))
        assert loaded['mcpServers']['deus-ex-map-bridge'] == entry
        return dict(configured=True, changed=True, file=str(destination), server='deus-ex-map-bridge',
                    note='The running Claude session may need MCP reconnect or a new session; CLI is available immediately.')
    raise ValueError('Claude settings kept changing; no registration performed. Use mcp-config.json.')


def configure():
    python = core.HERE / '.venv/Scripts/python.exe'
    if not python.exists():
        raise ValueError('Private Python runtime is missing')
    entry = dict(type='stdio', command=str(python), args=[str(core.HERE / 'server.py')])
    core.save(core.HERE / 'mcp-config.json', {'mcpServers': {'deus-ex-map-bridge': entry}})
    registrations = [register(Path.home() / '.claude.json', entry, 'claude-code')]
    packaged = Path.home() / 'AppData/Local/Packages/Claude_pzs8sxrjxfjjc/LocalCache/Roaming/Claude/claude_desktop_config.json'
    conventional = Path.home() / 'AppData/Roaming/Claude/claude_desktop_config.json'
    desktop = packaged if packaged.exists() else conventional
    if desktop.exists():
        desktop_entry = {k: v for k, v in entry.items() if k != 'type'}
        registrations.append(register(desktop, desktop_entry, 'claude-desktop'))
    return dict(configured=True, server='deus-ex-map-bridge', registrations=registrations,
                connected_in_existing_session='not yet verified; configuration is not a connection check')


if __name__ == '__main__':
    result = configure()
    core.save(core.HERE / 'mcp-registration.json', result)
    print(json.dumps(result, indent=2))
