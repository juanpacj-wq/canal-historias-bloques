"""Prueba voz_elevenlabs.py SIN llamar a la API real.

1. Crea una respuesta simulada con el formato documentado del endpoint
   'with-timestamps' (audio_base64 + alignment por carácter).
2. La procesa con --respuesta-simulada.
3. Levanta un servidor local que devuelve esa misma respuesta y comprueba que el
   script arma bien la petición (ruta, método, cabecera de la clave y cuerpo).
4. Comprueba que sin clave el script se niega a continuar.

La llamada real a ElevenLabs no se prueba aquí: hace falta una clave.
"""

from __future__ import annotations

import base64
import json
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

AQUI = Path(__file__).resolve().parent
HERRAMIENTAS = AQUI.parent
sys.path.insert(0, str(HERRAMIENTAS))
import comun  # noqa: E402

TEXTO = 'In this world, every friendship has a battery, even "Fort Maybe" at ninety-eight percent.'
SALIDA = AQUI / "elevenlabs"
CLAVE_FALSA = "clave-falsa-solo-para-la-prueba"
fallos = []


def comprobar(condicion: bool, descripcion: str) -> None:
    print(f"[{'BIEN' if condicion else 'FALLA'}] {descripcion}")
    if not condicion:
        fallos.append(descripcion)


def crear_respuesta() -> dict:
    """Respuesta con el esquema documentado: cada carácter dura 0,05 s."""
    mp3 = SALIDA / "tono.mp3"
    comun.ffmpeg(["-f", "lavfi", "-i", f"sine=frequency=330:duration={len(TEXTO) * 0.05:.2f}",
                  "-c:a", "libmp3lame", "-b:a", "64k", mp3])
    inicios = [round(i * 0.05, 3) for i in range(len(TEXTO))]
    finales = [round((i + 1) * 0.05, 3) for i in range(len(TEXTO))]
    alineacion = {
        "characters": list(TEXTO),
        "character_start_times_seconds": inicios,
        "character_end_times_seconds": finales,
    }
    return {
        "audio_base64": base64.b64encode(mp3.read_bytes()).decode("ascii"),
        "alignment": alineacion,
        "normalized_alignment": alineacion,
    }


def ejecutar_script(argumentos: list, entorno: dict) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(HERRAMIENTAS / "voz_elevenlabs.py")] + argumentos,
        capture_output=True, text=True, encoding="utf-8", errors="replace", env=entorno,
    )


def revisar_salida(carpeta: Path, respuesta: dict) -> None:
    palabras = json.loads((carpeta / "palabras.json").read_text(encoding="utf-8"))
    esperadas = TEXTO.split()
    comprobar([p["palabra"] for p in palabras] == esperadas, f"las {len(esperadas)} palabras salen con el texto original")
    comprobar(set(palabras[0]) == {"palabra", "inicio", "fin"}, "cada palabra tiene 'palabra', 'inicio' y 'fin'")
    comprobar(palabras[0]["inicio"] == 0.0 and palabras[0]["fin"] == 0.1, "tiempos de la primera palabra ('In': 0.0 a 0.1)")
    posicion = TEXTO.index("friendship")
    amistad = next(p for p in palabras if p["palabra"] == "friendship")
    comprobar(
        abs(amistad["inicio"] - posicion * 0.05) < 1e-6 and abs(amistad["fin"] - (posicion + 10) * 0.05) < 1e-6,
        "tiempos de una palabra intermedia ('friendship')",
    )
    comprobar(all(a["fin"] <= b["inicio"] + 1e-6 for a, b in zip(palabras, palabras[1:])), "los tiempos van en orden")
    audio = (carpeta / "voz.mp3").read_bytes()
    comprobar(audio == base64.b64decode(respuesta["audio_base64"]), "voz.mp3 es el audio de la respuesta")
    comprobar(comun.duracion(carpeta / "voz.mp3") > 1.0, "voz.mp3 es un audio que ffmpeg puede leer")


