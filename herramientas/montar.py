"""Arma el video final: recorte a 9:16, voz, subtítulos quemados, música y efectos."""

from __future__ import annotations

import argparse
import re
import tempfile
from pathlib import Path

import comun

EXTENSIONES_VIDEO = (".mp4", ".mov", ".mkv", ".webm", ".avi", ".m4v")
ROTACIONES = {
    "horario": "transpose=1",
    "antihorario": "transpose=2",
    "180": "hflip,vflip",
}


def filtro_geometria(rotar: str | None, encuadre: str) -> str:
    """Rotación opcional y paso a 1080x1920."""
    partes = []
    if rotar:
        partes.append(ROTACIONES[rotar])
    if encuadre == "recortar":
        # Recorte centrado: se conserva la franja 9:16 más grande posible.
        partes.append("crop=w='min(iw,ih*9/16)':h='min(ih,iw*16/9)'")
        partes.append(f"scale={comun.ANCHO}:{comun.ALTO}:flags=lanczos")
    else:
        partes.append(
            f"scale={comun.ANCHO}:{comun.ALTO}:force_original_aspect_ratio=decrease:flags=lanczos"
        )
        partes.append(f"pad={comun.ANCHO}:{comun.ALTO}:(ow-iw)/2:(oh-ih)/2:color=black")
    partes.append("setsar=1")
    return ",".join(partes)


def numero_de_clip(ruta: Path):
    numero = re.search(r"\d+", ruta.stem)
    return int(numero.group()) if numero else None


def unir_clips(carpeta_clips: Path, planos: dict, temporal: Path, rotar, encuadre: str,
               rellenar: bool) -> Path:
    """Convierte un clip por plano en un solo video, con la duración exacta de cada plano."""
    disponibles = {}
    for archivo in sorted(carpeta_clips.iterdir()):
        if archivo.suffix.lower() in EXTENSIONES_VIDEO:
            numero = numero_de_clip(archivo)
            if numero is not None and numero not in disponibles:
                disponibles[numero] = archivo
    faltantes = [p["n"] for p in planos["planos"] if p["n"] not in disponibles]
    if faltantes and not rellenar:
        raise comun.ErrorHerramienta(
            f"Faltan clips para los planos: {', '.join(map(str, faltantes))}. "
            "Cada clip debe llevar el número de su plano en el nombre (por ejemplo 007.mp4). "
            "Usa --rellenar-faltantes para poner negro en su lugar."
        )

    geometria = filtro_geometria(rotar, encuadre)
    lista = []
    for plano in planos["planos"]:
        cuadros = round(plano["fin"] * comun.CPS) - round(plano["inicio"] * comun.CPS)
        if cuadros <= 0:
            continue
        segundos = cuadros / comun.CPS
        nombre = f"seg_{plano['n']:04d}.mp4"
        codificacion = ["-frames:v", str(cuadros), "-an", "-c:v", "libx264", "-preset", "veryfast",
                        "-crf", "14", "-pix_fmt", "yuv420p", nombre]
        if plano["n"] in disponibles:
            filtro = (
                f"{geometria},fps={comun.CPS},"
                f"tpad=stop_mode=clone:stop_duration={segundos + 1:.3f}"
            )
            comun.ffmpeg(["-i", disponibles[plano["n"]], "-vf", filtro] + codificacion, cwd=temporal)
        else:
            origen = f"color=c=black:s={comun.ANCHO}x{comun.ALTO}:r={comun.CPS}"
            comun.ffmpeg(["-f", "lavfi", "-i", origen] + codificacion, cwd=temporal)
        lista.append(f"file '{nombre}'")
    (temporal / "lista.txt").write_text("\n".join(lista) + "\n", encoding="utf-8")
    unido = temporal / "unido.mp4"
    comun.ffmpeg(["-f", "concat", "-safe", "0", "-i", "lista.txt", "-c", "copy", "unido.mp4"], cwd=temporal)
    print(f"Clips unidos: {len(lista)} planos ({len(faltantes)} rellenados con negro).")
    return unido


