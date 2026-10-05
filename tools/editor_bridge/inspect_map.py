"""Read saved UE1 map objects as JSON, without opening or changing UnrealEd.

This exposes serialized overrides only: inherited class defaults and actors
spawned by UCMod at runtime are not present in this offline snapshot.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from ue1pkg import Pkg


def inspect(path, query='', object_name=None):
    pkg = Pkg(str(path))
    records = []
    errors = []
    for index, export in enumerate(pkg.exports, 1):
        if not export['size']:
            continue
        if object_name and export['name'].casefold() != object_name.casefold():
            continue
        try:
            properties = [dict(name=name, type=kind, array_index=array_index,
                               value=pkg.pval(value))
                          for name, kind, array_index, value in pkg.props(index)]
        except (ValueError, IndexError, KeyError, UnicodeError, struct.error) as exc:
            errors.append(dict(name=export['name'], error=str(exc)))
            continue
        record = dict(name=export['name'], class_name=pkg.classname(export),
                      export_index=index, properties=properties)
        if query and query.casefold() not in json.dumps(record).casefold():
            continue
        records.append(record)
    if object_name and not records:
        raise ValueError('Object not found or unreadable: ' + object_name)
    return dict(map=str(path.resolve()), package_version=pkg.ver,
                sha256=hashlib.sha256(pkg.d).hexdigest(),
                scope='serialized objects; inherited defaults and runtime actors excluded',
                export_count=len(pkg.exports), returned_count=len(records),
                located_object_count=sum(any(p['name'].lower() == 'location'
                                             for p in r['properties']) for r in records),
                classes=dict(Counter(r['class_name'] for r in records)),
                parse_errors=errors, objects=records)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('map', type=Path)
    parser.add_argument('--query', default='', help='Find a name, class, tag or saved value')
    parser.add_argument('--object', dest='object_name', help='Read one exact object name')
    parser.add_argument('--out', type=Path, help='Save JSON instead of printing it')
    args = parser.parse_args()
    if args.out and args.out.resolve() == args.map.resolve():
        parser.error('The JSON output must not overwrite the map')
    if args.out and args.out.suffix.lower() != '.json':
        parser.error('Use a .json file for the output')
    result = inspect(args.map, args.query, args.object_name)
    data = json.dumps(result, ensure_ascii=False, indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(data + '\n', encoding='utf-8')
        print(f"{result['returned_count']} objects, {len(result['parse_errors'])} parse errors: {args.out}")
    else:
        print(data)


if __name__ == '__main__':
    main()
