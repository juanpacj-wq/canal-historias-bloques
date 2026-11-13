#!/usr/bin/env python3
"""Genera la identidad visual del canal: perfil, banner, marca de agua y miniatura.

Uso basico (genera las cuatro imagenes en esta carpeta):

    python generar.py --nombre "Almostville"

Solo una miniatura con otro texto y otro color:

    python generar.py --solo miniatura --mini-texto "SECRETS BECOME MICE" \
        --mini-fondo "#3DDBB4" --mini-expresion sorpresa --mini-salida mini-001.png

Requiere Pillow (pip install --user pillow). Las fuentes estan en ./fuentes (licencia OFL).
El personaje es un diseno propio: no usa logos, tipografias de marca ni caras de terceros.
"""
import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

AQUI = Path(__file__).resolve().parent
FUENTE_TITULO = AQUI / "fuentes" / "LilitaOne-Regular.ttf"
FUENTE_TEXTO = AQUI / "fuentes" / "Fredoka-Variable.ttf"

# Paleta (5 colores)
AMARILLO = "#FFC531"  # Amarillo regla
MENTA = "#3DDBB4"     # Menta
CORAL = "#FF5A4E"     # Coral
NOCHE = "#1B2452"     # Azul noche
CREMA = "#FFF6E3"     # Crema
# Derivados (sombras y apoyos, no forman parte de la paleta principal)
ROSA = "#FF9AA2"
LAGRIMA = "#6FD3FF"
NOCHE_2 = "#27326B"
NOCHE_3 = "#34418A"

EXPRESIONES = ("feliz", "sorpresa", "llanto", "picaro")


def rgb(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def mezcla(c1, c2, t):
    a, b = rgb(c1), rgb(c2)
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def fuente_titulo(px):
    return ImageFont.truetype(str(FUENTE_TITULO), int(px))


def fuente_texto(px, peso=600):
    f = ImageFont.truetype(str(FUENTE_TEXTO), int(px))
    try:
        f.set_variation_by_axes([peso, 100])
    except Exception:
        pass
    return f


def ajustar_fuente(draw, texto, creador, ancho_max, px_max, px_min=20, borde=0):
    """Devuelve la fuente mas grande con la que el texto cabe en ancho_max."""
    px = px_max
    while px > px_min:
        f = creador(px)
        x0, y0, x1, y1 = draw.textbbox((0, 0), texto, font=f, stroke_width=int(borde * px))
        if x1 - x0 <= ancho_max:
            return f
        px -= 2
    return creador(px_min)


def linea(d, p1, p2, ancho, color):
    """Linea con puntas redondas."""
    d.line([p1, p2], fill=color, width=int(ancho))
    r = ancho / 2
    for (x, y) in (p1, p2):
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)


# ---------------------------------------------------------------- personaje

