#!/usr/bin/env python3
from pathlib import Path
import os,shutil,subprocess,sys
base=Path(__file__).resolve().parent
repo=base.parents[2]
name,bios,secs=sys.argv[1:4]
out=base/name
out.mkdir()
shutil.copy2(repo/'re/checkpoints/mos-install/mos-hd-bootable.chd',out/'hd.chd')
(out/'hd.chd').chmod(0o644)
env=os.environ.copy()
env.update(OUT=str(out),SDL_MAC_BACKGROUND_APP='1',SDL_VIDEODRIVER='dummy',SHOT_STEP='20',RUN_SECONDS=secs)
cmd=[str(repo.parent/'mame_latest/mame/m40'),'m40','-bios',bios,'-rompath',str(base/'roms'),'-ram','2m','-slot5','go363','-hard1',str(out/'hd.chd'),'-nvram_directory',str(out/'nvram'),'-cfg_directory',str(out/'cfg'),'-snapshot_directory',str(out/'snap'),'-autoboot_script',os.getenv('AUTOSCRIPT',str(base/'observe-keys.lua')),'-nomouse','-video','none','-sound','none','-nothrottle','-seconds_to_run',secs]
(out/'command.txt').write_text(repr(cmd)+'\n')
disk=repo/'reference/Disk Images (Stefano Marinelli + others)/diagnostici l1 dcos 8.4/G.IMD'
shutil.copy2(disk,out/'diag.imd')
cmd.extend(['-flop1',str(out/'diag.imd'),'-flop2',str(out/'diag.imd')])
(out/'command.txt').write_text(repr(cmd)+'\n')
print(out,flush=True)
with (out/'launch.out').open('w') as log:
 sys.exit(subprocess.call(cmd,cwd=out,env=env,stdout=log,stderr=subprocess.STDOUT))
