"""Build the new civilian rooftop and a local Wan Chai freight-yard extension.

The old MJ12 map is never used as an output. Existing Market lightmaps and
actor properties are preserved. New areas use explicit dynamic lighting.
Outputs stay private until a checkpoint trial succeeds.
"""
import argparse
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import uuid

HERE=Path(__file__).resolve().parent
sys.path[:0]=[str(HERE/'editor_bridge'),str(HERE)]
import core, editor, preserve_baked, geometry
from archive import objects
from build_tong_access import box

ROOF='06_HongKong_WanChai_Rooftop'
MARKET='06_HongKong_WanChai_Market'

def actor(cls,name,spot,props=''):
    loc='Location=(X=%s,Y=%s,Z=%s)\n'%tuple(spot)
    return 'Begin Actor Class='+cls+' Name='+name+'\n'+loc+props+'\nEnd Actor\n'

def mover(name,tag,spot,low,high,delta,texture='ClenMetlPanel_A',cls='DeusExMover'):
    mdl='UCMdl'+name
    p='Tag='+tag+'\nBasePos=(X=%s,Y=%s,Z=%s)\n'%tuple(spot)
    p+='KeyPos(1)=(X=%s,Y=%s,Z=%s)\n'%tuple(delta)
    p+='NumKeys=2\nMoveTime=1.4\nStayOpenTime=3600\nbDynamicLightMover=True\n'
    p+='bCollideActors=True\nbBlockActors=True\nbBlockPlayers=True\n'
    p+="OpeningSound=Sound'MoverSFX.door.MachineDoor3'\nClosingSound=Sound'MoverSFX.door.MachineDoor3'\n"
    if cls=='DeusExMover': p+='bIsDoor=True\nbFrobbable=False\nbBreakable=False\nbPickable=False\nInitialState=TriggerOpenTimed\n'
    p+=box(mdl,low,high,texture)+"Brush=Model'MyLevel."+mdl+"'\n"
    return actor(cls,name,spot,p)

def cuboid(name,low,high,texture='DrtyGreyBrick_A',flags=0):
    b=box(name,low,high,texture)
    if texture.startswith('UC'):
        # The visible sign face is mapped to one complete 256x128 placard.
        x,y,z=low; X,Y,Z=high
        def sign_face(m):
            t=m.group(0)
            n=tuple(float(q) for q in re.search(r'Normal ([^\n]+)',t)[1].split(','))
            if n[0]:
                origin=(x if n[0]<0 else X,y,Z)
                u=(0,256/(Y-y),0); v=(0,0,-128/(Z-z))
            elif n[1]:
                origin=(x,y if n[1]<0 else Y,Z)
                u=(256/(X-x),0,0); v=(0,0,-128/(Z-z))
            else: return t
            for key,value in [('Origin',origin),('TextureU',u),('TextureV',v)]:
                t=re.sub(key+r' [^\n]+',key+' '+','.join(map(str,value)),t)
            return t
        b=re.sub(r'Begin Polygon[\s\S]*?End Polygon',sign_face,b)
    if flags: b=re.sub(r'Flags=0\b','Flags='+str(flags),b)
    return b

def textured(brush,scale=1,vertical=None,floor=None,ceiling=None):
    """Explicit world-aligned repeats; face origins remain on their own planes."""
    def face(m):
        t=m.group(0)
        n=tuple(float(q) for q in re.search(r'Normal ([^\n]+)',t)[1].split(','))
        material=floor if n[2]<0 else ceiling if n[2]>0 else vertical
        if material: t=re.sub(r'Texture=\S+','Texture='+material,t)
        for key in ('TextureU','TextureV'):
            t=re.sub(key+r' ([^\n]+)',lambda q:key+' '+','.join(str(float(v)*scale) for v in q[1].split(',')),t)
        return t
    return re.sub(r'Begin Polygon[\s\S]*?End Polygon',face,brush)

def mesh_panel(name,low,high):
    # Native hexagonal wire mesh: masked, two-sided, with a real collision slab.
    return textured(cuboid(name,low,high,'PlatMetlGrate_B',258),4)

def lift_finish(prefix,center,back,front,left,right):
    """Passenger-scale metal frames, nonslip threshold and a rear grab rail."""
    result=[]
    rail=back+12 if back<front else back-18
    plinth=back+2 if back<front else back-6
    for i,x in enumerate((left,right-12)):
        result.append(('add',prefix+'jamb'+str(i),cuboid('LiftJamb',(x,front-20,0),(x+12,front+16,196),'ClenGrayMetal_A')))
    result += [('add',prefix+'lintel',cuboid('LiftLintel',(left,front-20,192),(right,front+16,204),'ClenGrayMetal_A')),
               ('add',prefix+'sill',cuboid('LiftSill',(left,front-24,0),(right,front+24,2),'GripMetlFloor_A')),
               ('add',prefix+'rearrail',cuboid('LiftGrabRail',(left+24,rail,84),(right-24,rail+6,90),'ClenGrayMetal_A')),
               ('add',prefix+'rearplinth',cuboid('LiftKickPlate',(left+2,plinth,0),(right-2,plinth+4,28),'ClenGrayMetal_A'))]
    return result

