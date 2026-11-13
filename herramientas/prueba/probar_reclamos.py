"""Prueba los reclamos de nuevo_video.py: muchos procesos intentan tomar el mismo video a la vez.

Trabaja sobre un proyecto de mentira en una carpeta temporal (usa --raiz), así
que no toca la carpeta videos/ real. Solo uno de los procesos puede ganar.
"""

from __future__ import annotations

import subprocess
import sys
import tempfile
from pathlib import Path

HERRAMIENTAS = Path(__file__).resolve().parent.parent
SCRIPT = HERRAMIENTAS / "nuevo_video.py"
CONCURRENTES = 12
fallos = []


def comprobar(condicion: bool, descripcion: str) -> None:
    print(f"[{'BIEN' if condicion else 'FALLA'}] {descripcion}")
    if not condicion:
        fallos.append(descripcion)


def orden(raiz: Path, *argumentos) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT), "--raiz", str(raiz), *argumentos],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="reclamos_") as carpeta:
        raiz = Path(carpeta) / "proyecto con espacios"
        (raiz / "guiones").mkdir(parents=True)
        (raiz / "guiones" / "001-video-de-prueba.md").write_text("# Guion de prueba\n", encoding="utf-8")
        (raiz / "guiones" / "002-otro-video.md").write_text("# Otro guion\n", encoding="utf-8")
        video = raiz / "videos" / "001-video-de-prueba"

        resultado = orden(raiz, "crear", "1")
        comprobar(resultado.returncode == 0 and (video / "estado.md").is_file(), "crear arma la carpeta con estado.md")
        casillas = (video / "estado.md").read_text(encoding="utf-8").count("- [ ]")
        comprobar(casillas == 9, f"estado.md tiene 9 casillas (tiene {casillas})")
        comprobar(all((video / n).is_dir() for n in ("voz", "tiempos", "grabacion", "montaje")), "crea las subcarpetas")

        # Carrera: todos los procesos arrancan a la vez.
        procesos = [
            subprocess.Popen(
                [sys.executable, str(SCRIPT), "--raiz", str(raiz), "tomar", "001", "--chat", f"chat-{i}"],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8", errors="replace",
            )
            for i in range(CONCURRENTES)
        ]
        salidas = [(p.communicate(), p.returncode) for p in procesos]
        ganadores = [i for i, (_, codigo) in enumerate(salidas) if codigo == 0]
        comprobar(len(ganadores) == 1, f"de {CONCURRENTES} intentos simultáneos gana exactamente uno (ganaron {len(ganadores)})")
        perdedores = [textos[1] for textos, codigo in salidas if codigo != 0]
        comprobar(
            len(perdedores) == CONCURRENTES - 1 and all("ya está tomado por" in t for t in perdedores),
            "los demás fallan diciendo quién lo tomó",
        )
        if ganadores and perdedores:
            comprobar(f"chat-{ganadores[0]}" in perdedores[0], "el mensaje nombra al chat ganador")
            print(f"       Mensaje de ejemplo: {perdedores[0].strip()}")

        resultado = orden(raiz, "estado")
        print(resultado.stdout.rstrip())
        comprobar(ganadores and f"chat-{ganadores[0]}" in resultado.stdout and "libre" in resultado.stdout,
                  "estado muestra quién tiene el 001 y que el 002 está libre")

        resultado = orden(raiz, "soltar", "001", "--chat", "otro-chat")
        comprobar(resultado.returncode != 0 and (video / ".tomado").exists(), "soltar con otro nombre de chat no borra el reclamo")
        resultado = orden(raiz, "soltar", "001")
        comprobar(resultado.returncode == 0 and not (video / ".tomado").exists(), "soltar borra el reclamo")
        resultado = orden(raiz, "tomar", "001", "--chat", "chat-nuevo")
        comprobar(resultado.returncode == 0, "después de soltar se puede volver a tomar")

        # La etapa es la primera casilla sin marcar.
        estado = video / "estado.md"
        texto = estado.read_text(encoding="utf-8").replace("- [ ] **guion**", "- [x] **guion**").replace("- [ ] **voz**", "- [x] **voz**")
        estado.write_text(texto, encoding="utf-8")
        resultado = orden(raiz, "estado")
        linea = next((l for l in resultado.stdout.splitlines() if l.startswith("001-")), "")
        comprobar("tiempos" in linea, f"estado informa la etapa actual: {linea.strip()}")

        resultado = orden(raiz, "tomar", "009", "--chat", "x")
        comprobar(resultado.returncode != 0 and "No hay ningún guion" in resultado.stderr, "un número sin guion da un error claro")

    print()
    if fallos:
        print(f"RESULTADO: {len(fallos)} comprobación(es) fallaron.")
        return 1
    print("RESULTADO: todas las comprobaciones pasaron.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
