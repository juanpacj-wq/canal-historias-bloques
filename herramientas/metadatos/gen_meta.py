# -*- coding: utf-8 -*-
"""Genera videos/NNN-slug/metadatos/publicacion.txt, videos/CALENDARIO.md y videos/LISTAS.md."""
import sys
from pathlib import Path

RAIZ = Path(sys.argv[1])
CANAL = "Almostville"

LISTAS = {
    "F": ("In This Town: Friendship", "#friendship"),
    "H": ("In This Town: Family", "#family"),
    "S": ("In This Town: School", "#school"),
    "L": ("In This Town: Love", "#love"),
    "K": ("In This Town: Spooky", "#spooky"),
    "C": ("In This Town: Funny", "#funny"),
}

# dia: (numero, tema, tono) segun guiones/INDICE.md
ORDEN = [
    ("023", "Comedia", "Cómico y tierno"),
    ("020", "Terror suave", "Emotivo y cálido"),
    ("017", "Familia", "Emotivo"),
    ("014", "Colegio", "Cómico"),
    ("003", "Familia", "Agridulce"),
    ("008", "Amistad", "Emotivo"),
    ("018", "Terror suave (pérdida)", "Emotivo"),
    ("004", "Amor", "Cómico"),
    ("009", "Familia", "Agridulce"),
    ("016", "Colegio", "Cómico"),
    ("006", "Amistad", "Agridulce"),
    ("002", "Familia", "Emotivo"),
    ("007", "Amistad", "Cómico"),
    ("021", "Terror suave (abuela)", "Emotivo"),
    ("024", "Comedia, amor", "Agridulce"),
    ("001", "Amistad", "Emotivo"),
    ("025", "Terror suave (mamá lejos)", "Emotivo"),
    ("012", "Familia", "Cómico"),
    ("015", "Colegio", "Redención"),
    ("013", "Familia (abuela)", "Emotivo"),
    ("010", "Amistad", "Cómico"),
    ("011", "Familia", "Emotivo"),
    ("005", "Amor", "Emotivo"),
    ("022", "Comedia", "Cómico"),
    ("019", "Terror suave (abuela)", "Agridulce"),
]
DIA = {n: i + 1 for i, (n, _, _) in enumerate(ORDEN)}

# Cada video: titulo, alt objeto, alt regla, lista, descripcion, comentario, plano, que se ve,
# plano alterno, relacionado, titulo es, descripcion es, notas extra
V = {}


def v(num, titulo, alt_obj, alt_regla, lista, desc, comentario, plano, se_ve, alterno, rel, es_t, es_d, extra=None, desc_extra=None):
    V[num] = dict(titulo=titulo, alt_obj=alt_obj, alt_regla=alt_regla, lista=lista, desc=desc,
                  comentario=comentario, plano=plano, se_ve=se_ve, alterno=alterno, rel=rel,
                  es_t=es_t, es_d=es_d, extra=extra or [], desc_extra=desc_extra)


v("001", "In This World, Friendships Have a Battery", "The Battery", "Every Friendship Runs on a Battery", "F",
  "In this world, every friendship has a battery that everybody can see. Ours was at two percent, and I thought I knew whose fault that was.",
  "Which friendship of yours is at 2% right now?",
  24, "la barra de batería en rojo, en 2 %, con la cara de susto del narrador en el pasillo del colegio",
  "plano 14 (el narrador y Theo con la barra en 98 entre los dos)",
  "008", "TODA AMISTAD TIENE BATERÍA",
  "En este mundo cada amistad tiene una batería que todos pueden ver, y la nuestra iba en dos por ciento.")

v("002", "In This World, Your Heartbeat Plays Out Loud as Music", "The Quiet Heart", "Your Heartbeat Plays Out Loud as Music", "H",
  "In this world, your heartbeat plays out loud as music and the whole street can hear it. Mine doesn't play anything, and then my baby sister was born.",
  "What instrument would your heart play? Be honest.",
  11, "el narrador solo, sin ninguna nota saliendo del pecho; elige el cuadro en que todavía se ven al fondo las notas de colores del pueblo",
  "plano 1 (personaje de frente con notas de colores saliendo del pecho)",
  "017", "NADIE TIENE UN CORAZÓN CALLADO",
  "En este mundo el corazón de cada persona suena como música en voz alta; el mío no suena, y entonces nació mi hermanita.")

