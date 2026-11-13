"""Saca el tiempo de cada palabra de un audio de voz y lo guarda en palabras.json."""

from __future__ import annotations

import argparse
import difflib
import os
import subprocess
from pathlib import Path

import comun


def reconocer(audio: Path, modelo: str, idioma: str, hilos: int, precision: str) -> list:
    """Transcribe con faster-whisper en CPU y devuelve las palabras con sus tiempos."""
    os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")
    try:
        import numpy
        from faster_whisper import WhisperModel
    except ImportError as error:
        raise comun.ErrorHerramienta(
            "Falta el paquete 'faster-whisper'. Instálalo con: "
            "python -m pip install -r herramientas/requirements.txt"
        ) from error

    # El audio se decodifica con ffmpeg (mono, 16 kHz, 32 bits flotante) y se le entrega
    # al modelo ya como arreglo. Así no dependemos del decodificador interno del paquete.
    decodificado = subprocess.run(
        [comun.buscar_ejecutable("ffmpeg"), "-hide_banner", "-nostdin", "-v", "error", "-i", str(audio),
         "-vn", "-ac", "1", "-ar", "16000", "-f", "f32le", "-"],
        capture_output=True,
        stdin=subprocess.DEVNULL,
    )
    if decodificado.returncode != 0 or not decodificado.stdout:
        detalle = decodificado.stderr.decode("utf-8", errors="replace").strip()[-400:]
        raise comun.ErrorHerramienta(f"ffmpeg no pudo leer el audio '{audio}'. {detalle}")
    muestras = numpy.frombuffer(decodificado.stdout, dtype=numpy.float32)

    if modelo.endswith(".en"):
        idioma = "en"
    print(f"Cargando el modelo '{modelo}' en CPU (la primera vez se descarga)...")
    motor = WhisperModel(modelo, device="cpu", compute_type=precision, cpu_threads=hilos)
    segmentos, _ = motor.transcribe(
        muestras,
        language=idioma,
        word_timestamps=True,
        beam_size=5,
        condition_on_previous_text=False,
    )
    palabras = []
    for segmento in segmentos:
        for palabra in segmento.words or []:
            texto = palabra.word.strip()
            if not texto:
                continue
            palabras.append(
                {"palabra": texto, "inicio": float(palabra.start), "fin": float(palabra.end)}
            )
    if not palabras:
        raise comun.ErrorHerramienta("El modelo no reconoció ninguna palabra en el audio.")
    return palabras


def repartir(inicio: float, fin: float, palabras: list) -> list:
    """Reparte un tramo de tiempo entre varias palabras según su largo."""
    pesos = [max(1, len(comun.normalizar(p))) for p in palabras]
    total = sum(pesos)
    tramos = []
    cursor = inicio
    for peso in pesos:
        siguiente = cursor + (fin - inicio) * peso / total
        tramos.append([cursor, siguiente])
        cursor = siguiente
    return tramos


