#!/usr/bin/env python3
"""Genera pruebas/api_roblox.luau a partir del volcado oficial de la API de Roblox Studio.

El volcado (API-Dump.json) lo publica Roblox en su servidor de instalación para cada
versión de Studio:  https://setup.rbxcdn.com/<version>-API-Dump.json
Para no guardar 7 MB en el proyecto, solo se conservan las clases y enumeraciones cuyo
nombre aparece en el código de studio/ (más todos sus ancestros). El doble de pruebas usa
esta tabla para rechazar cualquier clase, propiedad, método, evento o enumeración que no
exista, y para comprobar el tipo de cada valor que se asigna a una propiedad.

Uso:
  python studio/pruebas/generar_api.py --dump RUTA/API-Dump.json
  python studio/pruebas/generar_api.py --version version-63eb6055af4e4688   (lo descarga)
"""
from __future__ import annotations

import argparse
import json
import re
import urllib.request
from pathlib import Path

STUDIO = Path(__file__).resolve().parent.parent
FUENTES = ["lib", "empaque", "Director.luau", "pruebas/pruebas.luau", "pruebas/doble_roblox.luau"]
# Clases que el doble necesita aunque no aparezcan escritas en el código.
SIEMPRE = {"DataModel", "Workspace", "Camera", "Terrain", "Player", "PlayerGui", "ServiceProvider"}


def texto_del_proyecto() -> str:
    partes = []
    for nombre in FUENTES:
        ruta = STUDIO / nombre
        archivos = sorted(ruta.rglob("*.luau")) if ruta.is_dir() else [ruta]
        partes += [a.read_text(encoding="utf-8") for a in archivos if a.exists()]
    return "\n".join(partes)


def luau(valor: str) -> str:
    return json.dumps(valor, ensure_ascii=True)


def main() -> None:
    analizador = argparse.ArgumentParser()
    analizador.add_argument("--dump")
    analizador.add_argument("--version")
    args = analizador.parse_args()
    if args.dump:
        volcado = json.loads(Path(args.dump).read_text(encoding="utf-8"))
        origen = Path(args.dump).name
    elif args.version:
        url = f"https://setup.rbxcdn.com/{args.version}-API-Dump.json"
        with urllib.request.urlopen(url) as respuesta:  # noqa: S310 (URL fija de Roblox)
            volcado = json.loads(respuesta.read().decode("utf-8"))
        origen = url
    else:
        raise SystemExit("Indica --dump o --version")

    clases = {c["Name"]: c for c in volcado["Classes"]}
    palabras = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", texto_del_proyecto()))
    usadas = set()
    for nombre in (palabras | SIEMPRE) & set(clases):
        while nombre and nombre in clases and nombre not in usadas:
            usadas.add(nombre)
            nombre = clases[nombre]["Superclass"]
    enums = {e["Name"]: [i["Name"] for i in e["Items"]] for e in volcado["Enums"]}
    enums_usados = {n for n in enums if n in palabras}
    # También las enumeraciones que son tipo de alguna propiedad de las clases usadas.
    for nombre in usadas:
        for m in clases[nombre]["Members"]:
            if m["MemberType"] == "Property" and m["ValueType"]["Category"] == "Enum":
                enums_usados.add(m["ValueType"]["Name"])

    lineas = [
        "-- api_roblox.luau",
        "-- GENERADO por pruebas/generar_api.py; no editar a mano.",
        f"-- Origen: {origen} (volcado oficial de la API de Roblox Studio).",
        "-- Formato de cada miembro: P|categoria|tipo|banderas (R = solo lectura, K = exige la",
        "-- capacidad PluginOrOpenCloud para escribir, S = seguridad de plugin o superior),",
        "-- F|banderas (método), E (evento), C (callback).",
        "return {",
        "\tclases = {",
    ]
    for nombre in sorted(usadas):
        c = clases[nombre]
        etiquetas = c.get("Tags") or []
        lineas.append(f"\t\t[{luau(nombre)}] = {{ s = {luau(c['Superclass'])}, creable = {str('NotCreatable' not in etiquetas).lower()}, "
                      f"servicio = {str('Service' in etiquetas).lower()}, m = {{")
        for m in c["Members"]:
            tipo = m["MemberType"]
            etiq = m.get("Tags") or []
            if tipo == "Property":
                banderas = ""
                if "ReadOnly" in etiq:
                    banderas += "R"
                cap = m.get("Capabilities")
                if isinstance(cap, dict) and "PluginOrOpenCloud" in (cap.get("Write") or []):
                    banderas += "K"
                seg = m.get("Security") or {}
                if isinstance(seg, dict) and seg.get("Write") not in (None, "None"):
                    banderas += "S"
                vt = m["ValueType"]
                desc = f"P|{vt['Category']}|{vt['Name']}|{banderas}"
            elif tipo == "Function":
                seg = m.get("Security")
                desc = "F|" + ("S" if seg not in (None, "None") else "")
            elif tipo == "Event":
                desc = "E"
            else:
                desc = "C"
            lineas.append(f"\t\t\t[{luau(m['Name'])}] = {luau(desc)},")
        lineas.append("\t\t} },")
    lineas.append("\t},")
    lineas.append("\tenums = {")
    for nombre in sorted(enums_usados):
        lineas.append(f"\t\t[{luau(nombre)}] = {{ {', '.join(luau(i) for i in enums[nombre])} }},")
    lineas.append("\t},")
    lineas.append("}")
    destino = STUDIO / "pruebas/api_roblox.luau"
    destino.write_text("\n".join(lineas) + "\n", encoding="utf-8", newline="\n")
    print(f"{destino.name}: {len(usadas)} clases, {len(enums_usados)} enumeraciones, {destino.stat().st_size} bytes")


if __name__ == "__main__":
    main()