v("003", "In This World, You Only Get Three \"I Love Yous\"", "Three Lights", "You Only Get Three \"I Love Yous\"", "H",
  "In this world, you can only say \"I love you\" three times in your whole life. I had one left, and my dad was leaving on the six a.m. bus.",
  "You only get three. Who gets your first one?",
  15, "la muñeca del narrador con una luz encendida y dos apagadas, y su cara de preocupación",
  "plano 2 (muñeca con las tres luces amarillas, sin personaje)",
  "012", "SOLO TIENES TRES \"TE AMO\"",
  "En este mundo solo puedes decir \"te amo\" tres veces en la vida; a mí me quedaba una y mi papá se iba en el bus de las seis.")

v("004", "In This World, Your Shadow Walks Toward Who You Like", "The Yellow Umbrella", "Your Shadow Walks Toward Who You Like", "L",
  "In this world, your shadow gets up and walks toward whoever you like, and you can't call it back. Mine picked the Sunset Fair, in front of three hundred people.",
  "Be honest: where is your shadow parked right now? Food counts.",
  1, "un niño quieto con cara de susto mientras su sombra se despega del piso y camina hacia una niña",
  "plano 33 (el narrador con nueve sombras en abanico)",
  "024", "TU SOMBRA DELATA QUIÉN TE GUSTA",
  "En este mundo tu sombra se levanta y camina hacia la persona que te gusta, y no hay forma de llamarla de vuelta.")

v("005", "In This Town, Breakups Make It Snow", "The Snow Cloud", "Every Breakup Makes It Snow", "L",
  "In this town, every breakup makes it snow, but only over the house of whoever got dumped. It has been snowing on our house for three months.",
  "How many inches would it be snowing on your house right now?",
  14, "la casa del narrador bajo su propia nube de nieve, los vecinos en camiseta y el narrador con la pala",
  "plano 19 (medio techo con una montaña de nieve y la otra mitad con pasto)",
  "024", "CADA RUPTURA HACE NEVAR",
  "En este pueblo cada ruptura hace nevar solo sobre la casa de la persona a la que dejaron, y sobre la mía lleva tres meses nevando.")

v("006", "In This Town, Inside Jokes Become Pets", "Long Distance", "Every Inside Joke Becomes a Pet", "F",
  "In this town, every inside joke turns into a pet, and it lives as long as you both keep laughing. Then my best friend moved nine hundred miles away.",
  "What would your best inside joke look like as a pet? Describe it, no context.",
  22, "el pato con una sola media que aparece entre los dos charcos de sopa, con los dos amigos riendo",
  "plano 14 (el narrador y Ozzie rodeados de catorce animales raros)",
  "008", "CADA CHISTE INTERNO ES UNA MASCOTA",
  "En este pueblo cada chiste interno se convierte en una mascota que vive mientras los dos se sigan riendo, y mi mejor amigo se mudó lejos.")

v("007", "In This World, Everyone Can See Who You Miss", "Foggy Barty", "Everyone Can See Who You Miss", "F",
  "In this world, the person you miss walks right next to you as a gray silhouette, and everyone can see it. Mine is shaped like my biggest rival.",
  "Whose fog would be walking next to you right now?",
  12, "el narrador molesto y, a su lado, la silueta gris y bajita con gafas redondas",
  "plano 1 (personaje caminando con una silueta gris transparente al lado)",
  "010", "TODOS VEN A QUIÉN EXTRAÑAS",
  "En este mundo la silueta de la persona que extrañas camina a tu lado y todos la ven; la mía tiene la forma de mi peor rival.")

v("008", "In This World, You Can Lend Your Courage", "The Orange Marble", "Lend Your Courage and You Have None", "F",
  "In this world, you can lend your courage to a friend, but you have none until they give it back. Mine has been gone for three weeks.",
  "Who would you lend your courage to, and what is the first thing you'd be scared of without it?",
  1, "un niño le entrega a otro la canica naranja que brilla; uno feliz y el otro nervioso",
  "plano 5 (el amigo en pose de héroe y el que prestó abrazado a una banca)",
  "001", "NO PRESTES TU VALENTÍA",
  "En este mundo puedes prestarle tu valentía a un amigo, pero te quedas sin nada hasta que te la devuelva.")

v("009", "In This Town, Apologies Are Paid in Memories", "The Blanket Fort", "Saying Sorry Costs You a Happy Memory", "H",
  "In this town, saying sorry costs you one happy memory, and the worse you messed up, the better the memory. I'm fourteen and I have never said it.",
  "Which happy memory would you never give up, no matter how big the apology?",
  3, "la foto luminosa saliendo de una oreja, con la cara de sorpresa del personaje",
  "plano 1 (dos vecinos frente a frente con una foto luminosa flotando entre ellos)",
  "017", "PEDIR PERDÓN CUESTA UN RECUERDO",
  "En este pueblo pedir perdón de verdad te cuesta un recuerdo feliz, y entre peor la falta, mejor el recuerdo que pierdes.")

