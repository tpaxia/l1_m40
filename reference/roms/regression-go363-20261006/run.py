#!/usr/bin/env python3
"""Regression of the published mame_disks M40 media on disposable copies."""
from pathlib import Path
import concurrent.futures, hashlib, json, os, shutil, subprocess
base=Path(__file__).resolve().parent
media=Path('/Users/paxia/Projects/mame_disks/m40')
mame=Path('/Users/paxia/Projects/mame_latest/mame')
romsource=base.parent
for variant,filename in [('stock','m40rom-6.0'),('hd65','m40rom-6.0-hd65.bin')]:
    r=base/'roms'/variant/'m40'
    r.mkdir(parents=True,exist_ok=True)
    shutil.copy2(romsource/filename,r/'m40rom-6.0.bin')
    shutil.copy2(romsource/'9428ds-2067.bin',r/'9428ds-2067.bin')
nl='\n'
mossteps=f'203:=root{nl};262:=10;264:@? (29);266:=02;268:@? (29);270:=87;272:={nl};280:=10;282:@? (29);284:=30;286:@? (29);288:=00;290:={nl};402:=root{nl}'
bcossteps='200:=A;204:@Keypad ENTER;225:=860909;232:@Keypad ENTER;250:=120000;257:@Keypad ENTER'
cases=[(n,p,160,'') for n,p in [('ese','ESE.IMD'),('mdos30','MDOS30.IMD'),('mdosutil','MDOSUTIL.IMD'),('bcos-resident','BCOS_II_3.3_FD_ALL_RESIDENT.imd'),('bcos-config','K02733_BCOS_II_3.3_CONFIGURATOR.imd'),('gardini','Gardini_Utilities.imd')]]
cases += [('bcos-generated','BCOS_LOAD.imd',220,'90:!floppydisk1=-;93:!floppydisk1={run};97:@RETURN;130:=SPAM;135:@Keypad ENTER;155:=860909;162:@Keypad ENTER')]
cases += [(f'dcos-{c}',f'diagnostics/{c}.IMD',160,'70:=\n') for c in 'ABCDEFGHR']
cases += [('bcos-hd','m40-bcos-hd-kusa.chd',300,bcossteps),('mos-hd','m40-mos-hd.chd',480,mossteps)]
manifest={'branch':subprocess.check_output(['git','branch','--show-current'],cwd=mame,text=True).strip(),'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=mame,text=True).strip(),'binary_sha256':hashlib.sha256((mame/'m40').read_bytes()).hexdigest(),'media':{p:hashlib.sha256((media/p).read_bytes()).hexdigest() for _,p,_,_ in cases}}
(base/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(base/'mame.diff').write_text(subprocess.check_output(['git','diff'],cwd=mame,text=True))
def run(case,provisional=True):
    name,image,seconds,steps=case
    out=base/(name+('' if provisional else '-baseline'))
    out.mkdir()
    hd=image.endswith('.chd')
    shutil.copy2(media/image,out/('hd.chd' if hd else 'boot.imd'))
    # Attach the GO363 also during floppy regression, with a disposable HD.
    if not hd: shutil.copy2(media/'m40-mos-hd.chd',out/'hd.chd')
    if name=='bcos-generated':
        shutil.copy2(media/'BCOS_RUN.imd',out/'run.imd')
        steps=steps.format(run=out/'run.imd')
    env=os.environ.copy()
    env.update(OUT=str(out),SDL_MAC_BACKGROUND_APP='1',SDL_VIDEODRIVER='dummy',SHOT_STEP='20',RUN_SECONDS=str(seconds),STEPS=steps,ISL='hd' if hd else 'floppy',PROVISIONAL='1' if provisional else '0')
    cmd=[str(mame/'m40'),'m40','-bios','m40-60','-rompath',str(base/'roms'/('hd65' if hd else 'stock')),'-ram','2m','-slot5','go363','-hard1',str(out/'hd.chd'),'-nvram_directory',str(out/'nvram'),'-cfg_directory',str(out/'cfg'),'-snapshot_directory',str(out/'snap'),'-autoboot_script',str(base/'probe.lua'),'-nomouse','-video','none','-sound','none','-nothrottle','-seconds_to_run',str(seconds)]
    if not hd: cmd += ['-flop1',str(out/'boot.imd')]
    (out/'command.json').write_text(json.dumps({'argv':cmd,'environment':{k:env[k] for k in ['STEPS','ISL','PROVISIONAL','RUN_SECONDS']}},indent=2)+'\n')
    print('START '+out.name,flush=True)
    with (out/'launch.out').open('w') as log:
        rc=subprocess.call(cmd,cwd=out,env=env,stdout=log,stderr=subprocess.STDOUT)
    print(f'DONE {out.name} exit={rc}',flush=True)
    return out.name,rc
jobs=[(c,True) for c in cases]+[(c,False) for c in cases if c[0] in ('bcos-hd','mos-hd')]
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results=list(pool.map(lambda args:run(*args),jobs))
(base/'exit-status.json').write_text(json.dumps(dict(results),indent=2)+'\n')
