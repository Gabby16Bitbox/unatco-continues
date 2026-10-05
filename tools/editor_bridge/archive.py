"""Exact UE1 property snapshots and conservative edits to existing actors."""
import math
from pathlib import Path
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from ue1pkg import Pkg
from set_texture_prop import write_ci

PROJECT = Path(__file__).resolve().parents[2]
UNSET = {'unset': True}
INSERTABLE = {'location': ('struct', 'Vector'), 'rotation': ('struct', 'Rotator'),
              'tag': ('name', None), 'event': ('name', None),
              'bhidden': ('bool', None), 'bhiddened': ('bool', None),
              'bcollideactors': ('bool', None), 'bblockactors': ('bool', None),
              'bblockplayers': ('bool', None), 'drawscale': ('float', None),
              'collisionradius': ('float', None), 'collisionheight': ('float', None)}
TYPES = {1: 'byte', 2: 'int', 3: 'bool', 4: 'float', 5: 'object',
         6: 'name', 8: 'class', 10: 'struct', 13: 'string'}


def ancestry_index():
    result = {}
    for root in (PROJECT / 'DevInstall', PROJECT / 'src'):
        for folder in root.glob('*/Classes'):
            for path in folder.glob('*.uc'):
                match = re.search(r'\bclass\s+(\w+)\s+(?:extends|expands)\s+(\w+)',
                                  path.read_text(encoding='latin1'), re.I)
                if match:
                    result[match[1].lower()] = match[2].lower()
    return result


def is_actor(name, ancestors):
    seen = set()
    while name.lower() not in seen:
        name = name.lower()
        if name == 'actor':
            return True
        seen.add(name)
        name = ancestors.get(name, '')
        if not name:
            break
    return False


def tags(pkg, export):
    start = export['off']
    end = start + export['size']
    pos = start
    if export['flags'] & 0x02000000:
        node, pos = pkg.ci(pos)
        _, pos = pkg.ci(pos)
        pos += 12
        if node:
            _, pos = pkg.ci(pos)
    prefix_end = pos
    result = []
    while pos < end:
        beginning = pos
        ni, pos = pkg.ci(pos)
        if pkg.names[ni] == 'None':
            return result, prefix_end, beginning, pos, end
        info = pkg.d[pos]
        pos += 1
        kind, code = info & 15, (info >> 4) & 7
        subtype = None
        if kind == 10:
            sn, pos = pkg.ci(pos)
            subtype = pkg.names[sn]
        size = {0: 1, 1: 2, 2: 4, 3: 12, 4: 16}.get(code)
        if code >= 5:
            length = {5: 1, 6: 2, 7: 4}[code]
            size = int.from_bytes(pkg.d[pos:pos + length], 'little')
            pos += length
        array_index = 0
        is_array = bool(info & 128) and kind != 3
        if is_array:
            byte = pkg.d[pos]
            length = 1 if byte < 128 else (2 if byte & 192 == 128 else 4)
            mask = {1: 127, 2: 16383, 4: 1073741823}[length]
            array_index = int.from_bytes(pkg.d[pos:pos + length], 'big') & mask
            pos += length
        if kind == 3:
            size = 0
        raw_start = pos
        pos += size
        if pos > end:
            raise ValueError('Property extends beyond export: ' + export['name'])
        raw = pkg.d[raw_start:pos]
        value = raw.hex()
        if kind == 3:
            value = bool(info & 128)
        elif kind == 1:
            value = raw[0]
        elif kind == 2:
            value = struct.unpack('<i', raw)[0]
        elif kind == 4:
            value = struct.unpack('<f', raw)[0]
        elif kind == 6:
            value = pkg.names[pkg.ci_bytes(raw)[0]]
        elif kind in (5, 8):
            value = pkg.refname(pkg.ci_bytes(raw)[0])
        elif kind == 13:
            length, offset = pkg.ci_bytes(raw)
            if length < 0:
                value = raw[offset:offset - length * 2].decode('utf-16-le').rstrip('\0')
            else:
                value = raw[offset:offset + length].decode('latin1').rstrip('\0')
        elif kind == 10 and subtype.lower() == 'vector':
            value = list(struct.unpack('<fff', raw))
        elif kind == 10 and subtype.lower() == 'rotator':
            value = list(struct.unpack('<iii', raw))
        result.append(dict(name=pkg.names[ni], type=TYPES.get(kind, str(kind)),
                           kind=kind, subtype=subtype, value=value,
                           array_index=array_index, is_array=is_array,
                           start=beginning, end=pos))
    raise ValueError('Missing property terminator: ' + export['name'])