def alinear_con_guion(reconocidas: list, guion: list):
    """Pone los tiempos de lo reconocido sobre las palabras reales del guion.

    Devuelve (palabras, coincidencias_exactas, diferencias). El resultado tiene
    exactamente las palabras del guion, en su orden y con su ortografía.
    """
    reconocidas = [r for r in reconocidas if comun.normalizar(r["palabra"])]
    clave_oida = [comun.normalizar(r["palabra"]) for r in reconocidas]
    clave_guion = [comun.normalizar(g) for g in guion]
    comparador = difflib.SequenceMatcher(None, clave_oida, clave_guion, autojunk=False)

    tiempos = [None] * len(guion)
    exactas = 0
    diferencias = []
    for operacion, i1, i2, j1, j2 in comparador.get_opcodes():
        if operacion == "equal":
            for desplazamiento in range(i2 - i1):
                oida = reconocidas[i1 + desplazamiento]
                tiempos[j1 + desplazamiento] = [oida["inicio"], oida["fin"]]
            exactas += i2 - i1
        elif operacion == "replace":
            tramo = repartir(reconocidas[i1]["inicio"], reconocidas[i2 - 1]["fin"], guion[j1:j2])
            tiempos[j1:j2] = tramo
            diferencias.append(
                (" ".join(guion[j1:j2]), " ".join(r["palabra"] for r in reconocidas[i1:i2]))
            )
        elif operacion == "insert":
            diferencias.append((" ".join(guion[j1:j2]), "(no se oyó)"))
        elif operacion == "delete":
            diferencias.append(("(no está en el guion)", " ".join(r["palabra"] for r in reconocidas[i1:i2])))

    # Palabras del guion que el modelo no oyó: se acomodan en el hueco entre vecinas.
    fin_audio = reconocidas[-1]["fin"]
    j = 0
    while j < len(tiempos):
        if tiempos[j] is not None:
            j += 1
            continue
        k = j
        while k < len(tiempos) and tiempos[k] is None:
            k += 1
        cantidad = k - j
        izquierda = tiempos[j - 1][1] if j > 0 else 0.0
        derecha = tiempos[k][0] if k < len(tiempos) else fin_audio
        minimo = 0.08 * cantidad
        if derecha - izquierda < minimo and j > 0:
            # No hay hueco: se le toma prestada la mitad a la palabra anterior.
            anterior = tiempos[j - 1]
            izquierda = anterior[0] + (anterior[1] - anterior[0]) / 2
            anterior[1] = izquierda
        if derecha - izquierda < minimo and k < len(tiempos):
            siguiente = tiempos[k]
            derecha = siguiente[0] + (siguiente[1] - siguiente[0]) / 2
            siguiente[0] = derecha
        derecha = max(derecha, izquierda)
        tiempos[j:k] = repartir(izquierda, derecha, guion[j:k])
        j = k

    palabras = []
    anterior = 0.0
    for texto, (inicio, fin) in zip(guion, tiempos):
        inicio = max(inicio, anterior)
        fin = max(fin, inicio)
        palabras.append({"palabra": texto, "inicio": round(inicio, 3), "fin": round(fin, 3)})
        anterior = inicio
    return palabras, exactas, diferencias


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Transcribe un audio de voz (wav o mp3) con faster-whisper en CPU y guarda el "
            "tiempo de cada palabra en un JSON: [{\"palabra\", \"inicio\", \"fin\"}]. "
            "Con --guion, las palabras quedan escritas como en el guion y no como las oyó el modelo."
        ),
        epilog='Ejemplo: python transcribir.py "voz rapida.wav" --guion guion.txt --salida palabras.json',
    )
    analizador.add_argument("audio", help="Audio de la voz (wav, mp3, m4a...).")
    analizador.add_argument("--salida", default="palabras.json", help="Archivo JSON de salida (por defecto: palabras.json).")
    analizador.add_argument("--guion", help="Texto real de la narración (.txt). Corrige la ortografía de lo reconocido.")
    analizador.add_argument("--modelo", default="small.en", help="Modelo de Whisper: tiny.en, base.en, small.en, medium.en... (por defecto: small.en).")
    analizador.add_argument("--idioma", default="en", help="Idioma del audio (por defecto: en). Los modelos '.en' siempre usan inglés.")
    analizador.add_argument("--hilos", type=int, default=0, help="Hilos de CPU (0 = automático).")
    analizador.add_argument("--precision", default="int8", help="Tipo de cálculo de CTranslate2 (por defecto: int8, el más rápido en CPU).")
    analizador.add_argument("--crudo", help="Guarda también lo que oyó el modelo, sin corregir, en este JSON.")
    args = analizador.parse_args()

    audio = comun.exigir_archivo(args.audio, "el audio")
    guion = None
    if args.guion:
        guion = comun.separar_palabras(comun.leer_texto(comun.exigir_archivo(args.guion, "el guion")))
        if not guion:
            raise comun.ErrorHerramienta(f"El guion '{args.guion}' está vacío.")

    reconocidas = reconocer(audio, args.modelo, args.idioma, args.hilos, args.precision)
    print(f"Palabras reconocidas: {len(reconocidas)}")
    if args.crudo:
        comun.escribir_json(
            args.crudo,
            [{"palabra": r["palabra"], "inicio": round(r["inicio"], 3), "fin": round(r["fin"], 3)} for r in reconocidas],
        )

    if guion:
        palabras, exactas, diferencias = alinear_con_guion(reconocidas, guion)
        porcentaje = 100.0 * exactas / len(guion)
        print(f"Palabras del guion: {len(guion)}. Coinciden con lo oído: {exactas} ({porcentaje:.1f} %).")
        if diferencias:
            print(f"Diferencias corregidas con el guion: {len(diferencias)}")
            for del_guion, oido in diferencias[:20]:
                print(f"  guion: {del_guion!r}  <-  oído: {oido!r}")
            if len(diferencias) > 20:
                print(f"  ... y {len(diferencias) - 20} más.")
        if porcentaje < 80:
            print("AVISO: menos del 80 % coincide. Revisa que el guion sea el de este audio.")
    else:
        palabras = [
            {"palabra": r["palabra"], "inicio": round(r["inicio"], 3), "fin": round(r["fin"], 3)}
            for r in reconocidas
        ]

    comun.escribir_json(args.salida, palabras)
    print(f"Listo: {len(palabras)} palabras en '{args.salida}' (última termina en {palabras[-1]['fin']:.2f} s).")
    return 0


if __name__ == "__main__":
    comun.principal(main)
