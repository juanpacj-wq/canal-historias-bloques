"""Arma una hoja de contactos: un cuadro por plano, numerado, en una sola imagen PNG."""

from __future__ import annotations

import argparse
import math
import tempfile
from pathlib import Path

import comun


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Saca un cuadro por cada plano de planos.json y arma una hoja de contactos PNG "
            "numerada, para revisar todos los planos de un vistazo. Los planos demasiado cortos "
            "o largos salen con la etiqueta en rojo."
        ),
        epilog="Ejemplo: python hoja_contactos.py --video final.mp4 --planos planos.json --salida hoja.png",
    )
    analizador.add_argument("--video", required=True, help="Video del que se sacan los cuadros.")
    analizador.add_argument("--planos", required=True, help="planos.json con los tiempos.")
    analizador.add_argument("--salida", default="hoja_contactos.png", help="PNG de salida (por defecto: hoja_contactos.png).")
    analizador.add_argument("--columnas", type=int, default=0, help="Columnas de la hoja (0 = automático según el formato del video).")
    analizador.add_argument("--ancho", type=int, default=0, help="Ancho de cada miniatura en pixeles (0 = automático).")
    analizador.add_argument("--posicion", type=float, default=0.5, help="Punto del plano del que se saca el cuadro, de 0 (inicio) a 1 (fin). Por defecto: 0.5.")
    analizador.add_argument("--desfase", type=float, default=0.0, help="Segundos que se suman a los tiempos de planos.json (útil para una grabación sin montar).")
    analizador.add_argument("--min", type=float, default=0.6, dest="minimo", help="Duración mínima recomendada de un plano (por defecto: 0.6 s).")
    analizador.add_argument("--max", type=float, default=3.5, dest="maximo", help="Duración máxima recomendada de un plano (por defecto: 3.5 s).")
    args = analizador.parse_args()

    try:
        from PIL import Image, ImageDraw, ImageFont
    except ImportError as error:
        raise comun.ErrorHerramienta(
            "Falta el paquete 'Pillow'. Instálalo con: python -m pip install -r herramientas/requirements.txt"
        ) from error

    video = comun.exigir_archivo(args.video, "el video").resolve()
    datos = comun.leer_json(comun.exigir_archivo(args.planos, "planos.json"))
    planos = datos.get("planos", [])
    if not planos:
        raise comun.ErrorHerramienta("planos.json no tiene planos.")
    if not 0.0 <= args.posicion <= 1.0:
        raise comun.ErrorHerramienta("--posicion va de 0 a 1.")

    informacion = comun.ffprobe_json(video)
    imagen = next((s for s in informacion["streams"] if s.get("codec_type") == "video"), None)
    if not imagen:
        raise comun.ErrorHerramienta(f"'{video}' no tiene imagen.")
    duracion_video = float(informacion["format"]["duration"])
    vertical = int(imagen["height"]) > int(imagen["width"])
    columnas = args.columnas or (10 if vertical else 6)
    ancho = args.ancho or (180 if vertical else 300)
    alto = int(round(ancho * int(imagen["height"]) / int(imagen["width"]) / 2)) * 2

    try:
        fuente_numero = ImageFont.truetype(str(comun.ARCHIVO_FUENTE), 30)
        fuente_dato = ImageFont.truetype(str(comun.ARCHIVO_FUENTE), 15)
        fuente_titulo = ImageFont.truetype(str(comun.ARCHIVO_FUENTE), 24)
    except OSError:
        fuente_numero = fuente_dato = fuente_titulo = ImageFont.load_default()

    margen = 8
    pie = 22
    cabecera = 44
    filas = math.ceil(len(planos) / columnas)
    hoja = Image.new(
        "RGB",
        (margen + columnas * (ancho + margen), cabecera + filas * (alto + pie + margen) + margen),
        (24, 24, 28),
    )
    dibujo = ImageDraw.Draw(hoja)
    titulo = f"{datos.get('video', video.stem)}   {len(planos)} planos   {comun.formato_tiempo(duracion_video)}"
    dibujo.text((margen, 8), titulo, font=fuente_titulo, fill=(255, 255, 255))

    fuera_de_rango = 0
    with tempfile.TemporaryDirectory(prefix="hoja_") as carpeta:
        for posicion, plano in enumerate(planos):
            largo = float(plano["fin"]) - float(plano["inicio"])
            instante = float(plano["inicio"]) + largo * args.posicion + args.desfase
            instante = min(max(instante, 0.0), max(0.0, duracion_video - 0.05))
            cuadro = Path(carpeta) / f"{posicion:04d}.png"
            comun.ffmpeg([
                "-ss", f"{instante:.3f}", "-i", video, "-frames:v", "1",
                "-vf", f"scale={ancho}:{alto}:flags=bicubic", cuadro,
            ])
            if not cuadro.exists():
                raise comun.ErrorHerramienta(f"No pude sacar el cuadro del plano {plano['n']} ({instante:.2f} s).")
            x = margen + (posicion % columnas) * (ancho + margen)
            y = cabecera + (posicion // columnas) * (alto + pie + margen)
            with Image.open(cuadro) as miniatura:
                hoja.paste(miniatura.convert("RGB"), (x, y))

            malo = largo < args.minimo or largo > args.maximo
            fuera_de_rango += int(malo)
            numero = str(plano["n"])
            caja = dibujo.textbbox((0, 0), numero, font=fuente_numero)
            ancho_caja = caja[2] - caja[0] + 14
            dibujo.rectangle([x, y, x + ancho_caja, y + 38], fill=(200, 30, 30) if malo else (0, 0, 0))
            dibujo.text((x + 7, y + 2), numero, font=fuente_numero, fill=(255, 255, 255))
            dato = f"{comun.formato_tiempo(float(plano['inicio']))}  ({largo:.2f} s)"
            dibujo.text((x + 2, y + alto + 3), dato, font=fuente_dato,
                        fill=(255, 110, 110) if malo else (200, 200, 205))

    salida = Path(args.salida)
    salida.parent.mkdir(parents=True, exist_ok=True)
    hoja.save(salida, "PNG", optimize=True)
    print(f"Hoja de contactos: {len(planos)} planos en {columnas} columnas, {hoja.width}x{hoja.height} px.")
    if fuera_de_rango:
        print(f"Planos fuera del rango de {args.minimo} a {args.maximo} s (etiqueta roja): {fuera_de_rango}.")
    print(f"Listo: '{salida}'")
    return 0


if __name__ == "__main__":
    comun.principal(main)