def cylinder(name,center,radius,height,texture='DrtySilvMetal_A',segments=16,cap_texture=None):
    x,y,z=center
    ring=[(x+radius*math.cos(i*2*math.pi/segments),y+radius*math.sin(i*2*math.pi/segments),z) for i in range(segments)]
    faces=[(list(reversed(ring)),(0,0,-1)),([(a,b,z+height) for a,b,_ in ring],(0,0,1))]
    for i in range(segments):
        a,b=ring[i],ring[(i+1)%segments]
        mid=(i+.5)*2*math.pi/segments
        faces.append(([a,b,(b[0],b[1],z+height),(a[0],a[1],z+height)],(math.cos(mid),math.sin(mid),0)))
    lines=['Begin Brush Name='+name,'Begin PolyList']
    for vs,n in faces:
        u=(-n[1],n[0],0) if n[2]==0 else (1,0,0)
        v=(0,0,-1) if n[2]==0 else (0,-1,0)
        face_texture=cap_texture if cap_texture and n[2] else texture
        lines+=['Begin Polygon Texture='+face_texture,'Origin '+','.join(map(str,vs[0])),
                'Normal '+','.join(map(str,n)), 'TextureU '+','.join(map(str,u)), 'TextureV '+','.join(map(str,v))]
        lines+=['Vertex '+','.join(map(str,a)) for a in vs]
        lines+=['End Polygon']
    return '\n'.join(lines+['End PolyList','End Brush'])+'\n'

def incline(name,x,X,y,Y,z,Z,thickness,texture='DrtyIronPlain_A'):
    """Solid steel stringer/handrail; polygon origins stay on their own planes."""
    faces=[[(x,y,z),(x,y,z+thickness),(x,Y,Z+thickness),(x,Y,Z)],
           [(X,y,z),(X,Y,Z),(X,Y,Z+thickness),(X,y,z+thickness)],
           [(x,y,z),(X,y,z),(X,y,z+thickness),(x,y,z+thickness)],
           [(x,Y,Z),(x,Y,Z+thickness),(X,Y,Z+thickness),(X,Y,Z)],
           [(x,y,z),(x,Y,Z),(X,Y,Z),(X,y,z)],
           [(x,y,z+thickness),(X,y,z+thickness),(X,Y,Z+thickness),(x,Y,Z+thickness)]]
    lines=['Begin Brush Name='+name,'Begin PolyList']
    for vs in faces:
        a,b,c=vs[:3];u=tuple(b[i]-a[i] for i in range(3));v=tuple(c[i]-a[i] for i in range(3))
        n=(u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0])
        length=math.sqrt(sum(q*q for q in n));n=tuple(q/length for q in n)
        texu=(0,1,0) if abs(n[0])>.9 else (1,0,0)
        texv=(0,0,-1) if abs(n[2])<.1 else (0,-1,-(Z-z)/(Y-y))
        lines+=['Begin Polygon Texture='+texture+' Flags=0','Origin '+','.join(map(str,a)),
                'Normal '+','.join(map(str,n)),'TextureU '+','.join(map(str,texu)),
                'TextureV '+','.join(map(str,texv))]
        lines+=['Vertex '+','.join(map(str,p)) for p in vs];lines+=['End Polygon']
    return '\n'.join(lines+['End PolyList','End Brush'])+'\n'

def signs():
    # drawn like the game's own signs (tools/mapkit/signs.py): Hong Kong's are bilingual
    sys.path.insert(0,str(HERE/'mapkit'))
    import signs as dxsigns
    from signs import Line
    folder=core.PROJECT/'src/UnatcoContinues/Textures'
    dxsigns.plate(folder/'UCCoalitionAccess.pcx',(256,128),'notice',
        [Line('COALITION',.34),Line('AUTHORIZED ACCESS  SP-HK-06',.17),Line('\u53ea\u9650\u6388\u6b0a\u4eba\u54e1',.2,'cjk')],
        header='restricted',header_size=.24)
    dxsigns.plate(folder/'UCFreightSign.pcx',(256,128),'caution',
        [Line('FREIGHT LIFT',.36),Line('\u8ca8\u904b\u5347\u964d\u6a5f',.24,'cjk'),Line('SERVICE YARD  /  ROOF ACCESS',.16)])
    dxsigns.plate(folder/'UCCargoLabel.pcx',(256,128),'paper',
        [Line('VL-HK',.34,'heavy'),Line('RESTRICTED TRANSFER',.2,'narrow',(160,24,26)),
         Line('SPECIAL PROJECTS  /  DESTINATION: CLASSIFIED',.14)],align='left',barcode=True,rule=False,wear=.5)

