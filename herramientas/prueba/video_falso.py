"""Genera una grabación falsa para la prueba: cada plano es un color con su número encima.

Sirve para comprobar a ojo y con revisar.py que los cortes caen donde dice planos.json.
"""

from __future__ import annotations

import argparse
import colorsys
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import comun  # noqa: E402


def color_del_plano(posicion: int) -> str:
    """Colores bien distintos entre planos vecinos, para que el corte se detecte."""
    tono = (posicion * 0.381966) % 1.0
    # Se alterna claro y oscuro: el detector de cortes de ffmpeg mira sobre todo el brillo.
    if posicion % 2 == 0:
        rojo, verde, azul = colorsys.hsv_to_rgb(tono, 0.35, 1.0)
    else:
        rojo, verde, azul = colorsys.hsv_to_rgb(tono, 0.85, 0.28)
    return f"0x{int(rojo * 255):02X}{int(verde * 255):02X}{int(azul * 255):02X}"


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Genera un video falso a 60 cps en el que cada plano de planos.json es un color "
            "distinto con el número del plano sobreimpreso. Opcionalmente deja también un clip "
            "por plano, para probar 'montar.py --clips'."
        ),
        epilog="Ejemplo: python video_falso.py --planos planos.json --salida video_falso.mp4 --clips clips",
    )
    analizador.add_argument("--planos", required=True, help="planos.json con los tiempos.")
    analizador.add_argument("--salida", required=True, help="Video de salida.")
    analizador.add_argument("--tamano", default="1920x1080", help="Tamaño del video (por defecto: 1920x1080, horizontal).")
    analizador.add_argument("--clips", help="Carpeta donde se deja además un clip por plano (001.mp4, 002.mp4...).")
    args = analizador.parse_args()

    planos = comun.leer_json(comun.exigir_archivo(args.planos, "planos.json"))["planos"]
    salida = Path(args.salida).resolve()
    salida.parent.mkdir(parents=True, exist_ok=True)
    carpeta_clips = Path(args.clips).resolve() if args.clips else None
    if carpeta_clips:
        carpeta_clips.mkdir(parents=True, exist_ok=True)
    alto = int(args.tamano.split("x")[1])

    with tempfile.TemporaryDirectory(prefix="falso_") as carpeta:
        temporal = Path(carpeta)
        comun.preparar_carpeta_filtros(temporal)
        lista = []
        for posicion, plano in enumerate(planos):
            cuadros = round(plano["fin"] * comun.CPS) - round(plano["inicio"] * comun.CPS)
            if cuadros <= 0:
                continue
            nombre = f"{plano['n']:03d}.mp4"
            origen = f"color=c={color_del_plano(posicion)}:s={args.tamano}:r={comun.CPS}"
            texto = (
                f"drawtext=fontfile=fuentes/{comun.ARCHIVO_FUENTE.name}:text='{plano['n']}':"
                f"fontsize={int(alto * 0.42)}:fontcolor=white:borderw=12:bordercolor=black:"
                "x=(w-text_w)/2:y=(h-text_h)/2"
            )
            comun.ffmpeg(
                ["-f", "lavfi", "-i", origen, "-vf", texto, "-frames:v", str(cuadros), "-an",
                 "-c:v", "libx264", "-preset", "veryfast", "-crf", "18", "-pix_fmt", "yuv420p", nombre],
                cwd=temporal,
            )
            lista.append(f"file '{nombre}'")
            if carpeta_clips:
                shutil.copyfile(temporal / nombre, carpeta_clips / nombre)
        (temporal / "lista.txt").write_text("\n".join(lista) + "\n", encoding="utf-8")
        comun.ffmpeg(["-f", "concat", "-safe", "0", "-i", "lista.txt", "-c", "copy", salida], cwd=temporal)

    print(f"Video falso: {len(lista)} planos, {comun.duracion(salida):.2f} s, '{salida}'")
    if carpeta_clips:
        print(f"Clips por plano: '{carpeta_clips}'")
    return 0


if __name__ == "__main__":
    comun.principal(main)
