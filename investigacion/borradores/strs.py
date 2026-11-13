import re,sys
d=open(sys.argv[1],'rb').read()
out=open(sys.argv[2],'w',encoding='utf-8')
for m in re.finditer(rb'[\x20-\x7e\t]{%d,}'%int(sys.argv[3]),d):
    out.write(m.group().decode('ascii')+'\n')
for m in re.finditer(rb'(?:[\x20-\x7e]\x00){%d,}'%int(sys.argv[3]),d):
    out.write('U:'+m.group().decode('utf-16le')+'\n')
