#!/usr/bin/env python3
"""usage: mksteps.py START 'cmd1' [GAP] 'cmd2' ... -> STEPS string for run_keys.lua.
'/' is sent as the '? (29)' key; each command ends with Enter; default gap 12 s."""
import sys
t=float(sys.argv[1]); out=[]; gap=12
for a in sys.argv[2:]:
    if a.isdigit(): gap=int(a); continue
    parts=a.split('/')
    for i,p in enumerate(parts):
        if i: out.append('%g:@? (29)'%t); t+=1.5
        if p: out.append('%g:=%s'%(t,p)); t+=1.5
    out.append('%g:=\n'%t); t+=gap
out.append('%g:='%t); print(';'.join(out),end='')
print(' END=%d'%t,file=sys.stderr)
