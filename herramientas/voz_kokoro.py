"""Genera la narracion de un video con Kokoro-82M (voz sintetica local, CPU, licencia
Apache 2.0). Es la voz gratuita del canal; se probo en el video 001.

Se ejecuta con el Python del entorno de Kokoro, no con el de las herramientas:

    herramientas\\kokoro\\.venv\\Scripts\\python.exe herramientas\\voz_kokoro.py --video 001
    ... --voz am_puck            otra voz (af_heart por defecto; af_bella, am_michael, am_puck...)
    ... --salida RUTA.wav        por defecto videos/NNN-slug/voz/voz.wav

Normalmente no se llama a mano: `producir.py voz NNN` lo corre y sigue con ritmo, tiempos y
subtitulos. Instalacion del entorno y de los modelos: herramientas/kokoro/LEEME.txt.

Lee guiones/NNN-slug.txt, pasa a minusculas las palabras en MAYUSCULAS (son solo para
resaltar en subtitulos; se conserva "I"), sintetiza oracion por oracion y une todo con
pausas cortas. Tarda unos 3 segundos por segundo de audio en este equipo.
"""
import argparse
import glob
import re
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro

RAIZ = Path(__file__).resolve().parent.parent
MODELO = RAIZ / "herramientas" / "kokoro" / "modelos" / "kokoro-v1.0.onnx"
VOCES = RAIZ / "herramientas" / "kokoro" / "modelos" / "voices-v1.0.bin"

PAUSA_ORACION = 0.20    # segundos entre oraciones
PAUSA_PARRAFO = 0.45    # segundos entre parrafos
MARGEN_SILENCIO = 0.03  # silencio que se deja en los bordes de cada oracion
UMBRAL = 10 ** (-45 / 20)


def bajar_mayusculas(texto: str) -> str:
    """Pasa a minusculas las palabras escritas enteras en mayusculas (2+ letras)."""
    def cambiar(m: re.Match) -> str:
        palabra = m.group(0)
        antes = texto[: m.start()].rstrip()
        abre = (not antes) or antes[-1] in ".!?"
        return palabra.capitalize() if abre else palabra.lower()

    return re.sub(r"\b[A-Z]{2,}\b", cambiar, texto)


def oraciones(parrafo: str) -> list[str]:
    partes = re.split(r'(?:(?<=[.!?])|(?<=[.!?]"))\s+(?=[A-Z"])', parrafo.strip())
    return [p.strip() for p in partes if p.strip()]


def recortar(audio: np.ndarray, fm: int) -> np.ndarray:
    fuertes = np.flatnonzero(np.abs(audio) > UMBRAL)
    if fuertes.size == 0:
        return audio
    margen = int(MARGEN_SILENCIO * fm)
    return audio[max(0, fuertes[0] - margen): min(len(audio), fuertes[-1] + margen)]


def main() -> int:
    ap = argparse.ArgumentParser(description="Narracion con Kokoro-82M")
    ap.add_argument("--video", required=True)
    ap.add_argument("--voz", default="af_heart")
    ap.add_argument("--velocidad", type=float, default=1.0)
    ap.add_argument("--idioma", default="en-us")
    ap.add_argument("--salida")
    args = ap.parse_args()

    carpetas = glob.glob(str(RAIZ / "videos" / (args.video.zfill(3) + "-*")))
    if not carpetas:
        print("No existe la carpeta del video", args.video)
        return 1
    video = Path(carpetas[0])
    guion = RAIZ / "guiones" / (video.name + ".txt")
    for f in (guion, MODELO, VOCES):
        if not f.exists():
            print(f"Falta el archivo: {f.relative_to(RAIZ)} (ver herramientas/kokoro/LEEME.txt)")
            return 1

    texto = bajar_mayusculas(guion.read_text(encoding="utf-8"))
    plan = [oraciones(p) for p in re.split(r"\n\s*\n", texto) if p.strip()]
    print(f"Guion: {guion.name}, {len(plan)} parrafos, {sum(len(p) for p in plan)} oraciones, {len(texto.split())} palabras")

    kokoro = Kokoro(str(MODELO), str(VOCES))
    trozos = []
    fm = 24000
    for ip, parrafo in enumerate(plan):
        for io, oracion in enumerate(parrafo):
            audio, fm = kokoro.create(oracion, voice=args.voz, speed=args.velocidad, lang=args.idioma)
            trozos.append(recortar(np.asarray(audio, dtype=np.float32), fm))
            ultima_parrafo = io == len(parrafo) - 1
            if not (ultima_parrafo and ip == len(plan) - 1):
                trozos.append(np.zeros(int((PAUSA_PARRAFO if ultima_parrafo else PAUSA_ORACION) * fm), dtype=np.float32))
    total = np.concatenate(trozos)
    salida = Path(args.salida) if args.salida else video / "voz" / "voz.wav"
    salida.parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(salida), total, fm, subtype="PCM_16")
    print(f"{salida.name}: {len(total) / fm:.2f} s, {fm} Hz, voz {args.voz}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
