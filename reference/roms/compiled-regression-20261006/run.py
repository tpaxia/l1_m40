#!/usr/bin/env python3
"""Retest the compiled fixes on fresh published media, without Lua overrides."""
from pathlib import Path
import concurrent.futures, hashlib, json, os, shutil, subprocess
base=Path(__file__).resolve().parent
previous=base.parent/'regression-go363-20261006'
media=Path('/Users/paxia/Projects/mame_disks/m40')
mame=Path('/Users/paxia/Projects/mame_latest/mame')
disks={'ese':'ESE.IMD','mdos30':'MDOS30.IMD','mdosutil':'MDOSUTIL.IMD','bcos-resident':'BCOS_II_3.3_FD_ALL_RESIDENT.imd','bcos-config':'K02733_BCOS_II_3.3_CONFIGURATOR.imd','gardini':'Gardini_Utilities.imd','bcos-generated':'BCOS_LOAD.imd','bcos-hd':'m40-bcos-hd-kusa.chd','mos-hd':'m40-mos-hd.chd'}
disks.update({f'dcos-{c}':f'diagnostics/{c}.IMD' for c in 'ABCDEFGHR'})
manifest={'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=mame,text=True).strip(),'binary_sha256':hashlib.sha256((mame/'m40').read_bytes()).hexdigest(),'media':{p:hashlib.sha256((media/p).read_bytes()).hexdigest() for p in list(disks.values())+['BCOS_RUN.imd']}}
(base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(base/'mame.diff').write_text(subprocess.check_output(['git','diff'],cwd=mame,text=True))
def run(name):
    source='mos-hd' if name=='a5-mos-hd' else name
    data=json.loads((previous/source/'command.json').read_text())
    out=base/name
    out.mkdir()
    cmd=[arg.replace(str(previous/source),str(out)) for arg in data['argv']]
    image=disks[source]
    hd=image.endswith('.chd')
    shutil.copy2(media/image,out/('hd.chd' if hd else 'boot.imd'))
    if not hd: shutil.copy2(media/'m40-mos-hd.chd',out/'hd.chd')
    if name=='bcos-generated': shutil.copy2(media/'BCOS_RUN.imd',out/'run.imd')
    if name=='a5-mos-hd':
        cmd[cmd.index('-bios')+1]='m40-a5'
        cmd[cmd.index('-rompath')+1]=str(base.parent/'mos-a5-boot-test/roms')
    env=os.environ.copy()
    env.update(data['environment'])
    env['STEPS']=env['STEPS'].replace(str(previous/source),str(out))
    env.update(OUT=str(out),SDL_MAC_BACKGROUND_APP='1',SDL_VIDEODRIVER='dummy',SHOT_STEP='20',PROVISIONAL='0',CLEAR_TIMER='0')
    (out/'command.json').write_text(json.dumps({'argv':cmd,'environment':{k:env[k] for k in ['STEPS','ISL','PROVISIONAL','CLEAR_TIMER','RUN_SECONDS']}},indent=2)+'\n')
    print('START '+name,flush=True)
    with (out/'launch.out').open('w') as log:
        rc=subprocess.call(cmd,cwd=out,env=env,stdout=log,stderr=subprocess.STDOUT)
    print(f'DONE {name} exit={rc}',flush=True)
    return name,rc
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    results=list(pool.map(run,['a5-mos-hd','bcos-hd','mos-hd']+[n for n in disks if n not in ('bcos-hd','mos-hd')]))
(base/'exit-status.json').write_text(json.dumps(dict(results),indent=2)+'\n')