def dibujar_personaje(s, color=MENTA, ropa=CORAL, expresion="feliz", mirada=(0, 0),
                      bloque=AMARILLO, cuerpo=True, contorno=NOCHE, brazos="abajo", piernas=None):
    """Devuelve una capa RGBA con el personaje insignia.

    s es el ancho de la cabeza en pixeles. La capa mide 2s x 2.4s y el centro de
    la cabeza queda en (s, 1.0s). Proporciones propias: cabeza enorme y mas ancha
    que alta, cuerpo pequeno en forma de campana, ojos desiguales y un bloque
    inclinado que flota sobre la cabeza.
    """
    W, H = int(2 * s), int(2.4 * s)
    capa = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    cx, cy = s, 1.0 * s
    o = max(2, int(0.05 * s))  # grosor del contorno
    hw, hh = 0.5 * s, 0.43 * s  # medio ancho y medio alto de la cabeza
    oscuro = rgb(contorno)

    if cuerpo:
        ty = cy + hh - 0.06 * s  # arranque del torso (queda bajo la cabeza)
        by = ty + 0.50 * s
        # piernas
        for sx in (-1, 1):
            x = cx + sx * 0.14 * s
            d.rounded_rectangle([x - 0.105 * s, by - 0.08 * s, x + 0.105 * s, by + 0.22 * s],
                                radius=0.05 * s, fill=rgb(piernas) if piernas else oscuro)
        # brazos
        for sx in (-1, 1):
            hx, hy = cx + sx * 0.25 * s, ty + 0.16 * s
            if brazos == "arriba":
                fx, fy = cx + sx * 0.62 * s, ty - 0.02 * s
            else:
                fx, fy = cx + sx * 0.44 * s, ty + 0.42 * s
            linea(d, (hx, hy), (fx, fy), 0.17 * s + 2 * o, oscuro)
            linea(d, (hx, hy), (fx, fy), 0.17 * s, rgb(ropa))
            r = 0.085 * s
            d.ellipse([fx - r - o, fy - r - o, fx + r + o, fy + r + o], fill=oscuro)
            d.ellipse([fx - r, fy - r, fx + r, fy + r], fill=rgb(color))
        # torso en campana
        pts = [(cx - 0.24 * s, ty), (cx + 0.24 * s, ty), (cx + 0.33 * s, by), (cx - 0.33 * s, by)]
        d.polygon(pts, fill=oscuro)
        d.line(pts + [pts[0]], fill=oscuro, width=2 * o, joint="curve")
        ins = [(cx - 0.24 * s + o * 0.4, ty), (cx + 0.24 * s - o * 0.4, ty),
               (cx + 0.33 * s - o * 0.6, by - o * 0.5), (cx - 0.33 * s + o * 0.6, by - o * 0.5)]
        d.polygon(ins, fill=rgb(ropa))
        # franja de la ropa
        d.rectangle([cx - 0.29 * s, ty + 0.30 * s, cx + 0.29 * s, ty + 0.37 * s], fill=rgb(CREMA))

    # cabeza
    d.rounded_rectangle([cx - hw - o, cy - hh - o, cx + hw + o, cy + hh + o],
                        radius=0.2 * s + o, fill=oscuro)
    d.rounded_rectangle([cx - hw, cy - hh, cx + hw, cy + hh], radius=0.2 * s, fill=rgb(color))
    # bloque flotante (firma del personaje)
    b = int(0.25 * s)
    cubo = Image.new("RGBA", (b * 2, b * 2), (0, 0, 0, 0))
    dc = ImageDraw.Draw(cubo)
    dc.rounded_rectangle([b * 0.5 - o, b * 0.5 - o, b * 1.5 + o, b * 1.5 + o], radius=0.06 * s + o, fill=oscuro)
    dc.rounded_rectangle([b * 0.5, b * 0.5, b * 1.5, b * 1.5], radius=0.06 * s, fill=rgb(bloque))
    cubo = cubo.rotate(18, resample=Image.BICUBIC)
    capa.alpha_composite(cubo, (int(cx + 0.20 * s - b), int(cy - hh - 0.25 * s - b)))
    d = ImageDraw.Draw(capa)

    # cara
    mx, my = mirada
    ojos = [(-0.215, 0.150, 0.190), (0.215, 0.125, 0.160)]  # (x, radio x, radio y): desiguales a proposito
    ey = cy - 0.07 * s
    if expresion == "llanto":
        for (ox, rx, ry) in ojos:
            x = cx + ox * s
            # ojos apretados
            d.arc([x - rx * s, ey - 0.02 * s, x + rx * s, ey + 0.20 * s], 200, 340, fill=oscuro, width=int(0.055 * s))
            # lagrimas
            d.rounded_rectangle([x - 0.055 * s, ey + 0.07 * s, x + 0.055 * s, cy + hh - 0.03 * s],
                                radius=0.05 * s, fill=rgb(LAGRIMA))
        linea(d, (cx - 0.33 * s, ey - 0.13 * s), (cx - 0.12 * s, ey - 0.21 * s), 0.05 * s, oscuro)
        linea(d, (cx + 0.33 * s, ey - 0.13 * s), (cx + 0.12 * s, ey - 0.21 * s), 0.05 * s, oscuro)
        # boca temblorosa
        bx, byy = cx, cy + 0.24 * s
        pts = [(bx - 0.13 * s, byy + 0.03 * s), (bx - 0.065 * s, byy - 0.03 * s), (bx, byy + 0.03 * s),
               (bx + 0.065 * s, byy - 0.03 * s), (bx + 0.13 * s, byy + 0.03 * s)]
        for a, c in zip(pts, pts[1:]):
            linea(d, a, c, 0.05 * s, oscuro)
    else:
        for i, (ox, rx, ry) in enumerate(ojos):
            x = cx + ox * s
            d.ellipse([x - rx * s - o * 0.8, ey - ry * s - o * 0.8, x + rx * s + o * 0.8, ey + ry * s + o * 0.8], fill=oscuro)
            d.ellipse([x - rx * s, ey - ry * s, x + rx * s, ey + ry * s], fill=(255, 255, 255, 255))
            k = 0.48 if expresion == "sorpresa" else 0.66
            px_, py_ = rx * s * k, ry * s * k
            ux = x + mx * (rx * s - px_) * 0.9
            uy = ey + my * (ry * s - py_) * 0.9
            d.ellipse([ux - px_, uy - py_, ux + px_, uy + py_], fill=oscuro)
            br = px_ * 0.38
            d.ellipse([ux - px_ * 0.55, uy - py_ * 0.62, ux - px_ * 0.55 + 2 * br, uy - py_ * 0.62 + 2 * br],
                      fill=(255, 255, 255, 255))
            if expresion == "picaro" and i == 1:
                # parpado a medio cerrar
                d.chord([x - rx * s, ey - ry * s, x + rx * s, ey + ry * s], 180, 360, fill=rgb(color))
                linea(d, (x - rx * s, ey), (x + rx * s, ey), 0.045 * s, oscuro)
        # cejas
        g = 0.055 * s
        if expresion == "sorpresa":
            linea(d, (cx - 0.33 * s, ey - 0.30 * s), (cx - 0.12 * s, ey - 0.33 * s), g, oscuro)
            linea(d, (cx + 0.12 * s, ey - 0.31 * s), (cx + 0.31 * s, ey - 0.28 * s), g, oscuro)
        elif expresion == "picaro":
            linea(d, (cx - 0.34 * s, ey - 0.31 * s), (cx - 0.12 * s, ey - 0.27 * s), g, oscuro)
            linea(d, (cx + 0.10 * s, ey - 0.17 * s), (cx + 0.32 * s, ey - 0.25 * s), g, oscuro)
        else:
            linea(d, (cx - 0.33 * s, ey - 0.27 * s), (cx - 0.13 * s, ey - 0.31 * s), g, oscuro)
            linea(d, (cx + 0.12 * s, ey - 0.28 * s), (cx + 0.30 * s, ey - 0.25 * s), g, oscuro)
        # boca
        bx, byy = cx + 0.01 * s, cy + 0.20 * s
        if expresion == "sorpresa":
            d.ellipse([bx - 0.085 * s, byy - 0.06 * s, bx + 0.085 * s, byy + 0.15 * s], fill=oscuro)
            d.ellipse([bx - 0.05 * s, byy + 0.06 * s, bx + 0.05 * s, byy + 0.135 * s], fill=rgb(ROSA))
        elif expresion == "picaro":
            d.arc([bx - 0.17 * s, byy - 0.14 * s, bx + 0.17 * s, byy + 0.12 * s], 15, 130, fill=oscuro, width=int(0.055 * s))
        else:
            caja = [bx - 0.19 * s, byy - 0.17 * s, bx + 0.19 * s, byy + 0.17 * s]
            d.pieslice(caja, 0, 180, fill=oscuro)
            d.pieslice([bx - 0.10 * s, byy + 0.06 * s, bx + 0.10 * s, byy + 0.24 * s], 180, 360, fill=rgb(ROSA))
            # recorta la lengua que se salga de la boca
            d.arc([caja[0] - 0.04 * s, caja[1] - 0.04 * s, caja[2] + 0.04 * s, caja[3] + 0.04 * s], 20, 160,
                  fill=rgb(color), width=int(0.04 * s))
            linea(d, (caja[0], byy), (caja[2], byy), 0.03 * s, oscuro)
    # mejillas
    if expresion != "llanto":
        for sx in (-1, 1):
            x = cx + sx * 0.37 * s
            d.ellipse([x - 0.07 * s, cy + 0.13 * s, x + 0.07 * s, cy + 0.21 * s], fill=mezcla(color, NOCHE, 0.20))
    return capa


