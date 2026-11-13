"""Genera subtitulos.ass (1080x1920) palabra por palabra con el estilo del formato."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import comun

PUNTUACION_FUERTE = ".?!"
PUNTUACION_SUAVE = ",;:"
BORDES_A_QUITAR = ".,;:\"“”‘()[]"


def color_ass(color_hex: str) -> str:
    """Convierte #RRGGBB al formato de ASS (&H00BBGGRR)."""
    limpio = color_hex.strip().lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", limpio):
        raise comun.ErrorHerramienta(f"Color inválido: '{color_hex}'. Usa el formato #RRGGBB.")
    rojo, verde, azul = limpio[0:2], limpio[2:4], limpio[4:6]
    return f"&H00{azul}{verde}{rojo}".upper()


def tiempo_ass(segundos: float) -> str:
    centesimas = max(0, int(round(segundos * 100)))
    horas, resto = divmod(centesimas, 360000)
    minutos, resto = divmod(resto, 6000)
    seg, cent = divmod(resto, 100)
    return f"{horas}:{minutos:02d}:{seg:02d}.{cent:02d}"


def texto_visible(palabra: str, conservar_puntuacion: bool) -> str:
    texto = palabra.replace("’", "'").replace("{", "(").replace("}", ")").replace("\\", "/")
    if not conservar_puntuacion:
        texto = texto.strip(BORDES_A_QUITAR)
        texto = texto.replace("\"", "").replace("“", "").replace("”", "")
    return texto


def crear_medidor(archivo_fuente: Path):
    """Devuelve una función que estima el ancho en pixeles de un texto a tamaño ASS 1.

    libass escala la fuente para que ascendente + descendente midan el tamaño
    pedido, así que el ancho real es (ancho a tamaño S) / (ascendente + descendente).
    Sin Pillow se usa una estimación por número de caracteres.
    """
    try:
        from PIL import ImageFont
        fuente = ImageFont.truetype(str(archivo_fuente), 200)
        ascendente, descendente = fuente.getmetrics()
        return lambda texto: fuente.getlength(texto) / (ascendente + descendente)
    except Exception:  # Pillow ausente o fuente ilegible: estimación conservadora.
        return lambda texto: 0.5 * len(texto)


def leer_claves(ruta) -> set:
    claves = set()
    for linea in comun.leer_texto(comun.exigir_archivo(ruta, "la lista de palabras clave")).splitlines():
        linea = linea.split("#", 1)[0]
        for palabra in linea.split():
            if comun.normalizar(palabra):
                claves.add(comun.normalizar(palabra))
    return claves


def es_mayuscula(palabra: str) -> bool:
    letras = [c for c in palabra if c.isalpha()]
    return len(letras) >= 2 and all(c.isupper() for c in letras)


