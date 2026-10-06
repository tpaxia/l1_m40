import concurrent.futures, subprocess
from pathlib import Path
base=Path(__file__).resolve().parent
def run(c):
    rc=subprocess.call(['python3',str(base/'recheck.py'),'dcos-'+c,'dcos-'+c+'-monitor','160','probe'])
    print(c,rc,flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    list(pool.map(run,'ABCDEFGH'))
