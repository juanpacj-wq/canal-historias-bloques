import re, glob
from ed import *
VIEJOS = {}
orig = Path(r"C:\Users\jcespedes\AppData\Local\Temp\claude\orig")
for r in sorted(orig.glob("0*.md")):
    VIEJOS[r.name[:3]] = re.sub(r"^# Guion(?: piloto)? \d{3}: ", "", r.read_text(encoding="utf-8").split("\n")[0])
for r in sorted(G.glob("0*.md")):
    num = r.name[:3]
    t = leer(num).rstrip("\n")
    if "**Título y mayúsculas (2026-11-13)**" in t:
        continue
    nuevo = re.sub(r"^# Guion(?: piloto)? \d{3}: ", "", t.split("\n")[0])
    alterno = re.search(r"^- \*\*Título alterno\*\*: (.+)$", t, re.M).group(1)
    viejo = VIEJOS[num]
    if viejo == nuevo:
        frase = f'el título "{nuevo}" no cambió'
    else:
        frase = f'el título pasó de "{viejo}" a "{nuevo}"'
    t += f'''
- **Título y mayúsculas (2026-11-13)**: {frase} y se
  agregó el título alterno "{alterno}". Motivo: la medición de 360 Shorts de
  canales líderes (`docs/08`) muestra que en inglés los títulos no llevan
  palabras en mayúsculas sostenidas ni pasan de 10 palabras. Dentro de la
  narración sí se marcaron palabras clave en MAYÚSCULAS (en el `.md` y en el
  `.txt`) para resaltarlas en los subtítulos; el texto es el mismo.
'''
    escribir(num, t)
print(VIEJOS["019"])
