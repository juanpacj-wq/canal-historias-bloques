import re,os
d=r"C:\Users\jcespedes\Documents\Code\plata\YT CHANNEL\guiones"
def sub(t,a,b):
    assert t.count(a)==1,(a,t.count(a)); return t.replace(a,b)
p=os.path.join(d,"019-the-borrower.md"); t=open(p,encoding="utf-8").read()
t=sub(t,"| 15 | Small for small. | Cocina | Una cuchara a un lado, un botón al otro | (sin personaje) | C |\n| 16 | Big for big. | Sala | Un televisor a un lado, una bicicleta vieja al otro | (sin personaje) | M |\n",
"| 15 | Small for small. Big for big. | Cocina | Una cuchara frente a un botón; detrás, un televisor frente a una bicicleta vieja | (sin personaje) | M |\n")
t=sub(t,"| 41 | My savings jar, two hundred and twelve dollars. | Cocina de noche | Frasco de vidrio lleno de billetes y monedas | (sin personaje) | C |\n| 42 | My trophies. The TV. | Cocina de noche | Tres trofeos y el televisor en el piso | (sin personaje) | M |\n",
"| 41 | My savings jar, two hundred and twelve dollars. My trophies. The TV. | Cocina de noche | Frasco de vidrio lleno de billetes, tres trofeos y el televisor en el piso | (sin personaje) | M |\n")
t=sub(t,"| 65 | In the morning, the table was empty. | Cocina | Mesa vacía con sol de la mañana | (sin personaje) | G |\n| 66 | First time ever. | Cocina | La narradora mirando debajo de la mesa | Confundida | M |\n",
"| 65 | In the morning, the table was empty. First time ever. | Cocina | Mesa vacía con sol de la mañana; la narradora mirando debajo | Confundida | G |\n")
t=sub(t,"| 75 | I don't know what used to sit there. | Cuarto | La narradora tocando el cuadrado con un dedo | Desconcertada | C |\n",
"| 75 | I don't know what used to sit there. | Cuarto | La narradora tocando el cuadrado con un dedo | Desconcertada | C |\n| 76 | Now I know how Nana feels. | Sala | La narradora sentada junto a Nana, las dos mirando el mismo cajón vacío | Ternura | M |\n| 77 | It still takes one thing every night. | Cocina de noche | La puerta de la despensa abierta una rendija; la taza llena al lado | (sin personaje) | M |\n| 78 | But last night, for the first time, it washed the cup. | Cocina | La taza de flores limpia, boca abajo sobre un trapo, brillando | (sin personaje) | C |\n")
i=t.index("- **Nota de planos**"); j=t.index("## Alternativas")
t=t[:i].rstrip("\n")+"\n\n"+t[j:]
t=sub(t,"I just had to offer something big enough.\n","Dad says by summer, she might lose his name too. I just had to offer something big enough.\n")
t=sub(t,"| 30 | I just had to offer something big enough. |","| 30 | Dad says by summer, she might lose his name too. | Sala | Papá mirando a Nana desde la puerta | Preocupado | M |\n| 31 | I just had to offer something big enough. |")
# renumber
n=[0]
def rn(m): n[0]+=1; return "| %d |"%n[0]
head,rest=t.split("|---|---|---|---|---|---|\n",1)
tab,tail=rest.split("\n\n",1)
tab=re.sub(r"^\| \d+ \|",rn,tab,flags=re.M)
t=head+"|---|---|---|---|---|---|\n"+tab+"\n\n"+tail
open(p,"w",encoding="utf-8",newline="\n").write(t)
p=os.path.join(d,"015-rumors-become-graffiti.md"); t=open(p,encoding="utf-8").read()
t=sub(t,"In this school, every rumor paints itself on the walls, and it only comes off when somebody says the truth out loud.","In this school, rumors paint themselves on the walls, and only come off when somebody says the truth out loud.")
t=sub(t,"| 1 | In this school, every rumor paints itself... |","| 1 | In this school, rumors paint themselves on the walls... |")
t=sub(t,"| 2 | and it only comes off when","| 2 | and only come off when")
open(p,"w",encoding="utf-8",newline="\n").write(t)