def pegar(lienzo, capa, cx, cy, s, angulo=0):
    """Pega el personaje con el centro de la cabeza en (cx, cy)."""
    if angulo:
        # rota alrededor del centro de la cabeza
        capa = capa.rotate(angulo, resample=Image.BICUBIC, center=(s, 1.0 * s))
    lienzo.alpha_composite(capa, (int(cx - s), int(cy - 1.0 * s)))


def dibujar_bateria(d, x, y, w, h, nivel=1, total=4, color=CORAL):
    """Barra de bateria flotante. (x, y) es la esquina superior izquierda."""
    o = max(2, int(h * 0.11))
    d.rounded_rectangle([x + w, y + h * 0.28, x + w + h * 0.22, y + h * 0.72], radius=h * 0.08, fill=rgb(CREMA))
    d.rounded_rectangle([x, y, x + w, y + h], radius=h * 0.26, fill=rgb(CREMA))
    d.rounded_rectangle([x + o, y + o, x + w - o, y + h - o], radius=h * 0.18, fill=rgb(NOCHE))
    hueco = o * 0.8
    cw = (w - 2 * o - hueco * (total + 1)) / total
    for i in range(total):
        cx0 = x + o + hueco + i * (cw + hueco)
        relleno = rgb(color) if i < nivel else rgb(NOCHE_3)
        d.rounded_rectangle([cx0, y + o + hueco, cx0 + cw, y + h - o - hueco], radius=h * 0.08, fill=relleno)


