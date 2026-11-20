"""Efectos de sonido del video 001: en que plano suena cada uno. Los sonidos son propios
(herramientas/studio/efectos.py). Uso: python hacer_efectos.py"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "herramientas", "studio"))
from efectos import escribir  # noqa: E402

escribir("001", [
    # (efecto, (plano, fraccion del plano), volumen en dB)
    ("pop", (1, 0.02), -8), ("pop", (2, 0.0), -14), ("pop", (3, 0.0), -12),
    ("sube", (4, 0.2), -8), ("baja", (5, 0.25), -9), ("campana", (7, 0.05), -9),
    ("bip", (9, 0.2), -12), ("bip", (9, 0.4), -12), ("bip", (9, 0.6), -12),
    ("bip_doble", (10, 0.15), -17), ("bip_doble", (10, 0.6), -17),
    ("pop", (11, 0.0), -13), ("campana", (15, 0.0), -10), ("golpe", (17, 0.0), -8),
    ("pop", (18, 0.0), -12), ("pop", (20, 0.0), -11),
    ("alarma", (24, 0.0), -10), ("apagado", (25, 0.15), -8),
    ("pop", (29, 0.0), -9), ("blip_sube_baja", (31, 0.2), -10), ("pop", (33, 0.0), -10),
    ("triste", (34, 0.0), -10), ("corneta", (35, 0.05), -11), ("golpe", (37, 0.0), -8),
    ("alarma", (38, 0.0), -10),
    ("bip", (39, 0.1), -13), ("bip", (39, 0.6), -13), ("bip", (40, 0.1), -13), ("bip", (40, 0.4), -13), ("bip", (40, 0.7), -13),
    ("revelacion", (42, 0.0), -9), ("golpe", (44, 0.0), -9),
    ("patada", (53, 0.05), -7), ("alarma", (55, 0.1), -14),
    ("explosion", (56, 0.0), -4), ("chispazo", (57, 0.05), -8),
    ("triste", (58, 0.1), -12), ("logro", (59, 0.0), -8), ("pop", (60, 0.0), -12),
], lluvia=(49, 57, -15))
