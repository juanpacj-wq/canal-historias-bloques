# -*- coding: utf-8 -*-
import sys, re
from collections import Counter
from pathlib import Path
R = Path(sys.argv[1]); V = R / "videos"
ROTULOS = ["VIDEO ", "Internal name:", "Scheduled:", "TITLE (", "ALT TITLE 1 (", "ALT TITLE 2 (", "DESCRIPTION (",
           "HASHTAGS (", "PINNED COMMENT (", "PLAYLIST", "SERIES (", "COVER FRAME", "Timecode:", "What is in it:",
           "RELATED VIDEO", "AUDIENCE:", "VIDEO LANGUAGE:", "CATEGORY:", "ALTERED CONTENT:", "CHECK BEFORE PUBLISHING",
           "PARA EL CANAL EN ESPAÑOL", "Título:", "Descripción:"]
LISTAS = {"In This Town: Friendship", "In This Town: Family", "In This Town: School", "In This Town: Love",
          "In This Town: Spooky", "In This Town: Funny"}
VOSEO = re.compile(r"\b(vos|creá|generá|abrí|hacé|tené|poné|elegí|guardá|enviá|seguí|usá|dejá|mirá|subí|pegá|cambiá|revisá|registrate|fijate|acordate)\b", re.I)
err = []; filas = []; dias = []
guiones = sorted((R / "guiones").glob("[0-9][0-9][0-9]-*.md"))
for g in guiones:
    num = g.stem[:3]
    f = V / g.stem / "metadatos" / "publicacion.txt"
    if not f.is_file():
        err.append(f"{num}: falta {f}"); continue
    t = f.read_text(encoding="utf-8"); ls = t.split("\n")
    pos = -1
    for r in ROTULOS:
        i = next((k for k, l in enumerate(ls) if k > pos and l.startswith(r)), None)
        if i is None:
            err.append(f"{num}: falta el rótulo o está fuera de orden: {r}")
        else:
            pos = i

    def tras(r):
        i = next(k for k, l in enumerate(ls) if l.startswith(r)); return ls[i + 1]

    def bloque(r):
        i = next(k for k, l in enumerate(ls) if l.startswith(r)); out = []
        for l in ls[i + 1:]:
            if not l:
                break
            out.append(l)
        return out
    tit, a1, a2 = tras("TITLE ("), tras("ALT TITLE 1 ("), tras("ALT TITLE 2 (")
    gt = g.read_text(encoding="utf-8").split("\n")[0].split(": ", 1)[1].strip()
    if tit != gt:
        err.append(f"{num}: el título no es el del guion ({tit!r} / {gt!r})")
    for nombre, x in (("título", tit), ("alterno 1", a1), ("alterno 2", a2)):
        w = x.split()
        if len(w) > 10: err.append(f"{num}: {nombre} con {len(w)} palabras")
        if len(x) > 100: err.append(f"{num}: {nombre} pasa de 100 caracteres")
        if re.search(r"\b[A-Z]{3,}\b", x): err.append(f"{num}: {nombre} con palabra en mayúsculas sostenidas: {x}")
        if "#" in x: err.append(f"{num}: {nombre} con hashtag")
        if re.search(r"roblox|blox", x, re.I): err.append(f"{num}: {nombre} menciona la marca")
    if not 1 <= len(a1.split()) <= 3: err.append(f"{num}: el alterno de objeto no tiene de 1 a 3 palabras")
    desc = bloque("DESCRIPTION (")
    cuerpo = " ".join(l for l in desc if not l.startswith("#"))
    if re.search(r"roblox|blox", cuerpo, re.I): err.append(f"{num}: la descripción menciona la marca fuera de los hashtags")
    if "original work of fiction" not in cuerpo: err.append(f"{num}: falta la línea de ficción original")
    tags = tras("HASHTAGS (").split()
    if not (1 <= len(tags) <= 3 and all(x.startswith("#") for x in tags)): err.append(f"{num}: hashtags fuera de rango: {tags}")
    if desc[-1].split() != tags: err.append(f"{num}: los hashtags de la descripción no coinciden")
    com = tras("PINNED COMMENT (")
    if "?" not in com: err.append(f"{num}: el comentario fijado no es pregunta")
    lista = tras("PLAYLIST")
    if lista not in LISTAS: err.append(f"{num}: lista desconocida {lista!r}")
    if "AUDIENCE: No, it's not made for kids" not in t: err.append(f"{num}: falta hecho para niños = No")
    if not re.search(r"^ALTERED CONTENT: No$", t, re.M): err.append(f"{num}: falta la declaración de IA")
    if not re.search(r"What is in it: plano \d+ ", t): err.append(f"{num}: portada sin número de plano")
    m = re.search(r"^Scheduled: día (\d+) ", t, re.M)
    if not m:
        err.append(f"{num}: sin día")
    else:
        dias.append(int(m.group(1)))
    es = tras("Título:")
    if es != es.upper() or not 3 <= len(es.split()) <= 6: err.append(f"{num}: título en español mal formado: {es}")
    for x in [tit, a1, a2, com, lista] + desc:
        if x != x.strip() or x[:1] in "-*>•" or (x.startswith('"') and x.endswith('"')):
            err.append(f"{num}: línea con adorno: {x[:40]}")
    for car, nom in ((chr(0x2014), "raya larga"), ("–", "raya corta"), ("\t", "tabulador")):
        if car in t: err.append(f"{num}: contiene {nom}")
    if VOSEO.search(t): err.append(f"{num}: posible voseo: {VOSEO.search(t).group(0)}")
    filas.append((num, tit, lista, len(tit.split()), len(tit)))
