import sys,struct,zipfile
sys.path.insert(0,sys.argv[4])
import zstandard
def lz4(src,usize):
    out=bytearray(); i=0; n=len(src)
    while i<n:
        t=src[i]; i+=1
        l=t>>4
        if l==15:
            while True:
                b=src[i]; i+=1; l+=b
                if b!=255: break
        out+=src[i:i+l]; i+=l
        if i>=n: break
        off=src[i]|(src[i+1]<<8); i+=2
        m=t&15
        if m==15:
            while True:
                b=src[i]; i+=1; m+=b
                if b!=255: break
        m+=4
        s=len(out)-off
        if off>=m: out+=out[s:s+m]
        else:
            for k in range(m): out.append(out[s+k])
    return bytes(out)
z=zipfile.ZipFile(sys.argv[1])
name=[n for n in z.namelist() if n.endswith(sys.argv[2])][0]
d=z.read(name)
print(d[:16], len(d))
p=32; kinds={}; outf=open(sys.argv[3],'wb')
while p<len(d):
    nm=d[p:p+4]; c,u,_=struct.unpack('<III',d[p+4:p+16]); p+=16
    if c==0: body=d[p:p+u]; p+=u; k='raw'
    else:
        raw=d[p:p+c]; p+=c
        if raw[:4]==b'\x28\xb5\x2f\xfd': k="zstd"; body=zstandard.ZstdDecompressor().decompress(raw,max_output_size=u)
        else: k='lz4'; body=lz4(raw,u)
    kinds[(nm,k)]=kinds.get((nm,k),0)+1
    if body: outf.write(body+b'\n')
    if nm==b'END\0': break
print(kinds)
