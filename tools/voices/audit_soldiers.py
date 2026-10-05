"""Offline provenance of native soldier voices and their actors in route maps."""
import json
from collections import Counter
from pathlib import Path
from prepare_samples import Pkg, HERE, ROOT


def audit():
    system = ROOT / 'DevInstall/System'
    text = Pkg(str(system / 'RevisionConversationsText.u'))
    speech = []
    speakers = Counter()
    for index, export in enumerate(text.exports, 1):
        if text.classname(export) != 'ConEventSpeech':
            continue
        props = {name.lower(): value for name, _, _, value in text.props(index)}
        speaker = props.get('speakername', '')
        if not any(word in speaker.lower() for word in ('unatco', 'troop', 'soldier', 'jock')):
            continue
        speakers[speaker] += 1
        con = props.get('conversation', ('ref', 0))[1]
        say = props.get('conspeech', ('ref', 0))[1]
        if con <= 0 or say <= 0:
            continue
        speech.append({'speaker': speaker, 'conversation': text.get(con, 'conName', ''),
                       'owner': text.get(con, 'conOwnerName', ''),
                       'audio': text.get(con, 'audioPackageName', ''),
                       'sound_id': text.get(say, 'soundID', -1), 'text': text.get(say, 'speech', '')})
    actors = []
    for map_name in ('04_NYC_Street', '04_NYC_BatteryPark', '04_NYC_Hotel', '06_HongKong_HeliBase'):
        map_path = Path('C:/Program Files (x86)/Steam/steamapps/common/Deus Ex/Revision/Maps') / (map_name + '.dx')
        if not map_path.exists():
            continue
        pkg = Pkg(str(map_path))
        for index, export in enumerate(pkg.exports, 1):
            cls = pkg.classname(export)
            if not (cls.startswith('UNATCO') or cls == 'Jock'):
                continue
            props = {name.lower(): value for name, _, _, value in pkg.props(index)}
            actors.append({'map': map_name.upper(), 'actor': export['name'], 'class': cls,
                           'bind': props.get('bindname', 'UNATCOTroop'),
                           'barks': props.get('barks', None), 'tag': props.get('tag', cls),
                           'location': props.get('location'),
                           'properties': {name: pkg.pval(value) for name, _, _, value in pkg.props(index)
                                          if any(word in name.lower() for word in ('bark', 'conlist', 'bind', 'voice'))}})
    result = {'speakers': dict(speakers), 'actors': actors, 'speech': speech}
    (HERE / 'soldier_audit.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print('Native speakers:', dict(speakers))
    for actor in actors:
        if actor['map'] == '04_NYC_BATTERYPARK' or actor['actor'] in ('UNATCOTroop19','UNATCOTroop41','UNATCOTroop11','UNATCOTroop40'):
            print(actor)
    print('Conversations by soldier speaker:')
    for speaker in speakers:
        if 'jock' not in speaker.lower():
            print(speaker, Counter(record['audio'] for record in speech if record['speaker'] == speaker))


if __name__ == '__main__':
    audit()