def destello(d, x, y, r, color=CREMA):
    d.polygon([(x, y - r), (x + r * 0.28, y - r * 0.28), (x + r, y), (x + r * 0.28, y + r * 0.28),
               (x, y + r), (x - r * 0.28, y + r * 0.28), (x - r, y), (x - r * 0.28, y - r * 0.28)], fill=rgb(color))


def reducir(img, tam):
    return img.resize(tam, Image.LANCZOS)


# ---------------------------------------------------------------- piezas

def perfil(salida, fondo=AMARILLO):
    SS = 3
    T = 800 * SS
    img = Image.new("RGBA", (T, T), rgb(fondo))
    s = 470 * SS
    p = dibujar_personaje(s, color=MENTA, ropa=CORAL, expresion="feliz", mirada=(0.25, -0.1), bloque=CORAL)
    pegar(img, p, T * 0.49, T * 0.575, s, angulo=-4)
    reducir(img, (800, 800)).convert("RGB").save(salida)
    return salida


def marca_de_agua(salida):
    SS = 6
    T = 150 * SS
    img = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    s = 96 * SS
    # contorno crema para que se vea sobre cualquier video
    p = dibujar_personaje(s, color=MENTA, expresion="feliz", mirada=(0.25, -0.1), bloque=AMARILLO,
                          cuerpo=False, contorno=NOCHE)
    alfa = p.getchannel("A")
    halo = Image.new("RGBA", p.size, rgb(CREMA))
    from PIL import ImageFilter
    grueso = alfa.filter(ImageFilter.MaxFilter(2 * (4 * SS) + 1))
    halo.putalpha(grueso)
    halo.alpha_composite(p)
    pegar(img, halo, T * 0.48, T * 0.655, s)
    reducir(img, (150, 150)).save(salida)
    return salida


