import sys,re
seen=[];out=[]
for l in open(sys.argv[1],encoding='utf-8'):
    l=l.strip()
    if not l or '-->' in l or l.startswith(('WEBVTT','Kind:','Language:')): continue
    l=re.sub(r'<[^>]+>','',l)
    if l and (not out or out[-1]!=l): out.append(l)
print(' '.join(out))
