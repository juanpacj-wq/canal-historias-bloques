"""Crea la carpeta de trabajo de un video y maneja los reclamos para trabajar en paralelo."""

from __future__ import annotations

import argparse
import json
import os
import re
import time
from datetime import datetime
from pathlib import Path

import comun

ETAPAS = [
    ("guion", "Guion revisado y texto de la narración listo"),
    ("voz", "Voz generada y pasada por ritmo.py"),
    ("tiempos", "palabras.json y planos.json generados"),
    ("escenas", "Escenarios, personajes y script director listos"),
    ("grabación", "Grabación continua hecha"),
    ("montaje", "Video montado con montar.py"),
    ("revisión", "revisar.py aprobado y hoja de contactos revisada"),
    ("metadatos", "Título, descripción y etiquetas escritos"),
    ("publicado", "Subido a YouTube"),
]
SUBCARPETAS = ["voz", "tiempos", "escenas", "grabacion", "montaje", "revision", "metadatos"]
ARCHIVO_RECLAMO = ".tomado"


def raiz_del_proyecto(argumento) -> Path:
    raiz = Path(argumento).resolve() if argumento else comun.CARPETA_HERRAMIENTAS.parent
    if not (raiz / "guiones").is_dir():
        raise comun.ErrorHerramienta(
            f"No encuentro la carpeta 'guiones' en '{raiz}'. Indica la raíz del proyecto con --raiz."
        )
    return raiz


def normalizar_numero(texto: str) -> str:
    if not re.fullmatch(r"\d{1,3}", texto.strip()):
        raise comun.ErrorHerramienta(f"'{texto}' no es un número de video válido (por ejemplo: 001).")
    return f"{int(texto):03d}"


def listar_guiones(raiz: Path) -> list:
    return sorted(p for p in (raiz / "guiones").glob("[0-9][0-9][0-9]-*.md"))


def buscar_guion(raiz: Path, numero: str) -> Path:
    encontrados = [p for p in listar_guiones(raiz) if p.name.startswith(f"{numero}-")]
    if not encontrados:
        raise comun.ErrorHerramienta(f"No hay ningún guion '{numero}-*.md' en '{raiz / 'guiones'}'.")
    if len(encontrados) > 1:
        nombres = ", ".join(p.name for p in encontrados)
        raise comun.ErrorHerramienta(f"Hay más de un guion con el número {numero}: {nombres}.")
    return encontrados[0]


def carpeta_del_video(raiz: Path, guion: Path) -> Path:
    return raiz / "videos" / guion.stem


