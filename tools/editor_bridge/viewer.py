"""Standalone, local map plan with actor selection and optional engine snapshot."""
import json
from pathlib import Path

from archive import objects
from bspmap import read_model


def write_preview(source, destination, title, runtime_file=None):
    pkg, actors = objects(source)
    model = max((e['size'], i + 1) for i, e in enumerate(pkg.exports)
                if pkg.classname(e) == 'Model')[1]
    points, nodes, surfaces, verts = read_model(pkg, model)
    polygons = []
    for plane, start, count, surface in nodes:
        if count < 3 or start + count > len(verts) or (surface < len(surfaces) and surfaces[surface] & 1):
            continue
        if plane[2] <= .7 and abs(plane[2]) >= .3:
            continue
        polygon = [points[verts[start + i]] for i in range(count)]
        polygons.append(dict(points=polygon, floor=plane[2] > .7,
                             z=sum(p[2] for p in polygon) / len(polygon)))
    runtime = None
    if runtime_file:
        runtime = json.loads(Path(runtime_file).read_text(encoding='utf-8'))
    payload = dict(title=title, actors=actors, geometry=polygons, runtime=runtime)
    data = json.dumps(payload, ensure_ascii=True, separators=(',', ':')).replace('<', '\\u003c')
    destination.write_text(HTML.replace('__DATA__', data), encoding='utf-8')


