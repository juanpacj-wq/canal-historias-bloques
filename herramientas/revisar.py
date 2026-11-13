"""Control de calidad automático del MP4 final. Informe con APROBADO o REVISAR por línea."""

from __future__ import annotations

import argparse
import re
import struct
import tempfile
from pathlib import Path

import comun


class Informe:
    def __init__(self) -> None:
        self.lineas = []

    def agregar(self, estado: str, nombre: str, detalle: str) -> None:
        self.lineas.append((estado, nombre, detalle))

    def comprobar(self, bien: bool, nombre: str, detalle: str) -> None:
        self.agregar("APROBADO" if bien else "REVISAR", nombre, detalle)

    def omitir(self, nombre: str, detalle: str) -> None:
        self.agregar("OMITIDO", nombre, detalle)

    def por_revisar(self) -> int:
        return sum(1 for estado, _, _ in self.lineas if estado == "REVISAR")

    def imprimir(self) -> None:
        for estado, nombre, detalle in self.lineas:
            print(f"[{estado:<8}] {nombre}: {detalle}")


def moov_al_inicio(ruta: Path):
    """True si el átomo 'moov' va antes que 'mdat' (es decir, +faststart)."""
    orden = []
    with open(ruta, "rb") as archivo:
        while len(orden) < 20:
            cabecera = archivo.read(8)
            if len(cabecera) < 8:
                break
            tamano, tipo = struct.unpack(">I4s", cabecera)
            consumido = 8
            if tamano == 1:
                tamano = struct.unpack(">Q", archivo.read(8))[0]
                consumido = 16
            orden.append(tipo)
            if tipo in (b"moov", b"mdat") and b"moov" in orden and b"mdat" in orden:
                break
            if tamano == 0:
                break
            archivo.seek(tamano - consumido, 1)
    if b"moov" not in orden or b"mdat" not in orden:
        return None
    return orden.index(b"moov") < orden.index(b"mdat")


def detectar_cortes(video: Path, umbral: float) -> list:
    filtro = f"select='gt(scene,{umbral})',metadata=print:file=-"
    salida = comun.ffmpeg(["-i", video, "-an", "-vf", filtro, "-f", "null", "-"]).stdout
    return [float(t) for t in re.findall(r"pts_time:([\d.]+)", salida)]


def cajas_de_subtitulos(subtitulos: Path, fuentes, duracion: float, cps: int):
    """Dibuja los subtítulos solos sobre negro y mide la caja que ocupan en cada cuadro.

    Devuelve (cajas, fuentes sustituidas, si ffmpeg informó la fuente elegida).
    """
    with tempfile.TemporaryDirectory(prefix="revisar_") as carpeta:
        temporal = Path(carpeta)
        comun.preparar_carpeta_filtros(temporal, subtitulos, fuentes)
        origen = f"color=c=black:s={comun.ANCHO}x{comun.ALTO}:r={cps}:d={duracion:.3f}"
        salida = comun.ffmpeg(
            ["-f", "lavfi", "-i", origen, "-vf", "ass=sub.ass:fontsdir=fuentes,bbox=min_val=40",
             "-f", "null", "-"],
            cwd=temporal,
        ).stderr
    cajas = []
    patron = re.compile(r"pts_time:([\d.]+) x1:(\d+) x2:(\d+) y1:(\d+) y2:(\d+)")
    for tiempo, x1, x2, y1, y2 in patron.findall(salida):
        cajas.append((float(tiempo), int(x1), int(x2), int(y1), int(y2)))
    return cajas, comun.fuentes_sustituidas(salida), "fontselect:" in salida


def borde_del_estilo(subtitulos: Path) -> float:
    """Borde + sombra del estilo: no se ven sobre negro, así que se suman a la caja medida."""
    for linea in comun.leer_texto(subtitulos).splitlines():
        if linea.startswith("Style:"):
            campos = linea.split(":", 1)[1].split(",")
            try:
                return float(campos[16]) + float(campos[17])
            except (IndexError, ValueError):
                return 0.0
    return 0.0