def roof_geometry():
    # Roof units are local; the Market building represents the same service core.
    g=[('sub','void',cuboid('RoofAir',(-3800,-4000,-1600),(3800,4000,2200),'sky_a_front',128)),
       ('add','roof',cuboid('RoofSlab',(-256,-1664,-96),(1536,704,0),'un_heli_cncrt_a'))]
    for i,(lo,hi) in enumerate([((-256,-1664,0),(-232,704,80)),((1512,-1664,0),(1536,704,80)),
                                ((-232,-1664,0),(1512,-1640,80)),((-232,680,0),(1512,704,80))]):
        g.append(('add','parapet'+str(i),textured(cuboid('Parapet'+str(i),lo,hi,'RuffWhitStuco_B'),.5)))
        g.append(('add','coping'+str(i),cuboid('ParapetCoping',(lo[0]-2,lo[1]-2,80),(hi[0]+2,hi[1]+2,86),'ClenGrayMetal_A')))
    # Keep the roof and stairs; shrink only the landing deck by 39.5% in area.
    pad=cuboid('LandingPad',(0,-544,48),(896,352,64),'ClenGrayMetal_A')
    def pad_top(m):
        t=m.group(0)
        if 'Normal 0,0,1\n' not in t: return t
        t=t.replace('Texture=ClenGrayMetal_A','Texture=Heli_LiftDetl_B')
        for k,value in [('Origin',(0,352,64)),('TextureU',(128/896,0,0)),('TextureV',(0,-128/896,0))]:
            t=re.sub(k+r' [^\n]+',k+' '+','.join(map(str,value)),t)
        return t
    pad=re.sub(r'Begin Polygon[\s\S]*?End Polygon',pad_top,pad)
    g.append(('add','pad',pad))
    # Steel support structure and low horizontal safety mesh, open at the stairs.
    for i,x in enumerate((16,224,664,864)):
        g.append(('add','padbeam'+str(i),cuboid('DeckBeam',(x,-528,24),(x+16,336,48),'DrtyIronWOriv_A')))
        for j,y in enumerate((-512,304)):
            g.append(('add','padfoot%d_%d'%(i,j),cuboid('DeckFoot',(x-4,y,0),(x+20,y+24,24),'ClenGrayMetal_A')))
    for i,(lo,hi) in enumerate([((-56,-544,52),(0,352,54)),((896,-544,52),(952,352,54)),
        ((-56,352,52),(952,408,54)),((0,-600,52),(264,-544,54)),((576,-600,52),(896,-544,54))]):
        g.append(('add','padnet'+str(i),mesh_panel('PadSafetyNet',lo,hi)))
    for i,(lo,hi) in enumerate([((-62,-548,50),(-56,414,58)),((952,-548,50),(958,414,58)),
        ((-62,408,50),(958,414,58)),((0,-606,50),(264,-600,58)),((576,-606,50),(896,-600,58))]):
        g.append(('add','padnetframe'+str(i),cuboid('NetFrame',lo,hi,'ClenGrayMetal_A')))
    # Open steel treads, stringers and sloping rails, rather than concrete blocks.
    for i in range(4):
        tread=cuboid('PadStep',(288,-736+48*i,8+16*i),(544,-688+48*i,16*(i+1)),'ClenGrayMetal_A')
        def grate_top(m):
            t=m.group(0)
            if 'Normal 0,0,1\n' not in t: return t
            t=t.replace('Texture=ClenGrayMetal_A','Texture=HevyMetlGrate_C')
            for k,value in [('TextureU',(1,0,0)),('TextureV',(0,-2,0))]:
                t=re.sub(k+r' [^\n]+',k+' '+','.join(map(str,value)),t)
            return t
        g.append(('add','padstep'+str(i),re.sub(r'Begin Polygon[\s\S]*?End Polygon',grate_top,tread)))
        g.append(('add','stepbrace'+str(i),cuboid('StepBrace',(272,-720+48*i,4+16*i),(572,-712+48*i,8+16*i),'DrtyIronPlain_A')))
    for side,x in enumerate((272,560)):
        g.append(('add','stringer'+str(side),incline('StairStringer',x,x+12,-736,-544,0,48,16)))
        for j,y in enumerate((-724,-552)):
            g.append(('add','stairpost%d_%d'%(side,j),cuboid('StairPost',(x,y,0),(x+8,y+8,80 if j==0 else 128),'DrtyIronPlain_A')))
        g.append(('add','stairrail'+str(side),incline('StairRail',x,x+8,-724,-552,80,128,8)))
    # Service headhouse: solid shell, lobby, blind lift shaft and storage room.
    g += [('add','headhouse',textured(cuboid('ServiceCore',(672,-1632,0),(1488,-608,320),'RuffWhitStuco_B'),.5)),
          ('sub','lobby',textured(cuboid('RoofLobby',(736,-1120,0),(1424,-672,240),'RuffWhitStuco_A'),.5,floor='INDUgraytile')),
          ('sub','entry',cuboid('CheckpointOpening',(672,-864,0),(752,-672,192),'ClenGrayMetal_A')),
          ('sub','shaft',textured(cuboid('LiftShaft',(1040,-1536,-320),(1392,-1104,288),'ClenMetlPanel_A'),.5)),
          ('sub','store',cuboid('RoofStore',(736,-1568,0),(992,-1168,208),'DrtyPlyWood_A')),
          ('sub','storeentry',cuboid('StoreEntry',(800,-1184,0),(928,-1104,176),'DrtyGreyBrick_A'))]
    g += lift_finish('roof',1216,-1536,-1128,1040,1392)
    g += [('add','headhousecap',cuboid('ServiceCoreCoping',(660,-1644,320),(1500,-596,336),'ClenGrayMetal_A')),
          ('add','entrycanopy',cuboid('RainCanopy',(592,-900,204),(684,-648,212),'ClenGrayMetal_A')),
          ('add','entryjamb0',cuboid('AccessFrame',(664,-878,0),(680,-864,204),'ClenGrayMetal_A')),
          ('add','entryjamb1',cuboid('AccessFrame',(664,-672,0),(680,-658,204),'ClenGrayMetal_A')),
          ('add','entrylintel',cuboid('AccessLintel',(664,-878,192),(680,-658,204),'ClenGrayMetal_A')),
          ('add','facadevent',cuboid('ServiceLouver',(666,-1500,128),(672,-1250,236),'RustMetlVents_A')),
          ('add','electricalbox',cuboid('DistributionBox',(656,-1100,60),(672,-1036,152),'ClenGrayMetal_A')),
          ('add','electricconduit',cuboid('CableConduit',(652,-1072,152),(658,-1066,314),'ClenGrayMetal_A')),
          ('add','liftmachine',cuboid('LiftMachineHousing',(1024,-1552,336),(1408,-1160,448),'ClenGrayMetal_A')),
          ('add','liftmachinevent',cuboid('MachineVent',(1018,-1490,364),(1024,-1240,420),'RustMetlVents_A'))]
    # Service bay: roof equipment behind mesh, with a clear maintenance entrance.
    for i,(lo,hi) in enumerate([((-228,-864,0),(132,-860,128)),((132,-1632,0),(136,-1120,128)),((132,-968,0),(136,-860,128))]):
        g.append(('add','utilityfence'+str(i),mesh_panel('ServiceMesh',lo,hi)))
    for i,(x,y) in enumerate(((-228,-864),(132,-864),(132,-968),(132,-1120),(132,-1632))):
        g.append(('add','fencepost'+str(i),cuboid('FencePost',(x-4,y-4,0),(x+4,y+4,136),'DrtyIronWOriv_A')))
    for i,y in enumerate((-1100,-1390)):
        g += [('add','hvac'+str(i),cuboid('HVAC'+str(i),(-216,y,24),(-24,y+224,112),'StanGalvMetal')),
              ('add','hvacvent'+str(i),cuboid('HVACVent',(-24,y+24,48),(-20,y+200,100),'RustMetlVents_A')),
              ('add','hvacbase'+str(i),cuboid('HVACBase',(-224,y-8,0),(-16,y+232,24),'ClenGreyCncrt_A')),
              ('add','duct'+str(i),cuboid('Duct'+str(i),(-20,y+64,24),(96,y+128,64),'StanGalvMetal')),
              ('add','ductrise'+str(i),cuboid('DuctRiser',(64,y+64,24),(96,y+128,160),'StanGalvMetal')),
              ('add','ductcowl'+str(i),cuboid('DuctCowl',(56,y+56,160),(104,y+136,168),'DrtyIronWOriv_A'))]
        for j,yy in enumerate((y+8,y+216)):
            g.append(('add','hvacrib%d_%d'%(i,j),cuboid('HVACRib',(-218,yy,24),(-22,yy+4,112),'DrtyIronWOriv_A')))
    for i,x in enumerate((220,408)):
        g.append(('add','tank'+str(i),cylinder('WaterTank'+str(i),(x,-1510,24),72,144,'DrtySilvMetal_A',cap_texture='ClenGrayMetal_A')))
        for j,z in enumerate((48,148)):
            g.append(('add','tankband%d_%d'%(i,j),cylinder('TankBand',(x,-1510,z),74,8,'DrtyIronWOriv_A')))
        g.append(('add','tanklid'+str(i),cylinder('TankLid',(x,-1510,168),24,8,'DrtyIronPlain_A')))
    g += [('add','tankstand0',cuboid('TankStand0',(140,-1590,0),(300,-1430,24),'ClenGreyCncrt_A')),
          ('add','tankstand1',cuboid('TankStand1',(328,-1590,0),(488,-1430,24),'ClenGreyCncrt_A')),
          ('add','tankpipe',cuboid('TankPipe',(208,-1620,12),(420,-1608,24),'DrtyIronPlain_A')),
          ('add','antenna',cuboid('Antenna',(584,-1560,0),(592,-1552,384),'DrtyIronPlain_A')),
          ('add','cable',cuboid('RoofCable',(32,-1628,1),(672,-1620,5),'DrtyIronPlain_A')),
          ('add','sign',cuboid('CoalitionNotice',(668,-860,126),(672,-680,216),'UCCoalitionAccess')),
          ('add','liftsign',cuboid('FreightNotice',(1040,-1108,198),(1392,-1104,280),'UCFreightSign'))]
    for i,x in enumerate((280,444)):
        g.append(('add','maintenancepallet'+str(i),cuboid('MaintenancePallet',(x,-1330,0),(x+120,-1240,10),'ShipGrayMetal_A')))
    # Low pipe runs hug the parapet; no equipment crosses the arrival route.
    for i,x in enumerate((160,196)):
        g.append(('add','utilitypipe'+str(i),cuboid('WaterPipe',(x,-1590,28),(x+8,-1110,36),'ClenGrayMetal_A')))
    buildings=[(-3200,-2800,-2450,-1800,700),(-3000,-1200,-2400,-350,1050),(-3200,850,-2400,1950,580),
               (-2100,2600,-1050,3400,1500),(0,2700,900,3500,850),(2100,2100,3100,3300,1150),
               (2600,-1600,3400,-500,500),(2200,-3400,3250,-2500,1250)]
    for i,(x,y,X,Y,Z) in enumerate(buildings):
        # Authentic Wan Chai windows, with a continuous masonry facade.
        b=cuboid('WanChaiBlock'+str(i),(x,y,-1600),(X,Y,Z),'ClenBrwnWndow_C' if i%2 else 'ClenBrckWndow_B')
        b=re.sub(r'(Texture[UV]) ([^\n]+)',lambda m:m[1]+' '+','.join(str(float(q)*.5) for q in m[2].split(',')),b)
        g.append(('add','skyline'+str(i),b))
        g.append(('add','skylinecap'+str(i),cuboid('BuildingCap',(x-16,y-16,Z),(X+16,Y+16,Z+24),'ClenGreyCncrt_A')))
    sky=cuboid('RooftopSky',(6500,-500,-500),(7500,500,500),'HK_City_A_A',64)
    def sky_face(m):
        t=m.group(0);n=tuple(float(q) for q in re.search(r'Normal ([^\n]+)',t)[1].split(','))
        if n[2]: return t.replace('Texture=HK_City_A_A','Texture=HK_City_A_B')
        for key in ('TextureU','TextureV'):
            t=re.sub(key+r' ([^\n]+)',lambda s:key+' '+','.join(str(float(q)*256/1000) for q in s[1].split(',')),t)
        return t
    g.append(('sub','skybox',re.sub(r'Begin Polygon[\s\S]*?End Polygon',sky_face,sky)))
    return g

