from ed import *
VIEJA = '''Dentro de la
  narración sí se marcaron palabras clave en MAYÚSCULAS (en el `.md` y en el
  `.txt`) para resaltarlas en los subtítulos; el texto es el mismo.'''
NUEVA = '''La narración
  ya traía suficientes palabras en MAYÚSCULAS (letreros y gritos del propio
  cuento) y no se marcaron más.'''
for num in ("015", "018", "021"):
    sub(num, VIEJA, NUEVA)
t = leer("012")
print(t.count("Lund"))
t = t.replace("Lund", "Park")
escribir("012", t)
t = leer("012").rstrip("\n") + '''
- **Nombre cambiado (2026-11-13)**: Mr. Lund pasó a llamarse Mr. Park porque
  quedaba a una letra de Mr. Lutz (002).
'''
escribir("012", t)
