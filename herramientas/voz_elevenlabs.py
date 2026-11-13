"""Genera la narración con ElevenLabs y saca el tiempo de cada palabra.

Usa el endpoint con marcas de tiempo:
POST /v1/text-to-speech/{voice_id}/with-timestamps
La respuesta trae 'audio_base64' y 'alignment' (un tiempo por carácter).
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

import comun

VARIABLE_CLAVE = "ELEVENLABS_API_KEY"
VARIABLE_VOZ = "ELEVENLABS_VOICE_ID"


def pedir_a_la_api(base_url: str, voz: str, cuerpo: dict, formato: str, espera: float) -> dict:
    clave = os.environ.get(VARIABLE_CLAVE, "").strip()
    if not clave:
        raise comun.ErrorHerramienta(
            f"Falta la variable de entorno {VARIABLE_CLAVE}. En PowerShell: "
            f"$env:{VARIABLE_CLAVE} = 'tu_clave'  (no la guardes en ningún archivo)."
        )
    url = (
        f"{base_url.rstrip('/')}/v1/text-to-speech/{urllib.parse.quote(voz, safe='')}/with-timestamps"
        f"?{urllib.parse.urlencode({'output_format': formato})}"
    )
    peticion = urllib.request.Request(
        url,
        data=json.dumps(cuerpo).encode("utf-8"),
        headers={"xi-api-key": clave, "Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(peticion, timeout=espera) as respuesta:
            return json.loads(respuesta.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detalle = error.read().decode("utf-8", errors="replace")[:600]
        raise comun.ErrorHerramienta(f"ElevenLabs respondió {error.code}: {detalle}") from error
    except urllib.error.URLError as error:
        raise comun.ErrorHerramienta(f"No pude conectar con ElevenLabs: {error.reason}") from error


def caracteres_a_palabras(alineacion: dict) -> list:
    """Agrupa los tiempos por carácter en palabras separadas por espacios."""
    try:
        caracteres = alineacion["characters"]
        inicios = alineacion["character_start_times_seconds"]
        finales = alineacion["character_end_times_seconds"]
    except (KeyError, TypeError) as error:
        raise comun.ErrorHerramienta(
            "La respuesta no trae 'characters', 'character_start_times_seconds' y "
            "'character_end_times_seconds' dentro de la alineación."
        ) from error
    if not (len(caracteres) == len(inicios) == len(finales)):
        raise comun.ErrorHerramienta("La alineación de la respuesta tiene listas de distinto largo.")

    palabras = []
    actual = ""
    inicio = fin = 0.0
    for caracter, t0, t1 in zip(caracteres, inicios, finales):
        if caracter.isspace():
            if comun.normalizar(actual):
                palabras.append({"palabra": actual, "inicio": round(inicio, 3), "fin": round(fin, 3)})
            actual = ""
            continue
        if not actual:
            inicio = float(t0)
        actual += caracter
        fin = float(t1)
    if comun.normalizar(actual):
        palabras.append({"palabra": actual, "inicio": round(inicio, 3), "fin": round(fin, 3)})
    return palabras


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Genera la narración con la API de ElevenLabs (endpoint 'with-timestamps') y escribe "
            "el audio y un palabras.json con el tiempo de cada palabra. La clave se lee de la "
            f"variable de entorno {VARIABLE_CLAVE}; nunca se escribe en archivos."
        ),
        epilog=(
            "Ejemplo: python voz_elevenlabs.py --texto guion.txt --voz ID_DE_LA_VOZ --carpeta salida. "
            "Para probar sin gastar créditos: --respuesta-simulada respuesta.json"
        ),
    )
    analizador.add_argument("--texto", required=True, help="Archivo .txt con la narración.")
    analizador.add_argument("--voz", help=f"ID de la voz en ElevenLabs (o la variable de entorno {VARIABLE_VOZ}).")
    analizador.add_argument("--carpeta", default=".", help="Carpeta donde se guardan los archivos de salida (por defecto: la actual).")
    analizador.add_argument("--salida-audio", default="voz.mp3", help="Nombre del audio de salida (por defecto: voz.mp3).")
    analizador.add_argument("--salida-palabras", default="palabras.json", help="Nombre del JSON de palabras (por defecto: palabras.json).")
    analizador.add_argument("--modelo", default="eleven_multilingual_v2", help="model_id de ElevenLabs (por defecto: eleven_multilingual_v2).")
    analizador.add_argument("--formato", default="mp3_44100_128", help="output_format (por defecto: mp3_44100_128).")
    analizador.add_argument("--velocidad", type=float, help="voice_settings.speed (1.0 es normal).")
    analizador.add_argument("--estabilidad", type=float, help="voice_settings.stability (0 a 1).")
    analizador.add_argument("--similitud", type=float, help="voice_settings.similarity_boost (0 a 1).")
    analizador.add_argument("--estilo", type=float, help="voice_settings.style (0 a 1).")
    analizador.add_argument("--semilla", type=int, help="seed, para intentar repetir el mismo resultado.")
    analizador.add_argument("--conservar-saltos", action="store_true", help="Envía el texto con sus saltos de línea (por defecto se une en una sola línea).")
    analizador.add_argument("--conservar-mayusculas", action="store_true", help="Envía las palabras en MAYÚSCULAS tal cual (por defecto se pasan a minúsculas para la voz; los subtítulos recuperan las mayúsculas del guion al correr transcribir.py --guion).")
    analizador.add_argument("--respuesta-simulada", help="JSON con una respuesta ya guardada; no se llama a la API.")
    analizador.add_argument("--guardar-respuesta", help="Guarda la alineación de la respuesta (sin el audio) en este JSON.")
    analizador.add_argument("--base-url", default="https://api.elevenlabs.io", help="Servidor de la API (por defecto: https://api.elevenlabs.io).")
    analizador.add_argument("--espera", type=float, default=300.0, help="Segundos máximos de espera de la respuesta (por defecto: 300).")
    args = analizador.parse_args()

    texto = comun.leer_texto(comun.exigir_archivo(args.texto, "el texto")).strip()
    if not args.conservar_saltos:
        texto = " ".join(texto.split())
    if not args.conservar_mayusculas:
        # Las palabras en MAYÚSCULAS del guion son para los subtítulos; a la voz
        # se le envían normales para que no las deletree ni las grite.
        import re
        texto = re.sub(r"\b[A-Z][A-Z']{1,}\b", lambda m: m.group(0).lower(), texto)
        texto = re.sub(r"(^|[.!?]\s+)([a-z])", lambda m: m.group(1) + m.group(2).upper(), texto)
        texto = re.sub(r"\bi(?=\b|')", "I", texto)
    if not texto:
        raise comun.ErrorHerramienta(f"El archivo '{args.texto}' está vacío.")

    if args.respuesta_simulada:
        print("Usando una respuesta simulada: no se llama a la API.")
        respuesta = comun.leer_json(comun.exigir_archivo(args.respuesta_simulada, "la respuesta simulada"))
    else:
        voz = args.voz or os.environ.get(VARIABLE_VOZ, "").strip()
        if not voz:
            raise comun.ErrorHerramienta(f"Indica la voz con --voz o con la variable de entorno {VARIABLE_VOZ}.")
        cuerpo = {"text": texto, "model_id": args.modelo}
        ajustes = {
            "speed": args.velocidad,
            "stability": args.estabilidad,
            "similarity_boost": args.similitud,
            "style": args.estilo,
        }
        ajustes = {clave: valor for clave, valor in ajustes.items() if valor is not None}
        if ajustes:
            cuerpo["voice_settings"] = ajustes
        if args.semilla is not None:
            cuerpo["seed"] = args.semilla
        print(f"Pidiendo la voz a ElevenLabs ({len(texto)} caracteres, modelo {args.modelo})...")
        respuesta = pedir_a_la_api(args.base_url, voz, cuerpo, args.formato, args.espera)

    if not isinstance(respuesta, dict) or not respuesta.get("audio_base64"):
        raise comun.ErrorHerramienta("La respuesta no trae 'audio_base64'.")
    alineacion = respuesta.get("alignment")
    if not alineacion:
        alineacion = respuesta.get("normalized_alignment")
        if not alineacion:
            raise comun.ErrorHerramienta("La respuesta no trae 'alignment' ni 'normalized_alignment'.")
        print("AVISO: no vino 'alignment'; uso 'normalized_alignment' (los números pueden salir en letras).")

    try:
        audio = base64.b64decode(respuesta["audio_base64"], validate=True)
    except ValueError as error:
        raise comun.ErrorHerramienta("El campo 'audio_base64' no es base64 válido.") from error
    palabras = caracteres_a_palabras(alineacion)
    if not palabras:
        raise comun.ErrorHerramienta("La alineación no contiene palabras.")

    carpeta = Path(args.carpeta)
    carpeta.mkdir(parents=True, exist_ok=True)
    ruta_audio = carpeta / args.salida_audio
    ruta_palabras = carpeta / args.salida_palabras
    ruta_audio.write_bytes(audio)
    comun.escribir_json(ruta_palabras, palabras)
    if args.guardar_respuesta:
        comun.escribir_json(
            args.guardar_respuesta,
            {k: respuesta.get(k) for k in ("alignment", "normalized_alignment")},
        )

    esperadas = comun.contar_palabras(texto)
    print(f"Audio: '{ruta_audio}' ({len(audio)} bytes).")
    print(f"Palabras: '{ruta_palabras}' ({len(palabras)}; el texto tiene {esperadas}).")
    if len(palabras) != esperadas:
        print("AVISO: la cantidad de palabras de la respuesta no coincide con la del texto.")
    minutos = (palabras[-1]["fin"] - palabras[0]["inicio"]) / 60
    if minutos > 0:
        print(f"Ritmo de la voz: {len(palabras) / minutos:.0f} palabras por minuto.")
    return 0


if __name__ == "__main__":
    comun.principal(main)
