from ed import *
N="022"
t=leer(N)
t=t.replace("Marisol","Delia").replace("a goose directs traffic","a raccoon directs traffic")
t=t.replace("Ganso","Mapache").replace("ganso","mapache")
escribir(N,t)
bloque(N,6,'''Saturday I walked six miles back, sneezing, carrying a nine-pound Thing. I stood at Delia's gate with no excuses left. "I can't swim," I said. "I never learned. I'm fourteen, and I'm scared of the shallow end. That's why I said no six times." I waited for the poof. Nothing. The truth doesn't poof.''')
bloque(N,7,'''Delia didn't laugh. She looked at her pool. Then she yelled, "Sorry, everybody! Our deep end is broken!" Poof. The whole pool was two feet deep. Everybody stood up, very confused. No take-backs. She did that to her own pool. Then the Thing waddled past us and hopped in. It floats. Of course it floats. I held on with both arms. And guess who was a lifeguard for twenty-two years? Uncle Rondo. He cried again.''')
bloque(N,8,'''I can swim now. I sneeze the whole time, but I can swim. Delia's pool is still two feet deep. She says she'd do it again. She invited the Thing to her next party. It hummed, "Sorry, I have a thing." Poof. Now there are two.''')
filas(N,49,68,'''
"I can't swim," I said. | Patio con piscina | Narrador | Vulnerable | C
"I never learned. | Patio con piscina | Narrador mirando el agua de reojo | Vergüenza | C
I'm fourteen, and I'm scared of the shallow end. | Patio con piscina | Parte baja de la piscina; un niño pequeño con flotadores chapotea feliz | Narrador con miedo | M
That's why I said no six times." | Patio con piscina | Delia escuchando | Seria | C
I waited for the poof. | Patio con piscina | Narrador con los ojos apretados | Ojos apretados | C
Nothing. The truth doesn't poof. | Patio con piscina | Aire vacío a su lado | Sorpresa | M
Delia didn't laugh. | Patio con piscina | Delia | Seria | C
She looked at her pool. | Patio con piscina | Delia mira la piscina llena de invitados | Pensativa | M
Then she yelled, "Sorry, everybody! | Patio con piscina | Delia con las manos en bocina hacia la piscina | Decidida | M
Our deep end is broken!" | Patio con piscina | Invitados voltean a mirarla | Confundidos | G
Poof. | Patio con piscina | Nube de "puf" gigante sobre toda la piscina | (sin personaje) | G
The whole pool was two feet deep. | Patio con piscina | Piscina con el agua por las rodillas; letrero "2 FT" | (sin personaje) | G
Everybody stood up, very confused. | Patio con piscina | Invitados de pie con el agua en las rodillas | Confundidos | M
No take-backs. | Patio con piscina | El letrero "2 FT", ahora atornillado | (sin personaje) | C
She did that to her own pool. | Patio con piscina | Narrador mira a Delia; ella se encoge de hombros | Ojos aguados, sonrisa | M
Then the Thing waddled past us | Patio con piscina | La Cosa camina entre los dos | (sin personaje) | M
and hopped in. | Patio con piscina | Salpicón pequeño | Ambos sorprendidos | G
It floats. Of course it floats. | Patio con piscina | La Cosa flotando feliz | (sin personaje) | C
I held on with both arms. | Patio con piscina | Narrador abrazado a la Cosa en el agua bajita | Miedo y risa | M
And guess who was a lifeguard for twenty-two years? | Patio con piscina | Silla alta de salvavidas, silueta con silbato | (silueta) | G
Uncle Rondo. | Patio con piscina | Tío Rondo con silbato y camisa hawaiana | Orgulloso | C
He cried again. | Patio con piscina | Tío Rondo llorando a chorros | Llanto | C
I can swim now. | Patio con piscina | Narrador nada solo | Feliz | M
I sneeze the whole time, but I can swim. | Patio con piscina | Narrador estornuda en mitad de la brazada | Estornudo | C
Delia's pool is still two feet deep. | Patio con piscina | Delia de pie en la piscina, con el agua en las rodillas | Tranquila | M
She says she'd do it again. | Patio con piscina | Delia y el narrador chocan los puños | Sonrisas | C
She invited the Thing to her next party. | Patio con piscina | Delia entrega una invitación a la Cosa | Sonrisa | M
It hummed, "Sorry, I have a thing." | Patio con piscina | La Cosa con notas musicales | Narrador con pánico | C
Poof. | Patio con piscina | Nube de "puf" | (sin personaje) | C
Now there are two. | Patio con piscina | Dos Cosas, una pequeña; narrador y Delia mirando | Derrotado, risa | G
''')
sub(N,'''- **Giro**: las seis negativas no ocultaban desinterés sino vergüenza: tiene
  catorce años y no sabe nadar. Y Delia llevaba seis fiestas creyendo que
  ya no le caía bien''','''- **Giro**: cuando el narrador por fin dice la verdad, Delia no se ríe: grita
  una excusa a propósito ("Our deep end is broken!") y deja su propia piscina
  de dos pies de hondo para siempre. La regla, que todo el guion fue un
  castigo, se usa una vez como regalo, y con el mismo costo: sin devoluciones''')
sub(N,'''- **Final**: cómico con un momento sincero antes del desenlace''','''- **Final**: cómico, con confesión sincera y un gesto de amistad antes del
  remate''')
sub(N,'''calendario en blanco, invitaciones, 43 cajas (un bloque repetido), piano,
  vaso de agua, afiche de lago, silla de salvavidas, silbato.''','''calendario en blanco, invitaciones, 43 cajas (un bloque repetido), piano,
  vaso de agua, afiche de lago, silla de salvavidas, silbato, letrero "2 FT",
  flotadores. La piscina necesita dos niveles de agua (normal y por las
  rodillas).''')
t=leer(N).rstrip("\n")+'''
- **Revisión editorial de conjunto (2026-11-13)**: el giro anterior ("pensé
  que ya no te caía bien") era previsible y repetía el motivo del 001 (un
  amigo que invita y el otro que dice que no). Se reemplazó por una acción
  que depende de la regla: Delia gasta una excusa irreversible en su propia
  piscina para que él pueda entrar. La confesión creció de tres frases a
  cinco ("I'm scared of the shallow end"). Además: la amiga se llamaba
  Marisol, igual que la exnovia del 005, y pasó a llamarse Delia; el ganso
  del tráfico pasó a ser un mapache porque ya hay gansos en el 003 y el 008.
'''
escribir(N,t)
N="013"
sub(N,'''("I didn't like the math", "Neither of
us looks at it")''','''("Her number drops every day", "Neither of
us looks at it")''')
