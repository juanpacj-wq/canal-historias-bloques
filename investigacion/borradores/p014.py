from ed import *
N="014"
bloque(N,5,'''Monday, she built a volcano. Real smoke. I yelled, "Done! Hand it in!" She tore it down. The lava was "the wrong orange." Wednesday, she built the solar system. Eight planets, spinning. I told her it was perfect. Wrong word. She found Neptune two millimeters off. Thursday, she built a robot that folds socks. I grabbed it and ran for Mr. Haskell's room. I made it nine steps. The robot folded my sock. I was wearing it.''')
bloque(N,6,'''She shoved the robot in her locker. That's when I saw inside. Tests. Four hundred and twelve of them. All perfect. None turned in. "If I never hand it in," she whispered, "it can't be wrong." So Friday, I went first. A potato, two wires, and a light bulb. The bulb did not light. My C flickered and dropped to a D. In front of everybody. I pointed at my forehead and looked right at Winnie. "See? Still here. I even had a sandwich today."''')
filas(N,25,49,'''
Monday, she built a volcano. | Colegio, salón | Volcán de maqueta sobre la mesa; Winnie al lado | Concentrada | M
Real smoke. | Colegio, salón | Humo saliendo del cráter | Narrador asombrado | C
I yelled, "Done! Hand it in!" | Colegio, salón | Narrador señalando el escritorio del profesor con los dos brazos | Emocionado | M
She tore it down. | Colegio, salón | Winnie desarmando el volcán en pedazos | Frustrada | M
The lava was "the wrong orange." | Colegio, salón | Dos muestras de naranja casi idénticas | Narrador confundido | C
Wednesday, she built the solar system. | Colegio, salón | Sistema solar colgante con un sol amarillo | Concentrada | G
Eight planets, spinning. | Colegio, salón | Planetas girando | Narrador ilusionado | C
I told her it was perfect. | Colegio, salón | Narrador con los dos pulgares arriba | Sonrisa enorme | M
Wrong word. | Colegio, salón | Winnie se queda tiesa; saca una regla | Ojos muy abiertos | C
She found Neptune two millimeters off. | Colegio, salón | Regla junto a la esfera azul; los planetas ya en una caja | Frustrada | C
Thursday, she built a robot that folds socks. | Colegio, salón | Robot de cubos con brazos y una media | Narrador boquiabierto | M
I grabbed it and ran for Mr. Haskell's room. | Colegio, pasillo | Narrador corriendo con el robot en brazos; Winnie detrás | Decidido, pánico | G
I made it nine steps. | Colegio, pasillo | Narrador en el piso, boca abajo | Derrotado | M
The robot folded my sock. | Colegio, pasillo | El robot doblando la media del narrador | (sin personaje) | C
I was wearing it. | Colegio, pasillo | Pie del narrador con la media doblada en un cuadrito perfecto | Narrador resignado | C
She shoved the robot in her locker. | Colegio, pasillo | Winnie empujando el robot dentro del casillero | Angustia | M
That's when I saw inside. | Colegio, pasillo | Narrador asomado por encima del hombro de Winnie | Curioso | C
Tests. Four hundred and twelve of them. | Colegio, pasillo | Casillero lleno de torres de hojas hasta el techo | (sin personaje) | C
All perfect. | Colegio, pasillo | Una hoja en primer plano, llena y sin un solo tachón | (sin personaje) | C
None turned in. | Colegio, salón | Bandeja de "entregas" vacía, con telaraña | (sin personaje) | C
"If I never hand it in," she whispered, | Colegio, pasillo | Winnie abrazando el borrador gigante; su signo de pregunta parpadea | Miedo, ojos brillantes | C
"it can't be wrong." | Colegio, pasillo | Cara de Winnie | Miedo | C
So Friday, I went first. | Colegio, salón | Narrador se pone de pie entre los pupitres y camina al frente | Decidido | M
A potato, two wires, and a light bulb. | Colegio, salón | Papa con dos cables y un bombillo sobre el escritorio | (sin personaje) | C
The bulb did not light. | Colegio, salón | Bombillo apagado; Mr. Haskell mirándolo | Sin expresión | C
My C flickered and dropped to a D. | Colegio, salón | La C parpadea y se vuelve D roja | Narrador traga saliva | C
In front of everybody. | Colegio, salón | Todo el salón mirando | Sorprendidos | G
I pointed at my forehead... | Colegio, salón | Narrador se señala la D y mira a Winnie | Sonrisa valiente | M
"See? Still here. I even had a sandwich today." | Colegio, salón | Narrador saca medio sándwich del bolsillo | Sonrisa | C
''')
sub(N,'''pregunta "desde tercero" (bloque 3). Se cosechan en el bloque 5 (412 exámenes''','''pregunta "desde tercero" (bloque 3). Se cosechan en el bloque 6 (412 exámenes''')
t=leer(N).rstrip("\n")+'''
- **Revisión editorial de conjunto (2026-11-13)**: los tres intentos eran de
  Winnie y el narrador solo miraba. Ahora cada uno es un empujón de él que
  falla peor que el anterior: grita "Done!" y ella desarma el volcán, le dice
  "perfect" y ella encuentra el error de Neptuno, y por último sale corriendo
  con el robot, que le dobla la media puesta. El bloque 5 bajó de 93 a 76
  palabras; el casillero con los 412 exámenes pasó a abrir el bloque 6, pegado
  a la frase de Winnie y a la decisión del narrador. Se quitó "A forehead
  can't grade what it never gets" porque la imagen del casillero ya lo dice.
'''
escribir(N,t)
