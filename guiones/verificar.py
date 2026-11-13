"""Verificación mecánica de los guiones de la carpeta guiones/.

Revisa, por cada guion NNN-slug.md con su NNN-slug.txt:

  1. Palabras de la narración (se cuentan en el .txt) y duración a 230 palabras
     por minuto.
  2. Que la narración del .md sea idéntica a la del .txt.
  3. Que estén los 8 bloques, en orden, y cuántas palabras tiene cada uno.
  4. Que la ficha declare el conteo real en la línea
     "- **Conteo real**: N palabras (a, b, c, d, e, f, g, h)" y que coincida.
     Si un bloque lleva "(N palabras)" junto a su etiqueta, también se revisa.
  5. Que estén las secciones obligatorias: Narración, Lista de planos, Qué hay
     que construir, Alternativas y Bitácora de originalidad.
  6. Que no aparezca la raya larga (U+2014) en ningún archivo de la carpeta.
  7. Frases de más de 20 palabras.
  8. Que la primera frase empiece por "In this world", "In this town" o
     "In this school".
  9. Que cada plano de la tabla "Lista de planos" ancle en la narración, con el
     mismo criterio de herramientas/planos_tiempos.py: se busca el texto de la
     columna "Frase (inicio)" dentro de la narración, siempre hacia adelante.
     Solo se acepta el anclaje exacto; el parcial, el aproximado y la falta de
     anclaje son errores porque en producción dependen de la suerte.
 10. Título: sin palabras en MAYÚSCULAS sostenidas, máximo 10 palabras, y una
     viñeta "- **Título alterno**:" en la ficha con las mismas condiciones.
 11. Que la narración tenga al menos 6 palabras en MAYÚSCULAS (sirven para
     resaltar los subtítulos; lo recomendado es de 6 a 12 palabras clave, y los
     letreros del mundo, como "NOBODY HOME", también cuentan).
 12. Aviso (no error) de planos que durarían demasiado a la velocidad de la voz.

Uso:
    python guiones/verificar.py                 revisa todos los guiones
    python guiones/verificar.py 001 019         revisa solo esos números
    python guiones/verificar.py --detalle       muestra también los avisos de duración
    python guiones/verificar.py --json          imprime el resultado como JSON
    python guiones/verificar.py --sincronizar   antes de revisar, reescribe cada .txt
                                                a partir de la narración del .md y
                                                actualiza los conteos de la ficha

Flujo recomendado al corregir un guion: edita solo el .md (narración y tabla de
planos), ejecuta con --sincronizar y luego revisa la salida.

Termina con código 0 si no hay errores y con 1 si hay alguno. Los avisos no
cambian el código de salida.
"""

from __future__ import annotations

import argparse
import difflib
import json
import math
import re
import sys
import unicodedata
from pathlib import Path

CARPETA = Path(__file__).resolve().parent
RAYA_LARGA = chr(0x2014)
PUNTOS_SUSPENSIVOS = chr(0x2026)
PALABRAS_POR_MINUTO = 230
MAX_PALABRAS_FRASE = 20
MAX_PALABRAS_TITULO = 10
MAYUSCULAS_MIN, MAYUSCULAS_MAX = 6, 12
INICIOS_VALIDOS = ("in this world", "in this town", "in this school")
SECCIONES = ["narracion", "lista de planos", "que hay que construir", "alternativas",
             "bitacora de originalidad"]
NOMBRES_SECCIONES = {
    "narracion": "Narración",
    "lista de planos": "Lista de planos",
    "que hay que construir": "Qué hay que construir",
    "alternativas": "Alternativas",
    "bitacora de originalidad": "Bitácora de originalidad",
}
ETIQUETA_BLOQUE = re.compile(r"^(\s*\*\*\[(\d+)\.\s*(.+?)\]\*\*)(?:\s*\((\d+) palabras\))?\s*$")
LINEA_CONTEO = re.compile(r"^- \*\*(Conteo real|Palabras de narración|Palabras)\*\*:")


