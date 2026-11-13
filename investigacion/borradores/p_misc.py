from ed import *

def todo(num, pares):
    t = leer(num)
    for a, b in pares:
        assert a in t, (num, a)
        t = t.replace(a, b)
    escribir(num, t)

def nota(num, texto):
    """Agrega una viñeta al final de la bitácora (que es la última sección)."""
    t = leer(num).rstrip("\n")
    assert "## Bitácora de originalidad" in t, num
    escribir(num, t + "\n- **Revisión editorial de conjunto (2026-11-13)**: " + texto.strip() + "\n")

# 002
todo("002", [("Dad fell asleep standing up in the pantry.", "Dad said goodnight to the pantry."),
             ("| Dad fell asleep standing up... | Cocina, despensa | Papá de pie entre latas, dormido | Dormido | M |",
              "| Dad said goodnight to the pantry. | Cocina, despensa | Papá en pijama se despide con la mano de una repisa de latas | Zombi | M |")])
nota("002", '''se cambió "Dad fell asleep standing up in the pantry" por "Dad said
  goodnight to the pantry" porque el 011 usa el mismo chiste (la mamá que se
  duerme de pie) y allá es parte del conflicto.''')

# 003
filas("003", 31, 31, '''
The ink slid right off the paper | Cuarto | Las letras resbalan de la tarjeta | Narrador boquiabierto | C
and made a puddle on my desk. | Cuarto | Charco negro de tinta en el escritorio | (sin personaje) | C
''')
todo("003", [("He spent one on my mom, one on me the day I was born, and one on a chili dog in 1996.",
              "He spent one on my mom. One on me, the day I was born. And one on a chili dog in 1996."),
             ("| He spent one on my mom... |", "| He spent one on my mom. |"),
             ("| one on me the day I was born... |", "| One on me, the day I was born. |"),
             ("| and one on a chili dog in 1996. |", "| And one on a chili dog in 1996. |")])
nota("003", '''la frase de 22 palabras sobre los tres "I love you" del papá se
  partió en tres frases cortas (una por plano, como ya estaba en la tabla) y
  el plano de la tinta se dividió en dos. Aviso de conjunto: comparte familia
  de premisa con el 013 (cantidad limitada de por vida y un último cupo para
  alguien de la familia); no se publican en la misma semana.''')

# 006
todo("006", [("He showed up on the worst day of my life, when I dropped my lunch tray in front of the whole cafeteria.",
              "He showed up on the worst day of my life. I dropped my lunch tray in front of the whole cafeteria."),
             ("| when I dropped my lunch tray... |", "| I dropped my lunch tray... |"),
             ("thirty-one hamsters", "fifty-two hamsters")])
nota("006", '''la frase de 22 palabras del bloque 3 se partió en dos, y los
  hámsteres de los gemelos pasaron de treinta y uno a cincuenta y dos porque
  "thirty-one" se repetía en el 023 y es estructural en el 024.''')

# 007
filas("007", 63, 63, '''
He transferred back on Monday. | Colegio, pasillo | Barty entra por la puerta del colegio con su morral | Barty retador | M
We're tied, two hundred twelve to two hundred twelve. | Colegio, salón | Los dos frente a micrófonos; marcador "212 a 212" | Furiosos y felices | M
''')
todo("007", [("My worst enemy.", "My biggest rival."),
             ("next to my enemy", "next to my rival"),
             ("auditions for a new enemy", "auditions for a new rival"),
             ('"ENEMY AUDITIONS"', '"RIVAL AUDITIONS"')])
nota("007", '''el narrador y el del 010 decían los dos "My worst enemy" y los
  dos giros son de la misma familia (el enemigo era el vínculo que importaba).
  Aquí Barty pasó a ser "my biggest rival": lo suyo es competencia, no
  enemistad, y así los dos guiones no arrancan con la misma frase. Deben
  publicarse separados. El último plano doble se partió en dos.''')

# 008
filas("008", 49, 49, '''
"I was too scared to put it in," | Colegio, cafetería | Bram encogido de hombros | Vergüenza | M
"What if I broke it? | Colegio, cafetería | Bram mirando la canica en la palma de su mano | Miedo | C
''')
nota("008", '''sin cambios en la narración. Solo se partió en dos el plano de
  "I was too scared to put it in", que duraba casi cuatro segundos.''')

# 009
todo("009", [('| I said, "Good. I finally get your room." |', '| I said, "Good. |'),
             ("| (reacción) |", '| I finally get your room." |'),
             ("Okafor", "Tuttle")])
nota("009", '''el plano 21 decía "(reacción)" y no anclaba en la voz; ahora los
  planos 20 y 21 se reparten la frase del narrador. El vecino Mr. Okafor pasó
  a llamarse Mr. Tuttle porque el apellido se repetía con Winnie Okafor (014).
  Aviso de conjunto: el desenlace (pagar con un recuerdo propio) es pariente
  del final del 019; van en semanas distintas.''')

# 010
nota("010", '''sin cambios en la narración. Aviso de conjunto: giro de la
  misma familia que el 007 (el enemigo resulta ser el vínculo que importa);
  se publican separados. El apellido Vance se dejó aquí y se cambió en el 016.''')