def objects(path):
    pkg = Pkg(str(path))
    if pkg.tag != 0x9E2A83C1 or pkg.ver != 68:
        raise ValueError('Expected a Deus Ex UE1 package, version 68')
    ancestors = ancestry_index()
    result = []
    for index, export in enumerate(pkg.exports, 1):
        cls = pkg.classname(export)
        if not export['size'] or not is_actor(cls, ancestors):
            continue
        properties, *_ = tags(pkg, export)
        props = {p['name']: p['value'] for p in properties if not p['is_array']}
        result.append(dict(name=export['name'], class_name=cls, export_index=index,
                           location=props.get('Location'), rotation=props.get('Rotation'),
                           tag=props.get('Tag'), event=props.get('Event'),
                           hidden=props.get('bHidden'), properties=props,
                           serialized_properties=[{k: p[k] for k in
                               ('name', 'type', 'subtype', 'value', 'array_index', 'is_array')}
                                                  for p in properties]))
    return pkg, result


def equal(actual, expected):
    if isinstance(actual, bool) or isinstance(expected, bool):
        return type(actual) is type(expected) and actual == expected
    if isinstance(actual, (int, float)) and isinstance(expected, (int, float)):
        return math.isclose(actual, expected, rel_tol=1e-7, abs_tol=1e-5)
    if isinstance(actual, (list, tuple)) and isinstance(expected, (list, tuple)):
        return len(actual) == len(expected) and all(equal(a, b) for a, b in zip(actual, expected))
    return actual == expected


