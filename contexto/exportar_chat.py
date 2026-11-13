"""Exporta la conversación de Claude Code a Markdown legible y sin datos personales.

Lee el archivo .jsonl de la sesión y escribe solo lo que sirve como contexto:
los mensajes del usuario, las respuestas del asistente, una línea por cada
herramienta usada y los informes finales de los subagentes. No copia el
resultado crudo de las herramientas ni los avisos internos del sistema.

Uso:
    python contexto/exportar_chat.py RUTA_AL.jsonl contexto/conversacion.md

Para ocultar además palabras propias (en PowerShell, antes de correrlo):
    $env:OCULTAR = "minombredeusuario=usuario;NombreDeUnPrograma=un programa"
"""

import json
import re
import sys
from pathlib import Path

REEMPLAZOS = [
    (re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+"), "[correo]"),
    (re.compile(r"(Users[\\/]+)[^\\/\s\"'`]+", re.I), r"\1usuario"),
    (re.compile(r"(Users-)[A-Za-z0-9_.]+(-)", re.I), r"\1usuario\2"),
    (re.compile(r"\b[A-Z0-9]{6}~\d\b"), "USUARIO"),
    (re.compile(r"\b[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\b", re.I), "[id]"),
    (re.compile(r"gh[opsu]_[A-Za-z0-9*]{10,}"), "[token]"),
    (re.compile(r"req_[A-Za-z0-9]{10,}"), "[id]"),
    (re.compile(chr(0x2014)), ", "),
]
RUIDO = re.compile(
    r"<system-reminder>.*?</system-reminder>|<local-command-caveat>.*?</local-command-caveat>",
    re.S,
)
INFORME = re.compile(r"<summary>(.*?)</summary>.*?<result>(.*?)</result>", re.S)


def reemplazos_extra():
    """Lee la variable de entorno OCULTAR: 'texto=reemplazo;otro texto=otro reemplazo'.

    Sirve para ocultar palabras propias de tu equipo (nombre de usuario, nombres
    de programas, lo que no quieras publicar) sin escribirlas en este archivo.
    """
    import os

    extra = []
    for par in os.environ.get("OCULTAR", "").split(";"):
        if "=" in par:
            texto, valor = par.split("=", 1)
            if texto.strip():
                extra.append((re.compile(texto.strip(), re.I), valor))
    return extra


EXTRA = reemplazos_extra()


def limpiar(texto: str) -> str:
    for patron, valor in EXTRA + REEMPLAZOS:
        texto = patron.sub(valor, texto)
    return texto.strip()


def bloques(contenido):
    if isinstance(contenido, str):
        return [{"type": "text", "text": contenido}]
    return contenido or []


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    origen, destino = Path(sys.argv[1]), Path(sys.argv[2])
    salida = [
        "# Conversación completa de la sesión de trabajo",
        "",
        "Exportada con `contexto/exportar_chat.py`. Incluye los mensajes del usuario,",
        "las respuestas del asistente, una línea por herramienta usada y los informes",
        "de los subagentes. Se quitaron los avisos internos del sistema, el resultado",
        "crudo de las herramientas y los datos personales (correo, nombre de usuario",
        "de Windows, identificadores del equipo).",
        "",
    ]
    turno = 0
    for linea in origen.read_text(encoding="utf-8").splitlines():
        try:
            evento = json.loads(linea)
        except json.JSONDecodeError:
            continue
        if evento.get("isSidechain") or evento.get("type") not in ("user", "assistant"):
            continue
        mensaje = evento.get("message") or {}
        rol = mensaje.get("role")
        fecha = (evento.get("timestamp") or "")[:16].replace("T", " ")
        for bloque in bloques(mensaje.get("content")):
            tipo = bloque.get("type")
            if tipo == "text":
                crudo = bloque.get("text") or ""
                informes = INFORME.findall(crudo) if "<task-notification>" in crudo else []
                for resumen, cuerpo in informes:
                    salida += [f"### Informe de subagente: {limpiar(resumen)} ({fecha} UTC)", "", limpiar(cuerpo), ""]
                if informes:
                    continue
                texto = limpiar(RUIDO.sub("", crudo))
                if not texto or texto.startswith("[SYSTEM NOTIFICATION"):
                    continue
                if rol == "user":
                    turno += 1
                    salida += [f"## Usuario, mensaje {turno} ({fecha} UTC)", "", texto, ""]
                else:
                    salida += [f"**Asistente** ({fecha} UTC)", "", texto, ""]
            elif tipo == "tool_use" and rol == "assistant":
                datos = bloque.get("input") or {}
                detalle = datos.get("description") or datos.get("summary") or datos.get("file_path") or datos.get("pattern") or ""
                detalle = limpiar(str(detalle))[:160]
                salida += [f"- _Herramienta {bloque.get('name')}: {detalle}_", ""]
    destino.write_text("\n".join(salida) + "\n", encoding="utf-8")
    print(f"{destino}: {turno} mensajes del usuario, {len(salida)} bloques")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
