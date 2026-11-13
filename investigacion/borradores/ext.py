import sys,re,glob,os
out=sys.argv[1]
files=sorted(glob.glob('[0-9][0-9][0-9]-*.md'))[1:]
for i in range(0,len(files),4):
    buf=[]
    for f in files[i:i+4]:
        t=open(f,encoding='utf-8').read()
        end=re.search(r'\n## (Qué hay que construir|Alternativas|Bitácora)',t)
        t=t[:end.start()] if end else t
        lines=[]
        for l in t.splitlines():
            if l.startswith('|') and re.match(r'\|\s*\d+\s*\|',l):
                c=[x.strip() for x in l.strip('|').split('|')]
                l=' | '.join([c[0],c[1],c[3] if len(c)>3 else '',c[4] if len(c)>4 else ''])
            lines.append(l)
        buf.append('#### FILE '+f+'\n'+'\n'.join(lines))
    open(os.path.join(out,'g%02d.txt'%(i//4)),'w',encoding='utf-8').write('\n\n'.join(buf))
