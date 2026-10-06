#!/usr/bin/env python3
"""Rerun a saved case, changing only explicitly requested test settings."""
import json, os, shutil, subprocess, sys
from pathlib import Path
base=Path(__file__).resolve().parent
source,name,seconds,mode=sys.argv[1:]
out=base/name
out.mkdir()
data=json.loads((base/source/'command.json').read_text())
cmd=[a.replace(str(base/source),str(out)) for a in data['argv']]
for filename in ('boot.imd','hd.chd','run.imd'):
    p=base/source/filename
    if p.exists(): shutil.copy2(p,out/filename)
cmd[cmd.index('-seconds_to_run')+1]=seconds
if mode=='no-go':
    i=cmd.index('-hard1');del cmd[i:i+2]
    cmd[cmd.index('-slot5')+1]=''
env=os.environ.copy()
env.update(data['environment'])
env.update(OUT=str(out),SDL_MAC_BACKGROUND_APP='1',SDL_VIDEODRIVER='dummy',SHOT_STEP='20',RUN_SECONDS=seconds,PROVISIONAL='1' if mode in ('probe','go-only') else '0',CLEAR_TIMER='0' if mode=='go-only' else '1')
(out/'command.json').write_text(json.dumps({'argv':cmd,'environment':{k:env[k] for k in ['STEPS','ISL','PROVISIONAL','RUN_SECONDS','CLEAR_TIMER']}},indent=2)+'\n')
with (out/'launch.out').open('w') as log:
    sys.exit(subprocess.call(cmd,cwd=out,env=env,stdout=log,stderr=subprocess.STDOUT))
