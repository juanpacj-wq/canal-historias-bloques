"""Efectos de sonido propios, sintetizados con numpy (tonos, barridos y ruido). No se
descarga nada: no hay licencias de terceros ni riesgo de reclamo.

Cada video tiene `videos/NNN-slug/montaje/hacer_efectos.py`, que declara en que plano suena
cada efecto y llama a escribir(). Ejemplo completo: el del video 001.

    from efectos import escribir, en
    escribir("001", [
        ("pop", (1, 0.02), -8),        # efecto, (plano, fraccion del plano), volumen en dB
        ("alarma", (24, 0.0), -10),
    ], lluvia=(49, 57, -15))           # opcional: ruido de lluvia del plano 49 al 57

Catalogo: pop, sube, baja, campana, bip, bip_doble, alarma, apagado, triste,
blip_sube_baja, corneta, golpe, revelacion, patada, explosion, chispazo, logro.
Criterio de uso (video 001): un efecto por idea, no por plano; "pop" suave en cambios de
escena, sonidos de bateria cuando la carga cambia, uno fuerte en el climax. Entre -8 y -14
dB; el climax a -4. La mezcla final la nivela montar.py.
"""
import json
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as _b  # noqa: E402

SR = 48000
_rng = np.random.default_rng(7)


def _t(dur):
    return np.arange(int(SR * dur)) / SR


def _env(n, ataque=0.005, caida=0.08):
    e = np.ones(n)
    a, c = int(SR * ataque), int(SR * caida)
    e[:a] = np.linspace(0, 1, a)
    e[-c:] = np.linspace(1, 0, c)
    return e


def tono(f, dur, forma="seno", caida=0.08, vib=0.0):
    t = _t(dur)
    fase = 2 * np.pi * f * t + vib * np.sin(2 * np.pi * 6 * t)
    if forma == "cuadrada":
        x = np.sign(np.sin(fase)) * 0.5 + 0.3 * np.sin(fase)
    elif forma == "campana":
        x = (np.sin(fase) + 0.5 * np.sin(2.01 * fase) + 0.25 * np.sin(3.02 * fase)) * np.exp(-t * 6)
    else:
        x = np.sin(fase)
    return x * _env(len(x), caida=min(caida, dur / 2))


def barrido(f0, f1, dur, forma="seno"):
    t = _t(dur)
    fase = 2 * np.pi * np.cumsum(f0 * (f1 / f0) ** (t / dur)) / SR
    x = np.sin(fase) if forma == "seno" else np.sign(np.sin(fase)) * 0.4 + 0.4 * np.sin(fase)
    return x * _env(len(x), caida=dur * 0.3)


def ruido(dur, corte_bajo=0, suav=1):
    x = _rng.standard_normal(int(SR * dur))
    if suav > 1:
        x = np.convolve(x, np.ones(suav) / suav, mode="same")
    if corte_bajo:
        x = x - np.convolve(x, np.ones(corte_bajo) / corte_bajo, mode="same")
    return x / (np.max(np.abs(x)) + 1e-9)


def silencio(dur):
    return np.zeros(int(SR * dur))


def unir(*partes):
    return np.concatenate(partes)


def mezclar(*capas):
    out = np.zeros(max(len(c) for c in capas))
    for c in capas:
        out[:len(c)] += c
    return out


