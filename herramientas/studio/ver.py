"""Revision de planos en modo edicion, sin grabar: monta cada plano pedido, captura la
vista de Studio y arma una hoja con el encuadre vertical final de cada uno.

  python ver.py --video NNN SALIDA.png 1 2 3 [...]     planos sueltos
  python ver.py --video NNN SALIDA.png 1-20            un rango
  python ver.py --video NNN SALIDA.png todos           todos (una hoja cada 10 planos: SALIDA_1.png...)
  python ver.py --video NNN --panorama CLAVE SALIDA.png [dx dy dz  mx my mz]
        vista general de un escenario vacio, para planear posiciones (camara en
        origen+(dx,dy,dz) mirando a origen+(mx,my,mz); por defecto 0 30 45 y 0 2 0)
Opciones: --frac 0.5 (instante del plano, 0 a 1), --sin-plan (usa los tiempos de la puesta).

Detalle que costo descubrir: la camara de EDICION no respeta siempre el giro de 90 grados
del modo vertical. Aqui se quita el giro y se abre el campo vertical (65.8 grados con fov
40); el recorte central 9:16 de la captura es exactamente el encuadre del video final.
Las marcas rojas del borde izquierdo senalan la franja de subtitulos (21 % a 28 %).
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as b  # noqa: E402

FOTO = """
H.Luz.tinte(nil)
local ctx = H.preparar(PLAN_JSON, PUESTA_JSON, { version = "detalle" })
local r = H.foto(ctx, %d, %s)
local e = ctx.estado and ctx.estado.camara
if e then
	local p = ctx.planos[1]
	for _, q in ctx.planos do if q.n == %d then p = q end end
	local cf, fov = H.Camara.cframeEn(e, (p.fin - p.inicio) * %s)
	local cam = workspace.CurrentCamera
	cam.CFrame = cf * CFrame.Angles(0, 0, math.rad(e.vertical and -90 or 0))
	cam.FieldOfView = e.vertical and math.deg(2 * math.atan(math.tan(math.rad(fov) / 2) * 16 / 9)) or fov
	task.wait(0.25)
end
return game:GetService("HttpService"):JSONEncode({ n = r.n, texto = r.texto, duracion = r.duracion, avisos = r.avisos, error = r.error })
"""

PANORAMA = """
local H = require(game.ReplicatedStorage.Historias.Director)
H.Luz.tinte(nil)
local e = H.Escenarios.buscar("%s") or H.Escenarios.construir("%s", { version = "detalle", luz = false })
H.Escenarios.activar("%s")
H.Escenarios.clima(e, "sol")
H.Luz.aplicar(H.Escenarios.luzSugerida(e))
for _, x in workspace.Historias.Elenco:GetChildren() do H.Elenco.ocultar(x) end
for _, x in workspace.Historias.Utileria:GetChildren() do x.Parent = game.ReplicatedStorage.HistoriasBodega end
workspace.CurrentCamera.FieldOfView = 60
local o = e:GetAttribute("Origen").Position
local anclas = {}
for _, a in e.Anclas:GetChildren() do
	local p = e:GetAttribute("Origen"):PointToObjectSpace(a:IsA("BasePart") and a.Position or a:GetPivot().Position)
	table.insert(anclas, string.format("%%s(%%.1f,%%.1f,%%.1f)", a.Name, p.X, p.Y, p.Z))
end
table.sort(anclas)
return string.format("%%f %%f %%f|", o.X, o.Y, o.Z) .. table.concat(anclas, " ")
"""


def numeros(partes, video):
    plan = json.loads(b.leer(video.plan if os.path.exists(video.plan) else video.puesta))
    todos = [p["n"] for p in plan["planos"]]
    out = []
    for x in partes:
        if x == "todos":
            out += todos
        elif "-" in x:
            a, z = x.split("-")
            out += [n for n in todos if int(a) <= n <= int(z)]
        else:
            out.append(int(x))
    return out


def hoja(fotos, salida):
    alto = 560
    fotos = [f.resize((int(f.width * alto / f.height), alto)) for f in fotos]
    cols = min(len(fotos), 5)
    filas = (len(fotos) + cols - 1) // cols
    aw = fotos[0].width
    im = Image.new("RGB", (cols * (aw + 4), filas * (alto + 4)), (20, 20, 20))
    for k, f in enumerate(fotos):
        im.paste(f, ((k % cols) * (aw + 4), (k // cols) * (alto + 4)))
    os.makedirs(os.path.dirname(os.path.abspath(salida)), exist_ok=True)
    im.save(salida)
    print("hoja:", salida)


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    video = b.tomar_video(a)
    sin_plan = b.tomar_bandera(a, "--sin-plan")
    frac = b.tomar_opcion(a, "--frac", "0.5")
    pano = b.tomar_opcion(a, "--panorama")
    sid = b.studio_id(video)
    tmp = os.path.join(video.capturas, "_tmp.png")
    if pano:
        nums = [float(x) for x in a[1:]]
        d = nums[0:3] if len(nums) >= 3 else [0, 30, 45]
        m = nums[3:6] if len(nums) >= 6 else [0, 2, 0]
        txt, err = b.luau(video, PANORAMA % (pano, pano, pano), sid=sid)
        if err:
            raise SystemExit(txt)
        origen, anclas = txt.split("|", 1)
        o = [float(x) for x in origen.split()]
        res = b.llamar("screen_capture", {"capture_id": "ScreenCapture_1", "studio_id": sid,
                                          "camera_position": [o[i] + d[i] for i in range(3)],
                                          "look_at_position": [o[i] + m[i] for i in range(3)]})
        b.guardar_imagen(res, a[0])
        print("panorama:", a[0])
        print("anclas (x,y,z relativos al origen):", anclas)
        return
    salida, nums = a[0], numeros(a[1:], video)
    cab = b.cabecera_director(video, sin_plan)
    fotos = []
    for n in nums:
        txt, err = b.luau(video, cab + FOTO % (n, frac, n, frac), sid=sid)
        try:
            d = json.loads(txt)
            if d.get("avisos") or d.get("error"):
                print("plano %s: avisos=%s error=%s" % (n, d.get("avisos"), d.get("error")))
        except ValueError:
            print("plano %d: %s" % (n, txt[:500]))
        res = b.llamar("screen_capture", {"capture_id": "ScreenCapture_1", "studio_id": sid})
        if not b.guardar_imagen(res, tmp):
            print("plano %d: sin imagen: %s" % (n, b.texto(res)[:200]))
            continue
        im = Image.open(tmp).convert("RGB")
        w, h = im.size
        ancho = int(h * 9 / 16)
        im = im.crop(((w - ancho) // 2, 0, (w - ancho) // 2 + ancho, h))
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, 34, 14), fill=(0, 0, 0))
        d.text((4, 2), str(n), fill=(255, 255, 0))
        for f in (0.21, 0.28):
            d.line((0, int(h * f), 10, int(h * f)), fill=(255, 0, 0), width=2)
        fotos.append(im)
    if os.path.exists(tmp):
        os.remove(tmp)
    if not fotos:
        return
    if len(fotos) <= 10:
        hoja(fotos, salida)
    else:
        raiz, ext = os.path.splitext(salida)
        for k in range(0, len(fotos), 10):
            hoja(fotos[k:k + 10], "%s_%d%s" % (raiz, k // 10 + 1, ext))


if __name__ == "__main__":
    main()
