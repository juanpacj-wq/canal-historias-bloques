"""Base comun de las herramientas de Studio: ubica la carpeta de un video y habla con el
servidor MCP de Roblox Studio a traves de un puente local.

Por que un puente: cada proceso nuevo de StudioMCP.exe tarda en ver las instancias de
Studio y deja procesos huerfanos. El puente mantiene UN servidor MCP vivo y atiende
pedidos por HTTP en 127.0.0.1:8765. Se arranca solo la primera vez que hace falta.
"""
import base64
import glob
import json
import os
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, HTTPServer

PUERTO = 8765
RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ---------------------------------------------------------------- videos
class Video:
    def __init__(self, numero):
        numero = str(numero).zfill(3)
        halladas = glob.glob(os.path.join(RAIZ, "videos", numero + "-*"))
        if not halladas:
            raise SystemExit("No existe videos/%s-*; crea la carpeta con nuevo_video.py crear %s" % (numero, numero))
        self.dir = halladas[0]
        self.slug = os.path.basename(self.dir)
        self.numero = numero
        self.escenas = os.path.join(self.dir, "escenas")
        self.capturas = os.path.join(self.escenas, "capturas")
        self.puesta = os.path.join(self.escenas, "puesta.json")
        self.plan = os.path.join(self.dir, "tiempos", "planos.json")
        self.palabras = os.path.join(self.dir, "tiempos", "palabras.json")
        self.subtitulos = os.path.join(self.dir, "tiempos", "subtitulos.ass")
        self.vista = os.path.join(self.escenas, "vista.json")
        self.lugar = os.path.join(self.dir, self.slug + ".rbxl")
        self.guion_txt = os.path.join(RAIZ, "guiones", self.slug + ".txt")
        self.guion_md = os.path.join(RAIZ, "guiones", self.slug + ".md")

    def ruta(self, *partes):
        r = os.path.join(self.dir, *partes)
        os.makedirs(os.path.dirname(r), exist_ok=True)
        return r


def tomar_opcion(args, nombre, defecto=None, conv=str):
    """Saca '--nombre valor' de la lista de argumentos y devuelve el valor."""
    if nombre in args:
        i = args.index(nombre)
        valor = conv(args[i + 1])
        del args[i:i + 2]
        return valor
    return defecto


def tomar_bandera(args, nombre):
    if nombre in args:
        args.remove(nombre)
        return True
    return False


def tomar_video(args):
    """El numero del video llega como '--video NNN' o en la variable HISTORIAS_VIDEO."""
    numero = tomar_opcion(args, "--video") or os.environ.get("HISTORIAS_VIDEO")
    if not numero:
        raise SystemExit("Falta el video: agrega --video NNN")
    return Video(numero)


def leer(ruta):
    with open(ruta, encoding="utf-8-sig") as f:
        return f.read()


# ---------------------------------------------------------------- puente MCP
def _ejecutable():
    cands = glob.glob(os.path.join(os.environ["LOCALAPPDATA"], "Roblox", "Versions", "*", "StudioMCP.exe"))
    if not cands:
        raise SystemExit("No encuentro StudioMCP.exe: activa 'Enable Studio as MCP server' en Assistant.")
    cands.sort(key=os.path.getmtime)
    return cands[-1]


class _Cliente:
    def __init__(self):
        self.p = subprocess.Popen([_ejecutable()], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE, bufsize=0)
        self.n = 0
        self.candado = threading.Lock()
        threading.Thread(target=self._drenar, daemon=True).start()
        self.pedir("initialize", {"protocolVersion": "2024-11-05", "capabilities": {},
                                  "clientInfo": {"name": "cliente-local", "version": "1.0"}})
        self._enviar({"jsonrpc": "2.0", "method": "notifications/initialized", "params": {}})

    def _drenar(self):
        for _ in iter(self.p.stderr.readline, b""):
            pass

    def _enviar(self, obj):
        self.p.stdin.write((json.dumps(obj) + "\n").encode("utf-8"))
        self.p.stdin.flush()

    def pedir(self, metodo, params):
        with self.candado:
            self.n += 1
            ident = self.n
            self._enviar({"jsonrpc": "2.0", "id": ident, "method": metodo, "params": params})
            while True:
                linea = self.p.stdout.readline()
                if not linea:
                    raise RuntimeError("el servidor MCP cerro la conexion")
                try:
                    msg = json.loads(linea.decode("utf-8", "replace"))
                except ValueError:
                    continue
                if msg.get("id") == ident:
                    if "error" in msg:
                        return {"content": [{"type": "text", "text": "ERROR RPC: " + json.dumps(msg["error"], ensure_ascii=False)}], "isError": True}
                    return msg["result"]