def roof_actors():
    a=actor('DeusExLevelInfo','UCRoofInfo',(0,0,100),
        'MapName="'+ROOF+'"\nMissionLocation="Wan Chai rooftop"\nmissionNumber=6\n'
        "Script=Class'RevisionMission.RevisionMission06'\nConversationPackage=RevisionConversations\n")
    a+=actor('ZoneInfo','UCRoofZone',(0,0,800),'AmbientBrightness=45\nAmbientHue=160\nAmbientSaturation=120')
    a+=actor('SkyZoneInfo','UCRoofSky',(7000,0,0),'AmbientBrightness=255')
    a+=actor('PlayerStart','UCRoofStart',(1000,160,56),'Rotation=(Yaw=36000)')
    a+=actor('Teleporter','UCRoofReturn0',(1216,-960,56),'Tag=UCRoofReturn\nURL=""\nbEnabled=False\nRotation=(Yaw=32768)')
    a+=actor('BlackHelicopter','UCRoofChopper',(448,-96,139),'Tag=chopper\nBindName=Jock\nRotation=(Yaw=16384)\nDrawScale=0.85\nCollisionRadius=392.05\nCollisionHeight=74.66\nSoundRadius=48\nSoundVolume=100')
    for name,tag,bind,spot,yaw in [('RoofLiaison','UCRoofLiaison','UCHKOfficer',(460,-832,48),16384),
        ('RoofGuard0','UCRoofSecurity','UCHKGuard',(610,-730,48),32768),
        ('RoofGuard1','UCRoofSecurity','UCHKGuard',(1248,-320,48),32768)]:
        a+=actor('UnatcoContinues.UCTransitGuard','UC'+name,spot,
            'Tag='+tag+'\nBindName='+bind+'\nRotation=(Yaw='+str(yaw)+')\nOrders=Standing')
    a+=mover('UCRoofCheckpoint0','UCRoofCheckpoint',(708,-768,96),(-8,-96,-96),(8,96,96),(0,196,0))
    a+=mover('UCRoofLiftDoor0','UCRoofLiftDoor',(1216,-1128,96),(-160,-8,-96),(160,8,96),(-336,0,0))
    a+=mover('UCRoofCabin0','UCRoofCabin',(1216,-1336,-12),(-160,-192,-12),(160,192,12),(0,0,-192),'HevyMetlGrate_C','ElevatorMover')
    store=mover('UCRoofStoreDoor0','UCRoofStoreDoor',(864,-1144,88),(-64,-8,-88),(64,8,88),(-144,0,0))
    a+=store.replace('bFrobbable=False','bFrobbable=True\nbLocked=True\nlockStrength=0.6').replace('bPickable=False','bPickable=True')
    # Cab walls are shaft geometry; the moving floor carries JC to a short fade.
    a+=actor('UnatcoContinues.UCTransitButton','UCRoofLiftButton',(1380,-1360,84),'Rotation=(Yaw=32768)\nButtonType=BT_Down')
    a+=actor('Keypad1','UCRoofCheckpointPad',(660,-660,88),'validCode="0614"\nbToggleLock=False\nEvent=UCRoofCheckpoint')
    a+=actor('SecurityCamera','UCRoofCamera',(1400,-660,210),'Rotation=(Yaw=32768)\nbNoAlarm=True\nbActive=True')
    a+=actor('SatelliteDish','UCRoofDish',(196,-1040,32),'Rotation=(Yaw=42000)')
    for i,spot in enumerate([(-112,-650,33),(-112,-738,33)]):
        a+=actor('CrateUnbreakableMed','UCRoofCargo'+str(i),spot,'ItemName="SP-HK-06 sealed equipment"')
    for i,(x,y,skin) in enumerate([(316,-1280,'SC_Blue'),(372,-1280,'SC_Rusty'),(488,-1280,'SC_Brown')]):
        a+=actor('Barrel1','UCRoofMaintenanceDrum'+str(i),(x,y,39),'SkinColor='+skin+'\nItemName="Maintenance supplies"\nbExplosive=False\nbFlammable=False\nbPushable=False')
    for i,spot in enumerate([(496,-1410,16),(540,-1400,16),(540,-1400,48),(96,-768,16)]):
        a+=actor('CrateUnbreakableSmall','UCRoofParts'+str(i),spot,'ItemName="Service parts"')
    for i,y in enumerate((-988,-1278)):
        a+=actor('Fan1','UCRoofVentFan'+str(i),(-120,y,115),'DrawScale=0.22\nCollisionRadius=71.72\nCollisionHeight=22.66\nbCollideActors=False\nbBlockActors=False\nbBlockPlayers=False\nbFrobbable=False')
    for i,spot in enumerate([(640,-768,192),(1216,-720,224),(1216,-1480,262)]):
        a+=actor('CageLight','UCRoofFixture'+str(i),spot,'DrawScale=0.6\nCollisionRadius=10.3\nCollisionHeight=10.3\nLightBrightness=80\nLightRadius=5\nLightHue=32\nLightSaturation=160\nbFrobbable=False')
    for cls,name,spot in [('MedKit','UCRoofMed',(780,-1510,12)),('Multitool','UCRoofTool',(850,-1510,12)),
        ('Ammo10mm','UCRoofAmmo',(920,-1510,12))]: a+=actor(cls,name,spot)
    a+=actor('UnatcoContinues.UCFileCube','UCRoofAuthorization',(790,-1240,12),
        'document=Helibase\nSpecialText="'+ 'SPECIAL PROJECTS / SP-HK-0614|nFlight reception: AUTHORIZED|nAgent: J.C. Denton|nIssuing office: WALTON SIMONS'+'"')
    for i,(spot,brightness,radius,hue) in enumerate([((448,32,520),165,32,160),((1200,-900,220),110,12,32),
        ((420,-720,180),100,14,32),((180,-1280,220),75,14,160),
        ((864,-1410,180),65,6,32),((1216,-1380,180),100,8,32)]):
        a+=actor('Light','UCRoofLight'+str(i),spot,'bStatic=False\nbMovable=True\nLightBrightness=%d\nLightRadius=%d\nLightHue=%d\nLightSaturation=100'%(brightness,radius,hue))
    for i,(x,y) in enumerate([(16,-528),(16,336),(880,-528),(880,336)]):
        a+=actor('Light','UCPadRed'+str(i),(x,y,84),'bStatic=False\nbMovable=True\nLightBrightness=70\nLightRadius=5\nLightHue=0\nLightSaturation=0\nLightEffect=LE_Pulse')
        a+=actor('Flare','UCPadMarker'+str(i),(x,y,70),'bUnlit=True\nbCollideActors=False\nbBlockActors=False\nbBlockPlayers=False\nDrawScale=0.18')
    return 'Begin Map\n'+a+'End Map\n'