def armar_bloques(palabras: list, max_palabras: int, max_caracteres: int, pausa: float,
                  conservar_puntuacion: bool) -> list:
    """Agrupa las palabras en bloques cortos, cortando en pausas y en la puntuación."""
    # 1. Frases: tramos entre signos de puntuación o pausas.
    frases = []
    actual = []
    for palabra in palabras:
        visible = texto_visible(palabra["palabra"], conservar_puntuacion)
        if not visible:
            continue
        if actual:
            anterior = actual[-1]
            final_anterior = anterior["palabra"].rstrip("\"”’')")[-1:]
            if (
                final_anterior in PUNTUACION_FUERTE
                or (final_anterior in PUNTUACION_SUAVE and len(actual) >= 2)
                or float(palabra["inicio"]) - float(anterior["fin"]) > pausa
            ):
                frases.append(actual)
                actual = []
        actual.append({**palabra, "visible": visible})
    if actual:
        frases.append(actual)

    # 2. Cada frase se reparte en bloques parejos, para no dejar una palabra suelta al final.
    def largo(grupo: list) -> int:
        return sum(len(p["visible"]) for p in grupo) + len(grupo) - 1

    def partir(grupo: list) -> list:
        if len(grupo) > 1 and largo(grupo) > max_caracteres:
            mitad = (len(grupo) + 1) // 2
            return partir(grupo[:mitad]) + partir(grupo[mitad:])
        return [grupo]

    bloques = []
    for frase in frases:
        cantidad = -(-len(frase) // max_palabras)
        base, sobrantes = divmod(len(frase), cantidad)
        cursor = 0
        for numero in range(cantidad):
            tamano = base + (1 if numero < sobrantes else 0)
            bloques.extend(partir(frase[cursor:cursor + tamano]))
            cursor += tamano
    return bloques


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Convierte palabras.json en subtitulos.ass para video vertical de 1080x1920: bloques "
            "de 1 a 3 palabras en el tercio superior, letra gruesa redondeada blanca con borde "
            "negro, palabras clave en MAYÚSCULAS con color de acento y una entrada con escala."
        ),
        epilog="Ejemplo: python subtitulos.py --palabras palabras.json --salida subtitulos.ass --claves claves.txt",
    )
    analizador.add_argument("--palabras", required=True, help="palabras.json de entrada.")
    analizador.add_argument("--salida", default="subtitulos.ass", help="Archivo .ass de salida (por defecto: subtitulos.ass).")
    analizador.add_argument("--max-palabras", type=int, default=3, help="Máximo de palabras por bloque (por defecto: 3; usa 1 para una palabra a la vez).")
    analizador.add_argument("--max-caracteres", type=int, default=16, help="Máximo de caracteres por bloque (por defecto: 16).")
    analizador.add_argument("--pausa", type=float, default=0.35, help="Una pausa más larga que esto, en segundos, corta el bloque (por defecto: 0.35).")
    analizador.add_argument("--claves", help="Archivo de texto con las palabras clave (una o varias por línea). Por defecto se usan las que ya vienen en MAYÚSCULAS en palabras.json.")
    analizador.add_argument("--todo-mayusculas", action="store_true", help="Escribe todo el subtítulo en mayúsculas (las claves siguen con color de acento).")
    analizador.add_argument("--conservar-puntuacion", action="store_true", help="No quita puntos, comas ni comillas.")
    analizador.add_argument("--fuente", default=comun.NOMBRE_FUENTE, help=f"Nombre de la familia tipográfica (por defecto: {comun.NOMBRE_FUENTE}).")
    analizador.add_argument("--archivo-fuente", default=str(comun.ARCHIVO_FUENTE), help="Archivo .ttf de esa fuente, para medir el ancho del texto (por defecto: el de la carpeta fuentes).")
    analizador.add_argument("--tamano", type=int, default=120, help="Tamaño de letra (por defecto: 120).")
    analizador.add_argument("--borde", type=float, default=9, help="Grosor del borde negro (por defecto: 9).")
    analizador.add_argument("--sombra", type=float, default=3, help="Desplazamiento de la sombra (por defecto: 3; 0 la quita).")
    analizador.add_argument("--altura", type=float, default=0.24, help="Posición vertical del centro del texto, como fracción del alto (por defecto: 0.24, tercio superior).")
    analizador.add_argument("--margen", type=int, default=70, help="Margen lateral mínimo en pixeles (por defecto: 70).")
    analizador.add_argument("--color", default="#FFFFFF", help="Color del texto (por defecto: #FFFFFF).")
    analizador.add_argument("--color-acento", default="#FFE600", help="Color de las palabras clave (por defecto: #FFE600).")
    analizador.add_argument("--sin-animacion", action="store_true", help="Quita la animación de entrada.")
    args = analizador.parse_args()

    if args.max_palabras < 1:
        raise comun.ErrorHerramienta("--max-palabras tiene que ser 1 o más.")
    palabras = comun.leer_palabras(args.palabras)
    if args.claves:
        claves = leer_claves(args.claves)
        origen = f"archivo '{args.claves}'"
    else:
        claves = {comun.normalizar(p["palabra"]) for p in palabras if es_mayuscula(p["palabra"])}
        origen = "palabras en MAYÚSCULAS del guion"

    medir = crear_medidor(Path(args.archivo_fuente))
    ancho_util = comun.ANCHO - 2 * args.margen
    x = comun.ANCHO // 2
    y = int(round(comun.ALTO * args.altura))
    blanco = color_ass(args.color)
    acento = color_ass(args.color_acento)

    bloques = armar_bloques(palabras, args.max_palabras, args.max_caracteres, args.pausa,
                            args.conservar_puntuacion)
    lineas = []
    resaltadas = 0
    reducidos = 0
    for posicion, bloque in enumerate(bloques):
        inicio = float(bloque[0]["inicio"])
        fin_voz = float(bloque[-1]["fin"])
        if posicion + 1 < len(bloques):
            siguiente = float(bloques[posicion + 1][0]["inicio"])
            fin = siguiente if siguiente - fin_voz < 0.6 else fin_voz + 0.2
        else:
            fin = fin_voz + 0.3
        if fin - inicio < 0.05:
            fin = inicio + 0.05

        partes = []
        plano = []
        for palabra in bloque:
            visible = palabra["visible"]
            clave = comun.normalizar(palabra["palabra"]) in claves
            if clave or args.todo_mayusculas:
                visible = visible.upper()
            plano.append(visible)
            if clave:
                partes.append(f"{{\\c{acento}&}}{visible}{{\\c{blanco}&}}")
                resaltadas += 1
            else:
                partes.append(visible)

        # Si el bloque no cabe en una línea, se reduce la letra solo para ese bloque.
        tamano = args.tamano
        necesario = medir(" ".join(plano)) * tamano * 1.08 + 2 * args.borde
        etiqueta_tamano = ""
        if necesario > ancho_util:
            tamano = int(tamano * ancho_util / necesario)
            etiqueta_tamano = f"\\fs{tamano}"
            reducidos += 1

        if args.sin_animacion:
            animacion = ""
        else:
            animacion = "\\fscx78\\fscy78\\t(0,70,\\fscx108\\fscy108)\\t(70,140,\\fscx100\\fscy100)"
        etiquetas = f"{{\\an5\\pos({x},{y}){etiqueta_tamano}{animacion}}}"
        lineas.append(
            f"Dialogue: 0,{tiempo_ass(inicio)},{tiempo_ass(fin)},Base,,0,0,0,,{etiquetas}{' '.join(partes)}"
        )

    encabezado = f"""[Script Info]
; Generado por subtitulos.py. Fuente: {args.fuente} (se carga con fontsdir, no hace falta instalarla).
ScriptType: v4.00+
PlayResX: {comun.ANCHO}
PlayResY: {comun.ALTO}
WrapStyle: 2
ScaledBorderAndShadow: yes
YCbCr Matrix: None

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Base,{args.fuente},{args.tamano},{blanco},{blanco},&H00000000,&H78000000,0,0,0,0,100,100,0,0,1,{args.borde:g},{args.sombra:g},5,{args.margen},{args.margen},{args.margen},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    salida = Path(args.salida)
    salida.parent.mkdir(parents=True, exist_ok=True)
    salida.write_text(encabezado + "\n".join(lineas) + "\n", encoding="utf-8", newline="\n")

    print(f"Bloques: {len(bloques)} (de {len(palabras)} palabras, máximo {args.max_palabras} por bloque).")
    print(f"Palabras clave resaltadas: {resaltadas} (origen: {origen}).")
    if not claves:
        print("Nota: no hay palabras clave. Escribe algunas en MAYÚSCULAS en el guion o pasa --claves.")
    if reducidos:
        print(f"Bloques con letra reducida para caber en el ancho: {reducidos}.")
    print(f"Listo: '{salida}'")
    return 0


if __name__ == "__main__":
    comun.principal(main)