def main() -> int:
    analizador = argparse.ArgumentParser(
        description=(
            "Control de calidad del MP4 final para YouTube Shorts: resolución, cuadros por "
            "segundo, duración, sonoridad, pico real, cortes y duración media de plano, palabras "
            "por minuto y zona segura de los subtítulos. Cada línea sale con APROBADO o REVISAR. "
            "Termina con código 1 si hay algo por revisar."
        ),
        epilog="Ejemplo: python revisar.py --video final.mp4 --palabras palabras.json --subtitulos subtitulos.ass --planos planos.json",
    )
    analizador.add_argument("--video", required=True, help="MP4 final.")
    analizador.add_argument("--palabras", help="palabras.json, para calcular las palabras por minuto.")
    analizador.add_argument("--subtitulos", help="subtitulos.ass que se quemó en el video, para revisar la zona segura.")
    analizador.add_argument("--planos", help="planos.json, para comparar los cortes detectados con los previstos.")
    analizador.add_argument("--fuentes", default=str(comun.CARPETA_FUENTES), help="Carpeta de fuentes de los subtítulos.")
    analizador.add_argument("--umbral-corte", type=float, default=0.3, help="Umbral de detección de cortes de ffmpeg (por defecto: 0.3).")
    analizador.add_argument("--tolerancia-corte", type=float, default=0.05, help="Diferencia máxima en segundos entre un corte detectado y el previsto (por defecto: 0.05).")
    analizador.add_argument("--plano-medio-max", type=float, default=2.5, help="Duración media de plano máxima aceptada (por defecto: 2.5 s; el formato ronda 1.5 s).")
    analizador.add_argument("--ppm-min", type=float, default=220.0, help="Mínimo de palabras por minuto (por defecto: 220).")
    analizador.add_argument("--ppm-max", type=float, default=240.0, help="Máximo de palabras por minuto (por defecto: 240).")
    analizador.add_argument("--lufs", type=float, default=-14.0, help="Sonoridad integrada objetivo (por defecto: -14 LUFS).")
    analizador.add_argument("--tolerancia-lufs", type=float, default=1.0, help="Margen aceptado alrededor del objetivo (por defecto: 1 LU).")
    analizador.add_argument("--pico-max", type=float, default=-1.0, help="Pico real máximo aceptado en dBTP (por defecto: -1).")
    analizador.add_argument("--seguro-arriba", type=int, default=250, help="Franja superior que tapa la interfaz de Shorts, en pixeles (por defecto: 250).")
    analizador.add_argument("--seguro-abajo", type=int, default=384, help="Franja inferior que tapa la interfaz de Shorts, en pixeles (por defecto: 384).")
    analizador.add_argument("--seguro-lado", type=int, default=60, help="Margen lateral, en pixeles (por defecto: 60).")
    analizador.add_argument("--seguro-botones", type=int, default=190, help="Ancho de la columna de botones a la derecha en la mitad inferior, en pixeles (por defecto: 190).")
    args = analizador.parse_args()

    video = comun.exigir_archivo(args.video, "el video").resolve()
    datos = comun.ffprobe_json(video)
    imagen = next((s for s in datos["streams"] if s.get("codec_type") == "video"), None)
    sonido = next((s for s in datos["streams"] if s.get("codec_type") == "audio"), None)
    if not imagen:
        raise comun.ErrorHerramienta(f"'{video}' no tiene imagen.")
    duracion = float(datos["format"]["duration"])
    informe = Informe()

    # Imagen.
    ancho, alto = int(imagen["width"]), int(imagen["height"])
    informe.comprobar(
        (ancho, alto) == (comun.ANCHO, comun.ALTO), "Resolución",
        f"{ancho}x{alto} (se espera {comun.ANCHO}x{comun.ALTO})",
    )
    numerador, _, denominador = imagen.get("avg_frame_rate", "0/1").partition("/")
    cps = float(numerador) / float(denominador or 1) if float(denominador or 1) else 0.0
    informe.comprobar(abs(cps - comun.CPS) < 0.01, "Cuadros por segundo", f"{cps:.2f} (se espera {comun.CPS})")
    informe.comprobar(
        imagen.get("codec_name") == "h264" and imagen.get("pix_fmt") == "yuv420p", "Códec de video",
        f"{imagen.get('codec_name')} {imagen.get('pix_fmt')} (se espera h264 yuv420p)",
    )
    if sonido:
        informe.comprobar(
            sonido.get("codec_name") == "aac", "Códec de audio",
            f"{sonido.get('codec_name')} {sonido.get('sample_rate')} Hz, {sonido.get('channels')} canales (se espera aac)",
        )
    else:
        informe.comprobar(False, "Códec de audio", "el video no tiene sonido")
    inicio_rapido = moov_al_inicio(video)
    informe.comprobar(
        bool(inicio_rapido), "Inicio rápido (+faststart)",
        "el índice va al comienzo del archivo" if inicio_rapido else "el índice no va al comienzo del archivo",
    )

    # Duración.
    nota = "" if 90 <= duracion <= 160 else " (fuera del rango habitual del formato, 90 a 160 s)"
    informe.comprobar(duracion <= 180.0, "Duración", f"{duracion:.2f} s; el límite de Shorts es 180 s{nota}")

    # Sonido.
    if sonido:
        sonoridad = comun.medir_sonoridad(video)
        informe.comprobar(
            abs(sonoridad["integrada"] - args.lufs) <= args.tolerancia_lufs, "Sonoridad integrada",
            f"{sonoridad['integrada']:.1f} LUFS (objetivo {args.lufs:g}, margen {args.tolerancia_lufs:g})",
        )
        informe.comprobar(
            sonoridad["pico"] is not None and sonoridad["pico"] <= args.pico_max, "Pico real",
            f"{sonoridad['pico']:.1f} dBTP (máximo {args.pico_max:g})",
        )

    # Cortes.
    cortes = detectar_cortes(video, args.umbral_corte)
    media = duracion / (len(cortes) + 1)
    bordes = [0.0] + cortes + [duracion]
    mas_largo = max(b - a for a, b in zip(bordes, bordes[1:]))
    informe.comprobar(
        media <= args.plano_medio_max, "Cortes detectados",
        f"{len(cortes)} cortes; plano medio {media:.2f} s, plano más largo {mas_largo:.2f} s "
        f"(media máxima {args.plano_medio_max:g} s)",
    )
    if args.planos:
        planos = comun.leer_json(comun.exigir_archivo(args.planos, "planos.json"))["planos"]
        previstos = [float(p["inicio"]) for p in planos[1:]]
        desvios = []
        perdidos = []
        for plano, previsto in zip(planos[1:], previstos):
            cercano = min(cortes, key=lambda c: abs(c - previsto)) if cortes else None
            if cercano is None or abs(cercano - previsto) > args.tolerancia_corte:
                perdidos.append(plano["n"])
            else:
                desvios.append(abs(cercano - previsto))
        detalle = f"{len(previstos) - len(perdidos)} de {len(previstos)} cortes previstos coinciden"
        if desvios:
            detalle += f" (desvío máximo {max(desvios) * 1000:.0f} ms)"
        if perdidos:
            detalle += "; sin corte en los planos: " + ", ".join(map(str, perdidos[:15]))
            if len(perdidos) > 15:
                detalle += "..."
        informe.comprobar(not perdidos, "Cortes contra planos.json", detalle)
    else:
        informe.omitir("Cortes contra planos.json", "pasa --planos para compararlos")

    # Ritmo de la voz.
    if args.palabras:
        palabras = comun.leer_palabras(args.palabras)
        tramo = float(palabras[-1]["fin"]) - float(palabras[0]["inicio"])
        ppm = len(palabras) / (tramo / 60.0) if tramo > 0 else 0.0
        informe.comprobar(
            args.ppm_min <= ppm <= args.ppm_max, "Palabras por minuto",
            f"{ppm:.0f} ({len(palabras)} palabras en {tramo:.1f} s; se espera de {args.ppm_min:g} a {args.ppm_max:g})",
        )
        informe.comprobar(
            float(palabras[-1]["fin"]) <= duracion + 0.05, "Voz dentro del video",
            f"la última palabra termina en {float(palabras[-1]['fin']):.2f} s y el video dura {duracion:.2f} s",
        )
    else:
        informe.omitir("Palabras por minuto", "pasa --palabras para calcularlas")

    # Subtítulos.
    if args.subtitulos:
        subtitulos = comun.exigir_archivo(args.subtitulos, "el archivo de subtítulos").resolve()
        cajas, sustituidas, hubo_seleccion = cajas_de_subtitulos(subtitulos, args.fuentes, duracion, 20)
        if sustituidas:
            cambios = "; ".join(f"se pidió '{pedida}' y se usó '{usada}'" for pedida, usada in sustituidas)
            informe.comprobar(False, "Fuente de los subtítulos", f"{cambios} (revisa la carpeta de fuentes)")
        elif hubo_seleccion:
            informe.comprobar(True, "Fuente de los subtítulos", "ffmpeg encontró la fuente pedida en la carpeta de fuentes")
        else:
            informe.omitir("Fuente de los subtítulos", "ffmpeg no informó qué fuente usó")
        if not cajas:
            informe.comprobar(False, "Subtítulos en zona segura", "no se dibujó ningún subtítulo")
        else:
            borde = borde_del_estilo(subtitulos)
            izquierda = min(c[1] for c in cajas) - borde
            derecha = max(c[2] for c in cajas) + borde
            arriba = min(c[3] for c in cajas) - borde
            abajo = max(c[4] for c in cajas) + borde
            limite_derecho = comun.ANCHO - args.seguro_lado
            limite_abajo = comun.ALTO - args.seguro_abajo
            fuera = [
                c for c in cajas
                if c[1] - borde < args.seguro_lado or c[2] + borde > limite_derecho
                or c[3] - borde < args.seguro_arriba or c[4] + borde > limite_abajo
                or (c[4] + borde > comun.ALTO / 2 and c[2] + borde > comun.ANCHO - args.seguro_botones)
            ]
            detalle = (
                f"ocupan x de {izquierda:.0f} a {derecha:.0f} e y de {arriba:.0f} a {abajo:.0f}; "
                f"zona segura x de {args.seguro_lado} a {limite_derecho}, y de {args.seguro_arriba} a {limite_abajo}"
            )
            if fuera:
                detalle += f"; se salen en {len(fuera)} cuadros, el primero en {fuera[0][0]:.2f} s"
            informe.comprobar(not fuera, "Subtítulos en zona segura", detalle)
            centro_mas_bajo = max((c[3] + c[4]) / 2 for c in cajas)
            informe.comprobar(
                centro_mas_bajo <= comun.ALTO / 3, "Subtítulos en el tercio superior",
                f"el centro más bajo queda en y = {centro_mas_bajo:.0f} (el tercio superior llega hasta {comun.ALTO // 3})",
            )
    else:
        informe.omitir("Subtítulos en zona segura", "pasa --subtitulos para revisarla")

    print(f"INFORME DE CALIDAD: {video.name}")
    informe.imprimir()
    pendientes = informe.por_revisar()
    if pendientes:
        print(f"RESULTADO: REVISAR ({pendientes} línea(s) por revisar)")
        return 1
    print("RESULTADO: APROBADO")
    return 0


if __name__ == "__main__":
    comun.principal(main)
