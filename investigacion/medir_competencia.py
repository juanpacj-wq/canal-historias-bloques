#!/usr/bin/env python3
"""Mide los metadatos publicos de los Shorts recientes de los canales lideres.

Uso:
    python investigacion/medir_competencia.py recoger [--por-canal 40]
    python investigacion/medir_competencia.py analizar

"recoger" lee la pestana de Shorts de cada canal con yt-dlp (sin descargar
video), pide los metadatos completos de los N mas recientes y escribe
investigacion/metadatos-competencia.csv. "analizar" lee ese CSV e imprime las
tablas que se citan en docs/08-descubrimiento-y-metadatos.md.

Requisitos: yt-dlp en el PATH, Node (yt-dlp lo usa con --js-runtimes node) y
Python 3.10 o superior. No usa ninguna clave ni cuenta: solo datos publicos.
Las respuestas por video se guardan en una carpeta temporal para poder
reanudar sin repetir peticiones.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import statistics
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path

AQUI = Path(__file__).resolve().parent
CSV_SALIDA = AQUI / "metadatos-competencia.csv"
CACHE = Path(tempfile.gettempdir()) / "medir_competencia_cache"

# (nombre, id del canal, idioma del canal, grupo)
CANALES = [
    ("studby", "UCHQ6IK7bgQM_BkAYqOy7nXA", "en", "lider"),
    ("GreenBroRants", "UCMA3DbSKleVofUC_5KetUMg", "en", "lider"),
    ("VoidCast", "UCyyGQfCJdADdby5IVe0-EGw", "en", "lider"),
    ("Gelo Stories", "UCUayw3SkGYlGK_XosKVbtZg", "en", "lider"),
    ("R6Rants", "UCdhQwHEYe8kKJn4Zv5dyPiA", "en", "mediano"),
    ("FriendBob", "UCbzGSJcaYRHAFlRQDTZU9OA", "en", "tardio"),
    ("SoyGelo", "UChEkE9e8zXMgmNNoTUTiHJg", "es", "lider"),
    ("Custerk Blox", "UCcN2eyGprJfFdIhsY7Jng4Q", "es", "lider"),
    ("Xenost", "UC6VBobwMlMuAQPcc04ImdLQ", "en", "vecino"),
]

COLUMNAS = [
    "canal", "canal_id", "idioma_canal", "grupo", "posicion", "video_id",
    "url", "titulo", "duracion_s", "vistas", "me_gusta", "publicado_utc",
    "dia_semana_utc", "hora_utc", "descripcion", "hashtags_descripcion",
    "hashtags_titulo", "n_hashtags", "etiquetas", "n_etiquetas", "categoria",
    "idioma_declarado", "idiomas_audio", "n_doblajes_auto",
    "subtitulos_manuales", "comentario_fijado", "comentario_fijado_del_canal",
    "comentario_fijado_texto", "suscriptores", "capturado_utc",
]

DIAS = ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado",
        "domingo"]
RE_HASHTAG = re.compile(r"#[\wÀ-ɏ]+", re.UNICODE)
PAUSA = 1.5  # segundos entre peticiones de cada hilo
HILOS = 3


def correr(args: list[str], intentos: int = 4) -> str:
    """Ejecuta yt-dlp con reintentos y espera creciente (por si hay 429)."""
    espera = 20
    for intento in range(1, intentos + 1):
        res = subprocess.run(
            ["yt-dlp", "--no-warnings", *args],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
        )
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout
        err = (res.stderr or "").strip().splitlines()[-1:] or ["sin salida"]
        print(f"  intento {intento} fallo: {err[0][:160]}", file=sys.stderr)
        if intento < intentos:
            time.sleep(espera)
            espera *= 2
    return ""


def listar_shorts(canal_id: str, n: int) -> list[str]:
    salida = correr([
        "--flat-playlist", "--playlist-end", str(n), "--print", "id",
        f"https://www.youtube.com/channel/{canal_id}/shorts",
    ])
    return [x.strip() for x in salida.splitlines() if x.strip()]


def metadatos(video_id: str) -> dict | None:
    """Metadatos completos de un video, con cache en disco."""
    CACHE.mkdir(parents=True, exist_ok=True)
    archivo = CACHE / f"{video_id}.json"
    if archivo.exists():
        return json.loads(archivo.read_text(encoding="utf-8"))
    salida = correr([
        "--js-runtimes", "node", "--skip-download", "--dump-json",
        "--write-comments",
        "--extractor-args",
        "youtube:max_comments=1,1,0,0;comment_sort=top",
        f"https://www.youtube.com/shorts/{video_id}",
    ])
    time.sleep(PAUSA)
    if not salida:
        return None
    d = json.loads(salida)
    audio = {}
    for f in d.get("formats") or []:
        if f.get("vcodec") == "none" and f.get("acodec") != "none":
            idioma = f.get("language")
            if idioma:
                nota = (f.get("format_note") or "").lower()
                audio.setdefault(idioma, "otro")
                if "dubbed-auto" in nota:
                    audio[idioma] = "doblaje_auto"
                elif "original" in nota and audio[idioma] == "otro":
                    audio[idioma] = "original"
    com = (d.get("comments") or [None])[0]
    slim = {
        "id": d.get("id"),
        "title": d.get("title"),
        "duration": d.get("duration"),
        "view_count": d.get("view_count"),
        "like_count": d.get("like_count"),
        "timestamp": d.get("timestamp"),
        "description": d.get("description") or "",
        "tags": d.get("tags") or [],
        "categories": d.get("categories") or [],
        "language": d.get("language"),
        "audio": audio,
        "subtitles": sorted((d.get("subtitles") or {}).keys()),
        "comments_fetched": d.get("comments") is not None,
        "first_comment": None if not com else {
            "is_pinned": bool(com.get("is_pinned")),
            "author_is_uploader": bool(com.get("author_is_uploader")),
            "text": com.get("text") or "",
        },
        "channel_follower_count": d.get("channel_follower_count"),
        "captured": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    archivo.write_text(json.dumps(slim, ensure_ascii=False), encoding="utf-8")
    return slim


def fila(canal, pos: int, d: dict) -> dict:
    nombre, canal_id, idioma, grupo = canal
    ts = d.get("timestamp")
    pub = datetime.fromtimestamp(ts, timezone.utc) if ts else None
    desc = d["description"]
    h_desc = RE_HASHTAG.findall(desc)
    h_tit = RE_HASHTAG.findall(d.get("title") or "")
    com = d.get("first_comment")
    if not d.get("comments_fetched") or com is None:
        fijado = "sin_comentarios"
    else:
        fijado = "si" if com["is_pinned"] else "no"
    es_fijado = fijado == "si"
    return {
        "canal": nombre, "canal_id": canal_id, "idioma_canal": idioma,
        "grupo": grupo, "posicion": pos, "video_id": d["id"],
        "url": f"https://www.youtube.com/shorts/{d['id']}",
        "titulo": d.get("title") or "",
        "duracion_s": d.get("duration"),
        "vistas": d.get("view_count"),
        "me_gusta": d.get("like_count"),
        "publicado_utc": pub.strftime("%Y-%m-%dT%H:%M:%SZ") if pub else "",
        "dia_semana_utc": DIAS[pub.weekday()] if pub else "",
        "hora_utc": pub.hour if pub else "",
        "descripcion": desc,
        "hashtags_descripcion": " ".join(h_desc),
        "hashtags_titulo": " ".join(h_tit),
        "n_hashtags": len(h_desc) + len(h_tit),
        "etiquetas": "|".join(d["tags"]),
        "n_etiquetas": len(d["tags"]),
        "categoria": "|".join(d["categories"]),
        "idioma_declarado": d.get("language") or "",
        "idiomas_audio": "|".join(sorted(d["audio"])),
        "n_doblajes_auto": sum(1 for v in d["audio"].values()
                               if v == "doblaje_auto"),
        "subtitulos_manuales": "|".join(d["subtitles"]),
        "comentario_fijado": fijado,
        "comentario_fijado_del_canal":
            ("si" if com["author_is_uploader"] else "no") if es_fijado else "",
        "comentario_fijado_texto": com["text"] if es_fijado else "",
        "suscriptores": d.get("channel_follower_count"),
        "capturado_utc": d.get("captured"),
    }


def recoger(por_canal: int) -> None:
    filas = []
    for canal in CANALES:
        ids = listar_shorts(canal[1], por_canal)
        print(f"{canal[0]}: {len(ids)} shorts en la lista", flush=True)
        time.sleep(PAUSA)
        with ThreadPoolExecutor(max_workers=HILOS) as pool:
            datos = list(pool.map(metadatos, ids))
        ok = 0
        for pos, d in enumerate(datos, start=1):
            if d:
                filas.append(fila(canal, pos, d))
                ok += 1
        print(f"  {ok} con metadatos completos", flush=True)
        escribir(filas)
    print(f"Listo: {len(filas)} filas en {CSV_SALIDA}")


def escribir(filas: list[dict]) -> None:
    with CSV_SALIDA.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.DictWriter(f, fieldnames=COLUMNAS, quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        w.writerows(filas)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="orden", required=True)
    r = sub.add_parser("recoger")
    r.add_argument("--por-canal", type=int, default=40)
    sub.add_parser("analizar")
    a = p.parse_args()
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if a.orden == "recoger":
        recoger(a.por_canal)
    else:
        analizar()


# --------------------------------------------------------------------------
# Analisis
# --------------------------------------------------------------------------

EDAD_MINIMA_H = 48  # los videos mas nuevos no entran en comparaciones de vistas
N_MINIMO = 8        # por debajo de esto un grupo se marca como muestra chica
RE_EMOJI = re.compile(
    "[\U0001F000-\U0001FAFF☀-➿⬀-⯿️‍]")
RE_PALABRA = re.compile(r"[A-Za-zÀ-ɏ0-9']+")


def med(xs):
    xs = [x for x in xs if x is not None]
    return statistics.median(xs) if xs else None


def fmt(x, dec=2):
    if x is None:
        return "s/d"
    if isinstance(x, float) and dec == 0:
        return f"{x:,.0f}".replace(",", ".")
    if isinstance(x, float):
        return f"{x:.{dec}f}".replace(".", ",")
    return f"{x:,}".replace(",", ".")


def tabla(titulo, cabecera, filas):
    print(f"\n### {titulo}\n")
    print("| " + " | ".join(cabecera) + " |")
    print("|" + "---|" * len(cabecera))
    for f in filas:
        print("| " + " | ".join(str(c) for c in f) + " |")


def marca(n):
    return f"{n}" if n >= N_MINIMO else f"{n} (muestra chica)"


def spearman(xs, ys):
    def rangos(v):
        orden = sorted(range(len(v)), key=lambda i: v[i])
        r = [0.0] * len(v)
        i = 0
        while i < len(orden):
            j = i
            while j + 1 < len(orden) and v[orden[j + 1]] == v[orden[i]]:
                j += 1
            for k in range(i, j + 1):
                r[orden[k]] = (i + j) / 2 + 1
            i = j + 1
        return r
    if len(xs) < 5:
        return None
    rx, ry = rangos(xs), rangos(ys)
    mx, my = statistics.mean(rx), statistics.mean(ry)
    num = sum((a - mx) * (b - my) for a, b in zip(rx, ry))
    den = (sum((a - mx) ** 2 for a in rx) * sum((b - my) ** 2 for b in ry))
    return num / den ** 0.5 if den else None


def limpiar_titulo(t):
    """Titulo sin hashtags ni emojis, para contar palabras."""
    t = RE_HASHTAG.sub("", t)
    t = RE_EMOJI.sub("", t)
    return " ".join(t.split())


def cargar():
    with CSV_SALIDA.open(encoding="utf-8-sig", newline="") as f:
        filas = list(csv.DictReader(f))
    for r in filas:
        for k in ("duracion_s", "vistas", "me_gusta", "n_hashtags",
                  "n_etiquetas", "n_doblajes_auto", "posicion"):
            r[k] = int(r[k]) if r[k] not in ("", None) else None
        r["pub"] = datetime.strptime(
            r["publicado_utc"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=timezone.utc)
        cap = datetime.fromisoformat(r["capturado_utc"])
        r["edad_h"] = (cap - r["pub"]).total_seconds() / 3600
        r["maduro"] = r["edad_h"] >= EDAD_MINIMA_H
        limpio = limpiar_titulo(r["titulo"])
        r["titulo_limpio"] = limpio
        palabras = RE_PALABRA.findall(limpio)
        r["palabras"] = palabras
        r["n_palabras"] = len(palabras)
        r["n_car"] = len(r["titulo"])
        mayus = [p for p in palabras
                 if len(p) >= 2 and p.isupper() and any(c.isalpha() for c in p)]
        r["n_mayus"] = len(mayus)
        letras = [c for c in limpio if c.isalpha()]
        r["todo_mayus"] = bool(letras) and all(c.isupper() for c in letras)
        r["emoji"] = bool(RE_EMOJI.search(r["titulo"]))
        r["pub_col"] = r["pub"] - timedelta(hours=5)
    # indice relativo: vistas / mediana del propio canal (solo maduros)
    por_canal = defaultdict(list)
    for r in filas:
        por_canal[r["canal"]].append(r)
    for canal, rs in por_canal.items():
        m = med([r["vistas"] for r in rs if r["maduro"]])
        for r in rs:
            r["indice"] = (r["vistas"] / m) if (m and r["maduro"]) else None
    return filas, por_canal


def grupo_indice(filas, clave, orden=None):
    """Mediana del indice relativo por grupo. Devuelve filas de tabla."""
    g = defaultdict(list)
    for r in filas:
        if r["indice"] is not None:
            k = clave(r)
            if k is not None:
                g[k].append(r["indice"])
    llaves = orden if orden else sorted(g)
    out = []
    for k in llaves:
        v = g.get(k, [])
        if not v:
            continue
        sobre = sum(1 for x in v if x >= 2) / len(v) * 100
        out.append((k, marca(len(v)), fmt(med(v)), f"{sobre:.0f} %"))
    return out


CAB_IND = ["Grupo", "n", "Mediana del índice", "Con índice de 2 o más"]


def tramo_palabras(r):
    n = r["n_palabras"]
    if n <= 2:
        return "1 a 2 palabras"
    if n <= 4:
        return "3 a 4 palabras"
    if n <= 7:
        return "5 a 7 palabras"
    if n <= 10:
        return "8 a 10 palabras"
    return "11 o más palabras"


ORD_PAL = ["1 a 2 palabras", "3 a 4 palabras", "5 a 7 palabras",
           "8 a 10 palabras", "11 o más palabras"]


def tramo_dur(r):
    d = r["duracion_s"]
    if d is None:
        return None
    for tope, nombre in ((60, "hasta 59 s"), (90, "60 a 89 s"),
                         (120, "90 a 119 s"), (150, "120 a 149 s")):
        if d < tope:
            return nombre
    return "150 a 185 s"


ORD_DUR = ["hasta 59 s", "60 a 89 s", "90 a 119 s", "120 a 149 s",
           "150 a 185 s"]


def franja(h):
    ini = h // 3 * 3
    return f"{ini:02d} a {ini + 2:02d} h"


def analizar() -> None:
    filas, por_canal = cargar()
    nombres = [c[0] for c in CANALES if c[0] in por_canal]
    en = [r for r in filas if r["idioma_canal"] == "en"]
    es = [r for r in filas if r["idioma_canal"] == "es"]
    formato_en = [r for r in en if r["grupo"] != "vecino"]
    maduros = [r for r in filas if r["maduro"]]
    print(f"Filas: {len(filas)}; maduras (>= {EDAD_MINIMA_H} h): "
          f"{len(maduros)}; en inglés: {len(en)}; en español: {len(es)}")
    print("Índice = vistas del video / mediana de vistas de los videos "
          "maduros del mismo canal.")

    # 1. Resumen por canal
    t = []
    for c in nombres:
        rs = por_canal[c]
        mad = [r for r in rs if r["maduro"]]
        fechas = sorted(r["pub"] for r in rs)
        dias = max((fechas[-1] - fechas[0]).total_seconds() / 86400, 0.01)
        t.append((c, len(rs), len(mad),
                  fechas[0].strftime("%m-%d") + " a "
                  + fechas[-1].strftime("%m-%d"),
                  fmt(float(med([r["vistas"] for r in mad]) or 0), 0),
                  fmt(float(med([r["duracion_s"] for r in rs])), 0),
                  fmt((len(rs) - 1) / dias, 1)))
    tabla("Resumen por canal",
          ["Canal", "n", "n maduros", "Rango de fechas (UTC)",
           "Mediana de vistas (maduros)", "Mediana de duración (s)",
           "Videos por día"], t)

    # 2. Forma del titulo por canal
    t = []
    for c in nombres:
        rs = por_canal[c]
        n = len(rs)
        t.append((c, n,
                  fmt(float(med([r["n_palabras"] for r in rs])), 0),
                  fmt(float(med([r["n_car"] for r in rs])), 0),
                  f"{sum(1 for r in rs if r['n_mayus']) / n * 100:.0f} %",
                  f"{sum(1 for r in rs if r['todo_mayus']) / n * 100:.0f} %",
                  f"{sum(1 for r in rs if r['emoji']) / n * 100:.0f} %",
                  f"{sum(1 for r in rs if r['hashtags_titulo']) / n * 100:.0f} %"))
    tabla("Forma del título por canal",
          ["Canal", "n", "Mediana de palabras", "Mediana de caracteres",
           "Con palabra en MAYÚSCULAS", "Todo en mayúsculas", "Con emoji",
           "Con hashtag en el título"], t)

    # 3. Longitud del titulo frente al indice
    tabla("Palabras del título frente al índice (canales en inglés del "
          "formato)", CAB_IND, grupo_indice(formato_en, tramo_palabras, ORD_PAL))
    tabla("Palabras del título frente al índice (canales en español)",
          CAB_IND, grupo_indice(es, tramo_palabras, ORD_PAL))
    t = []
    for c in nombres:
        mad = [r for r in por_canal[c] if r["maduro"]]
        if len(mad) < 8:
            continue
        orden = sorted(mad, key=lambda r: -r["vistas"])
        k = max(len(orden) // 4, 1)
        top, resto = orden[:k], orden[k:]
        rho = spearman([r["n_palabras"] for r in mad],
                       [r["vistas"] for r in mad])
        t.append((c, len(mad), k,
                  fmt(float(med([r["n_palabras"] for r in top])), 1),
                  fmt(float(med([r["n_palabras"] for r in resto])), 1),
                  fmt(float(med([r["n_car"] for r in top])), 0),
                  fmt(float(med([r["n_car"] for r in resto])), 0),
                  fmt(rho)))
    tabla("Cuartil superior de vistas frente al resto, por canal",
          ["Canal", "n maduros", "n cuartil superior",
           "Palabras (cuartil superior)", "Palabras (resto)",
           "Caracteres (cuartil superior)", "Caracteres (resto)",
           "Spearman palabras y vistas"], t)

    # 4. Mayusculas y emoji
    def caps(r):
        if r["todo_mayus"]:
            return "todo en mayúsculas"
        return "con palabra en MAYÚSCULAS" if r["n_mayus"] else "sin mayúsculas"
    tabla("Mayúsculas frente al índice (inglés, formato)", CAB_IND,
          grupo_indice(formato_en, caps))
    tabla("Mayúsculas frente al índice (español)", CAB_IND,
          grupo_indice(es, caps))
    tabla("Emoji en el título frente al índice (todos)", CAB_IND,
          grupo_indice(filas, lambda r: "con emoji" if r["emoji"]
                       else "sin emoji"))

    # 5. Palabras iniciales
    for nombre, sub in (("inglés, formato", formato_en), ("español", es),
                        ("Xenost, vecino", por_canal.get("Xenost", []))):
        c1 = Counter()
        ind = defaultdict(list)
        for r in sub:
            if not r["palabras"]:
                continue
            for k in (1, 2):
                ini = " ".join(p.lower() for p in r["palabras"][:k])
                c1[(k, ini)] += 1
                if r["indice"] is not None:
                    ind[(k, ini)].append(r["indice"])
        t = [(f"{ini}", k, n, marca(len(ind[(k, ini)])),
              fmt(med(ind[(k, ini)])))
             for (k, ini), n in c1.most_common(40) if n >= 4]
        tabla(f"Arranques de título más frecuentes ({nombre}, "
              f"n total {len(sub)})",
              ["Arranque", "Palabras", "Veces", "n maduros",
               "Mediana del índice"], t[:16])

    # 6. Hashtags
    t = []
    for c in nombres:
        rs = por_canal[c]
        cnt = Counter()
        for r in rs:
            cnt.update(h.lower() for h in
                       (r["hashtags_descripcion"] + " "
                        + r["hashtags_titulo"]).split())
        t.append((c, len(rs),
                  fmt(float(med([r["n_hashtags"] for r in rs])), 0),
                  f"{min(r['n_hashtags'] for r in rs)} a "
                  f"{max(r['n_hashtags'] for r in rs)}",
                  f"{sum(1 for r in rs if '#shorts' in (r['hashtags_descripcion'] + ' ' + r['hashtags_titulo']).lower().split()) / len(rs) * 100:.0f} %",
                  ", ".join(f"{h} ({n})" for h, n in cnt.most_common(6))))
    tabla("Hashtags por canal",
          ["Canal", "n", "Mediana de hashtags", "Rango", "Usa #shorts",
           "Más usados (veces)"], t)
    tabla("Número de hashtags frente al índice (todos)", CAB_IND,
          grupo_indice(filas, lambda r: "0" if r["n_hashtags"] == 0 else
                       "1 a 3" if r["n_hashtags"] <= 3 else
                       "4 a 5" if r["n_hashtags"] <= 5 else "6 o más",
                       ["0", "1 a 3", "4 a 5", "6 o más"]))

    # 7. Descripcion, etiquetas, categoria, idioma, doblaje, fijado
    t = []
    for c in nombres:
        rs = por_canal[c]
        n = len(rs)
        sin_h = [len(RE_HASHTAG.sub("", r["descripcion"]).strip()) for r in rs]
        fij = Counter(r["comentario_fijado"] for r in rs)
        t.append((c, n,
                  fmt(float(med([len(r["descripcion"]) for r in rs])), 0),
                  f"{sum(1 for x in sin_h if x > 0) / n * 100:.0f} %",
                  fmt(float(med([r["n_etiquetas"] for r in rs])), 0),
                  ", ".join(f"{k} ({v})" for k, v in
                            Counter(r["categoria"] for r in rs).most_common(2)),
                  ", ".join(f"{k or 'vacío'} ({v})" for k, v in
                            Counter(r["idioma_declarado"]
                                    for r in rs).most_common(2)),
                  f"{sum(1 for r in rs if r['n_doblajes_auto']) / n * 100:.0f} %",
                  fmt(float(med([r["n_doblajes_auto"] for r in rs])), 0),
                  f"{fij['si']} sí, {fij['no']} no, "
                  f"{fij['sin_comentarios']} sin comentarios"))
    tabla("Descripción, etiquetas, categoría, idioma, doblaje y comentario "
          "fijado por canal",
          ["Canal", "n", "Mediana de caracteres de la descripción",
           "Con texto además de hashtags", "Mediana de etiquetas ocultas",
           "Categoría (veces)", "Idioma declarado (veces)",
           "Con doblaje automático", "Mediana de idiomas doblados",
           "Comentario fijado"], t)
    tabla("Doblaje automático frente al índice (todos)", CAB_IND,
          grupo_indice(filas, lambda r: "con doblaje automático"
                       if r["n_doblajes_auto"] else "sin doblaje"))
    tabla("Comentario fijado frente al índice (todos)", CAB_IND,
          grupo_indice(filas, lambda r: {"si": "con comentario fijado",
                                         "no": "sin comentario fijado"}
                       .get(r["comentario_fijado"])))
    idi = Counter()
    for r in filas:
        idi.update(x for x in r["idiomas_audio"].split("|") if x)
    print("\nIdiomas de audio más frecuentes:",
          ", ".join(f"{k} ({v})" for k, v in idi.most_common(14)))
    fijados = [r for r in filas if r["comentario_fijado"] == "si"]
    print(f"\nEjemplos de comentarios fijados ({len(fijados)} en total):")
    vistos = Counter()
    for r in fijados:
        if vistos[r["canal"]] < 4:
            vistos[r["canal"]] += 1
            txt = " ".join(r["comentario_fijado_texto"].split())[:150]
            print(f"- {r['canal']} (del canal: "
                  f"{r['comentario_fijado_del_canal']}): {txt}")

    # 8. Duracion
    tabla("Duración frente al índice (inglés, formato)", CAB_IND,
          grupo_indice(formato_en, tramo_dur, ORD_DUR))
    tabla("Duración frente al índice (español)", CAB_IND,
          grupo_indice(es, tramo_dur, ORD_DUR))
    t = []
    for c in nombres:
        rs = por_canal[c]
        mad = [r for r in rs if r["maduro"]]
        d = sorted(r["duracion_s"] for r in rs)
        t.append((c, len(rs), d[0], fmt(float(med(d)), 0), d[-1],
                  f"{sum(1 for x in d if x > 60) / len(d) * 100:.0f} %",
                  len(mad),
                  fmt(spearman([r["duracion_s"] for r in mad],
                               [r["vistas"] for r in mad]))))
    tabla("Duración por canal",
          ["Canal", "n", "Mínima (s)", "Mediana (s)", "Máxima (s)",
           "De más de 60 s", "n maduros", "Spearman duración y vistas"], t)

    # 9. Dia y hora
    for nombre, sub in (("inglés, formato", formato_en), ("español", es)):
        cnt = Counter(r["pub"].weekday() for r in sub)
        ind = defaultdict(list)
        for r in sub:
            if r["indice"] is not None:
                ind[r["pub"].weekday()].append(r["indice"])
        tabla(f"Día de publicación en UTC ({nombre})",
              ["Día", "Publicados", "n maduros", "Mediana del índice"],
              [(DIAS[d], cnt[d], marca(len(ind[d])), fmt(med(ind[d])))
               for d in range(7) if cnt[d]])
        cnt = Counter(franja(r["pub"].hour) for r in sub)
        ind = defaultdict(list)
        for r in sub:
            if r["indice"] is not None:
                ind[franja(r["pub"].hour)].append(r["indice"])
        t = []
        for h in range(0, 24, 3):
            k = franja(h)
            if cnt[k]:
                col = (h - 5) % 24
                t.append((k, f"{col:02d} a {(col + 2) % 24:02d} h", cnt[k],
                          f"{cnt[k] / len(sub) * 100:.0f} %",
                          marca(len(ind[k])), fmt(med(ind[k]))))
        tabla(f"Franja horaria de publicación ({nombre})",
              ["Franja UTC", "Hora de Colombia", "Publicados",
               "Parte del total", "n maduros", "Mediana del índice"], t)
    t = []
    for c in nombres:
        rs = por_canal[c]
        horas = Counter(r["pub"].hour for r in rs)
        top = horas.most_common(4)
        minutos = Counter(r["pub"].minute for r in rs)
        en_punto = sum(v for m, v in minutos.items() if m % 15 == 0)
        t.append((c, len(rs),
                  ", ".join(f"{h:02d} h ({n})" for h, n in top),
                  len(horas),
                  f"{en_punto / len(rs) * 100:.0f} %"))
    tabla("Horas UTC preferidas por canal",
          ["Canal", "n", "Horas más usadas (veces)", "Horas distintas usadas",
           "Publicados en minuto 00, 15, 30 o 45"], t)

    # 10. Cadencia
    t = []
    for c in nombres:
        rs = sorted(por_canal[c], key=lambda r: r["pub"])
        huecos = [(b["pub"] - a["pub"]).total_seconds() / 3600
                  for a, b in zip(rs, rs[1:])]
        por_dia = Counter(r["pub"].date() for r in rs)
        # dias completos: se descartan el primero y el ultimo del rango
        dias = sorted(por_dia)
        completos = [por_dia[d] for d in dias[1:-1]] or list(por_dia.values())
        t.append((c, len(rs), fmt(float(med(huecos)), 1),
                  fmt(float(min(huecos)), 1), fmt(float(max(huecos)), 1),
                  fmt(float(med(completos)), 1), max(por_dia.values()),
                  len(dias)))
    tabla("Cadencia por canal",
          ["Canal", "n", "Mediana de horas entre videos", "Mínimo (h)",
           "Máximo (h)", "Mediana de videos por día completo",
           "Máximo en un día", "Días con publicación"], t)

    # 11. Los mejores y peores titulos
    for nombre, sub in (("inglés, formato", formato_en), ("español", es)):
        mad = sorted([r for r in sub if r["indice"] is not None],
                     key=lambda r: -r["indice"])
        tabla(f"Los 12 títulos con mayor índice ({nombre})",
              ["Índice", "Canal", "Vistas", "Duración (s)", "Título"],
              [(fmt(r["indice"]), r["canal"], fmt(r["vistas"]),
                r["duracion_s"], r["titulo"]) for r in mad[:12]])
        tabla(f"Los 8 títulos con menor índice ({nombre})",
              ["Índice", "Canal", "Vistas", "Duración (s)", "Título"],
              [(fmt(r["indice"]), r["canal"], fmt(r["vistas"]),
                r["duracion_s"], r["titulo"]) for r in mad[-8:]])

    # 11b. Arranque "In this ..." frente al resto, dentro de cada canal
    t = []
    for c in nombres:
        mad = [r for r in por_canal[c] if r["indice"] is not None]
        a = [r["indice"] for r in mad
             if r["titulo_limpio"].lower().startswith("in this")]
        b = [r["indice"] for r in mad
             if not r["titulo_limpio"].lower().startswith("in this")]
        if a:
            t.append((c, marca(len(a)), fmt(med(a)), marca(len(b)),
                      fmt(med(b))))
    tabla('Títulos que empiezan por "In this" frente al resto, por canal',
          ["Canal", "n con In this", "Mediana del índice (In this)",
           "n resto", "Mediana del índice (resto)"], t)

    # 11c. Edad frente a vistas (para saber cuanto pesa la antiguedad)
    t = []
    for c in nombres:
        mad = [r for r in por_canal[c] if r["maduro"]]
        edades = [r["edad_h"] / 24 for r in mad]
        t.append((c, len(mad), fmt(min(edades), 1), fmt(max(edades), 1),
                  fmt(spearman(edades, [r["vistas"] for r in mad]))))
    tabla("Antigüedad frente a vistas (videos maduros)",
          ["Canal", "n", "Edad mínima (días)", "Edad máxima (días)",
           "Spearman edad y vistas"], t)

    # 11d. Tres mejores y tres peores por canal
    t = []
    for c in nombres:
        mad = sorted([r for r in por_canal[c] if r["indice"] is not None],
                     key=lambda r: -r["indice"])
        for etiqueta, grupo in (("mejor", mad[:3]), ("peor", mad[-3:])):
            for r in grupo:
                t.append((c, etiqueta, fmt(r["indice"]), fmt(r["vistas"]),
                          r["duracion_s"], r["titulo"]))
    tabla("Tres mejores y tres peores títulos por canal (videos maduros)",
          ["Canal", "Grupo", "Índice", "Vistas", "Duración (s)", "Título"], t)

    # 11e. Ejemplos de descripcion
    print()
    print("Ejemplos de descripción (los dos más recientes por canal):")
    for c in nombres:
        for r in sorted(por_canal[c], key=lambda r: r["posicion"])[:2]:
            txt = " / ".join(x for x in r["descripcion"].splitlines() if x)
            print(f"- {c}: {txt[:230] or '(vacía)'}")

    # 12. Me gusta
    t = []
    for c in nombres:
        mad = [r for r in por_canal[c] if r["maduro"] and r["me_gusta"]
               and r["vistas"]]
        if not mad:
            continue
        tasas = [r["me_gusta"] / r["vistas"] * 100 for r in mad]
        t.append((c, len(mad), fmt(med(tasas)),
                  fmt(spearman(tasas, [r["vistas"] for r in mad]))))
    tabla("Me gusta por cada 100 vistas (videos maduros)",
          ["Canal", "n", "Mediana (%)", "Spearman tasa y vistas"], t)


if __name__ == "__main__":
    main()