def banner(salida, nombre, frase="In this world...", lema="every town has one impossible rule"):
    SS = 2
    W, H = 2560 * SS, 1440 * SS
    img = Image.new("RGBA", (W, H), rgb(NOCHE))
    d = ImageDraw.Draw(img)
    u = SS

    # Zona segura: 1546 x 423 centrada. Todo lo importante va dentro.
    zx0, zy0 = (2560 - 1546) // 2 * u, (1440 - 423) // 2 * u
    zx1, zy1 = zx0 + 1546 * u, zy0 + 423 * u

    # Fondo para TV y escritorio ancho: cielo plano, bloques y pueblo en un solo tono
    import random
    rnd = random.Random(7)
    for _ in range(90):
        x, y = rnd.randint(0, W), rnd.randint(0, int(H * 0.70))
        t = rnd.choice([5, 6, 8, 10]) * u
        d.rectangle([x, y, x + t, y + t], fill=rgb(NOCHE_3))
    for _ in range(16):
        x, y = rnd.randint(0, W), rnd.randint(int(H * 0.04), int(H * 0.60))
        if zx0 - 80 * u < x < zx1 + 80 * u and zy0 - 120 * u < y < zy1 + 60 * u:
            continue
        t = rnd.randint(36, 90) * u
        cubo = Image.new("RGBA", (t * 2, t * 2), (0, 0, 0, 0))
        ImageDraw.Draw(cubo).rounded_rectangle([t * 0.5, t * 0.5, t * 1.5, t * 1.5], radius=t * 0.2,
                                               fill=rgb(rnd.choice([NOCHE_2, NOCHE_3])))
        img.alpha_composite(cubo.rotate(rnd.randint(-30, 30), resample=Image.BICUBIC), (x - t, y - t))
    d = ImageDraw.Draw(img)
    # suelo y casas
    suelo = int(H * 0.86)
    x = -40 * u
    while x < W:
        w = rnd.randint(150, 260) * u
        h = rnd.randint(130, 300) * u
        c = rnd.choice([NOCHE_2, NOCHE_3])
        d.rounded_rectangle([x, suelo - h, x + w, suelo + 20 * u], radius=18 * u, fill=rgb(c))
        d.polygon([(x - 16 * u, suelo - h + 8 * u), (x + w / 2, suelo - h - 90 * u), (x + w + 16 * u, suelo - h + 8 * u)],
                  fill=rgb(NOCHE_3 if c == NOCHE_2 else NOCHE_2))
        vx = x + w * 0.5 - 22 * u
        d.rounded_rectangle([vx, suelo - h * 0.62, vx + 44 * u, suelo - h * 0.62 + 50 * u], radius=8 * u,
                            fill=rgb(AMARILLO) if rnd.random() < 0.45 else rgb(NOCHE))
        x += w + rnd.randint(20, 70) * u
    d.rectangle([0, suelo, W, H], fill=rgb(NOCHE_2))

    # --- contenido de la zona segura
    cy = (zy0 + zy1) / 2
    s_izq = 195 * u
    s_der = 168 * u
    # personaje izquierdo: mira hacia el titulo
    p1 = dibujar_personaje(s_izq, color=MENTA, ropa=CORAL, expresion="sorpresa", mirada=(0.75, -0.35),
                           bloque=AMARILLO, brazos="arriba", piernas=CREMA)
    pegar(img, p1, zx0 + 150 * u, zy0 + 195 * u, s_izq, angulo=4)
    # pareja derecha con la bateria flotando entre los dos
    p2 = dibujar_personaje(s_der, color=AMARILLO, ropa=MENTA, expresion="feliz", mirada=(0.5, -0.5), bloque=CORAL, piernas=CREMA)
    p3 = dibujar_personaje(s_der, color=CORAL, ropa=NOCHE_3, expresion="llanto", bloque=MENTA, piernas=CREMA)
    pegar(img, p2, zx1 - 315 * u, zy0 + 212 * u, s_der, angulo=3)
    pegar(img, p3, zx1 - 120 * u, zy0 + 212 * u, s_der, angulo=-3)
    d = ImageDraw.Draw(img)
    bw, bh = 150 * u, 58 * u
    bx, by = zx1 - 218 * u - bw / 2, zy0 + 10 * u
    dibujar_bateria(d, bx, by, bw, bh, nivel=1)
    destello(d, bx - 26 * u, by + 12 * u, 13 * u, AMARILLO)
    destello(d, bx + bw + 46 * u, by + 50 * u, 10 * u, AMARILLO)

    # textos centrados entre los personajes
    tx0, tx1 = zx0 + 300 * u, zx1 - 450 * u
    tcx, ancho = (tx0 + tx1) / 2, tx1 - tx0
    f_frase = ajustar_fuente(d, frase, lambda px: fuente_texto(px, 600), ancho * 0.8, 64 * u)
    f_nombre = ajustar_fuente(d, nombre, fuente_titulo, ancho * 0.97, 190 * u)
    f_lema = ajustar_fuente(d, lema, lambda px: fuente_texto(px, 500), ancho * 0.92, 40 * u)
    tam_n = f_nombre.size
    alto_total = f_frase.size * 1.0 + tam_n * 1.02 + f_lema.size * 1.2
    y = cy - alto_total / 2
    d.text((tcx, y + f_frase.size * 0.5), frase, font=f_frase, fill=rgb(MENTA), anchor="mm")
    y += f_frase.size * 1.0
    d.text((tcx + tam_n * 0.035, y + tam_n * 0.54), nombre, font=f_nombre, fill=rgb(CORAL), anchor="mm")
    d.text((tcx, y + tam_n * 0.5), nombre, font=f_nombre, fill=rgb(AMARILLO), anchor="mm")
    y += tam_n * 1.02
    d.text((tcx, y + f_lema.size * 0.6), lema, font=f_lema, fill=rgb(CREMA), anchor="mm")

    reducir(img, (2560, 1440)).convert("RGB").save(salida)
    return salida


