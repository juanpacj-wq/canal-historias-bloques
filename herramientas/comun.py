"""Funciones compartidas por la caja de herramientas de posproducción.

No se ejecuta directamente: lo importan los demás scripts de esta carpeta.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from pathlib import Path

CARPETA_HERRAMIENTAS = Path(__file__).resolve().parent
CARPETA_FUENTES = CARPETA_HERRAMIENTAS / "fuentes"
ARCHIVO_FUENTE = CARPETA_FUENTES / "LilitaOne-Regular.ttf"
NOMBRE_FUENTE = "Lilita One"

ANCHO = 1080
ALTO = 1920
CPS = 60


_ARGPARSE_ES = {
    "usage: ": "uso: ",
    "positional arguments": "argumentos",
    "options": "opciones",
    "optional arguments": "opciones",
    "show this help message and exit": "muestra esta ayuda y termina",
    "the following arguments are required: %s": "faltan estos argumentos obligatorios: %s",
    "unrecognized arguments: %s": "argumentos no reconocidos: %s",
    "argument %(argument_name)s: %(message)s": "argumento %(argument_name)s: %(message)s",
    "expected one argument": "se esperaba un valor",
    "expected at least one argument": "se esperaba al menos un valor",
    "invalid %(type)s value: %(value)r": "valor inválido (%(type)s): %(value)r",
    "invalid choice: %(value)r (choose from %(choices)s)": "opción inválida: %(value)r (elige entre %(choices)s)",
    "one of the arguments %s is required": "se requiere uno de estos argumentos: %s",
    "not allowed with argument %s": "no se puede usar junto con %s",
    "ambiguous option: %(option)s could match %(matches)s": "opción ambigua: %(option)s puede ser %(matches)s",
}

# argparse trae sus textos fijos en inglés; aquí se cambian por los de la tabla.
argparse._ = lambda mensaje: _ARGPARSE_ES.get(mensaje, mensaje)


class ErrorHerramienta(Exception):
    """Error con un mensaje listo para mostrarle a la persona."""


def configurar_salida() -> None:
    """Evita que un carácter raro tumbe el script al imprimir en Windows."""
    for flujo in (sys.stdout, sys.stderr):
        try:
            flujo.reconfigure(errors="replace")
        except (AttributeError, ValueError):
            pass


def salir_con_error(mensaje: str, codigo: int = 1) -> None:
    print(f"ERROR: {mensaje}", file=sys.stderr)
    sys.exit(codigo)


def principal(funcion) -> None:
    """Ejecuta la función principal de un script y traduce los errores."""
    configurar_salida()
    try:
        codigo = funcion()
    except ErrorHerramienta as error:
        salir_con_error(str(error))
    except KeyboardInterrupt:
        salir_con_error("Interrumpido por el usuario.", 130)
    sys.exit(codigo or 0)


def buscar_ejecutable(nombre: str) -> str:
    """Busca ffmpeg o ffprobe: primero la variable de entorno, luego el PATH."""
    variable = os.environ.get(nombre.upper())
    if variable and Path(variable).exists():
        return variable
    ruta = shutil.which(nombre)
    if not ruta:
        raise ErrorHerramienta(
            f"No encuentro '{nombre}'. Instala ffmpeg y agrégalo al PATH, "
            f"o define la variable de entorno {nombre.upper()} con la ruta al ejecutable."
        )
    return ruta


def ejecutar(comando: list, cwd=None, permitir_error: bool = False) -> subprocess.CompletedProcess:
    """Ejecuta un comando sin pasar por la consola (las rutas con espacios no dan problema)."""
    comando = [str(parte) for parte in comando]
    resultado = subprocess.run(
        comando,
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdin=subprocess.DEVNULL,
    )
    if resultado.returncode != 0 and not permitir_error:
        cola = "\n".join(resultado.stderr.strip().splitlines()[-15:])
        raise ErrorHerramienta(
            f"Falló el comando '{Path(comando[0]).name}' (código {resultado.returncode}).\n{cola}"
        )
    return resultado


def ffmpeg(argumentos: list, cwd=None, permitir_error: bool = False) -> subprocess.CompletedProcess:
    base = [buscar_ejecutable("ffmpeg"), "-hide_banner", "-nostdin", "-y"]
    return ejecutar(base + list(argumentos), cwd=cwd, permitir_error=permitir_error)


def ffprobe_json(ruta) -> dict:
    resultado = ejecutar(
        [
            buscar_ejecutable("ffprobe"),
            "-v", "error",
            "-show_format",
            "-show_streams",
            "-of", "json",
            str(ruta),
        ]
    )
    return json.loads(resultado.stdout)


def duracion(ruta) -> float:
    """Duración en segundos de un archivo de audio o video."""
    datos = ffprobe_json(ruta)
    try:
        return float(datos["format"]["duration"])
    except (KeyError, ValueError) as error:
        raise ErrorHerramienta(f"No pude leer la duración de '{ruta}'.") from error


def exigir_archivo(ruta, descripcion: str) -> Path:
    ruta = Path(ruta)
    if not ruta.is_file():
        raise ErrorHerramienta(f"No existe {descripcion}: '{ruta}'.")
    return ruta


def leer_json(ruta):
    with open(ruta, "r", encoding="utf-8-sig") as archivo:
        return json.load(archivo)


def escribir_json(ruta, datos) -> None:
    ruta = Path(ruta)
    ruta.parent.mkdir(parents=True, exist_ok=True)
    with open(ruta, "w", encoding="utf-8", newline="\n") as archivo:
        json.dump(datos, archivo, ensure_ascii=False, indent=1)
        archivo.write("\n")


def leer_texto(ruta) -> str:
    return Path(ruta).read_text(encoding="utf-8-sig")


def leer_palabras(ruta) -> list:
    """Lee y valida un palabras.json: [{"palabra", "inicio", "fin"}]."""
    datos = leer_json(exigir_archivo(ruta, "el archivo de palabras"))
    if not isinstance(datos, list) or not datos:
        raise ErrorHerramienta(f"'{ruta}' no contiene una lista de palabras.")
    for elemento in datos:
        if not all(clave in elemento for clave in ("palabra", "inicio", "fin")):
            raise ErrorHerramienta(
                f"'{ruta}' no tiene el formato esperado: cada elemento necesita 'palabra', 'inicio' y 'fin'."
            )
    return datos


def normalizar(palabra: str) -> str:
    """Deja una palabra en minúsculas y sin signos, para poder compararla."""
    texto = unicodedata.normalize("NFKD", palabra.lower())
    texto = "".join(c for c in texto if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]", "", texto)


def separar_palabras(texto: str) -> list:
    """Parte un texto por espacios y descarta lo que no tenga letras ni números."""
    return [parte for parte in texto.split() if normalizar(parte)]


def contar_palabras(texto: str) -> int:
    return len(separar_palabras(texto))


def formato_tiempo(segundos: float) -> str:
    minutos = int(segundos // 60)
    return f"{minutos}:{segundos - 60 * minutos:05.2f}"


def medir_sonoridad(ruta, limite_segundos: float | None = None) -> dict:
    """Mide sonoridad integrada (LUFS), rango (LU) y pico real (dBTP) con ebur128."""
    argumentos = []
    if limite_segundos:
        argumentos += ["-t", f"{limite_segundos:.3f}"]
    argumentos += ["-i", str(ruta), "-map", "0:a:0", "-af", "ebur128=peak=true", "-f", "null", "-"]
    salida = ffmpeg(argumentos).stderr
    resumen = salida[salida.rfind("Summary:"):] if "Summary:" in salida else ""
    integrada = re.search(r"I:\s+(-?[\d.]+|-?inf)\s+LUFS", resumen)
    rango = re.search(r"LRA:\s+(-?[\d.]+|-?inf)\s+LU", resumen)
    pico = re.search(r"Peak:\s+(-?[\d.]+|-?inf)\s+dBFS", resumen)
    if not integrada:
        raise ErrorHerramienta(f"No pude medir la sonoridad de '{ruta}'.")

    def numero(coincidencia):
        if not coincidencia:
            return None
        valor = coincidencia.group(1)
        return float("-inf") if "inf" in valor else float(valor)

    return {"integrada": numero(integrada), "rango": numero(rango), "pico": numero(pico)}


def medir_loudnorm(argumentos_entrada: list, filtro_previo: str, objetivo: float, pico: float,
                   rango: float = 11.0, complejo: bool = False, cwd=None) -> dict:
    """Primera pasada de loudnorm: devuelve las mediciones que necesita la segunda."""
    medidor = f"loudnorm=I={objetivo}:TP={pico}:LRA={rango}:print_format=json"
    if complejo:
        argumentos = list(argumentos_entrada) + [
            "-filter_complex", f"{filtro_previo},{medidor}[medido]",
            "-map", "[medido]", "-f", "null", "-",
        ]
    else:
        cadena = f"{filtro_previo},{medidor}" if filtro_previo else medidor
        argumentos = list(argumentos_entrada) + ["-vn", "-af", cadena, "-f", "null", "-"]
    salida = ffmpeg(argumentos, cwd=cwd).stderr
    inicio = salida.rfind("{")
    fin = salida.rfind("}")
    if inicio < 0 or fin < inicio:
        raise ErrorHerramienta("No pude leer la medición de sonoridad (loudnorm).")
    return json.loads(salida[inicio:fin + 1])


def filtro_loudnorm(medicion: dict, objetivo: float, pico: float, rango: float = 11.0) -> str:
    """Segunda pasada de loudnorm, con las mediciones de la primera."""
    if "inf" in str(medicion.get("input_i", "")):
        # Audio en silencio total: no hay nada que normalizar.
        return "anull"
    return (
        f"loudnorm=I={objetivo}:TP={pico}:LRA={rango}"
        f":measured_I={medicion['input_i']}:measured_TP={medicion['input_tp']}"
        f":measured_LRA={medicion['input_lra']}:measured_thresh={medicion['input_thresh']}"
        f":offset={medicion['target_offset']}:linear=true"
    )


def fuentes_sustituidas(registro_ffmpeg: str) -> list:
    """Lee del registro de ffmpeg qué fuente usó libass para cada fuente pedida.

    Devuelve [(pedida, usada)] solo de las que NO coinciden, es decir, cuando
    libass no encontró la fuente y la cambió por otra del sistema.
    """
    distintas = []
    for pedida, usada in set(re.findall(r"fontselect: \(([^,]+),[^)]*\) -> ([^,\r\n]+)", registro_ffmpeg)):
        if normalizar(pedida) not in normalizar(usada):
            distintas.append((pedida.strip(), usada.strip()))
    return distintas


def preparar_carpeta_filtros(temporal: Path, subtitulos=None, fuentes=None) -> None:
    """Copia subtítulos y fuentes a una carpeta temporal.

    ffmpeg se ejecuta parado en esa carpeta y los filtros usan nombres relativos
    ('sub.ass', 'fuentes'). Así no hay que escapar dos puntos, espacios ni
    apóstrofos de las rutas de Windows dentro del filtro.
    """
    if subtitulos:
        shutil.copyfile(subtitulos, temporal / "sub.ass")
    origen = Path(fuentes) if fuentes else CARPETA_FUENTES
    destino = temporal / "fuentes"
    destino.mkdir(exist_ok=True)
    encontradas = 0
    for archivo in origen.iterdir():
        if archivo.suffix.lower() in (".ttf", ".otf"):
            shutil.copyfile(archivo, destino / archivo.name)
            encontradas += 1
    if not encontradas:
        raise ErrorHerramienta(f"No hay fuentes .ttf ni .otf en '{origen}'.")