v("010", "In This World, Your Best Friend Is Chosen by Lottery", "The Green Crayon", "A Lottery Picks Your Best Friend", "F",
  "In this world, a lottery picks your best friend when you turn ten, and you're stuck with them by law. Mine picked my worst enemy.",
  "A lottery picks your best friend and you owe them every Saturday, two to four. What is the first thing you two do?",
  2, "dos niños unidos por una cinta que dice BEST FRIENDS, con cara de resignación",
  "plano 17 (la narradora y Birdie en los extremos de la banca, mirando a lados opuestos)",
  "007", "NADIE ELIGE A SU MEJOR AMIGO",
  "En este mundo un sorteo te asigna a tu mejor amigo a los diez años y es obligatorio por ley; a mí me tocó mi peor enemiga.")

v("011", "In This World, Parents Can Pause Their Kids", "The Clicker", "Every Parent Gets Ten Pauses", "H",
  "In this world, every parent gets ten pauses, and one click freezes their kid for five whole minutes. My mom never used a single one.",
  "Ten pauses for your whole childhood. Which moment would your parents have used the first one on?",
  2, "un niño congelado a mitad de un salto, con tono azulado; elige el cuadro en que todavía se ve el control rojo de la mamá",
  "plano 6 (los gemelos congelados en el aire con plumas flotando)",
  "012", "TUS PAPÁS TE PUEDEN PAUSAR",
  "En este mundo cada mamá y cada papá tiene diez pausas que congelan a su hijo cinco minutos; mi mamá nunca usó ninguna.")

v("012", "In This World, You Inherit Your Parents' Fears", "The 3:15 Text", "You Inherit Your Dad's Biggest Fear", "H",
  "In this world, on your thirteenth birthday, you inherit your dad's biggest fear, and he loses it. My dad is a firefighter, so I wasn't worried.",
  "What fear would your mom or dad hand down to you at midnight?",
  2, "la nubecita gris que sale del pecho del papá y entra en el niño, con cara de susto, junto a la torta del número 13",
  "plano 10 (el hijo abrazado a la escalera del camarote, a un peldaño del piso)",
  "003", "HEREDAS EL MIEDO DE TU PAPÁ",
  "En este mundo, al cumplir trece años heredas el mayor miedo de tu papá y él lo pierde; el mío es bombero, así que no me preocupé.",
  extra=["Advertencia de guiones/INDICE.md: ni llamas ni heridos en pantalla; revisa que el cuadro de portada tampoco los tenga."])

v("013", "In This World, Hugs Are Counted", "The Last Hug", "You Are Born With One Thousand Hugs", "H",
  "In this world, you're born with exactly one thousand hugs, and there's a counter on your wrist. I have four left, and my grandma has never opened her arms.",
  "One thousand hugs for your whole life. Who is worth your very last one?",
  19, "la muñeca del narrador con el contador en 4, en rojo, y su cara de susto",
  "plano 4 (el que abrió los brazos mira su número en rojo; el otro, intacto)",
  "003", "SOLO TIENES MIL ABRAZOS",
  "En este mundo naces con mil abrazos exactos y un contador en la muñeca; a mí me quedan cuatro y mi abuela nunca ha abierto los brazos.",
  extra=["Advertencia de guiones/INDICE.md: no pongas en pantalla la cuenta de cuántas mañanas le quedan a la abuela; evita como portada los planos 54 y 64 (su contador bajando)."])

v("014", "In This School, Your Grades Appear on Your Forehead", "The Question Mark", "Your Grade Glows on Your Forehead", "S",
  "In this school, your grade glows on your forehead, and no hat in the world can cover it. The smartest kid in the building has a question mark.",
  "What would your forehead say right now: a letter, or a question mark?",
  15, "el signo de pregunta blanco brillando en la frente de Winnie, seria",
  "plano 9 (el narrador de frente con su C naranja)",
  "016", "TU NOTA SALE EN LA FRENTE",
  "En este colegio tu nota brilla en la frente y nada la tapa; la más inteligente del colegio tiene un signo de pregunta.",
  extra=["Advertencia de guiones/INDICE.md: no uses de portada el plano 2 (el niño del gorro con la F); la portada no se ríe de una nota baja."])

