"""Rodaje cuadro a cuadro: la forma de grabar un video del canal. No usa OBS ni tiempo real.

Cada cuadro se monta en Studio (modo juego, cliente) en su instante exacto y se captura de
la pantalla. La toma sale con sincronia perfecta con la voz, sin cuadros perdidos y sin
destello de sincronia. Unos 0,22 s por cuadro: 4 minutos una vista previa a 10 cps, 21
minutos una toma de 94 s a 60 cps.

  python rodar.py --video NNN previa             vista previa completa a 10 cps + hojas de revision
  python rodar.py --video NNN toma               toma final a 60 cps -> grabacion/toma.mp4
  python rodar.py --video NNN tramo DESDE HASTA  solo un tramo (segundos) a 10 cps, para probar un arreglo
Opciones: --fps N, --salida RUTA.

Antes de rodar: la ventana de Studio del video en pantalla completa, sin paneles (ver ui.py),
y no usar el equipo mientras rueda. El programa toma el turno con grabacion.lock, entra y
sale del modo juego y suelta el turno al terminar.

La toma sale girada (camara vertical): montar.py --rotar antihorario la endereza.
"""
import json
import os
import subprocess
import sys
import time

from PIL import ImageGrab

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as b  # noqa: E402
import ui  # noqa: E402

CANDADO = os.path.join(b.RAIZ, "grabacion.lock")

PREPARAR = """
local H = require(game.ReplicatedStorage.Historias.Director)
H.Luz.tinte(nil)
local ctx = H.preparar(PLAN, PUESTA, { version = "detalle" })
H.guardarDatos(PLAN, PUESTA)
local carpeta = game.ReplicatedStorage.Historias
carpeta:SetAttribute("AutoRodar", false)
carpeta:SetAttribute("Modo", "cuadros")
carpeta:SetAttribute("Fps", %d)
for _, a in { "T", "Hecho", "Listo", "Error", "Calibrar" } do carpeta:SetAttribute(a, nil) end
game:GetService("Players").CharacterAutoLoads = false
local sps = game:GetService("StarterPlayer").StarterPlayerScripts
local viejo = sps:FindFirstChild("RodajeCuadroACuadro")
if viejo then viejo:Destroy() end
local s = Instance.new("LocalScript")
s.Name = "RodajeCuadroACuadro"
s.Source = FUENTE
s.Parent = sps
pcall(function() workspace.StreamingEnabled = false end)
H.aplicarPlano(ctx, 1)
return "lugar preparado: " .. #ctx.planos .. " planos, streaming " .. tostring(workspace.StreamingEnabled)
"""

CUADRO = """
local c = game.ReplicatedStorage.Historias
local t = %.6f
c:SetAttribute("Hecho", nil)
c:SetAttribute("T", t + 1e-7)
c:SetAttribute("T", t)
local limite = os.clock() + 20
while c:GetAttribute("Hecho") ~= t and os.clock() < limite do task.wait() end
return tostring(c:GetAttribute("Hecho") == t) .. "|" .. tostring(c:GetAttribute("Error"))
"""


