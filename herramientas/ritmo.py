"""Recorta silencios y acelera la voz hasta un ritmo objetivo, sin cambiar el tono."""

from __future__ import annotations

import argparse
import tempfile
from pathlib import Path

import comun


def cadena_atempo(factor: float) -> str:
    """atempo conserva el tono; se encadena en pasos de máximo 2x para cuidar la calidad."""
    partes = []
    restante = factor
    while restante > 2.0:
        partes.append("atempo=2.0")
        restante /= 2.0
    while restante < 0.5:
        partes.append("atempo=0.5")
        restante /= 0.5
    partes.append(f"atempo={restante:.6f}")
    return ",".join(partes)


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Recorta los silencios de una voz y la acelera hasta un objetivo de palabras por "
            "minuto sin cambiar el tono (ffmpeg silenceremove + atempo), y normaliza la sonoridad. "
            "Informa las palabras por minuto antes y después."
        ),
        epilog='Ejemplo: python ritmo.py voz.wav voz_ritmo.wav --guion guion.txt --ppm 230',
    )
    analizador.add_argument("entrada", help="Audio de voz original (wav, mp3...).")
    analizador.add_argument("salida", help="Audio de salida (se recomienda .wav).")
    grupo = analizador.add_mutually_exclusive_group(required=True)
    grupo.add_argument("--guion", help="Texto de la narración (.txt), para contar las palabras.")
    grupo.add_argument("--palabras", type=int, help="Número de palabras de la narración, si no tienes el texto.")
    analizador.add_argument("--ppm", type=float, default=230.0, help="Objetivo de palabras por minuto (por defecto: 230).")
    analizador.add_argument("--umbral", type=float, default=-40.0, help="Nivel en dB por debajo del cual se considera silencio (por defecto: -40).")
    analizador.add_argument("--silencio-min", type=float, default=0.20, help="Solo se recortan los silencios más largos que esto, en segundos (por defecto: 0.20).")
    analizador.add_argument("--silencio-max", type=float, default=0.10, help="Silencio que se deja en cada pausa recortada, en segundos (por defecto: 0.10).")
    analizador.add_argument("--tempo-max", type=float, default=1.6, help="Aceleración máxima permitida (por defecto: 1.6).")
    analizador.add_argument("--permitir-frenar", action="store_true", help="Si la voz ya va más rápido que el objetivo, la frena. Por defecto no la toca.")
    analizador.add_argument("--sin-recorte", action="store_true", help="No recorta silencios; solo acelera y normaliza.")
    analizador.add_argument("--lufs", type=float, default=-16.0, help="Sonoridad objetivo de la voz en LUFS (por defecto: -16).")
    analizador.add_argument("--pico", type=float, default=-1.5, help="Pico real máximo en dBTP (por defecto: -1.5).")
    analizador.add_argument("--sin-normalizar", action="store_true", help="No normaliza la sonoridad.")
    analizador.add_argument("--frecuencia", type=int, default=48000, help="Frecuencia de muestreo de salida (por defecto: 48000).")
    args = analizador.parse_args()

    entrada = comun.exigir_archivo(args.entrada, "el audio de entrada")
    salida = Path(args.salida)
    if args.guion:
        palabras = comun.contar_palabras(comun.leer_texto(comun.exigir_archivo(args.guion, "el guion")))
    else:
        palabras = args.palabras
    if not palabras or palabras <= 0:
        raise comun.ErrorHerramienta("El número de palabras tiene que ser mayor que cero.")
    if args.tempo_max < 1.0:
        raise comun.ErrorHerramienta("--tempo-max no puede ser menor que 1.")

    duracion_original = comun.duracion(entrada)
    ppm_antes = palabras / (duracion_original / 60.0)

    with tempfile.TemporaryDirectory(prefix="ritmo_") as carpeta:
        recortado = Path(carpeta) / "recortado.wav"
        base = f"aresample={args.frecuencia},aformat=sample_fmts=flt:channel_layouts=mono"
        if args.sin_recorte:
            filtro = base
        else:
            filtro = (
                f"{base},silenceremove="
                f"start_periods=1:start_threshold={args.umbral}dB:start_silence=0.03:"
                f"stop_periods=-1:stop_duration={args.silencio_min}:stop_threshold={args.umbral}dB:"
                f"stop_silence={args.silencio_max}:detection=rms"
            )
        comun.ffmpeg(["-i", entrada, "-vn", "-af", filtro, "-c:a", "pcm_s24le", recortado])
        duracion_recortada = comun.duracion(recortado)
        if duracion_recortada < 0.5:
            raise comun.ErrorHerramienta(
                "Después de recortar silencios casi no quedó audio. Prueba con un --umbral más bajo (por ejemplo -50)."
            )
        ppm_recortado = palabras / (duracion_recortada / 60.0)

        factor = args.ppm / ppm_recortado
        avisos = []
        if factor < 1.0 and not args.permitir_frenar:
            avisos.append(
                f"La voz ya va a {ppm_recortado:.0f} ppm, por encima del objetivo; no se frena (usa --permitir-frenar si quieres)."
            )
            factor = 1.0
        if factor > args.tempo_max:
            avisos.append(
                f"Para llegar a {args.ppm:.0f} ppm habría que acelerar {factor:.2f}x; se limita a {args.tempo_max:.2f}x (ver --tempo-max)."
            )
            factor = args.tempo_max

        filtro_final = cadena_atempo(factor) if abs(factor - 1.0) > 1e-4 else "anull"
        if not args.sin_normalizar:
            medicion = comun.medir_loudnorm(["-i", recortado], filtro_final, args.lufs, args.pico)
            filtro_final += "," + comun.filtro_loudnorm(medicion, args.lufs, args.pico)
        filtro_final += f",aresample={args.frecuencia}"
        salida.parent.mkdir(parents=True, exist_ok=True)
        argumentos = ["-i", recortado, "-vn", "-af", filtro_final, "-ar", str(args.frecuencia), "-ac", "1"]
        if salida.suffix.lower() == ".wav":
            argumentos += ["-c:a", "pcm_s16le"]
        comun.ffmpeg(argumentos + [salida])

    duracion_final = comun.duracion(salida)
    ppm_despues = palabras / (duracion_final / 60.0)
    sonoridad = comun.medir_sonoridad(salida)

    print(f"Palabras: {palabras}")
    print(f"Antes:                 {duracion_original:7.2f} s  {ppm_antes:6.1f} ppm")
    print(f"Sin silencios:         {duracion_recortada:7.2f} s  {ppm_recortado:6.1f} ppm  (se quitaron {duracion_original - duracion_recortada:.2f} s)")
    print(f"Después (tempo {factor:.3f}x): {duracion_final:7.2f} s  {ppm_despues:6.1f} ppm")
    print(f"Sonoridad final: {sonoridad['integrada']:.1f} LUFS, pico real {sonoridad['pico']:.1f} dBTP")
    for aviso in avisos:
        print(f"AVISO: {aviso}")
    print(f"Listo: '{salida}'")
    return 0


if __name__ == "__main__":
    comun.principal(main)
