"""Ayudas para editar guiones (uso interno de esta revisión)."""
import re, glob
from pathlib import Path
G = Path(r"C:\Users\jcespedes\Documents\Code\plata\YT CHANNEL\guiones")

def ruta(num):
    r = sorted(G.glob(f"{num}-*.md"))
    assert len(r) == 1, (num, r)
    return r[0]

def leer(num): return ruta(num).read_text(encoding="utf-8")
def escribir(num, t):
    assert chr(0x2014) not in t, "raya larga"
    ruta(num).write_text(t, encoding="utf-8", newline="\n")

def sub(num, old, new, count=1):
    t = leer(num)
    n = t.count(old)
    assert n >= 1, f"{num}: no encontrado: {old[:70]!r}"
    if count is not None:
        assert n == count, f"{num}: {n} apariciones de {old[:70]!r}, esperaba {count}"
    escribir(num, t.replace(old, new))

def bloque(num, n, texto):
    """Reemplaza el texto del bloque n de la narración."""
    t = leer(num)
    pat = re.compile(r"(\*\*\[%d\.[^\]]*\]\*\*[^\n]*\n\n)(.*?)(\n\n(?:\*\*\[|## ))" % n, re.S)
    m = pat.search(t)
    assert m, (num, n)
    escribir(num, t[:m.start(2)] + texto.strip() + t[m.end(2):])

def filas(num, desde, hasta, nuevas):
    """Reemplaza las filas desde..hasta (inclusive) de la tabla de planos por 'nuevas'
    (líneas 'frase | escenario | pantalla | cara | cam'); hasta < desde inserta antes de 'desde'.
    Luego renumera."""
    lineas = leer(num).split("\n")
    i0 = next(i for i, l in enumerate(lineas) if l.startswith("## Lista de planos"))
    out, k, hecho = [], 0, False
    nuevas = [l.strip() for l in nuevas.strip().split("\n") if l.strip()]
    en_tabla = False
    for i, l in enumerate(lineas):
        m = re.match(r"\|\s*(\d+)\s*\|(.*)$", l) if i > i0 else None
        if m and (en_tabla or True):
            n = int(m.group(1))
            if n == desde and not hecho:
                for nv in nuevas:
                    k += 1; out.append(f"| {k} | {nv} |")
                hecho = True
            if desde <= n <= hasta:
                continue
            k += 1
            out.append(f"| {k} |{m.group(2)}")
        else:
            if i > i0 and k and not hecho and desde > k and l.strip() == "" :
                for nv in nuevas:
                    k += 1; out.append(f"| {k} | {nv} |")
                hecho = True
            out.append(l)
    assert hecho, (num, desde)
    escribir(num, "\n".join(out))