def main() -> int:
    comun.configurar_salida()
    SALIDA.mkdir(parents=True, exist_ok=True)
    texto = SALIDA / "texto.txt"
    texto.write_text(TEXTO + "\n", encoding="utf-8")
    respuesta = crear_respuesta()
    simulada = AQUI / "respuesta_simulada_elevenlabs.json"
    simulada.write_text(json.dumps(respuesta), encoding="utf-8")

    entorno_sin_clave = {k: v for k, v in os.environ.items() if k not in ("ELEVENLABS_API_KEY", "ELEVENLABS_VOICE_ID")}

    print("== 1. Respuesta simulada desde archivo ==")
    carpeta = SALIDA / "desde_archivo"
    resultado = ejecutar_script(["--texto", str(texto), "--carpeta", str(carpeta),
                                 "--respuesta-simulada", str(simulada)], entorno_sin_clave)
    comprobar(resultado.returncode == 0, "el script termina bien" + ("" if resultado.returncode == 0 else f": {resultado.stderr}"))
    if resultado.returncode == 0:
        revisar_salida(carpeta, respuesta)

    print("== 2. Petición HTTP contra un servidor local ==")
    recibido = {}

    class Servidor(BaseHTTPRequestHandler):
        def do_POST(self):  # noqa: N802
            largo = int(self.headers.get("Content-Length", "0"))
            recibido["ruta"] = self.path
            recibido["clave"] = self.headers.get("xi-api-key")
            recibido["tipo"] = self.headers.get("Content-Type")
            recibido["cuerpo"] = json.loads(self.rfile.read(largo).decode("utf-8"))
            datos = json.dumps(respuesta).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(datos)))
            self.end_headers()
            self.wfile.write(datos)

        def log_message(self, *args):
            pass

    servidor = HTTPServer(("127.0.0.1", 0), Servidor)
    hilo = threading.Thread(target=servidor.serve_forever, daemon=True)
    hilo.start()
    try:
        carpeta = SALIDA / "desde_servidor"
        entorno = dict(entorno_sin_clave, ELEVENLABS_API_KEY=CLAVE_FALSA)
        resultado = ejecutar_script(
            ["--texto", str(texto), "--carpeta", str(carpeta), "--voz", "VOZ_DE_PRUEBA",
             "--velocidad", "1.1", "--semilla", "7",
             "--base-url", f"http://127.0.0.1:{servidor.server_port}"],
            entorno,
        )
    finally:
        servidor.shutdown()
    comprobar(resultado.returncode == 0, "el script termina bien" + ("" if resultado.returncode == 0 else f": {resultado.stderr}"))
    comprobar(
        recibido.get("ruta") == "/v1/text-to-speech/VOZ_DE_PRUEBA/with-timestamps?output_format=mp3_44100_128",
        f"ruta del endpoint: {recibido.get('ruta')}",
    )
    comprobar(recibido.get("clave") == CLAVE_FALSA, "la clave viaja en la cabecera 'xi-api-key', tomada de la variable de entorno")
    comprobar(recibido.get("tipo") == "application/json", "Content-Type: application/json")
    cuerpo = recibido.get("cuerpo") or {}
    comprobar(cuerpo.get("text") == TEXTO, "el cuerpo lleva el texto en 'text'")
    comprobar(cuerpo.get("model_id") == "eleven_multilingual_v2", "el cuerpo lleva 'model_id'")
    comprobar(cuerpo.get("voice_settings") == {"speed": 1.1} and cuerpo.get("seed") == 7, "'voice_settings.speed' y 'seed' viajan cuando se piden")
    comprobar(CLAVE_FALSA not in resultado.stdout + resultado.stderr, "la clave no se imprime en pantalla")
    if resultado.returncode == 0:
        revisar_salida(carpeta, respuesta)
        escritos = "".join(p.read_text(encoding="utf-8", errors="ignore") for p in carpeta.iterdir() if p.suffix == ".json")
        comprobar(CLAVE_FALSA not in escritos, "la clave no queda escrita en los archivos de salida")

    print("== 3. Sin clave ==")
    resultado = ejecutar_script(["--texto", str(texto), "--carpeta", str(SALIDA / "sin_clave"), "--voz", "VOZ_DE_PRUEBA"],
                                entorno_sin_clave)
    comprobar(resultado.returncode != 0 and "ELEVENLABS_API_KEY" in resultado.stderr, "sin clave el script se detiene con un mensaje claro")

    print()
    if fallos:
        print(f"RESULTADO: {len(fallos)} comprobación(es) fallaron.")
        return 1
    print("RESULTADO: todas las comprobaciones pasaron (la llamada real a ElevenLabs NO se probó).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