def sin_tildes(texto: str) -> str:
    texto = unicodedata.normalize("NFKD", texto)
    return "".join(c for c in texto if not unicodedata.combining(c))


def normalizar(palabra: str) -> str:
    """Igual que herramientas/comun.py: minúsculas, sin tildes y sin signos."""
    return re.sub(r"[^a-z0-9]", "", sin_tildes(palabra.lower()))


def palabras_de(texto: str) -> list:
    return [p for p in texto.split() if normalizar(p)]


def contar(texto: str) -> int:
    return len(palabras_de(texto))


def en_mayusculas(texto: str) -> list:
    """Palabras de dos o más letras escritas completas en mayúsculas."""
    encontradas = []
    for palabra in texto.split():
        letras = re.sub(r"[^A-Za-z]", "", palabra.split("'")[0])
        if len(letras) >= 2 and letras.isupper():
            encontradas.append(palabra.strip(".,!?\"':;()"))
    return encontradas


def frases_de(texto: str) -> list:
    """Parte un texto en frases por punto, signo de interrogación o exclamación."""
    partes = re.split(r"(?<=[.!?])[\"')\]]*\s+", texto.strip())
    return [p.strip() for p in partes if contar(p)]


def parrafos(texto: str) -> list:
    return [" ".join(p.split()) for p in re.split(r"\n\s*\n", texto) if p.strip()]


def secciones_md(lineas: list) -> dict:
    """Devuelve {titulo normalizado: (inicio, fin)} de los títulos de nivel 2."""
    marcas = []
    for i, linea in enumerate(lineas):
        if linea.startswith("## "):
            marcas.append((i, sin_tildes(linea[3:]).lower().strip()))
    resultado = {}
    for posicion, (i, titulo) in enumerate(marcas):
        fin = marcas[posicion + 1][0] if posicion + 1 < len(marcas) else len(lineas)
        resultado[titulo] = (i + 1, fin)
    return resultado


def buscar_seccion(secciones: dict, prefijo: str):
    for titulo, rango in secciones.items():
        if titulo.startswith(prefijo):
            return rango
    return None


def bloques_md(lineas: list) -> list:
    """Lee los bloques '**[N. Nombre]**' de la Narración: [(n, nombre, texto, declarado)]."""
    bloques = []
    actual = None
    for linea in lineas:
        marca = ETIQUETA_BLOQUE.match(linea)
        if marca:
            declarado = int(marca.group(4)) if marca.group(4) else None
            actual = [int(marca.group(2)), marca.group(3), [], declarado]
            bloques.append(actual)
        elif actual is not None:
            actual[2].append(linea)
    return [(n, nombre, "\n".join(texto).strip(), declarado) for n, nombre, texto, declarado in bloques]


def partir_fila(linea: str) -> list:
    linea = linea.strip()
    if linea.startswith("|"):
        linea = linea[1:]
    if linea.endswith("|") and not linea.endswith("\\|"):
        linea = linea[:-1]
    return [celda.replace("\\|", "|").strip() for celda in re.split(r"(?<!\\)\|", linea)]


def leer_planos(lineas: list) -> list:
    """Lee la tabla de planos como lo hace planos_tiempos.py: [(numero, frase)]."""
    filas = []
    for linea in lineas:
        if linea.strip().startswith("|"):
            filas.append(partir_fila(linea))
        elif filas:
            break
    if len(filas) < 3:
        return []
    col_n = col_frase = None
    for posicion, titulo in enumerate(filas[0]):
        clave = sin_tildes(titulo).lower().strip()
        if clave.startswith("#"):
            col_n = posicion
        elif clave.startswith("frase"):
            col_frase = posicion
    if col_n is None or col_frase is None:
        return []
    planos = []
    for fila in filas[1:]:
        if all(re.fullmatch(r":?-{2,}:?", celda) for celda in fila if celda):
            continue
        fila = fila + [""] * (len(filas[0]) - len(fila))
        numero = re.search(r"\d+", fila[col_n])
        if numero:
            planos.append((int(numero.group()), fila[col_frase]))
    return planos