def servir_puente():
    estado = {"c": _Cliente()}

    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def do_POST(self):
            cuerpo = json.loads(self.rfile.read(int(self.headers["Content-Length"])).decode("utf-8"))
            try:
                res = estado["c"].pedir(cuerpo["metodo"], cuerpo["params"])
            except Exception as e:
                try:
                    estado["c"].p.kill()
                except Exception:
                    pass
                estado["c"] = _Cliente()
                res = {"content": [{"type": "text", "text": "PUENTE: se reinicio el servidor MCP (%s). Repite la llamada." % e}], "isError": True}
            datos = json.dumps(res).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)

    print("puente MCP en 127.0.0.1:%d" % PUERTO, flush=True)
    HTTPServer(("127.0.0.1", PUERTO), H).serve_forever()


def _arrancar_puente():
    script = os.path.join(os.path.dirname(os.path.abspath(__file__)), "puente.py")
    subprocess.Popen([sys.executable, script, "servir"], creationflags=0x00000008 | 0x00000200,  # separado de la consola
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, close_fds=True)
    time.sleep(4)


def pedir(metodo, params):
    datos = json.dumps({"metodo": metodo, "params": params}).encode("utf-8")
    for intento in range(2):
        try:
            req = urllib.request.Request("http://127.0.0.1:%d/" % PUERTO, data=datos)
            with urllib.request.urlopen(req, timeout=900) as r:
                return json.loads(r.read().decode("utf-8"))
        except (urllib.error.URLError, ConnectionError):
            if intento == 1:
                raise
            _arrancar_puente()


def llamar(nombre, args):
    return pedir("tools/call", {"name": nombre, "arguments": args})


def texto(res):
    return "\n".join(c.get("text", "") for c in res.get("content", []) if c.get("type") == "text")


def guardar_imagen(res, ruta):
    for c in res.get("content", []):
        if c.get("type") == "image":
            os.makedirs(os.path.dirname(os.path.abspath(ruta)), exist_ok=True)
            with open(ruta, "wb") as f:
                f.write(base64.b64decode(c["data"]))
            return True
    return False


def studio_id(video):
    """Id de la ventana de Studio cuyo nombre contiene el nombre del lugar del video.
    Nunca devuelve otra ventana: si no esta abierta, se detiene."""
    for intento in range(3):
        res = llamar("list_roblox_studios", {})
        try:
            for s in json.loads(texto(res))["studios"]:
                if video.slug in (s.get("name") or ""):
                    return s["id"]
        except Exception:
            pass
        time.sleep(2)
    raise SystemExit("No hay una ventana de Studio con %s.rbxl abierta. Respuesta: %s" % (video.slug, texto(res)[:400]))


def luau(video, codigo, modo="Edit", sid=None):
    """Ejecuta Luau en Studio. Devuelve (texto, hubo_error)."""
    res = llamar("execute_luau", {"code": codigo, "studio_id": sid or studio_id(video), "datamodel_type": modo})
    return texto(res), bool(res.get("isError"))


def cabecera_director(video, sin_plan=False):
    """Luau que define PUESTA_JSON, PLAN_JSON y H (el Director) con los datos del video."""
    plan = "nil"
    if os.path.exists(video.plan) and not sin_plan:
        plan = "[==[" + leer(video.plan) + "]==]"
    return ("local PUESTA_JSON = [==[" + leer(video.puesta) + "]==]\nlocal PLAN_JSON = " + plan +
            "\nlocal H = require(game.ReplicatedStorage.Historias.Director)\n")