def market_geometry():
    # Blind frontage x1280..1472, between existing occupied north-side interiors.
    g=[('sub','marketneck',cuboid('FreightPassage',(1280,1776,0),(1472,2704,192),'DrtyGreyBrick_A')),
       ('sub','marketlobby',textured(cuboid('FreightLobby',(1248,2496,0),(1664,2720,208),'RuffWhitStuco_A'),.5,floor='INDUgraytile')),
       ('sub','marketshaft',textured(cuboid('FreightCabin',(1280,2688,0),(1600,3040,224),'ClenMetlPanel_A'),.5,floor='HevyMetlGrate_C')),
       ('sub','marketyard',cuboid('CargoYard',(1664,2336,0),(3072,3680,512),'DrtyCastCemnt_A')),
       ('sub','marketentrance',cuboid('YardEntrance',(1648,2528,0),(1760,2704,192),'DrtyGreyBrick_A')),
       ('sub','maintenance',cuboid('RaidService',(2752,3648,0),(3072,4096,224),'DrtyGreyBrick_A')),
       ('sub','balconyroom',cuboid('ServiceStairsRoom',(1728,3584,0),(2112,4096,432),'DrtyGreyBrick_A')),
       ('sub','galleryneck',cuboid('UpperServiceEntry',(1728,3504,192),(1952,3648,400),'DrtyGreyBrick_A')),
       ('sub','canallane',cuboid('ServiceLane',(3008,2752,0),(3456,2944,208),'DrtyGreyBrick_A'))]
    g += lift_finish('market',1440,3040,2680,1280,1600)
    g+=[('add','yardfloor',cuboid('YardPaving',(1664,2336,-8),(3072,3680,0),'DrtyGraySwalk_A')),
        ('add','gallery',cuboid('CargoGallery',(1728,3424,176),(2048,3680,192),'DrtyIronWOriv_A')),
        ('add','galleryback',cuboid('GalleryStagingFloor',(1728,3584,176),(1952,4096,192),'DrtyIronWOriv_A')),
        ('add','gatefront',cuboid('YardServiceNotice',(1276,1800,150),(1280,1970,218),'UCFreightSign')),
        ('add','cabinsign',cuboid('YardLiftSign',(1280,2684,190),(1600,2688,222),'UCFreightSign')),
        ('add','rooftopcore',cuboid('ServiceShaftExterior',(1224,2280,512),(1640,3064,1488),'ClenWhteWall_F'))]
    for i in range(8):
        g.append(('add','gallerystep'+str(i),cuboid('GalleryStep',(2048+24*i,3424,0),(2240,3552,24*(8-i)),'DrtyIronPlain_A')))
    # Canvas awning/steel supports, working-height cargo shelf, cargo cover.
    g.append(('add','awning',cuboid('LoadingCanopy',(1696,2380,320),(3016,2530,332),'DrtySilvMetal_A')))
    for i,x in enumerate((1704,2992)):
        g.append(('add','canopypole'+str(i),cuboid('CanopyPost',(x,2400,0),(x+16,2416,320),'DrtyIronPlain_A')))
    for i,(x,y) in enumerate(((1984,2456),(2800,2500),(2144,2872),(2864,3328))):
        g.append(('add','bumper'+str(i),cuboid('CargoBumper',(x,y,0),(x+64,y+12,56),'ClenGrayMetal_A')))
    return g