def claves_de_frase(frase: str) -> list:
    frase = frase.replace(PUNTOS_SUSPENSIVOS, " ").replace("...", " ")
    return [normalizar(p) for p in frase.split() if normalizar(p)]


def buscar_anclaje(frase: list, palabras: list, desde: int, ventana: int = 80):
    """Copia del criterio de herramientas/planos_tiempos.py."""
    if not frase:
        return None, None
    limite = len(palabras)
    largo = len(frase)
    for k in range(desde, limite - largo + 1):
        if palabras[k:k + largo] == frase:
            return k, "exacto"
    minimo = max(2, math.ceil(largo / 2))
    for corto in range(largo - 1, minimo - 1, -1):
        for k in range(desde, limite - corto + 1):
            if palabras[k:k + corto] == frase[:corto]:
                return k, "parcial"
    mejor, mejor_k = 0.0, None
    texto = " ".join(frase)
    for k in range(desde, min(limite, desde + ventana)):
        candidato = " ".join(palabras[k:k + largo])
        parecido = difflib.SequenceMatcher(None, texto, candidato, autojunk=False).ratio()
        if parecido > mejor:
            mejor, mejor_k = parecido, k
    if mejor >= 0.75:
        return mejor_k, "aproximado"
    return None, None


def revisar_titulo(titulo: str, nombre: str, errores: list) -> None:
    if not titulo:
        errores.append(f"Falta el {nombre}.")
        return
    gritadas = en_mayusculas(titulo)
    if gritadas:
        errores.append(f"El {nombre} tiene palabras en MAYÚSCULAS sostenidas: {', '.join(gritadas)}.")
    if contar(titulo) > MAX_PALABRAS_TITULO:
        errores.append(f"El {nombre} tiene {contar(titulo)} palabras (máximo {MAX_PALABRAS_TITULO}): \"{titulo}\".")


def sincronizar(ruta_md: Path) -> list:
    """Reescribe el .txt desde la narración del .md y actualiza los conteos. Devuelve los cambios."""
    cambios = []
    original = ruta_md.read_text(encoding="utf-8")
    lineas = original.splitlines()
    secciones = secciones_md(lineas)
    rango = buscar_seccion(secciones, "narracion")
    if not rango:
        return cambios
    bloques = bloques_md(lineas[rango[0]:rango[1]])
    if [b[0] for b in bloques] != list(range(1, 9)):
        return cambios
    conteos = [contar(b[2]) for b in bloques]
    total = sum(conteos)

    texto_txt = "\n\n".join(" ".join(b[2].split()) for b in bloques) + "\n"
    ruta_txt = ruta_md.with_suffix(".txt")
    if not ruta_txt.exists() or ruta_txt.read_text(encoding="utf-8") != texto_txt:
        ruta_txt.write_text(texto_txt, encoding="utf-8", newline="\n")
        cambios.append(f"{ruta_txt.name}: narración reescrita desde el .md")

    nueva_linea = (f"- **Conteo real**: {total} palabras ({', '.join(str(c) for c in conteos)}), "
                   "contadas con script")
    salida = []
    puesta = False
    saltar = False
    indice_narracion = next(i for i, l in enumerate(lineas) if l.startswith("## "))
    for i, linea in enumerate(lineas):
        if saltar:
            if linea.startswith("  ") and linea.strip():
                continue
            saltar = False
        if i < indice_narracion and LINEA_CONTEO.match(linea):
            salida.append(nueva_linea)
            puesta = True
            saltar = True
            continue
        if i == indice_narracion and not puesta:
            while salida and not salida[-1].strip():
                salida.pop()
            salida.extend([nueva_linea, ""])
            puesta = True
        marca = ETIQUETA_BLOQUE.match(linea)
        if marca and marca.group(4) and rango[0] <= i < rango[1]:
            linea = f"{marca.group(1)} ({conteos[int(marca.group(2)) - 1]} palabras)"
        salida.append(linea)
    nuevo = "\n".join(salida) + "\n"
    nuevo = re.sub(r"(Conteo real con script: \*\*)\d+( palabras\*\*)", rf"\g<1>{total}\g<2>", nuevo)
    if nuevo != original:
        ruta_md.write_text(nuevo, encoding="utf-8", newline="\n")
        cambios.append(f"{ruta_md.name}: conteos actualizados ({total} palabras)")
    return cambios


