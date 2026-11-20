"""Linea de comandos para hablar con Roblox Studio desde un chat sin las herramientas MCP
cargadas (o para ahorrar llamadas). El puente se arranca solo.

  python puente.py tools                              lista las herramientas del servidor MCP
  python puente.py ventanas                           list_roblox_studios
  python puente.py --video NNN abrir                  abre el lugar del video en Studio y marca VideoId
  python puente.py --video NNN instalar               instala studio/cargar.luau en el lugar
  python puente.py --video NNN luau ARCHIVO [Edit|Client|Server]
  python puente.py --video NNN dir ARCHIVO [--sin-plan]   igual, con PUESTA_JSON, PLAN_JSON y H definidos
  python puente.py --video NNN reconstruir            rehace escenarios, elenco y utileria y corre el ensayo
  python puente.py --video NNN call HERRAMIENTA ARGS  ARGS: JSON en linea, archivo .json o '-'
  python puente.py --video NNN guardar                save_place
  python puente.py servir                             (interno) deja el puente corriendo

Los archivos .luau deben estar en UTF-8; se tolera el BOM de PowerShell.
"""
import json
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as b  # noqa: E402

RECONSTRUIR = """
H.Luz.tinte(nil)
local t0 = os.clock()
local ctx = H.preparar(PLAN_JSON, PUESTA_JSON, { version = "detalle", reconstruir = true })
local inf = H.ensayo(ctx)
-- "tapados" se omite: con encuadres por punto da falsos positivos (el punto cae dentro de una cabeza).
return string.format("reconstruido en %.2f s; planos %d; cortos: %s; inexistentes: %s", os.clock() - t0, inf.total,
	game:GetService("HttpService"):JSONEncode(inf.cortos), game:GetService("HttpService"):JSONEncode(inf.inexistentes))
"""


def mostrar(res):
    print(b.texto(res))
    if res.get("isError"):
        print("[isError]")


def abrir(video):
    if not os.path.exists(video.lugar):
        # Lugar nuevo a partir de la plantilla vacia: el usuario no tiene que crear nada a mano.
        import shutil
        shutil.copyfile(os.path.join(b.RAIZ, "studio", "plantilla", "lugar-vacio.rbxl"), video.lugar)
        print("lugar creado desde la plantilla:", os.path.basename(video.lugar))
    try:
        sid = b.studio_id(video)
    except SystemExit:
        os.startfile(video.lugar)
        sid = None
        for _ in range(30):
            time.sleep(3)
            try:
                sid = b.studio_id(video)
                break
            except SystemExit:
                pass
        if not sid:
            raise SystemExit("Studio no abrio el lugar a tiempo")
    cod = """
for _, n in { "Baseplate", "SpawnLocation" } do local x = workspace:FindFirstChild(n) if x then x:Destroy() end end
if workspace:GetAttribute("VideoId") == nil then workspace:SetAttribute("VideoId", "%s") end
return "VideoId=" .. tostring(workspace:GetAttribute("VideoId"))
""" % video.numero
    txt, _ = b.luau(video, cod, sid=sid)
    print(txt)
    if ("VideoId=" + video.numero) not in txt:
        raise SystemExit("El lugar abierto tiene otro VideoId: no es el de este video.")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        return
    if a[0] == "servir":
        return b.servir_puente()
    if a[0] == "tools":
        for t in b.pedir("tools/list", {})["tools"]:
            print("##", t["name"], "\n", t.get("description", "")[:600])
        return
    if a[0] == "ventanas":
        return mostrar(b.llamar("list_roblox_studios", {}))
    sin_plan = b.tomar_bandera(a, "--sin-plan")
    video = b.tomar_video(a)
    orden = a[0]
    if orden == "abrir":
        return abrir(video)
    if orden == "instalar":
        subprocess.run([sys.executable, os.path.join(b.RAIZ, "studio", "empaquetar.py")], check=True, stdout=subprocess.DEVNULL)
        txt, err = b.luau(video, b.leer(os.path.join(b.RAIZ, "studio", "cargar.luau")))
        print(txt)
        return
    if orden == "reconstruir":
        print(b.luau(video, b.cabecera_director(video, sin_plan) + RECONSTRUIR)[0])
        return
    if orden == "guardar":
        return mostrar(b.llamar("save_place", {"studio_id": b.studio_id(video)}))
    if orden in ("luau", "dir"):
        codigo = b.leer(a[1])
        if orden == "dir":
            codigo = b.cabecera_director(video, sin_plan) + codigo
        txt, err = b.luau(video, codigo, a[2] if len(a) > 2 else "Edit")
        print(txt + ("\n[isError]" if err else ""))
        return
    if orden == "call":
        args = {}
        if len(a) > 2 and a[2] != "-":
            args = json.loads(b.leer(a[2])) if os.path.exists(a[2]) else json.loads(a[2])
        args.setdefault("studio_id", b.studio_id(video))
        return mostrar(b.llamar(a[1], args))
    raise SystemExit("orden desconocida: " + orden)


if __name__ == "__main__":
    main()
