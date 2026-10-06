from pathlib import Path
from PIL import Image
import hashlib,json
base=Path(__file__).resolve().parent
expected=base.parents[2]/'scripts/expected'
results={}
for name in ['bcos-hd','mos-hd','bcos-hd-baseline','mos-hd-baseline']:
    shots=sorted((base/name).glob('s_*.png'))
    if not shots: continue
    a=Image.open(shots[-1]).convert('RGB')
    b=Image.open(expected/('hd-bcos.png' if name.startswith('bcos') else 'hd-mos.png')).convert('RGB')
    results[name]={'screenshot':str(shots[-1].relative_to(base)),'matches_reference':a.size==b.size and a.tobytes()==b.tobytes()}
manifest=json.loads((base/'manifest.json').read_text())
media=Path('/Users/paxia/Projects/mame_disks/m40')
results['original_media_unchanged']=all(hashlib.sha256((media/p).read_bytes()).hexdigest()==h for p,h in manifest['media'].items())
(base/'verification.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