def market_actors():
    a=mover('UCMarketLiftDoor0','UCMarketLiftDoor',(1440,2680,96),(-160,-8,-96),(160,8,96),(-336,0,0))
    a+=mover('UCYardMaintenance0','UCYardMaintenance',(2912,3664,96),(-160,-8,-96),(160,8,96),(0,0,208))
    a+=actor('Teleporter','UCMarketArrival0',(1440,2880,56),'Tag=UCMarketArrival\nURL=""\nbEnabled=False\nRotation=(Yaw=49152)')
    a+=actor('UnatcoContinues.UCTransitButton','UCMarketLiftButton',(1588,2864,84),'bToRoof=True\nRotation=(Yaw=32768)\nButtonType=BT_Up')
    a+=actor('Van','UCYardVan',(2400,3152,67),'Tag=UCTransportVan\nRotation=(Yaw=16384)\nItemName="Secured transport"\nbInvincible=True')
    a+=actor('CrateUnbreakableMed','UCHKSecuredCase0',(2704,3104,33),'Tag=UCHKSecuredCase\nItemName="Restricted transport case"')
    a+=actor('UnatcoContinues.UCFileCube','UCHKShipmentLabel',(2704,3104,70),
        'document=Shipment\nSpecialText="VL-HK / RESTRICTED TRANSFER|nDestination: [CLASSIFIED]|nHandling authority: SPECIAL PROJECTS|nLogistics contractor: VersaLife Hong Kong"\nItemName="Cargo transfer label"')
    for i,spot in enumerate([(1984,2440,33),(2800,2450,33),(2864,3344,33),(2864,3344,99),(2144,2900,33)]):
        a+=actor('CrateUnbreakableMed','UCYardCargo'+str(i),spot,'ItemName="Sealed freight"')
    a+=actor('Cart','UCYardCart',(1952,3176,27),'Rotation=(Yaw=16384)')
    a+=actor('Barrel1','UCYardBarrel',(1810,3016,29),'bExplosive=False')
    for name,tag,bind,spot,yaw in [('Liaison','UCYardLiaison','UCHKOfficer',(1628,2608,48),32768),
        ('Guard0','UCYardSecurity','UCHKGuard',(1968,2864,48),0),
        ('Guard1','UCYardSecurity','UCHKGuard',(2680,2890,48),16384),
        ('Guard2','UCYardSecurity','UCHKGuard',(2320,3376,48),49152)]:
        a+=actor('UnatcoContinues.UCTransitGuard','UCYard'+name,spot,
            'Tag='+tag+'\nBindName='+bind+'\nRotation=(Yaw='+str(yaw)+')\nOrders=Standing')
    for i,(tag,spot,entry,cargo) in enumerate([('UCYardRaiderA',(2820,3920,48),(2816,3536,48),(2704,3104,48)),
        ('UCYardRaiderB',(1840,3840,240),(2192,3480,48),(2704,3104,48)),
        ('UCYardRaiderC',(3000,3992,48),(3000,3472,48),(2704,3104,48))]):
        a+=actor('UnatcoContinues.UCYardRaider','UCYardRaider'+str(i),spot,
            'Tag='+tag+'\nBindName=UCYardRaider'+str(i+1)+'\nentryPoint=(X=%s,Y=%s,Z=%s)\n'%entry
            +'cargoPoint=(X=%s,Y=%s,Z=%s)\n'%cargo
            +('galleryPoint=(X=1840,Y=3560,Z=240)\n' if i==1 else '')+'Orders=Standing')
    a+=actor('Teleporter','UCYardCanalExit',(3392,2848,56),'Tag=UCYardCanalExit\nURL="06_HongKong_WanChai_Canal#market01"\nCollisionRadius=40\nCollisionHeight=60')
    for i,(spot,b,r) in enumerate([((1400,2470,164),85,9),((1440,2880,176),100,8),
        ((2224,2850,420),145,22),((2832,3424,410),110,16),((1840,3650,340),80,10),((3300,2848,160),70,8)]):
        a+=actor('Light','UCFreightLight'+str(i),spot,
            'bStatic=False\nbMovable=True\nLightBrightness=%d\nLightRadius=%d\nLightHue=32\nLightSaturation=100'%(b,r))
    return 'Begin Map\n'+a+'End Map\n'

