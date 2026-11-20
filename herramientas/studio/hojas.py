"""Hojas de revision de una toma o del video final: dos cuadros por plano (al 25 % y al
80 % de su duracion), enderezados y recortados a 9:16, con el numero del plano y las marcas
de la franja de subtitulos (21 % a 28 %). Es la forma barata de "ver" el video: tres o
cuatro imagenes en vez de cientos de cuadros.

  python hojas.py --video NNN TOMA.mp4            toma girada de rodar.py (previa, tramo o toma)
  python hojas.py --video NNN FINAL.mp4 --final   video ya montado (vertical, con subtitulos)
Opciones: --desde S (la toma empieza en ese segundo del video), --prefijo RUTA.
Salida: escenas/capturas/hoja_N.png (o el prefijo dado).
"""
import json
import os
import subprocess
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as b  # noqa: E402

W, H = 216, 384


def main():
    a = sys.argv[1:]
    video = b.tomar_video(a)
    final = b.tomar_bandera(a, "--final")
    desde = b.tomar_opcion(a, "--desde", 0.0, float)
    prefijo = b.tomar_opcion(a, "--prefijo", os.path.join(video.capturas, "final" if final else "hoja"))
    toma = a[0]
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", toma],
                               capture_output=True, text=True).stdout.strip())
    vf = ("scale=%d:%d" % (W, H)) if final else ("transpose=2,crop=iw:iw*16/9,scale=%d:%d" % (W, H))
    plan = json.loads(b.leer(video.plan))
    celdas = []
    for p in plan["planos"]:
        for f in (0.25, 0.8):
            t = p["inicio"] + (p["fin"] - p["inicio"]) * f - desde
            if t < 0 or t >= dur:
                continue
            crudo = subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", "%.3f" % t, "-i", toma, "-frames:v", "1", "-vf", vf,
                                    "-f", "rawvideo", "-pix_fmt", "rgb24", "-"], capture_output=True).stdout
            if len(crudo) < W * H * 3:
                continue
            im = Image.frombytes("RGB", (W, H), crudo[:W * H * 3])
            d = ImageDraw.Draw(im)
            d.rectangle((0, 0, 30, 14), fill=(0, 0, 0))
            d.text((3, 2), "%d" % p["n"], fill=(255, 255, 0))
            if not final:
                for g in (0.21, 0.28):
                    d.line((0, int(H * g), 8, int(H * g)), fill=(255, 0, 0), width=2)
            celdas.append(im)
    cols, filas = 8, 3
    os.makedirs(os.path.dirname(os.path.abspath(prefijo)), exist_ok=True)
    for k in range(0, len(celdas), cols * filas):
        grupo = celdas[k:k + cols * filas]
        hoja = Image.new("RGB", (cols * (W + 3), ((len(grupo) + cols - 1) // cols) * (H + 3)), (20, 20, 20))
        for j, im in enumerate(grupo):
            hoja.paste(im, ((j % cols) * (W + 3), (j // cols) * (H + 3)))
        ruta = "%s_%d.png" % (prefijo, k // (cols * filas) + 1)
        hoja.save(ruta)
        print(ruta)


if __name__ == "__main__":
    main()