def encode_value(kind, subtype, value, name_index):
    if kind == 3:
        if type(value) is not bool:
            raise ValueError('Expected boolean')
        return b'', 128 if value else 0
    if kind in (1, 2):
        if type(value) is not int:
            raise ValueError('Expected integer')
        return struct.pack('<B' if kind == 1 else '<i', value), 0
    if kind == 4:
        if type(value) not in (int, float) or not math.isfinite(value):
            raise ValueError('Expected finite number')
        return struct.pack('<f', value), 0
    if kind == 6:
        if not isinstance(value, str) or len(value) > 63 or not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*', value):
            raise ValueError('Expected a UE1 name (letters, digits, underscore)')
        return write_ci(name_index(value)), 0
    if kind == 13:
        if not isinstance(value, str) or '\0' in value:
            raise ValueError('Expected string without null characters')
        try:
            encoded = value.encode('latin1') + b'\0'
            return write_ci(len(encoded)) + encoded, 0
        except UnicodeEncodeError:
            encoded = (value + '\0').encode('utf-16-le')
            return write_ci(-(len(encoded) // 2)) + encoded, 0
    if kind == 10 and subtype in ('Vector', 'Rotator'):
        if not isinstance(value, list) or len(value) != 3:
            raise ValueError('Expected [X,Y,Z] or [Pitch,Yaw,Roll]')
        if subtype == 'Vector':
            if any(type(v) not in (int, float) or not math.isfinite(v) for v in value):
                raise ValueError('Expected three finite coordinates')
            return struct.pack('<fff', *value), 0
        if any(type(v) is not int for v in value):
            raise ValueError('Expected three integer rotation units')
        return struct.pack('<iii', *value), 0
    raise ValueError('Unsupported property type; objects, arrays and native structures require the editor')


def patch_bytes(path, operations):
    pkg, records = objects(path)
    if not operations or len(operations) > 100:
        raise ValueError('Supply between 1 and 100 property changes')
    actor_names = {r['name'].lower() for r in records}
    output = bytearray(pkg.d)
    names = list(pkg.names)
    by_name = {v.lower(): i for i, v in enumerate(names)}
    added_names = []

    def name_index(name):
        if name.lower() not in by_name:
            by_name[name.lower()] = len(names)
            names.append(name)
            encoded = name.encode('latin1') + b'\0'
            added_names.append(write_ci(len(encoded)) + encoded + struct.pack('<I', 0x00070010))
        return by_name[name.lower()]

    changes = []
    grouped = {}
    seen = set()
    for op in operations:
        if set(op) != {'actor', 'property', 'expected', 'value'}:
            raise ValueError('Each change requires actor, property, expected and value only')
        if not isinstance(op['actor'], str) or not isinstance(op['property'], str):
            raise ValueError('Actor and property must be names')
        actor, prop = op['actor'].lower(), op['property'].lower()
        if (actor, prop) in seen:
            raise ValueError('Duplicate change to the same property')
        seen.add((actor, prop))
        if actor not in actor_names:
            raise ValueError('Not a known actor: ' + op['actor'])
        grouped.setdefault(actor, []).append(op)
    exports = [dict(e) for e in pkg.exports]
    changed_indices = set()
    for index, export in enumerate(exports):
        wanted = grouped.get(export['name'].lower())
        if not wanted:
            continue
        cls = pkg.classname(export)
        if cls == 'Brush' or 'mover' in cls.lower():
            raise ValueError('Brushes and movers require an editor backend; no offline edits')
        properties, prefix_end, none_start, none_end, end = tags(pkg, export)
        if none_end != end:
            raise ValueError('Actor has native trailing data; use the editor: ' + export['name'])
        replacements = {}
        inserted = []
        for op in wanted:
            found = [p for p in properties if p['name'].lower() == op['property'].lower()]
            if len(found) > 1 or (found and found[0]['is_array']):
                raise ValueError('Array properties require the editor')
            if found:
                item = found[0]
                actual = item['value']
                if not equal(actual, op['expected']):
                    raise ValueError('Previous value changed: ' + export['name'] + '.' + item['name'])
                prop_name, kind, subtype = item['name'], item['kind'], item['subtype']
            else:
                if op['expected'] != UNSET:
                    raise ValueError('Property is inherited/unset; expected must be {"unset":true}')
                definition = INSERTABLE.get(op['property'].lower())
                if not definition:
                    raise ValueError('Only known Actor base fields may be added as overrides')
                kind_name, subtype = definition
                kind = {v: k for k, v in TYPES.items()}[kind_name]
                # Field names must already be known to this package.
                if op['property'].lower() not in by_name:
                    raise ValueError('Property name is absent from the map name table')
                prop_name = names[by_name[op['property'].lower()]]
                actual = UNSET
            payload, flag = encode_value(kind, subtype, op['value'], name_index)
            size = len(payload)
            sizes = {1: 0, 2: 1, 4: 2, 12: 3, 16: 4}
            size_code = 0 if kind == 3 else sizes.get(size, 5 if size <= 255 else (6 if size <= 65535 else 7))
            header = write_ci(name_index(prop_name)) + bytes([kind | (size_code << 4) | flag])
            if kind == 10:
                header += write_ci(name_index(subtype))
            if size_code >= 5:
                header += size.to_bytes({5: 1, 6: 2, 7: 4}[size_code], 'little')
            encoded = header + payload
            if found:
                replacements[item['start']] = encoded
            else:
                inserted.append(encoded)
            changes.append(dict(actor=export['name'], class_name=cls, property=prop_name,
                                before=actual, after=op['value']))
        data = pkg.d[export['off']:prefix_end] + b''.join(inserted)
        data += b''.join(replacements.get(p['start'], pkg.d[p['start']:p['end']]) for p in properties)
        data += pkg.d[none_start:none_end]
        export['off'], export['size'] = len(output), len(data)
        output += data
        changed_indices.add(index)
    if added_names:
        count, offset = struct.unpack_from('<II', pkg.d, 12)
        pos = offset
        for _ in range(count):
            length, pos = pkg.ci(pos)
            if length <= 0:
                raise ValueError('Unexpected name encoding')
            pos += length + 4
        new_offset = len(output)
        output += pkg.d[offset:pos] + b''.join(added_names)
        struct.pack_into('<II', output, 12, len(names), new_offset)
        generations = struct.unpack_from('<I', output, 52)[0]
        if generations:
            struct.pack_into('<I', output, 56 + (generations - 1) * 8 + 4, len(names))
    export_offset = len(output)
    for e in exports:
        output += write_ci(e['class']) + write_ci(e['super']) + struct.pack('<i', e['pkg'])
        output += write_ci(name_index(e['name'])) + struct.pack('<I', e['flags']) + write_ci(e['size'])
        if e['size']:
            output += write_ci(e['off'])
    struct.pack_into('<I', output, 24, export_offset)
    return bytes(output), changes, changed_indices