# 012
todo("012", [("a full-grown llama", "a full-grown pony"),
             ("cargando una llama | Serio; la llama tranquila", "cargando un poni | Serio; el poni tranquilo"),
             ("gato naranja, llama (cubos beige con cuello", "gato naranja, poni (cubos beige con cuello"),
             ('la llama salía de un "burning barn"', 'el animal salía de un "burning barn"')])
nota("012", '''la llama que el papá saca del granero pasó a ser un poni porque
  ya hay una llama en el 006.''')

# 015
todo("015", [("His name is Gerald.", "His name is Stanley."),
             ("THE MEATLOAF IS MOSTLY CARROTS", "THE NUGGETS ARE MOSTLY CARROTS"),
             ("The meatloaf is still mostly carrots.", "The nuggets are still mostly carrots.")])
nota("015", '''la peluca del profesor se llamaba Gerald, igual que el muñeco de
  nieve del 013, y pasó a llamarse Stanley. El letrero de la cafetería cambió
  de "meatloaf" a "nuggets" porque el remate del 024 depende de "Great
  meatloaf, Dad".''')

# 016
todo("016", [("Principal Vance", "Principal Ruiz"), ("Rectora Vance", "Rectora Ruiz"), ("la rectora Vance", "la rectora Ruiz")])
nota("016", '''la rectora Vance pasó a llamarse Ruiz porque el apellido se
  repetía con Birdie Vance (010).''')

# 018
todo("018", [("He yelled it eleven times.", "He yelled it seven times.")])
nota("018", '''un solo retoque: "eleven times" pasó a "seven times" porque el
  número once aparecía en once de los 25 guiones. Aviso de conjunto: es una de
  las historias con pérdida familiar (la mamá murió); no debe publicarse junto
  al 019 ni al 021.''')

# 020
filas("020", 56, 56, '''
There was a card on top. | Calle de noche | Tarjeta amarillenta sobre el pie | (sin personaje) | C
WELCOME TO TOWN, | Calle de noche | La tarjeta de cerca: WELCOME TO TOWN | (sin personaje) | C
in handwriting from sixty-one years ago. | Calle de noche | Letra antigua y tinta desteñida; una telaraña en la esquina | (sin personaje) | C
''')
todo("020", [("| Nobody knows what... sixty-one years. |", "| Nobody knows what, because nobody has opened in sixty-one years. |"),
             ("| Four months later... Otis sleeps in the bathtub. |", "| Four months later, my little brother Otis sleeps in the bathtub. |")])
nota("020", '''sin cambios en la narración. En la tabla, dos planos tenían
  puntos suspensivos en la mitad de la frase y no anclaban en la voz (el 5 y
  el 25); se escribieron completos. El plano de la tarjeta se partió en tres.''')

# 021
filas("021", 56, 56, '''
I dug the green cape out of her hall closet | Sala | Narrador saca la capa de un armario | Serio | M
and tied it on. | Sala | Manos amarrando la capa al cuello | Decidido | C
''')
filas("021", 17, 17, '''
When I was seven, I wore a green dinosaur cape | Patio (recuerdo) | Niño con capa verde de púas, corriendo | Rugido feliz | M
for a whole year. | Patio (recuerdo) | El mismo niño con la capa bajo la lluvia, en la nieve y en la piscina | Rugido feliz | G
''')
filas("021", 6, 6, '''
You go downstairs and there it is, | Sótano | Personaje baja la escalera y ve una repisa | Feliz | M
on a shelf with a paper tag. | Sótano | Llaves en la repisa con una etiqueta de papel | (sin personaje) | C
''')
nota("021", '''sin cambios en la narración; se partieron tres planos que
  duraban más de 3,5 segundos. Aviso de conjunto: comparte familia con el 019
  (una abuela que deja de reconocer a su nieto y lo reconoce al final). Los
  dos son de lo mejor del lote y se dejaron, pero van en tandas de producción
  distintas y con más de diez días de separación al publicar.''')

# 023
todo("023", [("Abernathy", "Garza"), ("thirty-one cats", "twenty-three cats"), ("Thirty-one cats", "Twenty-three cats"),
             ("31 gatos", "23 gatos"), ("repetido 31 veces", "repetido 23 veces")])
nota("023", '''la señora Abernathy pasó a llamarse Garza (el apellido estaba
  en el 011) y sus gatos bajaron de treinta y uno a veintitrés porque el
  número se repetía en el 006 y es estructural en el 024.''')

# 024
todo("024", [("Juno", "Tess"), ("JUNO", "TESS"),
             ("Plus six tubas.", "Plus the whole drum line."),
             ("No banner. No tubas.", "No banner. No drums."),
             ("Seis músicos con tubas en fila | Cachetes inflados", "Fila de tambores del colegio tocando | Concentrados"),
             ("seis tubas", "seis tambores"), ("notas de tuba", "golpes de tambor")])
nota("024", '''Juno pasó a llamarse Tess porque quedaba muy cerca de Juniper
  (004), que también es el interés romántico. Las seis tubas de la pancarta
  pasaron a ser la banda de tambores porque el 016 ya tiene una tuba que se
  llena de granizo.''')

# 022: duración de la introducción
todo("022", [("cerca de 90 segundos", "cerca de 101 segundos")])
