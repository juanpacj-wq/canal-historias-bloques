"""Ayudas para escribir la puesta en escena de un video como programa corto de Python.

La puesta NO se escribe a mano en JSON: son 60 planos que repiten piezas. Cada video tiene
`videos/NNN-slug/escenas/hacer_puesta.py`, que importa este modulo, declara elenco y planos
y escribe `escenas/puesta.json`. El ejemplo completo es el del video 001.

    import os, sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "..", "herramientas", "studio"))
    from puesta import *
    pu = Puesta("001")
    pu.elenco["ana"] = persona("#F5CFA8", "#FFC233", "#33415C", "corto", "#6B3A1E")
    pu.plano(1, "In this world...", "pueblo", [P("ana", -1.7, 3, 30, cara="feliz")], [B(0, 5.8, 3, 98)],
             C(0, 5.0, 3, 7.4, "acercar_brusco"))
    pu.guardar()

REGLAS DE ENCUADRE (comprobadas en el video 001; seguirlas evita rehacer tomas):
- Coordenadas relativas al origen del escenario; el frente es +Z; `giro` 0 mira a camara y
  positivo gira hacia +X. Las anclas de cada escenario salen con `ver.py --panorama CLAVE`.
- Encuadra siempre con C(x, y, z, ancho): punto al que mira la camara y ancho en studs del
  cuadro vertical final. El alto visible es ancho * 16 / 9.
- Un personaje mide 5,3 studs; su cara queda en y = 4,2. Con los brazos ocupa 3,6 de ancho.
- Duo de frente: personajes en x = -1,7 y +1,7 con giro +30 y -30, barra en y = 5,8 a 6,9,
  camara C(0, 5.0 a 6.0, z, 7.2 a 7.6). Primer plano de una cara: ancho 4,4 a 4,8 con el
  punto en y = 4,5. Un objeto solo: ancho 4,6 a 5,4.
- SUBTITULOS: ocupan del 21 % al 28 % del alto, o sea entre y_punto + 0,39 * ancho y
  y_punto + 0,52 * ancho. Nada importante (barra, letrero, cara) puede caer ahi. Regla
  practica: el borde superior de lo importante debe quedar por debajo de
  y_punto + 0,36 * ancho. Si lo pisa, sube el punto de la camara, no bajes el objeto.
- Nunca pongas a un personaje de perfil puro (giro 90): la cara es un panel plano y
  desaparece. Maximo unos 40 grados; para "se miran" usa +30 y -30.
- No uses `mira` para girar personajes hacia otro: los pone de perfil. Usa `giro`.
- Varios personajes: en vertical caben dos lado a lado. Grupos: escalonalos en profundidad
  (z) y sube la camara con `elevacion` 15 a 20 para que los de atras asomen por encima.
- Cada plano declara todo lo que se ve; lo que no se nombra se oculta.
- Un mismo `id` de utileria es el mismo objeto en todos los planos: si cambia de forma o
  de tamano, usa otro id (barra, barra_vieja, barra_mitades, r1...).
- Dale vida a cada plano: `anim` en personajes (reir, saltar, temblar, caminar, negar,
  asentir, llorar; por defecto respiran), `mover` para desplazarlos, `cambios` para cambiar
  de cara o pose a mitad del plano, y un movimiento de camara distinto de "fijo".
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import base as _b  # noqa: E402

BW, BH = 3.4, 1.4  # tamano de la barra normal


def persona(piel, camisa, pantalon, pelo="corto", color_pelo="#6B3A1E", **extra):
    """pelo: corto, largo, coletas, copete, rizado, mono, abuelo, gorra, ninguno."""
    d = {"piel": piel, "camisa": camisa, "pantalon": pantalon, "pelo": {"tipo": pelo, "color": color_pelo}}
    d.update(extra)  # por ejemplo mangas="largas"
    return d


def P(id, x, z, giro=0, pose="de_pie", cara="neutra", y=0, **kw):
    """Personaje en una posicion. kw: anim, mover=[dx,dy,dz], cambios=[[frac,{cara,pose,anim}]], amplitud."""
    d = {"id": id, "pos": [x, y, z], "giro": giro, "pose": pose, "cara": cara}
    d.update(kw)
    return d


def PA(id, ancla, giro=None, pose="de_pie", cara="neutra", **kw):
    """Personaje en un ancla del escenario (sofa_1, silla_1, cama_borde, puerta...)."""
    d = {"id": id, "ancla": ancla, "pose": pose, "cara": cara}
    if giro is not None:
        d["giro"] = giro
    d.update(kw)
    return d


def B(x, y, z, pct, id="barra", ancho=BW, alto=BH, claves=None, **kw):
    """Bateria. (x, y, z) es el centro de su base. claves=[[frac, pct], ...] anima la carga.
    kw de movimiento: anim (flotar por defecto, quieto, latir, temblar), mover, arco, amplitud.
    kw de forma (solo al crear ese id): telaranas, mitades, izq, der, leyenda, color, apagada."""
    params = {"porcentaje": pct, "ancho": ancho, "alto": alto}
    extra = {}
    for k in list(kw):
        if k in ("anim", "mover", "arco", "amplitud", "giro"):
            extra[k] = kw.pop(k)
    params.update(kw)
    d = {"id": id, "tipo": "bateria", "pos": [x, y, z], "params": params}
    if claves:
        d["claves"] = {"porcentaje": claves}
    d.update(extra)
    return d


def U(id, tipo, x=None, y=0, z=None, ancla=None, params=None, **kw):
    """Utileria en una posicion o en un ancla. tipo: letrero, globos, balon, arco, marcador,
    celular, carta, flor, mesa, silla, cajas (piezas propias) y los prefabricados clavo,
    bolsa_papas, botella_salsa, calabaza, tazon_cereal, ajedrez, gorro_fiesta, boleta, telarana."""
    d = {"id": id, "tipo": tipo}
    if ancla:
        d["ancla"] = ancla
    else:
        d["pos"] = [x, y, z]
    if params:
        d["params"] = params
    d.update(kw)
    return d


def PEG(id, tipo, personaje, parte="mano_der", rel=(0, -0.4, 0.3), params=None):
    """Utileria pegada a un personaje. parte: mano_der, mano_izq, cabeza_arriba, pecho."""
    d = {"id": id, "tipo": tipo, "pegado": {"personaje": personaje, "parte": parte, "rel": list(rel)}}
    if params:
        d["params"] = params
    return d


def C(x, y, z, ancho, mov="acercar_lento", **kw):
    """Camara por punto y ancho. mov: fijo, acercar_lento, alejar_lento, acercar_brusco,
    paneo_der, paneo_izq, subir, temblor. kw: inclinacion, azimut, elevacion, desde, fov."""
    d = {"objetivo": [[x, y, z]], "tipo": "M", "ancho": ancho, "margen": 1.0, "movimiento": mov}
    d.update(kw)
    return d


def CU(ref, tipo="C", mov="acercar_brusco", **kw):
    """Camara que encuadra sola un objeto o personaje: CU("util:clavo", margen=1.5)."""
    d = {"objetivo": [ref] if isinstance(ref, str) else ref, "tipo": tipo, "movimiento": mov}
    d.update(kw)
    return d


# Poses propias que funcionaron (ademas de las 20 de Elenco.POSES)
POSES = {
    "sentado_dormido_a": {"bajar": "sentado", "caderaDer": {"x": 90}, "caderaIzq": {"x": 90}, "hombroDer": {"x": 15}, "hombroIzq": {"x": 15}, "cuello": {"x": -28, "z": 12}},
    "sentado_dormido_b": {"bajar": "sentado", "caderaDer": {"x": 90}, "caderaIzq": {"x": 90}, "hombroDer": {"x": 15}, "hombroIzq": {"x": 15}, "cuello": {"x": 22, "z": -14}},
    "sentado_mira_arriba": {"bajar": "sentado", "caderaDer": {"x": 90}, "caderaIzq": {"x": 90}, "hombroDer": {"x": 20}, "hombroIzq": {"x": 20}, "cuello": {"x": 26}},
    "sentado_piso": {"bajar": "sentado", "caderaDer": {"x": 90}, "caderaIzq": {"x": 90}, "hombroDer": {"x": 35, "z": -10}, "hombroIzq": {"x": 35, "z": 10}, "cuello": {"x": 12}},
    "puno_arriba": {"hombroDer": {"x": 165, "z": 12}, "hombroIzq": {"x": -10, "z": -12}, "cuello": {"x": 8}},
    "agarrado": {"hombroDer": {"x": 62, "z": 8}, "hombroIzq": {"x": 62, "z": -8}, "cuello": {"x": 6}},
    "patear": {"raiz": {"x": 8}, "hombroDer": {"x": 40}, "hombroIzq": {"x": -45}, "caderaDer": {"x": 70}, "caderaIzq": {"x": -15}},
    # Choque de manos: el de la izquierda de la pantalla usa chocar_izq y el otro chocar_der,
    # a 3,5 studs de distancia y con giro +12 y -12.
    "chocar_izq": {"hombroIzq": {"z": -148}},
    "chocar_der": {"hombroDer": {"z": 148}},
    # Triste con la cara visible ("cabeza_abajo" y "derrotado" la esconden en planos frontales)
    "cabizbajo": {"cuello": {"x": -14}, "hombroDer": {"x": 6}, "hombroIzq": {"x": 6}},
}

# Utileria de piezas (tipo "cajas") que ya se uso
BUZON = {"piezas": [
    {"nombre": "Poste", "tam": [0.4, 3.0, 0.4], "pos": [0, 1.5, 0], "color": "#6B4A2E", "material": "Wood"},
    {"nombre": "Caja", "tam": [1.5, 1.2, 2.2], "pos": [0, 3.5, 0], "color": "#E5383B"},
    {"nombre": "Tapa", "tam": [1.52, 1.22, 0.15], "pos": [0, 3.5, 1.15], "color": "#C22A2D"},
    {"nombre": "Bandera", "tam": [0.12, 0.9, 0.35], "pos": [0.82, 4.1, 0.3], "color": "#FFC233"},
]}
# Malla de 18 studs. El personaje va DETRAS (z menor) y entre dos postes (x = 1,9), no en x = 0.
MALLA = {"piezas": (
    [{"nombre": "Poste%d" % i, "tam": [0.3, 6.0, 0.3], "pos": [x, 3.0, 0], "color": "#8A919C", "material": "Metal"} for i, x in enumerate([-9, -4.5, 0, 4.5, 9])]
    + [{"nombre": "Riel%d" % i, "tam": [18.3, 0.22, 0.22], "pos": [0, y, 0], "color": "#8A919C", "material": "Metal"} for i, y in enumerate([0.4, 2.3, 5.9])]
    + [{"nombre": "Alambre%d" % i, "tam": [0.06, 5.6, 0.06], "pos": [-9 + 0.75 * i, 3.1, 0], "color": "#AEB4BD", "material": "Metal", "sombra": False} for i in range(1, 24)]
)}


class Puesta:
    def __init__(self, numero, clima="sol"):
        self.video = _b.Video(numero)
        self.elenco = {}
        self.planos = []
        self.clima = clima

    def plano(self, n, texto, escenario, personajes, utileria, camara, **kw):
        """kw: clima ("noche", "lluvia"...), luz ("atardecer", "dia_claro"...), efecto
        ("recuerdo", {"tipo": "vibrar"|"parpadeo"|"confeti"|"chispas"|"destello_verde", "en": "util:ID"})."""
        d = {"n": n, "texto": texto, "escenario": escenario, "personajes": personajes, "utileria": utileria, "camara": camara}
        d.update(kw)
        self.planos.append(d)

    def guardar(self):
        t = 0.0
        for p in self.planos:  # tiempos de relleno; los reales llegan con tiempos/planos.json
            p["inicio"] = round(t, 2)
            t += 1.5
            p["fin"] = round(t, 2)
        usados = {pj["id"] for p in self.planos for pj in p["personajes"]}
        faltan = usados - set(self.elenco)
        if faltan:
            raise SystemExit("personajes sin definir en el elenco: %s" % sorted(faltan))
        if os.path.exists(self.video.plan):
            plan = {p["n"] for p in json.loads(_b.leer(self.video.plan))["planos"]}
            mios = {p["n"] for p in self.planos}
            if plan != mios:
                print("AVISO: planos del plan sin puesta: %s; de la puesta sin plan: %s" % (sorted(plan - mios), sorted(mios - plan)))
        datos = {"video": self.video.slug, "esquema": 1, "vertical": True, "estilo": "propio",
                 "predeterminados": {"clima": self.clima}, "elenco": self.elenco, "planos": self.planos}
        os.makedirs(self.video.escenas, exist_ok=True)
        with open(self.video.puesta, "w", encoding="utf-8") as f:
            json.dump(datos, f, ensure_ascii=False, indent=1)
        print("puesta.json: %d planos, %d personajes" % (len(self.planos), len(self.elenco)))