v("015", "In This School, Rumors Become Graffiti", "The Gym Wall", "Rumors Paint Themselves on the Walls", "S",
  "In this school, rumors paint themselves on the walls, and they only come off when somebody says the truth out loud. I started one.",
  "What is the nicest rumor somebody could paint over your locker?",
  23, "el narrador pequeño, con susto, frente a una letra roja más alta que él en la pared del gimnasio",
  "plano 3 (la pared con MR. PELLMAN WEARS A WIG en verde)",
  "014", "LOS CHISMES SE PINTAN SOLOS",
  "En este colegio cada chisme se pinta solo en las paredes y solo se borra cuando alguien dice la verdad en voz alta; yo inventé uno.",
  extra=["Advertencia de guiones/INDICE.md: evita como portada el plano 24 (Soren restregando la pared); la víctima no se muestra humillada."])

v("016", "In This School, the Quietest Kid Controls the Weather", "The Weather Kid", "The Quietest Kid Controls the Weather", "S",
  "In this school, the weather over the building follows the mood of the kid who talks the least. I'm the kid who talks the most, and I said I'd fix it.",
  "If the sky followed your mood today, what would the forecast be?",
  2, "el niño callado junto a la ventana y la nube del colegio moviéndose con él",
  "plano 12 (todo el salón volteado hacia Tobin, él encogido)",
  "014", "EL MÁS CALLADO CONTROLA EL CLIMA",
  "En este colegio el clima sigue el ánimo del niño que menos habla; yo soy el que más habla y prometí arreglarlo.")

v("017", "In This World, Your Backpack Weighs Your Worries", "The Kite", "Your Backpack Weighs Your Worries", "H",
  "In this world, your backpack weighs exactly as much as your worries, and emptying it doesn't help. Mine floats, and my little brother can't lift his.",
  "How heavy is your backpack today, and whose would you take one worry from?",
  18, "Benji arrastrando el morral con la sonrisa enorme, el sudor y el surco que deja en el pasto",
  "plano 11 (el morral del narrador flotando sobre él)",
  "009", "TU MOCHILA PESA TUS PREOCUPACIONES",
  "En este mundo tu mochila pesa exactamente lo que pesan tus preocupaciones; la mía flota y mi hermanito no puede levantar la suya.",
  extra=["Advertencia de guiones/INDICE.md: Benji no debe verse desatendido; en el cuadro de portada va sonriendo."])

v("018", "The Echo", "The Notch", "In This Town, the Echo Says What You Really Think", "K",
  "In this town, the echo doesn't repeat what you say. It says what you really think, and lately it has been talking at two in the morning.",
  "If you yelled \"I'm fine\" into the Notch, what would it say back?",
  2, "el niño que grita HELLO frente a la grieta y el texto distinto que vuelve en letras pálidas, con su cara de susto",
  "plano 1 (el pueblo bajo los dos cerros negros con la grieta en medio)",
  "020", "EL ECO DICE LO QUE PIENSAS",
  "En este pueblo el eco no repite lo que gritas: dice lo que de verdad piensas, y últimamente habla a las dos de la mañana.",
  extra=["El título principal es de la familia A (objeto). El título alterno de regla conserva el arranque \"In This Town\" porque es la forma que docs/08 recomienda probar en un canal pequeño.",
         "Advertencia de guiones/INDICE.md: nada de enfermedad ni muerte en pantalla, y sin música de terror en la escena del papá."])

v("019", "The Night Trade", "The Pantry Door", "In This Town, Something Takes One Thing Every Night", "K",
  "In this town, something takes one thing from your house every night, and leaves one thing you lost years ago. My Nana lost my name, so I made it an offer.",
  "It takes one thing and leaves one thing you lost years ago. What do you hope shows up on your kitchen table?",
  57, "la narradora de espaldas a la despensa, con llanto contenido, y detrás la puerta abierta una rendija, negra por dentro",
  "plano 52 (la puerta de la despensa abriéndose una rendija, sin personaje)",
  "021", "CADA NOCHE SE LLEVA UNA COSA",
  "En este pueblo algo se lleva una cosa de tu casa cada noche y deja una que perdiste hace años; mi abuela perdió mi nombre y le hice una oferta.",
  extra=["El título principal es de la familia A (objeto). El título alterno de regla conserva el arranque \"In This Town\" porque es la forma que docs/08 recomienda probar en un canal pequeño.",
         "\"The Night Trade\" coincide con el título de una novela de Barry Eisler (ver la bitácora del guion); si prefieres evitar el homónimo, usa el título alterno de regla.",
         "Advertencia de guiones/INDICE.md: la criatura nunca se ve y la abuela se trata con ternura, sin efectos cómicos."])