def revisar(ruta_md: Path, max_plano: float) -> dict:
    errores, avisos = [], []
    datos = {"archivo": ruta_md.name, "numero": ruta_md.name[:3], "palabras": 0, "planos": 0,
             "bloques": [], "mayusculas": 0, "errores": errores, "avisos": avisos}

    ruta_txt = ruta_md.with_suffix(".txt")
    texto_md = ruta_md.read_text(encoding="utf-8")
    if not ruta_txt.exists():
        errores.append(f"Falta el archivo '{ruta_txt.name}'.")
        texto_txt = ""
    else:
        texto_txt = ruta_txt.read_text(encoding="utf-8")

    for nombre, texto in ((ruta_md.name, texto_md), (ruta_txt.name, texto_txt)):
        for n, linea in enumerate(texto.splitlines(), start=1):
            if RAYA_LARGA in linea:
                errores.append(f"Raya larga (U+2014) en {nombre}, línea {n}.")

    datos["palabras"] = contar(texto_txt)
    datos["segundos"] = round(datos["palabras"] * 60 / PALABRAS_POR_MINUTO)

    lineas = texto_md.splitlines()
    secciones = secciones_md(lineas)
    for clave in SECCIONES:
        if buscar_seccion(secciones, clave) is None:
            errores.append(f"Falta la sección '## {NOMBRES_SECCIONES[clave]}'.")

    # Título y título alterno
    encabezado = re.match(r"#\s+Guion(?:\s+piloto)?\s+(\d{3}):\s*(.+)$", lineas[0] if lineas else "")
    if not encabezado:
        errores.append("La primera línea debe ser '# Guion NNN: Título'.")
    else:
        if encabezado.group(1) != datos["numero"]:
            errores.append(f"El título dice guion {encabezado.group(1)} y el archivo es el {datos['numero']}.")
        datos["titulo"] = encabezado.group(2).strip()
        revisar_titulo(datos["titulo"], "título", errores)
    alterno = re.search(r"^- \*\*Título alterno\*\*:\s*(.+)$", texto_md, flags=re.MULTILINE)
    datos["titulo_alterno"] = alterno.group(1).strip() if alterno else ""
    revisar_titulo(datos["titulo_alterno"], "título alterno ('- **Título alterno**:')", errores)

    # Bloques y narración del .md
    rango = buscar_seccion(secciones, "narracion")
    bloques = bloques_md(lineas[rango[0]:rango[1]]) if rango else []
    numeros = [b[0] for b in bloques]
    if numeros != list(range(1, 9)):
        errores.append(f"Se esperan los bloques 1 a 8 en orden; encontré {numeros}.")
    datos["bloques"] = [contar(b[2]) for b in bloques]
    for n, _, texto, declarado in bloques:
        if declarado is not None and declarado != contar(texto):
            errores.append(f"El bloque {n} dice ({declarado} palabras) y tiene {contar(texto)}.")

    narracion_md = [" ".join(b[2].split()) for b in bloques]
    narracion_txt = parrafos(texto_txt)
    if narracion_md != narracion_txt:
        if " ".join(narracion_md) == " ".join(narracion_txt):
            errores.append("La narración del .md y la del .txt tienen el mismo texto pero "
                           "distinta división en párrafos.")
        else:
            a = " ".join(narracion_md).split()
            b = " ".join(narracion_txt).split()
            diferencia = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
            errores.append(
                "La narración del .md no es idéntica a la del .txt. Primera diferencia: "
                f".md \"{' '.join(a[max(0, diferencia - 3):diferencia + 4])}\" / "
                f".txt \"{' '.join(b[max(0, diferencia - 3):diferencia + 4])}\"."
            )

    # Conteo declarado en la ficha
    declarado = re.search(r"^- \*\*Conteo real\*\*:\s*(\d+)\s+palabras\s*\(([\d,\s]+)\)", texto_md,
                          flags=re.MULTILINE)
    if declarado:
        total = int(declarado.group(1))
        por_bloque = [int(x) for x in declarado.group(2).replace(" ", "").split(",") if x]
        if total != datos["palabras"]:
            errores.append(f"La ficha declara {total} palabras y la narración tiene {datos['palabras']}.")
        if por_bloque != datos["bloques"]:
            errores.append(f"La ficha declara por bloque {por_bloque} y el real es {datos['bloques']}.")
    else:
        errores.append("La ficha no declara el conteo ('- **Conteo real**: N palabras (a, b, ...)'). "
                       "Se arregla con --sincronizar.")
    otro = re.search(r"Conteo real con script: \*\*(\d+) palabras\*\*", texto_md)
    if otro and int(otro.group(1)) != datos["palabras"]:
        errores.append(f"La introducción dice {otro.group(1)} palabras y la narración tiene {datos['palabras']}.")

    # Frases
    narracion = " ".join(narracion_txt)
    frases = frases_de(narracion)
    if frases:
        inicio = sin_tildes(frases[0]).lower()
        if not inicio.startswith(INICIOS_VALIDOS):
            errores.append(f"La primera frase no empieza por 'In this world/town/school': \"{frases[0][:60]}\".")
    for frase in frases:
        if contar(frase) > MAX_PALABRAS_FRASE:
            errores.append(f"Frase de {contar(frase)} palabras: \"{frase}\"")

    # Palabras clave en mayúsculas
    datos["mayusculas"] = len(en_mayusculas(narracion))
    if datos["mayusculas"] < MAYUSCULAS_MIN:
        errores.append(f"La narración tiene {datos['mayusculas']} palabras en MAYÚSCULAS; "
                       f"se esperan al menos {MAYUSCULAS_MIN} (lo recomendado es de "
                       f"{MAYUSCULAS_MIN} a {MAYUSCULAS_MAX}).")

    # Planos
    rango = buscar_seccion(secciones, "lista de planos")
    planos = leer_planos(lineas[rango[0]:rango[1]]) if rango else []
    datos["planos"] = len(planos)
    if not planos:
        errores.append("No pude leer la tabla de planos.")
    if [n for n, _ in planos] != list(range(1, len(planos) + 1)):
        errores.append("Los planos no están numerados de corrido desde 1.")

    claves = [normalizar(p) for p in palabras_de(narracion)]
    anclas = []
    desde = 0
    for numero, frase in planos:
        indice, tipo = buscar_anclaje(claves_de_frase(frase), claves, desde)
        anclas.append(indice)
        if tipo is None:
            errores.append(f"Plano {numero}: no ancla. \"{frase}\" no está en la narración después del plano anterior.")
        elif tipo != "exacto":
            real = " ".join(claves[indice:indice + 6])
            errores.append(f"Plano {numero}: anclaje {tipo}. \"{frase}\" cae en \"{real}...\".")
        if indice is not None:
            desde = indice + 1
    if planos and anclas[0] not in (0, None):
        errores.append("El plano 1 no empieza en la primera palabra de la narración.")

    # Duración estimada de cada plano
    datos["plano_max"] = 0.0
    for posicion, (numero, frase) in enumerate(planos):
        if anclas[posicion] is None:
            continue
        siguiente = next((a for a in anclas[posicion + 1:] if a is not None), len(claves))
        segundos = (siguiente - anclas[posicion]) * 60 / PALABRAS_POR_MINUTO
        datos["plano_max"] = max(datos["plano_max"], round(segundos, 1))
        if segundos > max_plano:
            avisos.append(f"Plano {numero}: duraría unos {segundos:.1f} s "
                          f"({siguiente - anclas[posicion]} palabras). \"{frase}\"")
    return datos