def leer_efectos(ruta: Path) -> list:
    """efectos.json: [{"archivo": "pop.wav", "tiempo": 12.5, "volumen_db": -6}]"""
    datos = comun.leer_json(ruta)
    if not isinstance(datos, list):
        raise comun.ErrorHerramienta(f"'{ruta}' debe ser una lista de efectos.")
    efectos = []
    for elemento in datos:
        if "archivo" not in elemento or "tiempo" not in elemento:
            raise comun.ErrorHerramienta(f"Cada efecto de '{ruta}' necesita 'archivo' y 'tiempo'.")
        archivo = Path(elemento["archivo"])
        if not archivo.is_absolute():
            archivo = ruta.parent / archivo
        comun.exigir_archivo(archivo, "el efecto de sonido")
        efectos.append({
            "archivo": archivo,
            "tiempo": max(0.0, float(elemento["tiempo"])),
            "volumen_db": float(elemento.get("volumen_db", 0.0)),
        })
    return efectos


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Arma el video final para YouTube Shorts: MP4 H.264 de 1080x1920 a 60 cps con audio "
            "AAC, sonoridad normalizada y +faststart. Recorta la grabación a 9:16, pone la voz, "
            "quema los subtítulos y mezcla música y efectos."
        ),
        epilog=(
            'Ejemplos: python montar.py --video grabacion.mp4 --voz voz.wav --subtitulos subtitulos.ass '
            '--musica musica.mp3 --salida final.mp4   |   '
            'python montar.py --clips carpeta_clips --planos planos.json --voz voz.wav --salida final.mp4'
        ),
    )
    origen = analizador.add_mutually_exclusive_group(required=True)
    origen.add_argument("--video", help="Grabación continua (horizontal o vertical).")
    origen.add_argument("--clips", help="Carpeta con un clip por plano; el número del plano va en el nombre (001.mp4, plano_12.mov...). Requiere --planos.")
    analizador.add_argument("--planos", help="planos.json (obligatorio con --clips).")
    analizador.add_argument("--rellenar-faltantes", action="store_true", help="Con --clips: pone negro en los planos que no tengan clip en vez de fallar.")
    analizador.add_argument("--voz", required=True, help="Audio de la narración.")
    analizador.add_argument("--subtitulos", help="Archivo .ass para quemar en el video.")
    analizador.add_argument("--fuentes", default=str(comun.CARPETA_FUENTES), help="Carpeta con las fuentes de los subtítulos (por defecto: la carpeta fuentes de las herramientas).")
    analizador.add_argument("--salida", required=True, help="MP4 de salida.")
    analizador.add_argument("--rotar", choices=sorted(ROTACIONES), help="Gira la grabación antes de recortar: 'horario' o 'antihorario' (90 grados) para grabaciones hechas con la cámara girada, o '180'.")
    analizador.add_argument("--encuadre", choices=("recortar", "ajustar"), default="recortar", help="'recortar' hace un recorte centrado a 9:16 (por defecto); 'ajustar' muestra la imagen completa con franjas negras.")
    analizador.add_argument("--desfase", type=float, default=0.0, help="Sincronía entre grabación y voz, en segundos. Positivo: descarta ese tiempo del comienzo de la grabación. Negativo: retrasa la grabación congelando el primer cuadro.")
    analizador.add_argument("--cola", type=float, default=0.5, help="Segundos de imagen después de que termina la voz (por defecto: 0.5).")
    analizador.add_argument("--musica", help="Música de fondo (se repite si es más corta que el video).")
    analizador.add_argument("--nivel-musica", type=float, default=-12.0, help="Nivel de la música respecto a la voz, en dB (por defecto: -12).")
    analizador.add_argument("--fundido-entrada", type=float, default=1.0, help="Fundido de entrada de la música en segundos (por defecto: 1).")
    analizador.add_argument("--fundido-salida", type=float, default=2.0, help="Fundido de salida de la música en segundos (por defecto: 2).")
    analizador.add_argument("--efectos", help="efectos.json: lista de {\"archivo\", \"tiempo\", \"volumen_db\"}. Las rutas relativas se toman desde la carpeta del JSON.")
    analizador.add_argument("--lufs", type=float, default=-14.0, help="Sonoridad integrada objetivo (por defecto: -14 LUFS, la referencia de YouTube).")
    analizador.add_argument("--pico", type=float, default=-1.5, help="Pico real máximo en dBTP (por defecto: -1.5).")
    analizador.add_argument("--crf", type=int, default=18, help="Calidad de H.264; menor es mejor y más pesado (por defecto: 18).")
    analizador.add_argument("--preset", default="medium", help="Velocidad de codificación de x264 (por defecto: medium).")
    args = analizador.parse_args()

    voz = comun.exigir_archivo(args.voz, "la voz").resolve()
    salida = Path(args.salida).resolve()
    subtitulos = comun.exigir_archivo(args.subtitulos, "el archivo de subtítulos").resolve() if args.subtitulos else None
    musica = comun.exigir_archivo(args.musica, "la música").resolve() if args.musica else None
    efectos = leer_efectos(comun.exigir_archivo(args.efectos, "el archivo de efectos").resolve()) if args.efectos else []
    if args.clips and not args.planos:
        raise comun.ErrorHerramienta("Con --clips también tienes que pasar --planos planos.json.")

    total = comun.duracion(voz) + max(0.0, args.cola)
    salida.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="montar_") as carpeta:
        temporal = Path(carpeta)
        if subtitulos:
            comun.preparar_carpeta_filtros(temporal, subtitulos, args.fuentes)

        if args.clips:
            carpeta_clips = Path(args.clips).resolve()
            if not carpeta_clips.is_dir():
                raise comun.ErrorHerramienta(f"No existe la carpeta de clips: '{carpeta_clips}'.")
            planos = comun.leer_json(comun.exigir_archivo(args.planos, "planos.json"))
            video = unir_clips(carpeta_clips, planos, temporal, args.rotar, args.encuadre,
                               args.rellenar_faltantes)
            geometria = "setsar=1"
        else:
            video = comun.exigir_archivo(args.video, "la grabación").resolve()
            geometria = filtro_geometria(args.rotar, args.encuadre)

        # Entradas: 0 = video, 1 = voz, 2 = música (si hay), luego los efectos.
        entradas = []
        if args.desfase > 0:
            entradas += ["-ss", f"{args.desfase:.3f}"]
        entradas += ["-i", video, "-i", voz]
        siguiente = 2
        indice_musica = None
        if musica:
            entradas += ["-stream_loop", "-1", "-i", musica]
            indice_musica = siguiente
            siguiente += 1
        indices_efectos = []
        for efecto in efectos:
            entradas += ["-i", efecto["archivo"]]
            indices_efectos.append(siguiente)
            siguiente += 1

        # Imagen.
        cadena_video = [geometria, f"fps={comun.CPS}"]
        if args.desfase < 0:
            cadena_video.append(f"tpad=start_mode=clone:start_duration={-args.desfase:.3f}")
        cadena_video.append(f"tpad=stop_mode=clone:stop_duration={total + 1:.3f}")
        cadena_video.append(f"trim=duration={total:.3f}")
        cadena_video.append("setpts=PTS-STARTPTS")
        if subtitulos:
            cadena_video.append("ass=sub.ass:fontsdir=fuentes")
        cadena_video.append("format=yuv420p")
        grafo_video = f"[0:v]{','.join(cadena_video)}[imagen]"

        # Sonido.
        comun_audio = "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo"
        pistas = [f"[1:a]{comun_audio},apad=whole_dur={total:.3f},atrim=duration={total:.3f}[voz]"]
        etiquetas = ["[voz]"]
        if musica:
            nivel_voz = comun.medir_sonoridad(voz)["integrada"]
            nivel_musica = comun.medir_sonoridad(musica, limite_segundos=min(total, 180.0))["integrada"]
            if nivel_musica == float("-inf") or nivel_voz == float("-inf"):
                raise comun.ErrorHerramienta("La voz o la música están en silencio: no puedo calcular el nivel.")
            ganancia = (nivel_voz + args.nivel_musica) - nivel_musica
            salida_fundido = max(0.0, total - args.fundido_salida)
            pistas.append(
                f"[{indice_musica}:a]{comun_audio},atrim=duration={total:.3f},volume={ganancia:.2f}dB,"
                f"afade=t=in:st=0:d={args.fundido_entrada:.3f},"
                f"afade=t=out:st={salida_fundido:.3f}:d={args.fundido_salida:.3f}[musica]"
            )
            etiquetas.append("[musica]")
            print(f"Música: voz a {nivel_voz:.1f} LUFS, música a {nivel_musica:.1f} LUFS; "
                  f"ganancia aplicada {ganancia:+.1f} dB para dejarla {args.nivel_musica:g} dB respecto a la voz.")
        for numero, (indice, efecto) in enumerate(zip(indices_efectos, efectos)):
            retraso = int(round(efecto["tiempo"] * 1000))
            pistas.append(
                f"[{indice}:a]{comun_audio},volume={efecto['volumen_db']:.2f}dB,"
                f"adelay={retraso}:all=1[efecto{numero}]"
            )
            etiquetas.append(f"[efecto{numero}]")
        if len(etiquetas) > 1:
            mezcla = (
                ";".join(pistas) + ";" + "".join(etiquetas)
                + f"amix=inputs={len(etiquetas)}:duration=first:normalize=0"
            )
        else:
            mezcla = pistas[0].rsplit("[voz]", 1)[0].rstrip()
        # 'mezcla' termina sin etiqueta de salida: se le encadena loudnorm.
        print("Midiendo la sonoridad de la mezcla (primera pasada)...")
        medicion = comun.medir_loudnorm(entradas, mezcla, args.lufs, args.pico, complejo=True, cwd=temporal)
        grafo_audio = (
            f"{mezcla},{comun.filtro_loudnorm(medicion, args.lufs, args.pico)},"
            f"aresample=48000,atrim=duration={total:.3f}[sonido]"
        )

        print(f"Codificando {total:.2f} s a {comun.ANCHO}x{comun.ALTO}, {comun.CPS} cps...")
        codificado = comun.ffmpeg(
            entradas + [
                "-filter_complex", f"{grafo_video};{grafo_audio}",
                "-map", "[imagen]", "-map", "[sonido]",
                "-c:v", "libx264", "-preset", args.preset, "-crf", str(args.crf),
                "-profile:v", "high", "-pix_fmt", "yuv420p", "-r", str(comun.CPS),
                "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
                "-t", f"{total:.3f}",
                "-movflags", "+faststart",
                salida,
            ],
            cwd=temporal,
        )
        for pedida, usada in comun.fuentes_sustituidas(codificado.stderr):
            print(f"AVISO: los subtítulos piden la fuente '{pedida}' y ffmpeg usó '{usada}'. "
                  f"Revisa que el archivo de la fuente esté en '{args.fuentes}'.")

    megas = salida.stat().st_size / (1024 * 1024)
    print(f"Listo: '{salida}' ({comun.duracion(salida):.2f} s, {megas:.1f} MB)")
    return 0


if __name__ == "__main__":
    comun.principal(main)
