from pathlib import Path
from PIL import Image
import hashlib,json
base=Path(__file__).resolve().parent
previous=base.parent/'regression-go363-20261006'
expected=base.parents[2]/'scripts/expected'
def final(name): return sorted((base/name).glob('s_*.png'))[-1]
def same(a,b,box=None):
    a,b=(Image.open(p).convert('RGB') for p in (a,b))
    if box: a,b=a.crop(box),b.crop(box)
    return a.size==b.size and a.tobytes()==b.tobytes()
results={}
for name in ('bcos-hd','mos-hd','a5-mos-hd'):
    results[name]=same(final(name),expected/('hd-bcos.png' if name=='bcos-hd' else 'hd-mos.png'))
for name in ('ese','mdos30','mdosutil'):
    results[name]=same(final(name),previous/'ese/s_0160.0.png',(0,408,64,425))
for name in ('bcos-resident','bcos-config','bcos-generated','gardini'):
    results[name]=same(final(name),sorted((previous/name).glob('s_*.png'))[-1],(0,0,640,425))
for c in 'ABCDEFGHR':
    results['dcos-'+c]=same(final('dcos-'+c),previous/'dcos-A-monitor/s_0160.0.png',(0,325,400,400))
manifest=json.loads((base/'manifest.json').read_text())
media=Path('/Users/paxia/Projects/mame_disks/m40')
results['source_media_unchanged']=all(hashlib.sha256((media/p).read_bytes()).hexdigest()==h for p,h in manifest['media'].items())
results['no_lua_interventions']=all(not p.read_text() for p in base.glob('*/interventions.log'))
(base/'verification.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
