"""Orquestador de un video: encadena en una sola orden los pasos que siempre van juntos.
Existe para que un chat gaste una llamada (y una respuesta corta) donde antes gastaba seis.

  python producir.py voz NNN [--voz af_heart] [--ppm 230] [--audio RUTA]
        Narracion con Kokoro (o el archivo dado con --audio: voz propia o de ElevenLabs),
        ritmo, tiempos por palabra, tiempos por plano y subtitulos. Deja voz/voz_ritmo.wav,
        tiempos/palabras.json, tiempos/planos.json y tiempos/subtitulos.ass.
  python producir.py tiempos NNN
        Solo planos y subtitulos (despues de corregir la tabla de planos del guion).
  python producir.py montar NNN [--musica RUTA] [--nivel-musica -14] [--toma RUTA]
        Efectos (si existe montaje/hacer_efectos.py), montaje, hoja de contactos, informe de
        revisar.py y hojas del video final. Deja montaje/final.mp4 y revision/.
  python producir.py limpiar NNN
        Borra lo desechable del video (vistas previas, tramos, capturas de trabajo).

El rodaje va aparte: herramientas/studio/rodar.py (previa y toma).
Todas las ordenes imprimen solo el resumen; el detalle queda en revision/registro.txt.
"""
import glob
import os
import shutil
import subprocess
import sys

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(AQUI, "studio"))
import base as b  # noqa: E402

PY = sys.executable
PY_KOKORO = os.path.join(AQUI, "kokoro", ".venv", "Scripts", "python.exe")


def correr(video, args, ultimas=3, filtro=None):
    """Corre un paso, guarda toda su salida en el registro y muestra solo el final."""
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace")
    salida = (r.stdout or "") + (r.stderr or "")
    with open(video.ruta("revision", "registro.txt"), "a", encoding="utf-8") as f:
        f.write("\n$ " + " ".join(os.path.basename(x) if os.path.sep in x else x for x in args) + "\n" + salida)
    lineas = [x for x in salida.splitlines() if x.strip()]
    if filtro:
        lineas = [x for x in lineas if filtro(x)]
    else:
        lineas = lineas[-ultimas:]
    for x in lineas:
        print("  " + x)
    if r.returncode != 0:
        raise SystemExit("FALLO el paso %s (codigo %d). Detalle en revision/registro.txt" % (os.path.basename(args[1]), r.returncode))


def paso_tiempos(video):
    voz = video.ruta("voz", "voz_ritmo.wav")
    print("planos:")
    correr(video, [PY, os.path.join(AQUI, "planos_tiempos.py"), "--guion", video.guion_md, "--palabras", video.palabras,
                   "--audio", voz, "--salida", video.plan], ultimas=6)
    print("subtitulos:")
    correr(video, [PY, os.path.join(AQUI, "subtitulos.py"), "--palabras", video.palabras, "--salida", video.subtitulos])


def voz(video, a):
    nombre = b.tomar_opcion(a, "--voz", "af_heart")
    ppm = b.tomar_opcion(a, "--ppm", "230")
    audio = b.tomar_opcion(a, "--audio")
    cruda = video.ruta("voz", "voz.wav")
    if audio:
        if os.path.abspath(audio) != os.path.abspath(cruda):
            cruda = audio
        print("voz: se usa", audio)
    else:
        if not os.path.exists(PY_KOKORO):
            raise SystemExit("Falta el entorno de Kokoro: sigue herramientas/kokoro/LEEME.txt")
        print("voz (Kokoro, %s):" % nombre)
        correr(video, [PY_KOKORO, os.path.join(AQUI, "voz_kokoro.py"), "--video", video.numero, "--voz", nombre], ultimas=1)
    ritmo = video.ruta("voz", "voz_ritmo.wav")
    print("ritmo:")
    correr(video, [PY, os.path.join(AQUI, "ritmo.py"), cruda, ritmo, "--guion", video.guion_txt, "--ppm", ppm])
    print("palabras:")
    correr(video, [PY, os.path.join(AQUI, "transcribir.py"), ritmo, "--guion", video.guion_txt, "--salida", video.palabras,
                   "--crudo", video.ruta("tiempos", "palabras_crudo.json")])
    paso_tiempos(video)
    print("Siguiente: escribe escenas/hacer_puesta.py. Si hubo avisos de planos, corrige la tabla del guion y corre 'tiempos'.")