class Rodaje:
    def __init__(self, video):
        self.v = video
        self.sid = b.studio_id(video)

    def luau(self, codigo, modo):
        return b.luau(self.v, codigo, modo, self.sid)

    def preparar(self, fps):
        fuente = b.leer(os.path.join(b.RAIZ, "studio", "empaque", "RodajeCuadros.client.luau"))
        cod = ("local PUESTA = [==[" + b.leer(self.v.puesta) + "]==]\nlocal PLAN = [==[" + b.leer(self.v.plan) +
               "]==]\nlocal FUENTE = [===[" + fuente + "]===]\n" + PREPARAR % fps)
        txt, err = self.luau(cod, "Edit")
        print(txt)
        if err:
            raise SystemExit("no se pudo preparar el lugar")
        print(b.texto(b.llamar("save_place", {"studio_id": self.sid})).splitlines()[0])

    def jugar(self):
        print(b.texto(b.llamar("start_stop_play", {"studio_id": self.sid, "is_start": True})))
        fin = time.time() + 90
        txt = ""
        while time.time() < fin:
            txt, err = self.luau("local c = game.ReplicatedStorage.Historias return tostring(c:GetAttribute('Listo')) .. '|' .. tostring(c:GetAttribute('Error'))", "Client")
            if not err and not txt.startswith("nil"):
                print("cliente listo:", txt)
                return
            time.sleep(1.5)
        raise SystemExit("el cliente no quedo listo: " + txt)

    def parar(self):
        print(b.texto(b.llamar("start_stop_play", {"studio_id": self.sid, "is_start": False})))

    def cuadro(self, t):
        txt, err = self.luau(CUADRO % t, "Client")
        if err or not txt.startswith("true"):
            raise RuntimeError("cuadro %.3f: %s" % (t, txt))

    def calibrar(self):
        """Ubica la vista del juego en el escritorio con una pantalla magenta."""
        ui.frente(self.v.slug)
        self.luau("game.ReplicatedStorage.Historias:SetAttribute('Calibrar', true) task.wait(0.5) return 1", "Client")
        time.sleep(0.5)
        im = ImageGrab.grab().convert("RGB")
        self.luau("game.ReplicatedStorage.Historias:SetAttribute('Calibrar', false) task.wait(0.2) return 1", "Client")
        w, h = im.size
        px = im.load()
        xs, ys = [], []
        for y in range(0, h, 2):
            for x in range(0, w, 2):
                r, g, bl = px[x, y]
                if r > 235 and g < 30 and bl > 235:
                    xs.append(x)
                    ys.append(y)
        if not xs:
            raise SystemExit("no encontre la pantalla de calibracion: la ventana de Studio debe estar visible y al frente")
        x0, x1, y0, y1 = min(xs) + 1, max(xs) + 2, min(ys) + 1, max(ys) + 2
        x1 -= (x1 - x0) % 2
        y1 -= (y1 - y0) % 2
        caja = [x0, y0, x1, y1]
        with open(self.v.vista, "w") as f:
            json.dump(caja, f)
        ancho = min(x1 - x0, y1 - y0)
        print("vista: %s, %d x %d. Ancho util del video: %d px (escala %.2f para llegar a 1080)" % (caja, x1 - x0, y1 - y0, ancho, 1080 / ancho))
        if ancho < 700:
            print("AVISO: la vista es pequena. Cierra paneles y pon Studio en pantalla completa (ver ui.py) antes de la toma final.")
        return caja

    def rodar(self, salida, fps, desde, hasta):
        plan = json.loads(b.leer(self.v.plan))
        hasta = min(hasta, plan["duracion"]) if hasta else plan["duracion"]
        c = json.loads(b.leer(self.v.vista))
        ancho, alto = c[2] - c[0], c[3] - c[1]
        n0, n1 = int(round(desde * fps)), int(round(hasta * fps))
        os.makedirs(os.path.dirname(os.path.abspath(salida)), exist_ok=True)
        ff = subprocess.Popen(
            ["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "%dx%d" % (ancho, alto),
             "-r", str(fps), "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "10", "-pix_fmt", "yuv420p", salida],
            stdin=subprocess.PIPE)
        ui.frente(self.v.slug)
        t0 = time.time()
        for n in range(n0, n1):
            t = n / fps
            intentos = 0
            while True:
                intentos += 1
                if not ui.es_frente(self.v.slug):
                    print("Studio perdio el foco en %.2f s; lo traigo al frente y repito el cuadro" % t, flush=True)
                    ui.frente(self.v.slug)
                    time.sleep(1.0)
                try:
                    self.cuadro(t)
                except RuntimeError as e:
                    print("reintento:", e, flush=True)
                    if intentos > 5:
                        raise
                    time.sleep(1)
                    continue
                im = ImageGrab.grab(bbox=tuple(c)).convert("RGB")
                if ui.es_frente(self.v.slug):
                    break
            ff.stdin.write(im.tobytes())
            if (n - n0) % 300 == 0:
                v = (time.time() - t0) / (n - n0 + 1)
                print("cuadro %d de %d, %.2f s por cuadro, faltan %.1f min" % (n, n1, v, v * (n1 - n) / 60), flush=True)
        ff.stdin.close()
        ff.wait()
        print("toma: %s, %d cuadros en %.1f min" % (salida, n1 - n0, (time.time() - t0) / 60))


def sesion(video, salida, fps, desde=0.0, hasta=0.0):
    if os.path.exists(CANDADO):
        raise SystemExit("grabacion.lock existe (video %s): otro chat esta grabando. Espera." % b.leer(CANDADO).strip())
    with open(CANDADO, "x") as f:
        f.write(video.numero)
    r = Rodaje(video)
    try:
        r.preparar(fps)
        r.jugar()
        try:
            r.calibrar()
            r.rodar(salida, fps, desde, hasta)
        finally:
            r.parar()
    finally:
        os.remove(CANDADO)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    video = b.tomar_video(a)
    fps = b.tomar_opcion(a, "--fps", None, int)
    salida = b.tomar_opcion(a, "--salida")
    orden = a[0]
    if orden == "previa":
        salida = salida or video.ruta("grabacion", "previa.mp4")
        sesion(video, salida, fps or 10)
        subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "hojas.py"),
                        "--video", video.numero, salida], check=True)
    elif orden == "toma":
        sesion(video, salida or video.ruta("grabacion", "toma.mp4"), fps or 60)
    elif orden == "tramo":
        salida = salida or video.ruta("grabacion", "tramo.mp4")
        sesion(video, salida, fps or 10, float(a[1]), float(a[2]))
        subprocess.run([sys.executable, os.path.join(os.path.dirname(os.path.abspath(__file__)), "hojas.py"),
                        "--video", video.numero, salida, "--desde", a[1]], check=True)
    else:
        raise SystemExit("orden desconocida: " + orden)


if __name__ == "__main__":
    main()