def main() -> int:
    analizador = argparse.ArgumentParser(
        description="Verifica los guiones de la carpeta guiones/: conteo de palabras, narración "
                    "idéntica en .md y .txt, 8 bloques, secciones, raya larga, frases largas, "
                    "primera frase, títulos, palabras clave en mayúsculas y anclaje de cada plano.",
        epilog="Ejemplos: python guiones/verificar.py | python guiones/verificar.py 001 019 --detalle "
               "| python guiones/verificar.py --sincronizar",
    )
    analizador.add_argument("numeros", nargs="*", help="Números de guion a revisar (por defecto, todos).")
    analizador.add_argument("--detalle", action="store_true", help="Muestra los avisos de planos largos.")
    analizador.add_argument("--max-plano", type=float, default=3.5,
                            help="Segundos a partir de los cuales un plano se avisa como largo (por defecto: 3.5).")
    analizador.add_argument("--sincronizar", action="store_true",
                            help="Antes de revisar, reescribe cada .txt desde la narración del .md "
                                 "y actualiza los conteos de la ficha.")
    analizador.add_argument("--json", action="store_true", help="Imprime el resultado como JSON.")
    args = analizador.parse_args()

    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    rutas = sorted(CARPETA.glob("[0-9][0-9][0-9]-*.md"))
    if args.numeros:
        pedidos = {n.zfill(3) for n in args.numeros}
        rutas = [r for r in rutas if r.name[:3] in pedidos]
    if not rutas:
        print("No encontré guiones para revisar.")
        return 1

    if args.sincronizar:
        for ruta in rutas:
            for cambio in sincronizar(ruta):
                if not args.json:
                    print(f"Sincronizado: {cambio}")

    resultados = [revisar(ruta, args.max_plano) for ruta in rutas]

    # Raya larga en los demás archivos de texto de la carpeta
    otros = []
    for ruta in sorted(CARPETA.iterdir()):
        if ruta.suffix.lower() in (".md", ".txt", ".py") and not re.match(r"\d{3}-", ruta.name):
            for n, linea in enumerate(ruta.read_text(encoding="utf-8").splitlines(), start=1):
                if RAYA_LARGA in linea:
                    otros.append(f"Raya larga (U+2014) en {ruta.name}, línea {n}.")

    vistos = [r["numero"] for r in resultados]
    for numero in sorted(set(vistos)):
        if vistos.count(numero) > 1:
            otros.append(f"Hay más de un guion con el número {numero}.")

    if args.json:
        print(json.dumps({"guiones": resultados, "otros": otros}, ensure_ascii=False, indent=2))
    else:
        print(f"{'#':<4}{'Palabras':>9}{'Seg':>5}{'Planos':>8}{'Máx s':>7}{'MAYÚS':>7}  "
              f"{'Bloques':<34}{'Errores':>8}{'Avisos':>7}")
        for r in resultados:
            bloques = ",".join(str(b) for b in r["bloques"])
            print(f"{r['numero']:<4}{r['palabras']:>9}{r.get('segundos', 0):>5}{r['planos']:>8}"
                  f"{r.get('plano_max', 0):>7}{r['mayusculas']:>7}  {bloques:<34}"
                  f"{len(r['errores']):>8}{len(r['avisos']):>7}")
        print()
        for r in resultados:
            for error in r["errores"]:
                print(f"ERROR {r['numero']}: {error}")
            if args.detalle:
                for aviso in r["avisos"]:
                    print(f"AVISO {r['numero']}: {aviso}")
        for error in otros:
            print(f"ERROR: {error}")

    total_errores = sum(len(r["errores"]) for r in resultados) + len(otros)
    total_avisos = sum(len(r["avisos"]) for r in resultados)
    if not args.json:
        total_palabras = sum(r["palabras"] for r in resultados)
        print(f"Guiones: {len(resultados)}. Palabras: {total_palabras}. "
              f"Errores: {total_errores}. Avisos de plano largo: {total_avisos}"
              + ("" if args.detalle or not total_avisos else " (míralos con --detalle)") + ".")
    return 1 if total_errores else 0


if __name__ == "__main__":
    sys.exit(main())