def leer_reclamo(carpeta: Path):
    ruta = carpeta / ARCHIVO_RECLAMO
    # Si otro chat acaba de crear el archivo puede estar todavía vacío: se reintenta un momento.
    for _ in range(10):
        try:
            return json.loads(ruta.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return None
        except (json.JSONDecodeError, OSError):
            time.sleep(0.05)
    return {"chat": "(reclamo ilegible)", "fecha": "?"}


def etapa_actual(carpeta: Path) -> str:
    """La primera casilla sin marcar de estado.md."""
    ruta = carpeta / "estado.md"
    if not ruta.is_file():
        return "sin carpeta"
    marcadas = {}
    for linea in ruta.read_text(encoding="utf-8-sig").splitlines():
        coincidencia = re.match(r"\s*[-*]\s*\[( |x|X)\]\s*\*{0,2}([^:*]+)", linea)
        if coincidencia:
            marcadas[coincidencia.group(2).strip().lower()] = coincidencia.group(1).lower() == "x"
    for nombre, _ in ETAPAS:
        if not marcadas.get(nombre, False):
            return nombre
    return "terminado"


def crear(raiz: Path, numero: str) -> int:
    guion = buscar_guion(raiz, numero)
    carpeta = carpeta_del_video(raiz, guion)
    carpeta.mkdir(parents=True, exist_ok=True)
    for nombre in SUBCARPETAS:
        (carpeta / nombre).mkdir(exist_ok=True)
    estado = carpeta / "estado.md"
    if estado.exists():
        print(f"La carpeta ya existía y se conserva su estado.md: '{carpeta}'")
        return 0
    lineas = [
        f"# Estado del video {guion.stem}",
        "",
        f"- Guion: `guiones/{guion.name}`",
        f"- Creado: {datetime.now().strftime('%Y-%m-%d')}",
        "",
        "Marca cada casilla con una x cuando termines la etapa: `- [x]`.",
        "La etapa actual es la primera casilla sin marcar.",
        "",
        "## Etapas",
        "",
    ]
    lineas += [f"- [ ] **{nombre}**: {detalle}" for nombre, detalle in ETAPAS]
    lineas += [
        "",
        "## Carpetas",
        "",
        "- `voz/`: audio original y audio con el ritmo ajustado",
        "- `tiempos/`: palabras.json, planos.json y subtitulos.ass",
        "- `escenas/`: notas y scripts de los escenarios",
        "- `grabacion/`: la grabación continua o los clips por plano",
        "- `montaje/`: música, efectos y el MP4 final",
        "- `revision/`: hoja de contactos e informe de revisar.py",
        "- `metadatos/`: título, descripción y etiquetas",
        "",
        "## Notas",
        "",
    ]
    estado.write_text("\n".join(lineas), encoding="utf-8", newline="\n")
    print(f"Carpeta creada: '{carpeta}'")
    return 0


def tomar(raiz: Path, numero: str, chat: str) -> int:
    chat = chat.strip()
    if not chat:
        raise comun.ErrorHerramienta("Indica quién toma el video con --chat nombre.")
    guion = buscar_guion(raiz, numero)
    carpeta = carpeta_del_video(raiz, guion)
    carpeta.mkdir(parents=True, exist_ok=True)
    ruta = carpeta / ARCHIVO_RECLAMO
    contenido = json.dumps(
        {"chat": chat, "fecha": datetime.now().astimezone().isoformat(timespec="seconds")},
        ensure_ascii=False,
    )
    try:
        # O_EXCL hace que la creación sea atómica: si dos chats lo intentan a la vez,
        # el sistema operativo solo deja pasar a uno.
        descriptor = os.open(ruta, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
    except FileExistsError:
        actual = leer_reclamo(carpeta) or {"chat": "(desconocido)", "fecha": "?"}
        raise comun.ErrorHerramienta(
            f"El video {guion.stem} ya está tomado por '{actual.get('chat')}' desde {actual.get('fecha')}. "
            f"Elige otro video o espera a que lo suelten (nuevo_video.py soltar {numero})."
        ) from None
    with os.fdopen(descriptor, "w", encoding="utf-8") as archivo:
        archivo.write(contenido + "\n")
    print(f"Tomado: {guion.stem} queda a nombre de '{chat}'.")
    return 0


def soltar(raiz: Path, numero: str, chat, forzar: bool) -> int:
    guion = buscar_guion(raiz, numero)
    carpeta = carpeta_del_video(raiz, guion)
    actual = leer_reclamo(carpeta)
    if actual is None:
        print(f"El video {guion.stem} no estaba tomado.")
        return 0
    if chat and actual.get("chat") != chat.strip() and not forzar:
        raise comun.ErrorHerramienta(
            f"El video {guion.stem} lo tiene '{actual.get('chat')}', no '{chat}'. "
            "Usa --forzar solo si de verdad quedó abandonado."
        )
    try:
        (carpeta / ARCHIVO_RECLAMO).unlink()
    except FileNotFoundError:
        pass
    print(f"Soltado: {guion.stem} (lo tenía '{actual.get('chat')}').")
    return 0


def estado(raiz: Path) -> int:
    guiones = listar_guiones(raiz)
    if not guiones:
        print("No hay guiones con nombre NNN-slug.md en la carpeta guiones.")
        return 0
    filas = []
    for guion in guiones:
        carpeta = carpeta_del_video(raiz, guion)
        reclamo = leer_reclamo(carpeta) if carpeta.is_dir() else None
        quien = f"{reclamo.get('chat')} (desde {reclamo.get('fecha')})" if reclamo else "libre"
        filas.append((guion.stem, etapa_actual(carpeta), quien))
    ancho_video = max(len("Video"), max(len(f[0]) for f in filas))
    ancho_etapa = max(len("Etapa"), max(len(f[1]) for f in filas))
    print(f"{'Video':<{ancho_video}}  {'Etapa':<{ancho_etapa}}  Tomado por")
    print(f"{'-' * ancho_video}  {'-' * ancho_etapa}  {'-' * 10}")
    for video, etapa, quien in filas:
        print(f"{video:<{ancho_video}}  {etapa:<{ancho_etapa}}  {quien}")
    return 0


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Crea la carpeta de trabajo de un video (videos/NNN-slug/) a partir de su guion "
            "(guiones/NNN-slug.md) y maneja los reclamos para que varios chats trabajen en "
            "paralelo sin pisarse."
        ),
        epilog=(
            "Ejemplos: python nuevo_video.py crear 001  |  python nuevo_video.py tomar 001 --chat chat-a  |  "
            "python nuevo_video.py soltar 001  |  python nuevo_video.py estado"
        ),
    )
    analizador.add_argument("--raiz", help="Raíz del proyecto (por defecto: la carpeta que contiene a 'herramientas').")
    ordenes = analizador.add_subparsers(dest="orden", required=True, metavar="orden")

    orden_crear = ordenes.add_parser("crear", help="Crea videos/NNN-slug/ con sus subcarpetas y estado.md.")
    orden_crear.add_argument("numero", help="Número del guion, por ejemplo 001.")

    orden_tomar = ordenes.add_parser("tomar", help="Reclama un video. Falla si otro chat ya lo tomó.")
    orden_tomar.add_argument("numero", help="Número del guion, por ejemplo 001.")
    orden_tomar.add_argument("--chat", required=True, help="Nombre del chat o de la persona que lo toma.")

    orden_soltar = ordenes.add_parser("soltar", help="Libera el reclamo de un video.")
    orden_soltar.add_argument("numero", help="Número del guion, por ejemplo 001.")
    orden_soltar.add_argument("--chat", help="Si lo pasas, solo se suelta cuando el reclamo es de ese chat.")
    orden_soltar.add_argument("--forzar", action="store_true", help="Suelta aunque el reclamo sea de otro chat.")

    ordenes.add_parser("estado", help="Lista todos los guiones con su etapa y quién los tiene.")
    args = analizador.parse_args()

    raiz = raiz_del_proyecto(args.raiz)
    if args.orden == "estado":
        return estado(raiz)
    numero = normalizar_numero(args.numero)
    if args.orden == "crear":
        return crear(raiz, numero)
    if args.orden == "tomar":
        return tomar(raiz, numero, args.chat)
    return soltar(raiz, numero, args.chat, args.forzar)


if __name__ == "__main__":
    comun.principal(main)
