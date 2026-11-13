"""Ancla cada plano del guion a la palabra donde empieza su frase y escribe planos.json."""

from __future__ import annotations

import argparse
import difflib
import math
import re
import unicodedata
from pathlib import Path

import comun

COLUMNAS = {"#": "n", "frase": "texto", "escenario": "escenario", "en pantalla": "en_pantalla",
            "cara": "cara", "camara": "camara"}


def sin_tildes(texto: str) -> str:
    texto = unicodedata.normalize("NFKD", texto)
    return "".join(c for c in texto if not unicodedata.combining(c))


def partir_fila(linea: str) -> list:
    linea = linea.strip()
    if linea.startswith("|"):
        linea = linea[1:]
    if linea.endswith("|") and not linea.endswith("\\|"):
        linea = linea[:-1]
    return [celda.replace("\\|", "|").strip() for celda in re.split(r"(?<!\\)\|", linea)]


def leer_lista_de_planos(ruta: Path) -> list:
    """Lee la tabla Markdown que sigue al título 'Lista de planos'."""
    lineas = comun.leer_texto(ruta).splitlines()
    inicio = None
    for i, linea in enumerate(lineas):
        if linea.lstrip().startswith("#") and "lista de planos" in sin_tildes(linea).lower():
            inicio = i + 1
            break
    if inicio is None:
        raise comun.ErrorHerramienta(f"No encontré el título 'Lista de planos' en '{ruta}'.")

    filas = []
    for linea in lineas[inicio:]:
        if re.match(r"\s*#+\s", linea):
            break
        if linea.strip().startswith("|"):
            filas.append(partir_fila(linea))
        elif filas:
            break
    if len(filas) < 3:
        raise comun.ErrorHerramienta(f"La tabla 'Lista de planos' de '{ruta}' está vacía o incompleta.")

    indice = {}
    for posicion, titulo in enumerate(filas[0]):
        clave = sin_tildes(titulo).lower().strip()
        for prefijo, campo in COLUMNAS.items():
            if clave.startswith(prefijo):
                indice[campo] = posicion
    faltan = [campo for campo in COLUMNAS.values() if campo not in indice]
    if faltan:
        raise comun.ErrorHerramienta(
            "A la tabla de planos le faltan columnas: " + ", ".join(faltan)
            + ". Se esperan: # | Frase (inicio) | Escenario | En pantalla | Cara | Cámara."
        )

    planos = []
    for fila in filas[1:]:
        if all(re.fullmatch(r":?-{2,}:?", celda) for celda in fila if celda):
            continue
        fila = fila + [""] * (len(filas[0]) - len(fila))
        numero = re.search(r"\d+", fila[indice["n"]])
        if not numero:
            continue
        planos.append({
            "n": int(numero.group()),
            "texto": fila[indice["texto"]],
            "escenario": fila[indice["escenario"]],
            "en_pantalla": fila[indice["en_pantalla"]],
            "cara": fila[indice["cara"]],
            "camara": fila[indice["camara"]],
        })
    if not planos:
        raise comun.ErrorHerramienta(f"No hay planos en la tabla de '{ruta}'.")
    return planos


def claves_de_frase(frase: str) -> list:
    frase = frase.replace("…", " ").replace("...", " ")
    return [comun.normalizar(p) for p in frase.split() if comun.normalizar(p)]


