#!/usr/bin/env python3
"""Pasa todo el código Luau de studio/ por luau-analyze (sintaxis, tipos y lint).

El analizador oficial no conoce la API de Roblox. Se le da lo mínimo:
  * studio/.luaurc declara los globales (game, workspace, Instance, Vector3...).
  * pruebas/tipos_roblox.luau declara los tipos (Instance, CFrame...) como `any`. Es una
    sola línea que se antepone a la primera línea de cada copia temporal, así los números
    de línea de los mensajes coinciden con los archivos reales.
Por eso este análisis comprueba sintaxis, variables, aridad y tipos del código propio,
pero NO los nombres de propiedades o métodos de Roblox: eso lo cubren las pruebas con el
doble de la API (pruebas/ejecutar.py).

Uso: python studio/pruebas/analizar.py --luau-dir CARPETA_CON_LUAU [--estricto]
     (también sirve la variable LUAU_DIR o tener luau-analyze en el PATH)
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
ARCHIVOS = [
    "lib/Base.luau", "lib/Caras.luau", "lib/Elenco.luau", "lib/Luz.luau", "lib/Utileria.luau",
    "lib/Escenarios.luau", "lib/Camara.luau", "Director.luau", "empaque/Rodar.server.luau",
    "empaque/RodarCliente.client.luau", "cargar.luau", "monolito.luau",
    "pruebas/doble_roblox.luau", "pruebas/pruebas.luau",
]


def binario(nombre: str, carpeta: str | None) -> str:
    for base in filter(None, [carpeta, os.environ.get("LUAU_DIR")]):
        for candidato in (Path(base) / nombre, Path(base) / (nombre + ".exe")):
            if candidato.exists():
                return str(candidato)
    hallado = shutil.which(nombre)
    if not hallado:
        raise SystemExit(f"No se encontró {nombre}. Usa --luau-dir o la variable LUAU_DIR.")
    return hallado


def main() -> int:
    analizador = argparse.ArgumentParser()
    analizador.add_argument("--luau-dir")
    analizador.add_argument("--estricto", action="store_true", help="analiza con --mode=strict")
    args = analizador.parse_args()
    exe = binario("luau-analyze", args.luau_dir)
    tipos = (STUDIO / "pruebas/tipos_roblox.luau").read_text(encoding="utf-8").strip()
    with tempfile.TemporaryDirectory() as tmp:
        raiz = Path(tmp)
        shutil.copy(STUDIO / ".luaurc", raiz / ".luaurc")
        presentes = []
        for relativo in ARCHIVOS:
            origen = STUDIO / relativo
            if not origen.exists():
                continue
            destino = raiz / relativo
            destino.parent.mkdir(parents=True, exist_ok=True)
            texto = origen.read_text(encoding="utf-8")
            if relativo.startswith("pruebas/"):
                destino.write_text(texto, encoding="utf-8", newline="\n")
            elif texto.startswith("--!"):
                # Las directivas van primero: los tipos se anteponen a la segunda línea.
                primera, resto = texto.split("\n", 1)
                destino.write_text(primera + "\n" + tipos + " " + resto, encoding="utf-8", newline="\n")
            else:
                destino.write_text(tipos + " " + texto, encoding="utf-8", newline="\n")
            presentes.append(relativo)
        modo = "strict" if args.estricto else "nonstrict"
        resultado = subprocess.run([exe, f"--mode={modo}", *presentes], cwd=raiz, capture_output=True, text=True)
        salida = (resultado.stdout + resultado.stderr).strip()
        print(f"luau-analyze --mode={modo} sobre {len(presentes)} archivos")
        print(salida if salida else "(sin mensajes)")
        print(f"codigo de salida: {resultado.returncode}")
        return resultado.returncode


if __name__ == "__main__":
    sys.exit(main())