def miniatura(salida, texto="SECRETS BECOME MICE", fondo=CORAL, expresion="sorpresa",
              color_personaje=MENTA, resaltar=-1):
    """Plantilla 1280x720. texto: hasta tres palabras (una por renglon).
    resaltar: indice de la palabra que va en amarillo (-1 es la ultima)."""
    SS = 2
    W, H = 1280 * SS, 720 * SS
    u = SS
    img = Image.new("RGBA", (W, H), rgb(fondo))
    d = ImageDraw.Draw(img)
    # rayos planos desde el personaje
    ox, oy = W * 0.73, H * 0.52
    claro = mezcla(fondo, "#FFFFFF", 0.16)
    n = 18
    for i in range(0, n, 2):
        a0, a1 = 2 * math.pi * i / n, 2 * math.pi * (i + 1) / n
        R = W * 1.5
        d.polygon([(ox, oy), (ox + R * math.cos(a0), oy + R * math.sin(a0)),
                   (ox + R * math.cos(a1), oy + R * math.sin(a1))], fill=claro)
    # personaje con cara grande, cortado por abajo
    s = 560 * u
    ropa = CORAL if fondo.upper() != CORAL else AMARILLO
    bloque = AMARILLO if fondo.upper() != AMARILLO else CORAL
    p = dibujar_personaje(s, color=color_personaje, ropa=ropa, expresion=expresion, mirada=(-0.6, 0.1),
                          bloque=bloque, brazos="arriba")
    pegar(img, p, W * 0.735, H * 0.60, s, angulo=-5)
    d = ImageDraw.Draw(img)
    # texto: tres palabras apiladas a la izquierda
    palabras = texto.upper().split()[:3]
    if resaltar < 0:
        resaltar = len(palabras) + resaltar
    margen = 56 * u
    ancho = W * 0.47 - margen
    alto_renglon = (H - 2 * margen) / max(len(palabras), 1)
    fuentes = [ajustar_fuente(d, p_, fuente_titulo, ancho, min(alto_renglon * 0.98, 250 * u), borde=0.07)
               for p_ in palabras]
    total = sum(f.size * 0.98 for f in fuentes)
    y = (H - total) / 2
    for i, (p_, f) in enumerate(zip(palabras, fuentes)):
        borde = int(f.size * 0.07)
        relleno = rgb(AMARILLO) if i == resaltar else rgb(CREMA)
        if fondo.upper() == AMARILLO and i == resaltar:
            relleno = rgb(MENTA)
        yy = y + f.size * 0.49
        d.text((margen + borde + f.size * 0.035, yy + f.size * 0.05), p_, font=f, fill=rgb(NOCHE), anchor="lm",
               stroke_width=borde, stroke_fill=rgb(NOCHE))
        d.text((margen + borde, yy), p_, font=f, fill=relleno, anchor="lm", stroke_width=borde, stroke_fill=rgb(NOCHE))
        y += f.size * 0.98
    reducir(img, (1280, 720)).convert("RGB").save(salida)
    return salida