def buscar_anclaje(frase: list, palabras: list, desde: int, ventana: int):
    """Busca dónde empieza la frase. Devuelve (índice, tipo) o (None, None).

    Tipos: 'exacto' (toda la frase), 'parcial' (solo el comienzo coincide) y
    'aproximado' (parecido de texto, tolera palabras cambiadas).
    """
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


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Toma la tabla 'Lista de planos' de un guion (guiones/NNN-*.md) y un palabras.json, "
            "y produce planos.json con el inicio y el fin de cada plano, anclados a la palabra "
            "donde empieza su frase. Avisa de planos muy cortos, muy largos o sin anclaje."
        ),
        epilog='Ejemplo: python planos_tiempos.py --guion "guiones/001-x.md" --palabras palabras.json --audio voz.wav --salida planos.json',
    )
    analizador.add_argument("--guion", required=True, help="Guion en Markdown con la tabla 'Lista de planos'.")
    analizador.add_argument("--palabras", required=True, help="palabras.json con el tiempo de cada palabra.")
    analizador.add_argument("--salida", default="planos.json", help="Archivo de salida (por defecto: planos.json).")
    analizador.add_argument("--audio", help="Audio de la voz; su duración se usa como duración del video.")
    analizador.add_argument("--cola", type=float, default=0.4, help="Segundos que se agregan al final (por defecto: 0.4).")
    analizador.add_argument("--adelanto", type=float, default=0.0, help="Segundos que se adelanta cada corte respecto a su palabra (por defecto: 0).")
    analizador.add_argument("--min", type=float, default=0.6, dest="minimo", help="Avisa si un plano dura menos que esto (por defecto: 0.6 s).")
    analizador.add_argument("--max", type=float, default=3.5, dest="maximo", help="Avisa si un plano dura más que esto (por defecto: 3.5 s).")
    analizador.add_argument("--ventana", type=int, default=80, help="Cuántas palabras hacia adelante se revisan en la búsqueda aproximada (por defecto: 80).")
    analizador.add_argument("--estricto", action="store_true", help="Termina con error si hay algún aviso.")
    args = analizador.parse_args()

    guion = comun.exigir_archivo(args.guion, "el guion")
    palabras = comun.leer_palabras(args.palabras)
    planos = leer_lista_de_planos(guion)
    claves = [comun.normalizar(p["palabra"]) for p in palabras]

    fin_voz = float(palabras[-1]["fin"])
    if args.audio:
        duracion_audio = comun.duracion(comun.exigir_archivo(args.audio, "el audio"))
        total = max(duracion_audio, fin_voz) + args.cola
    else:
        total = fin_voz + args.cola

    # 1. Anclar cada frase, siempre hacia adelante.
    anclas = []
    tipos = []
    desde = 0
    for plano in planos:
        indice, tipo = buscar_anclaje(claves_de_frase(plano["texto"]), claves, desde, args.ventana)
        anclas.append(indice)
        tipos.append(tipo)
        if indice is not None:
            desde = indice + 1

    # 2. Los planos sin anclaje se reparten entre sus vecinos anclados.
    avisos = []
    i = 0
    while i < len(planos):
        if anclas[i] is not None:
            i += 1
            continue
        j = i
        while j < len(planos) and anclas[j] is None:
            j += 1
        izquierda = anclas[i - 1] if i > 0 else -1
        derecha = anclas[j] if j < len(planos) else len(palabras)
        for paso, k in enumerate(range(i, j), start=1):
            estimado = izquierda + round((derecha - izquierda) * paso / (j - i + 1))
            anclas[k] = min(max(estimado, 0), len(palabras) - 1)
            tipos[k] = "sin anclaje"
            avisos.append(
                f"Plano {planos[k]['n']}: no encontré la frase \"{planos[k]['texto']}\" en la voz; "
                f"su inicio es estimado ({palabras[anclas[k]]['inicio']:.2f} s)."
            )
        i = j

    # 3. Tiempos de inicio y fin.
    inicios = []
    for posicion, indice in enumerate(anclas):
        if posicion == 0:
            inicios.append(0.0)
        else:
            inicios.append(max(0.0, float(palabras[indice]["inicio"]) - args.adelanto))
    for posicion in range(1, len(inicios)):
        if inicios[posicion] < inicios[posicion - 1]:
            inicios[posicion] = inicios[posicion - 1]

    salida = []
    for posicion, plano in enumerate(planos):
        inicio = round(inicios[posicion], 3)
        fin = round(inicios[posicion + 1] if posicion + 1 < len(planos) else total, 3)
        salida.append({
            "n": plano["n"],
            "inicio": inicio,
            "fin": fin,
            "texto": plano["texto"],
            "escenario": plano["escenario"],
            "en_pantalla": plano["en_pantalla"],
            "cara": plano["cara"],
            "camara": plano["camara"],
        })
        largo = fin - inicio
        if tipos[posicion] in ("parcial", "aproximado"):
            real = " ".join(p["palabra"] for p in palabras[anclas[posicion]:anclas[posicion] + 6])
            print(f"Nota: plano {plano['n']} con anclaje {tipos[posicion]}: \"{plano['texto']}\" -> \"{real}...\"")
        if largo < args.minimo:
            avisos.append(f"Plano {plano['n']}: dura {largo:.2f} s, menos de {args.minimo} s (\"{plano['texto']}\").")
        elif largo > args.maximo:
            avisos.append(f"Plano {plano['n']}: dura {largo:.2f} s, más de {args.maximo} s (\"{plano['texto']}\").")

    resultado = {"video": guion.stem, "duracion": round(total, 3), "planos": salida}
    comun.escribir_json(args.salida, resultado)

    duraciones = [p["fin"] - p["inicio"] for p in salida]
    print(f"Planos: {len(salida)}. Duración total: {total:.2f} s. "
          f"Plano medio: {sum(duraciones) / len(duraciones):.2f} s "
          f"(mínimo {min(duraciones):.2f}, máximo {max(duraciones):.2f}).")
    sin_ancla = sum(1 for tipo in tipos if tipo == "sin anclaje")
    print(f"Anclajes: {tipos.count('exacto')} exactos, {tipos.count('parcial')} parciales, "
          f"{tipos.count('aproximado')} aproximados, {sin_ancla} sin anclaje.")
    for aviso in avisos:
        print(f"AVISO: {aviso}")
    print(f"Listo: '{args.salida}'")
    if avisos and args.estricto:
        return 1
    return 0


if __name__ == "__main__":
    comun.principal(main)