HTML = r'''<!doctype html><html lang="it"><meta charset="utf-8"><title>Deus Ex Map Bridge</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#10141b;color:#d6deea;font:14px system-ui}header{height:70px;padding:12px 20px;display:flex;align-items:center;gap:22px;border-bottom:1px solid #303947}h1{font-size:18px;margin:0 0 4px}small{color:#9baabd}main{display:grid;grid-template-columns:minmax(0,1fr) 370px;height:calc(100vh - 70px)}section{position:relative;overflow:hidden}canvas{width:100%;height:100%;touch-action:none;cursor:grab}aside{padding:14px;overflow:auto;border-left:1px solid #303947}input,button,select{background:#1c2532;color:#e7edf5;border:1px solid #41516b;border-radius:5px;padding:7px}input[type=search]{width:100%}label{display:inline-block;margin:8px 0}#list{max-height:240px;overflow:auto;margin:10px 0}#list button{display:block;width:100%;text-align:left;margin:4px 0;font-size:12px}#list button.active{border-color:#ffbf62;background:#3e3222}pre{white-space:pre-wrap;font:12px ui-monospace,monospace;background:#18202b;padding:10px;border-radius:5px;overflow-wrap:anywhere}.badge{padding:3px 8px;border-radius:4px;background:#253a46;color:#8adddc}#coords{position:absolute;bottom:12px;left:14px;background:#10141bdd;padding:6px 10px;border-radius:4px}#selection{font-size:16px;font-weight:600;margin-top:12px}#zmin,#zmax{width:110px}#empty{padding:10px;color:#9baabd}.legend{font-size:12px;margin:8px 0;color:#aebdd0}.dot{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px}
</style><header><div><h1 id="title"></h1><small>Pianta della copia privata · trascina per muovere, rotella per zoomare</small></div><span class="badge">Map Bridge</span></header><main><section><canvas id="map"></canvas><div id="coords">Seleziona un oggetto sulla pianta o nell’elenco.</div></section><aside><input id="search" type="search" placeholder="Cerca nome, classe, tag…"><label>Quota Z da <input id="zmin" type="number" step="64"></label><label>a <input id="zmax" type="number" step="64"></label><div><button id="fit">Inquadra mappa</button> <label id="rtlabel"><input type="checkbox" id="runtime"> Stato nel motore</label></div><div class="legend"><span class="dot" style="background:#67c6ef"></span>Mappa <span class="dot" style="background:#df94ff"></span>Creato in esecuzione <span class="dot" style="background:#ffbf62"></span>Selezionato</div><small id="summary"></small><div id="list"></div><div id="selection">Nessun oggetto selezionato</div><pre id="details">I valori mostrati della mappa sono quelli salvati. I default ereditati non sono risolti.</pre></aside></main><script id="data" type="application/json">__DATA__</script><script>
const D=JSON.parse(document.getElementById('data').textContent),C=document.getElementById('map'),ctx=C.getContext('2d'),S=document.getElementById('search'),Z0=document.getElementById('zmin'),Z1=document.getElementById('zmax'),RT=document.getElementById('runtime');
document.getElementById('title').textContent=D.title;document.getElementById('rtlabel').hidden=!D.runtime;
let selected=null,cx=0,cy=0,scale=1,drag=null,shift=0;
const xy=D.geometry.flatMap(p=>p.points),zs=D.geometry.filter(p=>p.floor).map(p=>p.z).sort((a,b)=>a-b);
Z0.value=Math.floor(zs[0]??0)-64;Z1.value=Math.ceil(zs.at(-1)??2048)+64;
function actors(){return RT.checked&&D.runtime?D.runtime.actors:D.actors}
function filtered(){const q=S.value.toLowerCase();return actors().filter(a=>a.location&&a.location[2]>=+Z0.value&&a.location[2]<=+Z1.value&&(!q||JSON.stringify(a).toLowerCase().includes(q)))}
function toScreen(p){return [(p[0]-cx)*scale+C.width/2,(cy-p[1])*scale+C.height/2]}
function toWorld(x,y){return [cx+(x-C.width/2)/scale,cy-(y-C.height/2)/scale]}
function fit(){if(!xy.length)return;let x0=Infinity,x1=-Infinity,y0=Infinity,y1=-Infinity;for(const p of xy){x0=Math.min(x0,p[0]);x1=Math.max(x1,p[0]);y0=Math.min(y0,p[1]);y1=Math.max(y1,p[1])}cx=(x0+x1)/2;cy=(y0+y1)/2;scale=.92*Math.min(C.width/Math.max(1,x1-x0),C.height/Math.max(1,y1-y0));draw()}
function draw(){ctx.fillStyle='#10141b';ctx.fillRect(0,0,C.width,C.height);for(const p of D.geometry){if(p.z<+Z0.value||p.z>+Z1.value)continue;ctx.beginPath();p.points.forEach((v,i)=>{const [x,y]=toScreen(v);i?ctx.lineTo(x,y):ctx.moveTo(x,y)});ctx.closePath();if(p.floor){ctx.fillStyle='#263847';ctx.fill()}else{ctx.strokeStyle='#718598';ctx.lineWidth=.65;ctx.stroke()}}for(const a of filtered()){const[x,y]=toScreen(a.location);if(x<0||x>C.width||y<0||y>C.height)continue;ctx.fillStyle=a.name===selected?.name?'#ffbf62':a.origin==='runtime_spawned'?'#df94ff':'#67c6ef';ctx.beginPath();ctx.arc(x,y,a.name===selected?.name?6:3,0,Math.PI*2);ctx.fill();if(a.name===selected?.name){ctx.font='12px system-ui';ctx.fillText(a.name,x+10,y-10)}}}
function select(a){selected=a;document.getElementById('selection').textContent=a.name;document.getElementById('details').textContent=JSON.stringify(a,null,2);list();draw()}
function list(){const rows=filtered();document.getElementById('summary').textContent=rows.length+' oggetti visibili · '+(RT.checked?'snapshot nel motore, stato dichiarato':'proprietà salvate nella mappa');const target=document.getElementById('list');target.replaceChildren();for(const a of rows.slice(0,200)){const b=document.createElement('button');b.textContent=a.name+' · '+a.class_name+(a.tag?' · '+a.tag:'');b.className=a.name===selected?.name?'active':'';b.onclick=()=>select(a);target.append(b)}if(!rows.length){const t=document.createElement('div');t.id='empty';t.textContent='Nessun oggetto nella ricerca e nella fascia di quota.';target.append(t)}}
function update(){selected=null;document.getElementById('selection').textContent='Nessun oggetto selezionato';document.getElementById('details').textContent=RT.checked?'Seleziona un oggetto dello snapshot nel motore.':'I valori mostrati della mappa sono quelli salvati. I default ereditati non sono risolti.';list();draw()}S.oninput=update;Z0.oninput=update;Z1.oninput=update;RT.onchange=update;document.getElementById('fit').onclick=fit;
C.onpointerdown=e=>{drag=[e.offsetX,e.offsetY,cx,cy];shift=0;C.setPointerCapture(e.pointerId)};C.onpointermove=e=>{if(drag){const dx=e.offsetX-drag[0],dy=e.offsetY-drag[1];shift=Math.max(shift,Math.abs(dx)+Math.abs(dy));cx=drag[2]-dx/scale;cy=drag[3]+dy/scale;draw()}const p=toWorld(e.offsetX,e.offsetY);document.getElementById('coords').textContent='X '+p[0].toFixed(1)+' · Y '+p[1].toFixed(1)+' · Z '+Z0.value+' … '+Z1.value};C.onpointerup=e=>{if(shift<5){let hit=null,best=12;for(const a of filtered()){const[x,y]=toScreen(a.location),dist=Math.hypot(x-e.offsetX,y-e.offsetY);if(dist<best){best=dist;hit=a}}if(hit)select(hit)}drag=null};C.onwheel=e=>{e.preventDefault();const before=toWorld(e.offsetX,e.offsetY);scale*=Math.exp(-e.deltaY*.001);scale=Math.min(10,Math.max(.005,scale));const after=toWorld(e.offsetX,e.offsetY);cx+=before[0]-after[0];cy+=before[1]-after[1];draw()};
new ResizeObserver(()=>{C.width=C.clientWidth;C.height=C.clientHeight;draw()}).observe(C);C.width=C.clientWidth;C.height=C.clientHeight;list();fit();
</script></html>'''
