#!/usr/bin/env python3
"""Empaqueta la biblioteca Historias para inyectarla en Roblox Studio.

Lee studio/lib/*.luau, studio/Director.luau y studio/empaque/ y genera, sin duplicar
código a mano:

  studio/cargar.luau            Un solo bloque para execute_luau: crea los ModuleScript en
                                ReplicatedStorage.Historias asignando Source.
  studio/cargar_multi_edit.json Lo mismo como lista de llamadas para la herramienta MCP
                                `multi_edit` (la vía que la propia herramienta recomienda
                                para crear scripts). Una entrada por script.
  studio/monolito.luau          Respaldo que no crea scripts ni usa require: todos los
                                módulos en un solo bloque; el chat pega su código al final.

Uso:  python studio/empaquetar.py            genera los tres archivos
      python studio/empaquetar.py --comprobar  falla si los generados están desactualizados
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

AQUI = Path(__file__).resolve().parent
# Orden de instalación: cada módulo solo requiere a los anteriores.
ORDEN = ["Base", "Caras", "Elenco", "Luz", "Utileria", "Escenarios", "Camara", "Director"]
LANZADORES = {
    "Rodar": ("empaque/Rodar.server.luau", "ServerScriptService.HistoriasRodar"),
    "RodarCliente": ("empaque/RodarCliente.client.luau", "StarterPlayer.StarterPlayerScripts.HistoriasRodarCliente"),
}
RAYA_LARGA = chr(0x2014)


def leer(ruta: Path) -> str:
    texto = ruta.read_text(encoding="utf-8").replace("\r\n", "\n")
    if RAYA_LARGA in texto:
        raise SystemExit(f"{ruta}: contiene el carácter prohibido U+2014")
    return texto


def ruta_modulo(nombre: str) -> Path:
    return AQUI / ("Director.luau" if nombre == "Director" else f"lib/{nombre}.luau")


def cadena_larga(texto: str) -> str:
    """Envuelve el texto en una cadena larga de Luau con un nivel que no choque."""
    nivel = 1
    while f"]{'=' * nivel}]" in texto or texto.endswith("]" + "=" * nivel):
        nivel += 1
    iguales = "=" * nivel
    # El primer salto de línea después del corchete de apertura se descarta en Luau.
    return f"[{iguales}[\n{texto}]{iguales}]"


def version(fuentes: dict[str, str]) -> str:
    hallado = re.search(r'Base\.VERSION\s*=\s*"([^"]+)"', fuentes["Base"])
    return hallado.group(1) if hallado else "0.0.0"


def generar_cargar(fuentes: dict[str, str], lanzadores: dict[str, str]) -> str:
    plantilla = leer(AQUI / "empaque/cargar.plantilla.luau")
    bloques = [f'FUENTES["{n}"] = {cadena_larga(fuentes[n])}' for n in ORDEN]
    bloques += [f'LANZADORES["{n}"] = {cadena_larga(t)}' for n, t in lanzadores.items()]
    salida = plantilla.replace("--@@FUENTES@@", "\n".join(bloques))
    salida = salida.replace("@@ORDEN@@", ", ".join(f'"{n}"' for n in ORDEN))
    return salida.replace("@@VERSION@@", version(fuentes))


def generar_multi_edit(fuentes: dict[str, str], lanzadores: dict[str, str]) -> str:
    llamadas = []
    for n in ORDEN:
        llamadas.append({
            "clase": "ModuleScript",
            "file_path": f"ReplicatedStorage.Historias.{n}",
            "edits": [{"old_string": "", "new_string": fuentes[n]}],
        })
    for n, texto in lanzadores.items():
        llamadas.append({
            "clase": "LocalScript" if n == "RodarCliente" else "Script",
            "file_path": LANZADORES[n][1],
            "edits": [{"old_string": "", "new_string": texto}],
        })
    nota = (
        "Una entrada por script para la herramienta MCP multi_edit (datamodel_type Edit). "
        "La forma {file_path, edits:[{old_string,new_string}]} sale de las cadenas del plugin de "
        "Studio 0.747 y no se ha probado en vivo; el campo 'clase' es informativo: si multi_edit "
        "no crea la clase esperada, crea primero la instancia vacia con execute_luau."
    )
    return json.dumps({"nota": nota, "version": version(fuentes), "llamadas": llamadas}, ensure_ascii=False, indent=1) + "\n"


def generar_monolito(fuentes: dict[str, str]) -> str:
    partes = [
        "--!nolint LocalUnused",
        "-- monolito.luau",
        "-- GENERADO por studio/empaquetar.py. No lo edites a mano.",
        "-- Respaldo para cuando execute_luau no pueda escribir Source ni hacer require de un",
        "-- ModuleScript: trae todos los módulos en un solo bloque, sin crear ningún script.",
        "-- Uso: pega este archivo completo en execute_luau y agrega tu código DESPUÉS de la",
        "-- última línea; ahí ya existe la variable local `Historias` (el Director, con",
        "-- Historias.Elenco, Historias.Caras, Historias.Escenarios, Historias.Luz,",
        "-- Historias.Utileria, Historias.Camara y Historias.Base).",
        "-- Limitación: como no hay ModuleScript, nada queda instalado en el lugar; los",
        "-- lanzadores para grabar en modo juego sí necesitan la instalación con scripts.",
        "",
        "local __fabricas: { [string]: (any, any) -> any } = {}",
        "local __cargados: { [string]: any } = {}",
        "local function __requerir(ref: any): any",
        "\tlocal nombre = (type(ref) == \"table\") and ref.__modulo or ref",
        "\tif __cargados[nombre] == nil then",
        "\t\tlocal guion = {",
        "\t\t\tName = nombre,",
        "\t\t\tParent = setmetatable({}, { __index = function(_, clave)",
        "\t\t\t\treturn { __modulo = clave }",
        "\t\t\tend }),",
        "\t\t}",
        "\t\t__cargados[nombre] = __fabricas[nombre](guion, __requerir)",
        "\tend",
        "\treturn __cargados[nombre]",
        "end",
        "",
    ]
    for n in ORDEN:
        partes.append(f'__fabricas["{n}"] = function(script: any, require: any): any')
        partes.append(fuentes[n].rstrip("\n"))
        partes.append("end")
        partes.append("")
    partes.append('local Historias = __requerir("Director")')
    partes.append("-- Tu código va debajo de esta línea, por ejemplo:  return Historias.Caras.NOMBRES")
    return "\n".join(partes) + "\n"


def main() -> int:
    analizador = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    analizador.add_argument("--comprobar", action="store_true", help="no escribe; falla si algo está desactualizado")
    args = analizador.parse_args()

    fuentes = {n: leer(ruta_modulo(n)) for n in ORDEN}
    lanzadores = {n: leer(AQUI / ruta) for n, (ruta, _) in LANZADORES.items()}
    salidas = {
        "cargar.luau": generar_cargar(fuentes, lanzadores),
        "cargar_multi_edit.json": generar_multi_edit(fuentes, lanzadores),
        "monolito.luau": generar_monolito(fuentes),
    }
    desactualizados = []
    for nombre, texto in salidas.items():
        destino = AQUI / nombre
        actual = destino.read_text(encoding="utf-8") if destino.exists() else None
        if actual != texto:
            desactualizados.append(nombre)
            if not args.comprobar:
                destino.write_text(texto, encoding="utf-8", newline="\n")
        print(f"{'DESACTUALIZADO' if args.comprobar and actual != texto else 'ok'}  {nombre}  {len(texto.encode('utf-8'))} bytes")
    if args.comprobar and desactualizados:
        print("Ejecuta: python studio/empaquetar.py")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