def build(site, private_build):
    workspace,manifest,original=core.workspace(site)
    original=workspace/manifest['versions'][0]['file']
    if core.sha(original)!=manifest['source_sha256']: raise ValueError('Survey base changed')
    folder,deps=editor.prepare_run(original,MARKET)
    if private_build:
        for name in ('UnatcoContinues.u','UnatcoVoices.u'):
            source=private_build/name
            shutil.copy2(source,folder/'System'/name)
            deps[name]=core.sha(source)
    for output,geometry_fn,actors_fn,new in [(ROOF,roof_geometry,roof_actors,True),(MARKET,market_geometry,market_actors,False)]:
        recipes=[]
        if new:
            recipes=['MAP LOAD FILE="..\\Input\\'+MARKET+'.dx"','MAP NEW']
        else:
            recipes=['MAP LOAD FILE="..\\Input\\'+MARKET+'.dx"','MAP EXPORT FILE="..\\before-market.t3d"']
        recipes+=['OBJ LOAD FILE="UnatcoContinues.u"']
        recipes+=['OBJ LOAD FILE="'+p+'.utx"' for p in ('CoreTexConcrete','CoreTexMetal','CoreTexStucco','CoreTexTiles','CoreTexSky','HK_Helibase','HK_BuildingExt')]
        for operation,key,brush in geometry_fn():
            (folder/(key+'.t3d')).write_text(brush,encoding='ascii')
            recipes+=['BRUSH RESET','BRUSH IMPORT FILE="..\\'+key+'.t3d"','BRUSH '+('ADD' if operation=='add' else 'SUBTRACT')]
        actors_path=folder/(output+'-actors.t3d')
        actors_path.write_text(actors_fn(),encoding='ascii')
        recipes+=['MAP IMPORTADD FILE="..\\'+actors_path.name+'"']
        _,actors=geometry.t3d_actors(actors_path)
        movers=[n for n,t in actors.items() if 'Brush=Model' in t]
        recipes+=['UC_MOVER scale '+n+' 1 1 1' for n in movers]
        recipes+=['UC_WORLD finish']
        recipes+=['MAP SAVE FILE="..\\Output\\'+output+'.dx"']
        editor.execute(folder,recipes,output+'.log')
        path=folder/'Output'/(output+'.dx')
        if not new: preserve_baked.restore(original,path)
        for n in movers:
            subprocess.run([sys.executable,str(HERE/'fix_brush_surfs.py'),str(path),'UCMdl'+n],check=True,capture_output=True)
        editor.execute(folder,['MAP LOAD FILE="..\\Output\\'+output+'.dx"']
            +['UC_MOVER bounds '+n+' 1 1 1' for n in movers]
            +['MAP SAVE FILE="..\\Output\\'+output+'.dx"','MAP EXPORT FILE="..\\after-'+output+'.t3d"'],output+'-reload.log')
        if not new: preserve_baked.restore(original,path)
    _,before=geometry.t3d_actors(folder/'before-market.t3d')
    _,after=geometry.t3d_actors(folder/('after-'+MARKET+'.t3d'))
    def gameplay(t): return re.sub(r'^    (?:Region|FootRegion|HeadRegion|bSelected)=.*\n?','',t,flags=re.M)
    # The builder brush is the only pre-existing actor edited by native CSG.
    for n,t in before.items():
        if n.startswith('Brush') and 'Brush=Model\'MyLevel.Brush\'' in t: continue
        if gameplay(t)!=gameplay(after.get(n,'')): raise ValueError('Original actor changed: '+n)
    out=folder/'Output'
    report=dict(site=site,run=str(folder),packages=deps,
        original_market_sha256=core.sha(original),old_helibase_sha256=core.sha(core.PROJECT/'maps/06_HongKong_Helibase.dx'),
        maps={n:dict(file=str(out/(n+'.dx')),sha256=core.sha(out/(n+'.dx'))) for n in (ROOF,MARKET)},
        existing_market_lighting_preserved=True,original_actor_properties_preserved=True,
        new_rooftop_lighting='dynamic; no headless viewport light solver',installed=False)
    version='versions/rooftop-yard-'+folder.name+'.dx'
    shutil.copy2(out/(MARKET+'.dx'),workspace/version)
    manifest['versions'].append(dict(file=version,sha256=report['maps'][MARKET]['sha256'],
        parent=manifest['current'],changes=[dict(operation='Wan Chai freight core and cargo yard')],
        action='rooftop_yard',native_run=str(folder)))
    manifest['current']=len(manifest['versions'])-1
    core.save(workspace/'manifest.json',manifest)
    core.save(folder/'rooftop-build.json',report)
    core.save(core.HERE/'rooftop-build.json',report)
    print(json.dumps(report,indent=2))
    return report

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--site'); p.add_argument('--build-system',type=Path); p.add_argument('--signs',action='store_true')
    args=p.parse_args()
    if args.signs: signs()
    else: build(args.site,args.build_system)