def montar(video, a):
    musica = b.tomar_opcion(a, "--musica")
    nivel = b.tomar_opcion(a, "--nivel-musica", "-14")
    toma = b.tomar_opcion(a, "--toma", video.ruta("grabacion", "toma.mp4"))
    if not musica:
        halladas = sorted(glob.glob(os.path.join(video.dir, "montaje", "musica*.mp3")) + glob.glob(os.path.join(video.dir, "montaje", "musica*.wav")))
        musica = halladas[0] if halladas else None
    efectos_py = os.path.join(video.dir, "montaje", "hacer_efectos.py")
    if os.path.exists(efectos_py):
        print("efectos:")
        correr(video, [PY, efectos_py], ultimas=1)
    final = video.ruta("montaje", "final.mp4")
    args = [PY, os.path.join(AQUI, "montar.py"), "--video", toma, "--rotar", "antihorario", "--voz", video.ruta("voz", "voz_ritmo.wav"),
            "--subtitulos", video.subtitulos, "--pico", "-2", "--salida", final]
    if musica:
        args += ["--musica", musica, "--nivel-musica", nivel]
    else:
        print("AVISO: sin musica (no hay montaje/musica*.mp3)")
    efectos = os.path.join(video.dir, "montaje", "efectos.json")
    if os.path.exists(efectos):
        args += ["--efectos", efectos]
    print("montaje:")
    correr(video, args, ultimas=1)
    print("hoja de contactos:")
    correr(video, [PY, os.path.join(AQUI, "hoja_contactos.py"), "--video", final, "--planos", video.plan,
                   "--salida", video.ruta("revision", "hoja_contactos.png")], ultimas=1)
    print("revision (solo lo que no aprueba):")
    informe = video.ruta("revision", "informe_revisar.txt")
    r = subprocess.run([PY, os.path.join(AQUI, "revisar.py"), "--video", final, "--palabras", video.palabras,
                        "--subtitulos", video.subtitulos, "--planos", video.plan], capture_output=True, text=True, encoding="utf-8", errors="replace")
    with open(informe, "w", encoding="utf-8") as f:
        f.write(r.stdout)
    for x in r.stdout.splitlines():
        if "REVISAR" in x or "RESULTADO" in x:
            print("  " + x)
    print("Mira revision/hoja_contactos.png antes de dar el video por bueno.")


def limpiar(video):
    borrados = 0
    for patron in ("grabacion/previa*.mp4", "grabacion/tramo*.mp4", "grabacion/prueba*.mp4", "grabacion/toma_v*.mp4",
                   "montaje/previa*.mp4", "escenas/capturas", "escenas/__pycache__", "escenas/vista.json", "revision/registro.txt"):
        for ruta in glob.glob(os.path.join(video.dir, patron)):
            if os.path.isdir(ruta):
                shutil.rmtree(ruta)
            else:
                os.remove(ruta)
            borrados += 1
    print("limpieza: %d elementos borrados de %s" % (borrados, video.slug))


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    if len(a) < 2:
        print(__doc__)
        return
    orden, video = a[0], b.Video(a[1])
    resto = a[2:]
    if orden == "voz":
        voz(video, resto)
    elif orden == "tiempos":
        paso_tiempos(video)
    elif orden == "montar":
        montar(video, resto)
    elif orden == "limpiar":
        limpiar(video)
    else:
        raise SystemExit("orden desconocida: " + orden)


if __name__ == "__main__":
    main()