if sorted(dias) != list(range(1, 26)): err.append(f"los días no son 1 a 25 sin repetir: {sorted(dias)}")
for extra in ["CALENDARIO.md", "LISTAS.md"]:
    f = V / extra
    if not f.is_file():
        err.append(f"falta {extra}"); continue
    t = f.read_text(encoding="utf-8")
    if chr(0x2014) in t or "–" in t: err.append(f"{extra}: contiene raya")
    if VOSEO.search(t): err.append(f"{extra}: posible voseo: {VOSEO.search(t).group(0)}")
cal = (V / "CALENDARIO.md").read_text(encoding="utf-8")
if len(re.findall(r"^\| \d+ \| \d{3} \|.*\| \[ \] \|$", cal, re.M)) != 25: err.append("CALENDARIO.md: no hay 25 filas con casilla")
lis = (V / "LISTAS.md").read_text(encoding="utf-8")
if len(re.findall(r"^- Día \d+: \d{3} ", lis, re.M)) != 25: err.append("LISTAS.md: no están los 25 videos")
if "Derechos de Roblox" not in lis: err.append("LISTAS.md: falta la nota de derechos")
for g in ["001-friendships-have-a-battery.md", "019-the-night-trade.md"]:
    if chr(0x2014) in (R / "guiones" / g).read_text(encoding="utf-8"): err.append(f"{g}: contiene raya larga")
print(f"{'#':<4}{'Título principal':<56}{'Lista':<26}{'Pal.':<5}Car.")
for n, t_, l, w, c in filas:
    print(f"{n:<4}{t_:<56}{l:<26}{w:<5}{c}")
print()
print(f"Archivos publicacion.txt encontrados: {len(filas)} de {len(guiones)}")
print(f"Títulos con más de 45 caracteres (aviso, no error): {', '.join(n for n, _, _, _, c in filas if c > 45) or 'ninguno'}")
print(f"Máximo de palabras en un título principal: {max(w for *_, w, _ in filas)}")
print("Videos por lista:", dict(Counter(l for _, _, l, _, _ in filas)))
print("ERRORES:" if err else "Sin errores: 25 archivos, rótulos completos y en orden, títulos de 10 palabras o menos, sin mayúsculas sostenidas, sin raya larga.")
for e in err:
    print(" -", e)
sys.exit(1 if err else 0)