v("020", "In This Town, Nobody Opens After the Third Knock", "The Third Knock", "Nobody Opens After the Third Knock", "K",
  "In this town, nobody opens the door after the third knock. Two knocks is a neighbor. Three is something else, and it picked our house.",
  "Three knocks at 9:14. Do you open the door? Be honest.",
  2, "la familia quieta, con susto, mirando la puerta cerrada",
  "plano 24 (el narrador con la oreja pegada a la puerta)",
  "018", "NADIE ABRE AL TERCER GOLPE",
  "En este pueblo nadie abre la puerta después del tercer golpe: dos golpes es un vecino, tres es otra cosa, y escogió nuestra casa.",
  extra=["No uses de portada los planos 51 a 63 (la figura del impermeable): destripan el final."])

v("021", "In This World, Forgotten Things Go to the Basement", "The Bottom Step", "Everything You Forget Ends Up in Your Basement", "K",
  "In this world, everything you forget ends up in your basement, on a shelf, with a paper tag. I went down to my grandma's, and somebody was sitting on the bottom step.",
  "What is sitting on a shelf in your basement right now, with a paper tag on it?",
  6, "un personaje que baja la escalera del sótano y encuentra la repisa de objetos con etiquetas de papel",
  "plano 62 (el narrador con la capa verde rugiendo; guiones/INDICE.md lo señala como imagen de miniatura, aunque no muestra la regla)",
  "018", "TODO LO OLVIDADO BAJA AL SÓTANO",
  "En este mundo todo lo que olvidas aparece en tu sótano con una etiqueta de papel; bajé al de mi abuela y había alguien sentado en el último escalón.",
  extra=["Advertencia de guiones/INDICE.md: la abuela se trata con ternura, sin efectos cómicos."])

v("022", "In This World, Excuses Become True", "No Take-Backs", "Every Excuse You Say Comes True", "C",
  "In this world, every excuse you say out loud comes true, instantly, and there are no take-backs. I have been dodging one pool party for a very long time.",
  "What excuse do you use the most, and what would happen if it came true?",
  16, "la Cosa, una bola morada con dos ojitos, y el narrador sin palabras a su lado",
  "plano 10 (el mapache con chaleco y silbato dirigiendo el tráfico)",
  "023", "TODA EXCUSA SE VUELVE VERDAD",
  "En este mundo toda excusa que dices en voz alta se vuelve verdad al instante y no hay devoluciones.",
  extra=["Advertencia de guiones/INDICE.md: si la portada sale de la piscina, que haya un salvavidas en el cuadro y el agua por las rodillas."])

v("023", "In This World, Pets Write Reviews of Their Owners", "One Star", "Every Pet Reviews Its Owner", "C",
  "In this world, every pet writes a review of its owner, and it gets posted on your front door. My cat has given me one star eight Saturdays in a row.",
  "What would your pet's review of you say? Stars included.",
  17, "la puerta del narrador con ocho hojas de una estrella y él, derrotado, al lado",
  "plano 1 (el gato con un lápiz frente a una hoja)",
  "022", "TU MASCOTA TE PONE ESTRELLAS",
  "En este mundo tu mascota escribe cada sábado una reseña sobre ti y queda pegada en la puerta de tu casa; mi gato me ha puesto una estrella ocho sábados seguidos.")

v("024", "In This Town, You Can Only Lie on Tuesdays", "The Tuesday List", "You Can Only Lie on Tuesdays", "L",
  "In this town, you can only lie on Tuesdays, so nobody believes one word you say that day. I had one day left to tell her, and it was a Tuesday.",
  "What is number one on your Tuesday List?",
  1, "el calendario gigante de la plaza con el martes en rojo y la gente celebrando",
  "plano 2 (el vecino que se tapa la boca y aun así se le escapa un globo de texto)",
  "004", "SOLO SE MIENTE LOS MARTES",
  "En este pueblo solo se puede mentir los martes y ese día nadie le cree a nadie; me quedaba un día para decírselo, y era martes.")

