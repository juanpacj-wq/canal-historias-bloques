import re,os
d=r"C:\Users\jcespedes\Documents\Code\plata\YT CHANNEL\guiones"
p=os.path.join(d,"019-the-borrower.md"); t=open(p,encoding="utf-8").read()
a="| 20 | By morning, the tea is gone. | Cocina | La taza vacía | (sin personaje) | C |\n| 21 | The cup never is. | Cocina | Nana recogiendo la taza | Tranquila | M |\n"
assert t.count(a)==1
t=t.replace(a,"| 20 | By morning, the tea is gone. The cup never is. | Cocina | Nana recogiendo la taza vacía | Tranquila | M |\n")
n=[0]
def rn(m): n[0]+=1; return "| %d |"%n[0]
head,rest=t.split("|---|---|---|---|---|---|\n",1)
tab,tail=rest.split("\n\n",1)
tab=re.sub(r"^\| \d+ \|",rn,tab,flags=re.M)
open(p,"w",encoding="utf-8",newline="\n").write(head+"|---|---|---|---|---|---|\n"+tab+"\n\n"+tail)
for f,a,b in [("017-backpack-weighs-your-worries.md",r"\bGus\b","Benji"),("014-grades-on-your-forehead.md","Pruitt","Haskell")]:
    p=os.path.join(d,f); t=open(p,encoding="utf-8").read()
    open(p,"w",encoding="utf-8",newline="\n").write(re.sub(a,b,t))