def guardar(ruta, x, pico=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * pico
    with wave.open(ruta, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((np.stack([x, x], axis=1) * 32767).astype("<i2").tobytes())


def catalogo():
    return {
        "pop": barrido(300, 900, 0.09),
        "sube": unir(tono(660, 0.09), tono(880, 0.09), tono(1320, 0.22, "campana", 0.2)),
        "baja": barrido(700, 180, 0.45),
        "campana": tono(1568, 0.7, "campana", 0.4),
        "bip": tono(1900, 0.11, "cuadrada", 0.02),
        "bip_doble": unir(tono(1900, 0.1, "cuadrada", 0.02), silencio(0.07), tono(1900, 0.1, "cuadrada", 0.02)),
        "alarma": unir(*[unir(tono(2200, 0.09, "cuadrada", 0.02), silencio(0.06)) for _ in range(3)]),
        "apagado": barrido(520, 60, 0.9),
        "triste": unir(tono(392, 0.22, vib=0.3), tono(330, 0.22, vib=0.3), tono(262, 0.5, vib=0.5, caida=0.3)),
        "blip_sube_baja": unir(tono(700, 0.1), tono(990, 0.14), silencio(0.25), tono(700, 0.1), tono(495, 0.2)),
        "corneta": mezclar(barrido(380, 520, 0.5, "cuadrada"), 0.3 * ruido(0.5, suav=4) * _env(int(SR * 0.5))),
        "golpe": mezclar(barrido(160, 50, 0.22), 0.5 * ruido(0.05, suav=6)),
        "revelacion": mezclar(*[np.concatenate([silencio(0.05 * i), tono(f, 0.9, "campana", 0.5)]) for i, f in enumerate([784, 988, 1175, 1568])]),
        "patada": mezclar(barrido(220, 60, 0.16), np.concatenate([silencio(0.05), 0.5 * ruido(0.5, corte_bajo=40, suav=3) * np.linspace(1, 0, int(SR * 0.5)) ** 2])),
        "explosion": mezclar(
            barrido(140, 35, 1.1) * 1.2, 0.8 * ruido(1.3, suav=12) * np.exp(-_t(1.3) * 3.5),
            np.concatenate([silencio(0.1), 0.5 * barrido(600, 3200, 0.9) * np.linspace(1, 0, int(SR * 0.9))]),
            np.concatenate([silencio(0.25), 0.5 * tono(1568, 1.2, "campana", 0.6)])),
        "chispazo": mezclar(*[np.concatenate([silencio(d), ruido(0.07, corte_bajo=12) * _env(int(SR * 0.07), 0.002, 0.03)]) for d in (0, 0.11, 0.2, 0.36, 0.52, 0.6)],
                            0.4 * barrido(900, 90, 0.7, "cuadrada")),
        "logro": unir(tono(784, 0.1), tono(988, 0.1), tono(1175, 0.1), tono(1568, 0.6, "campana", 0.4)),
    }


def escribir(numero, eventos, lluvia=None):
    """Escribe montaje/efectos/*.wav (solo los usados) y montaje/efectos.json."""
    video = _b.Video(numero)
    planos = {p["n"]: p for p in json.loads(_b.leer(video.plan))["planos"]}
    carpeta = os.path.join(video.dir, "montaje", "efectos")
    os.makedirs(carpeta, exist_ok=True)
    cat = catalogo()

    def instante(n, frac):
        p = planos[n]
        return round(p["inicio"] + (p["fin"] - p["inicio"]) * frac, 3)

    lista = []
    for nombre, (n, frac), db in eventos:
        if nombre not in cat:
            raise SystemExit("efecto inexistente: " + nombre)
        guardar(os.path.join(carpeta, nombre + ".wav"), cat[nombre])
        lista.append({"archivo": "efectos/%s.wav" % nombre, "tiempo": instante(n, frac), "volumen_db": db})
    if lluvia:
        n0, n1, db = lluvia
        ini, fin = planos[n0]["inicio"], planos[n1]["fin"]
        d = fin - ini + 0.6
        ll = ruido(d, corte_bajo=30, suav=2) * 0.6 + ruido(d, suav=24) * 0.5
        borde = int(SR * 0.5)
        e = np.ones(len(ll))
        e[:borde] = np.linspace(0, 1, borde)
        e[-borde:] = np.linspace(1, 0, borde)
        guardar(os.path.join(carpeta, "lluvia.wav"), ll * e, pico=0.5)
        lista.append({"archivo": "efectos/lluvia.wav", "tiempo": round(ini - 0.2, 3), "volumen_db": db})
    with open(os.path.join(video.dir, "montaje", "efectos.json"), "w", encoding="utf-8") as f:
        json.dump(lista, f, indent=1)
    print("efectos.json: %d eventos" % len(lista))