v("025", "The Tunda", "The Wooden Foot", "In This Town, You Check Your Mother's Feet First", "K",
  "In this town, when your mother calls you from the trees, you look at her feet before you answer. My little brother is six, and he didn't look down.",
  "Who in your family makes a sound nobody could ever copy? A laugh, a whistle, a sneeze.",
  8, "un pie descalzo y un pie de madera tallada asomando bajo la falda",
  "plano 2 (el niño que baja la mirada antes de dar un paso)",
  "018", "NO CONTESTES SIN MIRARLE LOS PIES",
  "En este pueblo, cuando tu mamá te llama desde los árboles, le miras los pies antes de contestar: lo que vive en el manglar copia caras y voces, pero un pie siempre le sale de madera.",
  extra=["El título principal es de la familia A (objeto). El título alterno de regla conserva el arranque \"In This Town\" porque es la forma que docs/08 recomienda probar en un canal pequeño.",
         "Advertencia de guiones/INDICE.md: no publiques sin la revisión cultural (que lo vea alguien del Pacífico colombiano). El origen de la leyenda va nombrado en la descripción; no lo quites.",
         "La portada no debe mostrar rasgos exagerados ni la cara de la figura; por eso se propone el plano de los pies."],
  desc_extra="Inspired by the legend of La Tunda, told by Afro-descendant communities of the Pacific coast of Colombia and Ecuador.")

assert len(V) == 25 and sorted(V) == ["%03d" % i for i in range(1, 26)]

IA = ("Nota (docs/07, sección 3.3): animación de ficción claramente irreal y guion asistido no se declaran. "
      "Con voz propia la respuesta es No sin duda. Con voz sintética genérica también es No, pero por interpretación: "
      "la ayuda de YouTube no menciona voces sintéticas (sin verificar con texto literal). "
      "Nunca una voz clonada de otra persona ni música generada con IA.")


def carpetas():
    return {p.name[:3]: p for p in (RAIZ / "videos").iterdir() if p.is_dir() and p.name[:3].isdigit()}


def texto(num, carpeta):
    d = V[num]
    dia = DIA[num]
    lista, tema_tag = LISTAS[d["lista"]]
    tags = f"#roblox #robloxstory {tema_tag}"
    rel = V[d["rel"]]
    notas = list(d["extra"])
    if len(d["titulo"]) > 45:
        notas.insert(0, f"El título principal tiene {len(d['titulo'])} caracteres y pasa de los 45 que pide la plantilla; "
                        "se deja el del guion (no pasa de 10 palabras). Si quieres cumplir los 45, usa el título alterno 2.")
    L = []
    L += [f"VIDEO {num}",
          f"Internal name: {carpeta.name}",
          f"Scheduled: día {dia} del calendario (videos/CALENDARIO.md), 15:00 Bogota (20:00 UTC)"]
    if notas:
        L += ["Notas internas (no van a YouTube):"] + notas
    L += ["",
          "TITLE (max 45 characters, Title Case, no hashtags, no ALL CAPS)",
          d["titulo"],
          "",
          "ALT TITLE 1 (the object, 1 to 3 words)",
          d["alt_obj"],
          "",
          "ALT TITLE 2 (the rule without the opener)",
          d["alt_regla"],
          "",
          "DESCRIPTION (1 or 2 sentences, then credits, then hashtags)",
          d["desc"]]
    if d["desc_extra"]:
        L.append(d["desc_extra"])
    L += [f"An original work of fiction, written and animated by {CANAL}.",
          tags,
          "",
          "HASHTAGS (already in the description; 3 at most; no #shorts needed)",
          tags,
          "",
          "PINNED COMMENT (needs advanced features; a question the story raises)",
          d["comentario"],
          "",
          "PLAYLIST",
          lista,
          "",
          "SERIES (only if the Shorts series feature is available)",
          f"In This Town, Season 1, Episode {dia:02d}",
          "",
          "COVER FRAME",
          f"Timecode: por definir al montar; es el inicio del plano {d['plano']} en tiempos/planos.json",
          f"What is in it: plano {d['plano']} de la lista de planos del guion: {d['se_ve']}. Sin subtítulo encima. Alterno: {d['alterno']}.",
          "",
          "RELATED VIDEO",
          f"{d['rel']} {rel['titulo']} (día {DIA[d['rel']]}, lista {LISTAS[rel['lista']][0]})"]
    if DIA[d["rel"]] > dia:
        if dia == 1:
            L.append(f"Ese video sale después (día {DIA[d['rel']]}). El día 1 no hay otro publicado: deja el campo vacío y ponlo cuando salga.")
        else:
            L.append(f"Ese video sale después (día {DIA[d['rel']]}). Mientras tanto pon el del día anterior y cámbialo cuando salga.")
    L.append("Pega aquí la URL cuando exista. Cuando haya un video largo de esta familia, reemplázalo por ese.")
    L += ["",
          "AUDIENCE: No, it's not made for kids",
          "VIDEO LANGUAGE: English (United States)",
          "CATEGORY: Film & Animation (la predeterminada del canal según docs/07, sección 2.5; la otra opción allí es Entertainment)",
          "ALTERED CONTENT: No",
          IA,
          "",
          "CHECK BEFORE PUBLISHING",
          "[ ] Copyright check finished with no claims",
          "[ ] Title has no hashtag and no word in ALL CAPS",
          "[ ] First spoken sentence is the rule and matches the title",
          "[ ] Cover frame chosen in the mobile app",
          "[ ] Added to playlist; related video set",
          "",
          "PARA EL CANAL EN ESPAÑOL",
          "Título:",
          d["es_t"],
          "Descripción:",
          d["es_d"],
          ""]
    return "\n".join(L)


