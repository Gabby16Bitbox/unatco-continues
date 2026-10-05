"""Prepare private SDK headers and import libraries from installed DLL exports."""
from pathlib import Path
import struct
import subprocess
import zipfile
import re
import core


def main():
    lab = core.HERE / 'editor_lab'
    header_root = lab / 'headers'
    header_root.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(core.PROJECT / 'tools/sdk_extract/ReleaseSDK1112f/Headers/DxHeaders.zip') as archive:
        for entry in archive.infolist():
            target = (header_root / entry.filename).resolve()
            if not target.is_relative_to(header_root.resolve()):
                raise ValueError('Invalid SDK archive path')
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(archive.read(entry))
    # Syntax-only adaptations in the private copy, for a modern MSVC parser.
    template = header_root / 'Core/Inc/UnTemplate.h'
    text = template.read_text(encoding='latin1')
    text = re.sub(r'(?<!typename )TTypeInfo<([^>]+)>::ConstInitType', r'typename TTypeInfo<\1>::ConstInitType', text)
    template.write_text(text, encoding='latin1')
    vswhere = Path('C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe')
    root = Path(subprocess.check_output([str(vswhere), '-latest', '-products', '*', '-property', 'installationPath']).decode().strip())
    version = sorted((root / 'VC/Tools/MSVC').iterdir())[-1]
    lib = version / 'bin/Hostx64/x86/lib.exe'
    for package in ('Core', 'Engine', 'Editor', 'Window'):
        raw = (core.PROJECT / 'DevInstall/System' / (package + '.dll')).read_bytes()
        pe = struct.unpack_from('<I', raw, 60)[0]
        count = struct.unpack_from('<H', raw, pe + 6)[0]
        optional = struct.unpack_from('<H', raw, pe + 20)[0]
        sections = [struct.unpack_from('<8s8I', raw, pe + 24 + optional + 40 * i) for i in range(count)]
        def section(rva):
            return next(s for s in sections if s[2] <= rva < s[2] + max(s[1], s[3]))
        def offset(rva):
            s = section(rva)
            return s[4] + rva - s[2]
        directory = offset(struct.unpack_from('<I', raw, pe + 24 + 96)[0])
        _, _, _, _, _, _, _, names, functions_rva, names_rva, ordinals_rva = struct.unpack_from('<IIHH7I', raw, directory)
        exports = []
        for i in range(names):
            name_at = offset(struct.unpack_from('<I', raw, offset(names_rva) + i * 4)[0])
            name = raw[name_at:raw.index(b'\0', name_at)].decode('ascii')
            ordinal = struct.unpack_from('<H', raw, offset(ordinals_rva) + i * 2)[0]
            address = struct.unpack_from('<I', raw, offset(functions_rva) + ordinal * 4)[0]
            data = not section(address)[8] & 0x20000000
            exports.append(name + (' DATA' if data else ''))
        definition = lab / (package + '.def')
        definition.write_text('LIBRARY ' + package + '.dll\nEXPORTS\n' + '\n'.join(exports) + '\n', encoding='ascii')
        subprocess.run([str(lib), '/nologo', '/machine:x86', '/def:' + str(definition), '/out:' + str(lab / (package + '.lib'))], check=True, capture_output=True)
    print('Private SDK headers and 4 import libraries prepared')


if __name__ == '__main__':
    main()