def main():
    ap = argparse.ArgumentParser(description="Genera las imagenes de identidad del canal.")
    ap.add_argument("--nombre", default="Almostville", help="nombre del canal que aparece en el banner")
    ap.add_argument("--frase", default="In this world...", help="frase sobre el nombre en el banner")
    ap.add_argument("--lema", default="every town has one impossible rule", help="renglon bajo el nombre")
    ap.add_argument("--salida", default=str(AQUI), help="carpeta de salida")
    ap.add_argument("--solo", choices=["todo", "perfil", "banner", "marca", "miniatura"], default="todo")
    ap.add_argument("--mini-texto", default="SECRETS BECOME MICE", help="tres palabras para la miniatura")
    ap.add_argument("--mini-fondo", default=CORAL, help="color de fondo de la miniatura, en hex")
    ap.add_argument("--mini-expresion", default="sorpresa", choices=EXPRESIONES)
    ap.add_argument("--mini-personaje", default=MENTA, help="color del personaje de la miniatura, en hex")
    ap.add_argument("--mini-resaltar", type=int, default=-1, help="indice de la palabra resaltada (-1: la ultima)")
    ap.add_argument("--mini-salida", default="miniatura-plantilla.png", help="nombre del archivo de la miniatura")
    a = ap.parse_args()

    out = Path(a.salida)
    out.mkdir(parents=True, exist_ok=True)
    hechos = []
    if a.solo in ("todo", "perfil"):
        hechos.append(perfil(out / "perfil-800.png"))
        reducir(Image.open(out / "perfil-800.png"), (48, 48)).save(out / "perfil-48-prueba.png")
        hechos.append(out / "perfil-48-prueba.png")
    if a.solo in ("todo", "banner"):
        hechos.append(banner(out / "banner-2560x1440.png", a.nombre, a.frase, a.lema))
    if a.solo in ("todo", "marca"):
        hechos.append(marca_de_agua(out / "marca-de-agua-150.png"))
    if a.solo in ("todo", "miniatura"):
        hechos.append(miniatura(out / a.mini_salida, a.mini_texto, a.mini_fondo, a.mini_expresion,
                                a.mini_personaje, a.mini_resaltar))
    for h in hechos:
        print(h)


if __name__ == "__main__":
    main()
