#!/usr/bin/env python3
"""Ejecuta las pruebas de la biblioteca con el intérprete oficial `luau`.

El intérprete no puede leer archivos, así que este script arma un único archivo temporal
con los textos que hacen falta (el doble de la API, la tabla de la API, cargar.luau,
monolito.luau, la puesta de ejemplo y las pruebas) y lo ejecuta. Antes regenera cargar.luau
y monolito.luau con empaquetar.py para probar exactamente lo que se inyecta en Studio.

Uso: python studio/pruebas/ejecutar.py --luau-dir CARPETA_CON_LUAU
     (también sirve la variable LUAU_DIR o tener `luau` en el PATH)
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

STUDIO = Path(__file__).resolve().parent.parent
TEXTOS = {
    "doble": "pruebas/doble_roblox.luau",
    "api": "pruebas/api_roblox.luau",
    "pruebas": "pruebas/pruebas.luau",
    "cargar": "cargar.luau",
    "monolito": "monolito.luau",
    "puesta001": "ejemplos/001-puesta.json",
}


def binario(nombre: str, carpeta: str | None) -> str:
    for base in filter(None, [carpeta, os.environ.get("LUAU_DIR")]):
        for candidato in (Path(base) / nombre, Path(base) / (nombre + ".exe")):
            if candidato.exists():
                return str(candidato)
    hallado = shutil.which(nombre)
    if not hallado:
        raise SystemExit(f"No se encontró {nombre}. Usa --luau-dir o la variable LUAU_DIR.")
    return hallado


def cadena_larga(texto: str) -> str:
    nivel = 1
    while f"]{'=' * nivel}]" in texto or texto.endswith("]" + "=" * nivel):
        nivel += 1
    iguales = "=" * nivel
    return f"[{iguales}[\n{texto}]{iguales}]"


def main() -> int:
    analizador = argparse.ArgumentParser()
    analizador.add_argument("--luau-dir")
    args = analizador.parse_args()
    exe = binario("luau", args.luau_dir)
    empaquetado = subprocess.run([sys.executable, str(STUDIO / "empaquetar.py")], capture_output=True, text=True)
    if empaquetado.returncode != 0:
        print(empaquetado.stdout + empaquetado.stderr)
        return empaquetado.returncode
    partes = ["local FUENTES = {}"]
    for clave, relativo in TEXTOS.items():
        texto = (STUDIO / relativo).read_text(encoding="utf-8").replace("\r\n", "\n")
        partes.append(f"FUENTES.{clave} = {cadena_larga(texto)}")
    partes += [
        'local Doble = assert(loadstring(FUENTES.doble, "=doble_roblox"))()',
        'local API = assert(loadstring(FUENTES.api, "=api_roblox"))()',
        'assert(loadstring(FUENTES.pruebas, "=pruebas"))(Doble, API, FUENTES)',
    ]
    with tempfile.TemporaryDirectory() as tmp:
        archivo = Path(tmp) / "conjunto.luau"
        archivo.write_text("\n".join(partes) + "\n", encoding="utf-8", newline="\n")
        resultado = subprocess.run([exe, archivo.name], cwd=tmp, capture_output=True, text=True, encoding="utf-8")
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print((resultado.stdout + resultado.stderr).rstrip())
    print(f"codigo de salida: {resultado.returncode}")
    return resultado.returncode


if __name__ == "__main__":
    sys.exit(main())