def main():
    cs = carpetas()
    for num in sorted(V):
        destino = cs[num] / "metadatos" / "publicacion.txt"
        destino.write_text(texto(num, cs[num]), encoding="utf-8", newline="\n")

    # CALENDARIO.md
    C = ["# Calendario de publicación: primeros 25 días",
         "",
         "Reglas del calendario (de `docs/08-descubrimiento-y-metadatos.md` y `guiones/INDICE.md`):",
         "",
         "1. Si un video no está listo, no publiques uno a medias: adelanta el siguiente del orden que ya esté terminado (sin dejar dos del mismo tema seguidos) y pon el atrasado en el hueco que deja; si no hay ninguno listo, deja el día vacío, porque una pausa no penaliza (`docs/08`, sección 1.4).",
         "2. No borres ni resubas un video porque \"no arrancó\", ni lo pases a privado para \"reiniciarlo\": YouTube lo desaconseja y puede verse como spam.",
         "3. No toques el título ni la portada en las primeras 48 horas, salvo que haya un error (una errata, un cuadro negro); la revisión se hace a las 48 horas con los títulos alternos.",
         "4. Mantén siempre un colchón de 5 videos terminados y programados por delante; si baja de 5, frena la cadencia antes que publicar sin colchón.",
         "5. Todo va programado, nunca a mano, a una sola hora fija: 3:00 p. m. de Colombia (20:00 UTC). La hora no decide el resultado, así que no la pruebes en estos 25 videos.",
         "",
         "El \"día N\" es el orden de `guiones/INDICE.md`; la fecha real del día 1 la pones tú. Marca la casilla cuando el video esté montado, revisado y con su `metadatos/publicacion.txt` verificado.",
         "",
         "| Día | Video | Título | Lista de reproducción | Tema | Tono | Hora de Colombia | UTC | Listo |",
         "|---|---|---|---|---|---|---|---|---|"]
    for i, (num, tema, tono) in enumerate(ORDEN, 1):
        d = V[num]
        C.append(f"| {i} | {num} | {d['titulo']} | {LISTAS[d['lista']][0]} | {tema} | {tono} | 3:00 p. m. | 20:00 | [ ] |")
    C += ["",
          "Notas:",
          "",
          "- El orden supone el colchón de producción de `guiones/INDICE.md`: tandas 1 y 2 listas antes del día 1, la 3 antes del día 8 y la 4 antes del día 14.",
          "- El 025 (día 17) no se publica sin la revisión cultural descrita en las advertencias de `guiones/INDICE.md`.",
          "- Si un video de la primera semana sale flojo en retención, cambia solo el siguiente del mismo tema por uno de nota más alta; no muevas todo el orden.",
          "- Un video diario es la cadencia de la fase 3 de `docs/08` (sección 3.3). Si arrancas con 3 o 5 por semana, conserva el orden y la hora, y salta los días que no toquen.",
          ""]
    (RAIZ / "videos" / "CALENDARIO.md").write_text("\n".join(C), encoding="utf-8", newline="\n")

    # LISTAS.md
    DESCS = {
        "F": "Stories about best friends, rivals and the people you would be lost without. Every video is a complete story set in a town with one impossible rule: friendships run on a battery, courage can be lent, inside jokes turn into pets. All of them are original fiction, written and animated by this channel.",
        "H": "Stories about parents, grandparents, brothers and sisters, each in a town with one impossible rule: hugs are counted, apologies cost a memory, your backpack weighs your worries. Every video is a complete story. All of them are original fiction, written and animated by this channel.",
        "S": "Stories from a school where one impossible rule changes everything: grades glow on your forehead, rumors paint themselves on the walls, the quietest kid controls the weather. Every video is a complete story. All of them are original fiction, written and animated by this channel.",
        "L": "First crushes in towns with one impossible rule: your shadow walks toward who you like, breakups make it snow, you can only lie on Tuesdays. Nothing past holding hands. Every video is a complete story. All of them are original fiction, written and animated by this channel.",
        "K": "Gently spooky stories from towns with one impossible rule: nobody opens after the third knock, the echo says what you really think, something trades with you every night. A chill, never gore, and always a heart. Every video is a complete story. All of them are original fiction, written and animated by this channel.",
        "C": "The funniest rules in town: every excuse you say comes true, and your pet posts a review of you on your front door. Every video is a complete story. All of them are original fiction, written and animated by this channel.",
    }
    QUE = {
        "F": "Amistad, incluidas las rivalidades que en el fondo son amistad.",
        "H": "Familia: papás, hermanos y abuelos, sin elemento de miedo.",
        "S": "Historias cuya regla es del colegio (las tres que arrancan con \"In This School\").",
        "L": "Primer amor, a nivel de \"me gustas\" y tomarse de la mano.",
        "K": "Terror suave: las cinco con escalofrío, aunque el fondo sea de familia.",
        "C": "Comedia pura, sin romance ni colegio como centro.",
    }
    Ls = ["# Listas de reproducción",
          "",
          "Seis listas temáticas para los 25 videos, con el nombre del universo adelante como pide `docs/08-descubrimiento-y-metadatos.md` (sección 3.5). Cada video va a una sola lista temática, la que dice su `metadatos/publicacion.txt`, y además a la lista principal del canal.",
          "",
          "Cómo usar este archivo: el título y la descripción de cada lista van en inglés y están a ras de margen para copiar y pegar. Lo demás es guía interna.",
          "",
          "Reglas:",
          "",
          "- Cada Short entra a su lista al subirlo. Una lista que solo tiene Shorts no se puede reordenar: el orden es el de entrada, o sea el del calendario.",
          "- No uses \"Roblox\" ni \"Blox\" en títulos ni descripciones de listas o videos.",
          "- Sobre el hashtag `#roblox` que llevan los videos: lee la sección \"Derechos de Roblox\" de `docs/04-monetizacion-y-politicas.md`, que explica el riesgo de marca, antes de decidir si lo dejas.",
          "- El nombre del canal (Almostville) es provisional; si cambia, cambia también la lista principal y la línea de crédito de cada descripción.",
          ""]
    for clave in ["F", "H", "S", "L", "K", "C"]:
        nombre, tag = LISTAS[clave]
        nums = sorted((n for n in V if V[n]["lista"] == clave), key=lambda n: DIA[n])
        Ls += [f"## {nombre}",
               "",
               f"Qué entra: {QUE[clave]} Hashtag de tema de sus videos: `{tag}`. Videos: {len(nums)}.",
               "",
               "Título:",
               "",
               nombre,
               "",
               "Descripción:",
               "",
               DESCS[clave],
               "",
               "Videos, en el orden en que entran:",
               ""]
        Ls += [f"- Día {DIA[n]}: {n} {V[n]['titulo']}" for n in nums]
        Ls.append("")
    Ls += ["## Listas generales",
           "",
           "No son temáticas y no reemplazan a las seis de arriba.",
           "",
           "- **All Almostville Stories**: la lista principal, con los 25. Su título y su descripción ya están en `canal/textos-canal.txt`.",
           "- **Start Here**: los 5 mejores Shorts según los datos del canal. Se crea cuando haya datos de las primeras semanas y se rehace en la revisión mensual (`docs/08`, sección 3.5). Mientras no haya datos no la crees.",
           "- **Full Stories**: para los videos largos, cuando exista el primero.",
           "",
           "## Decisiones tomadas",
           "",
           "- El 024 (comedia y primer amor) va a Love, junto a sus parientes 004 y 005; Funny queda con dos videos y es la lista que más conviene alimentar en el siguiente lote.",
           "- El 017 tiene marco de colegio pero es una historia de hermanos: va a Family.",
           "- Las cinco de terror suave van a Spooky aunque cuatro sean de familia, porque es el tono lo que el espectador busca repetir.",
           "- School solo tiene tres videos; el siguiente lote debería sumar ahí.",
           ""]
    (RAIZ / "videos" / "LISTAS.md").write_text("\n".join(Ls), encoding="utf-8", newline="\n")
    print("ok", len(V))


main()
