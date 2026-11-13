from ed import *
N="001"
bloque(N,2,'''It floats between you like a little green bar. Laugh together, it goes up. Ignore a text, it drops. My grandpa and his chess buddy have been at one hundred percent since 1974. They have never finished a game. My sister lost three friends in one group chat. You could hear the beeping from the kitchen. My mom and the mailman are at forty percent. Nobody knows how. Mom says he respects her mailbox.''')
bloque(N,4,'''Then Theo joined the soccer team. New friends. New jokes I wasn't in. One Monday I finally looked up. Red. Two percent. At zero, a friendship shuts off. You pass each other like strangers. My dad waves at a guy named Rick every morning. Neither of them remembers why.''')
bloque(N,6,'''That night the bar started beeping. I sat on my floor and stared at it. And I noticed something I'd never checked. The bar has two halves. His half was full. Mine was empty. Theo had invited me to every single game. I'd said no eleven times. I told him soccer was boring. Really, I just didn't want to watch him not need me. So on Saturday, I went. It was pouring. I stood at the fence, alone, soaked. And I yelled his name until my voice cracked.''')
# De abajo hacia arriba para no mover la numeración pendiente
filas(N,37,40,'''
Theo had invited me to every single game. | Colegio, pasillo (recuerdo) | Theo ofreciendo una boleta | Ilusionado | M
I'd said no eleven times. | Colegio, pasillo (recuerdo) | Narrador negando; Theo baja la cabeza | Indiferente, triste | M
I told him soccer was boring. | Colegio, pasillo (recuerdo) | Narrador encogiéndose de hombros; once boletas en el piso | Indiferente | C
Really, I just didn't want to watch him not need me. | Cancha (recuerdo) | Theo celebrando con el equipo; el narrador lejos, detrás de la malla | Triste | G
So on Saturday, I went. | Cancha con lluvia | Narrador llegando a la cancha | Decidido | G
It was pouring. | Cancha con lluvia | Lluvia fuerte sobre la tribuna vacía | (sin personaje) | G
I stood at the fence, alone, soaked. | Cancha con lluvia | Narrador empapado agarrado a la malla | Nervioso | M
And I yelled his name until my voice cracked. | Cancha con lluvia | Narrador gritando | Grito, llanto | C
''')
filas(N,32,32,'''
That night the bar started beeping. | Cuarto de noche | Narrador en la cama; barra parpadeando | Angustia | M
I sat on my floor and stared at it. | Cuarto de noche | Narrador sentado en el piso frente a la barra roja | Angustia | M
''')
filas(N,21,21,'''
At zero, a friendship shuts off. | Calle | Una barra se apaga y queda gris | (sin personaje) | C
You pass each other like strangers. | Calle | Dos personajes grises se cruzan sin mirarse | Vacías | G
My dad waves at a guy named Rick every morning. | Calle frente a la casa | Papá saluda con la mano a un vecino; entre ellos, una barra gris apagada | Papá confundido | M
Neither of them remembers why. | Calle frente a la casa | Rick devuelve el saludo, rascándose la cabeza | Confundido | C
''')
filas(N,9,9,'''
You could hear the beeping... | Cocina | Narrador con un cereal, mirando hacia arriba | Incómodo | C
My mom and the mailman are at forty percent. | Calle frente a la casa | Mamá y el cartero; barra en 40 entre ellos | Serios | M
Nobody knows how. | Calle frente a la casa | Narrador y papá mirando desde la ventana | Confundidos | C
Mom says he respects her mailbox. | Calle frente a la casa | Cartero cierra el buzón con mucho cuidado | Mamá satisfecha | C
''')
filas(N,7,7,'''
since 1974. | Sala | Barra al 100 con telarañas | (sin personaje) | C
They have never finished a game. | Sala | Tablero de ajedrez con telarañas; los dos abuelos dormidos | Dormidos | M
''')
sub(N,"# Guion piloto 001: In This World, Friendships Have a BATTERY","# Guion piloto 001: In This World, Friendships Have a Battery")
sub(N,'''- **Giro**: el que estaba dejando morir la amistad era el narrador, no su amigo
''','''- **Giro**: el que estaba dejando morir la amistad era el narrador, no su amigo
- **Título alterno**: The Battery
''')
sub(N,'''- **Escenarios (7)**: pueblo o calle, parque, cuarto (día y noche), sala,
  cocina, colegio (pasillo y cafetería), cancha de fútbol (seca y con lluvia),
  patio con casa del árbol.
- **Personajes (unos 10)**: narrador, Theo, hermana, dos abuelos, cuatro o
  cinco extras.''','''- **Escenarios (7)**: pueblo o calle (y frente de la casa), parque, cuarto
  (día y noche), sala, cocina, colegio (pasillo y cafetería), cancha de fútbol
  (seca y con lluvia), patio con casa del árbol.
- **Personajes (unos 14)**: narrador, Theo, hermana, dos abuelos, mamá, papá,
  cartero, el vecino Rick, cuatro o cinco extras.''')
t=leer(N).rstrip("\n")
t+='''

## Alternativas

Ganchos alternos:

In this world, you can see exactly how much friendship you have left with everybody you know.

In this world, friendships run on a battery, and my best friend and I just hit two percent.

In this town, every friendship comes with a charge bar, and nobody sells a charger.

Remates alternos:

We're at one hundred percent. Grandpa says that's cute. He's been there since 1974 and he still hasn't won.

They lost nine to nothing. Theo says it was worth it. His coach is at four percent with me.

## Bitácora de originalidad

- **Fecha**: 2026-11-12 (piloto); revisión editorial de conjunto el 2026-11-13.
- **Premisa de origen**: número 8 del banco propio (`docs/05`), "Friendships
  Have a BATTERY".
- **Variable cambiada respecto al tropo conocido**: el tropo cercano es la
  familia "número visible sobre la cabeza" de r/WritingPrompts. Aquí el número
  no es de una persona sino de un vínculo, flota entre los dos y tiene dos
  mitades: cada uno carga la suya. Theo, Fort Maybe, el clavo, la fiesta
  sorpresa en octubre y el marcador en corto son propios.
- **Búsqueda en YouTube**: pendiente. El piloto se escribió antes de que se
  llevara bitácora y no quedó registro de la búsqueda. Hazla con el título
  antes de producir y anota aquí el resultado.
- **Pasadas de revisión**: dos. La primera es la del piloto. En la segunda
  (lectura de conjunto de los 25 guiones) el texto pasó de 288 a 360 palabras
  sin relleno: un ejemplo nuevo del mundo (la mamá y el cartero al 40 %, y los
  abuelos que nunca terminan una partida), un ejemplo del costo (el papá que
  saluda a Rick sin saber por qué) y más aire en el bloque 6 (por qué decía
  que no, la lluvia y la malla antes del grito). El plano largo de "At zero"
  se partió en cuatro, y la tabla quedó alineada con "every single game". El
  giro "el problema era el narrador" se dejó solo en este guion: el 005, que
  lo compartía, se reestructuró.
'''
escribir(N,t+"")
