import re,sys,glob,os
d=r"C:\Users\jcespedes\Documents\Code\plata\YT CHANNEL\guiones"
write = len(sys.argv)>1
for f in sorted(glob.glob(os.path.join(d,"01[4-9]-*.md"))):
    t=open(f,encoding="utf-8").read()
    nar=t.split("## Narración")[1].split("## Lista de planos")[0]
    blocks=re.split(r"\*\*\[\d\. [^\]]+\]\*\*",nar)[1:]
    blocks=[" ".join(b.split()) for b in blocks]
    counts=[len(b.split()) for b in blocks]
    total=sum(counts)
    rows=len(re.findall(r"^\| \d+ \|",t,re.M))
    nums=[int(x) for x in re.findall(r"^\| (\d+) \|",t,re.M)]
    sents=re.split(r'(?<=[.!?])["”]?\s+',"\n".join(blocks))
    longs=[s for s in sents if len(s.split())>=14]
    print(os.path.basename(f),"total",total,counts,"rows",rows,"seq",nums==list(range(1,rows+1)),"emdash",t.count("\u2014"),"long",len(longs),"/",len(sents))
    for s in longs: print("   L:",len(s.split()),s[:90])
    if write:
        t=re.sub(r"PALABRAS_CONTEO|(?<=\*\*Palabras\*\*: )\d+",str(total),t)
        open(f,"w",encoding="utf-8",newline="\n").write(t)
        open(f[:-3]+".txt","w",encoding="utf-8",newline="\n").write("\n\n".join(blocks)+"\n")
