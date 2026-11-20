"""Puesta en escena de los 61 planos del video 001. Escribe escenas/puesta.json.

Es el ejemplo de referencia para los demas videos: usa las ayudas y las reglas de encuadre
de herramientas/studio/puesta.py. Uso:  python hacer_puesta.py
"""
import os
import random
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "herramientas", "studio"))
from puesta import B, BUZON, C, CU, MALLA, P, PA, PEG, POSES, U, Puesta  # noqa: E402

pu = Puesta("001")
plano = pu.plano

ELENCO = {
    "narrador": {"piel": "#F5CFA8", "camisa": "#FFC233", "pantalon": "#33415C", "pelo": {"tipo": "corto", "color": "#6B3A1E"}},
    "theo": {"piel": "#C98F5B", "camisa": "#E5383B", "pantalon": "#2B2D42", "pelo": {"tipo": "copete", "color": "#1B1B1F"}},
    "theo_f": {"piel": "#C98F5B", "camisa": "#7B4DFF", "pantalon": "#F4F4F8", "pelo": {"tipo": "copete", "color": "#1B1B1F"}},
    "f1": {"piel": "#F2D3B3", "camisa": "#7B4DFF", "pantalon": "#F4F4F8", "pelo": {"tipo": "corto", "color": "#C98A2B"}},
    "f2": {"piel": "#8D5A3B", "camisa": "#7B4DFF", "pantalon": "#F4F4F8", "pelo": {"tipo": "rizado", "color": "#1B1B1F"}},
    "f3": {"piel": "#F5CFA8", "camisa": "#7B4DFF", "pantalon": "#F4F4F8", "pelo": {"tipo": "mono", "color": "#B5451F"}},
    "f4": {"piel": "#D9A066", "camisa": "#7B4DFF", "pantalon": "#F4F4F8", "pelo": {"tipo": "gorra", "color": "#22252E"}},
    "hermana": {"piel": "#F5CFA8", "camisa": "#F0569F", "pantalon": "#5B4B8A", "pelo": {"tipo": "coletas", "color": "#6B3A1E"}},
    "abuelo": {"piel": "#EBC39C", "camisa": "#8A9A5B", "pantalon": "#6B4A2E", "pelo": {"tipo": "abuelo", "color": "#E4E4EA"}, "mangas": "largas"},
    "amigo_ajedrez": {"piel": "#A9683F", "camisa": "#D9A441", "pantalon": "#3A3D45", "pelo": {"tipo": "abuelo", "color": "#F4F4F4"}, "mangas": "largas"},
    "mama": {"piel": "#F5CFA8", "camisa": "#2EC4B6", "pantalon": "#3D405B", "pelo": {"tipo": "largo", "color": "#6B3A1E"}},
    "papa": {"piel": "#EBC39C", "camisa": "#4F772D", "pantalon": "#3A3D45", "pelo": {"tipo": "corto", "color": "#3B2414"}, "mangas": "largas"},
    "cartero": {"piel": "#D9A066", "camisa": "#3B6FD6", "pantalon": "#22335C", "pelo": {"tipo": "gorra", "color": "#22335C"}, "mangas": "largas"},
    "rick": {"piel": "#F2D3B3", "camisa": "#F28B30", "pantalon": "#4A4E69", "pelo": {"tipo": "rizado", "color": "#B5451F"}},
    "e1": {"piel": "#F2D3B3", "camisa": "#3CD070", "pantalon": "#28303F", "pelo": {"tipo": "corto", "color": "#C98A2B"}},
    "e2": {"piel": "#8D5A3B", "camisa": "#F2C230", "pantalon": "#1F2937", "pelo": {"tipo": "rizado", "color": "#1B1B1F"}},
    "e3": {"piel": "#F5CFA8", "camisa": "#B07CF2", "pantalon": "#28303F", "pelo": {"tipo": "largo", "color": "#7A3B1E"}},
    "e4": {"piel": "#D9A066", "camisa": "#F28B30", "pantalon": "#3A3D45", "pelo": {"tipo": "gorra", "color": "#22252E"}},
    "e5": {"piel": "#F2D3B3", "camisa": "#30B8C9", "pantalon": "#28303F", "pelo": {"tipo": "mono", "color": "#E8C36A"}},
    "extrano1": {"piel": "#CFC8C0", "camisa": "#8A8F98", "pantalon": "#5A5F6A", "pelo": {"tipo": "corto", "color": "#6E7178"}},
    "extrano2": {"piel": "#BEB7B0", "camisa": "#7C818A", "pantalon": "#4E535E", "pelo": {"tipo": "largo", "color": "#5E6168"}},
}
pu.elenco = ELENCO

SENTADO_DORMIDO_A = POSES["sentado_dormido_a"]
SENTADO_DORMIDO_B = POSES["sentado_dormido_b"]
SENTADO_MIRA_ARRIBA = POSES["sentado_mira_arriba"]
PUNO_ARRIBA = POSES["puno_arriba"]
AGARRADO = POSES["agarrado"]
SENTADO_PISO = POSES["sentado_piso"]
CHOCAR_N = POSES["chocar_izq"]
CHOCAR_T = POSES["chocar_der"]
PATEAR = POSES["patear"]

_r = random.Random(7)
BOLETAS = {"piezas": []}
for i in range(11):
    x, z, g = _r.uniform(-2.6, 2.6), _r.uniform(-0.9, 1.2), _r.uniform(-70, 70)
    BOLETAS["piezas"].append({"nombre": "Papel%d" % i, "tam": [1.2, 0.05, 0.6], "pos": [x, 0.04 + i * 0.012, z], "rot": [0, g, 0], "color": "#FFE9A8"})
    BOLETAS["piezas"].append({"nombre": "Franja%d" % i, "tam": [0.26, 0.06, 0.6], "pos": [x, 0.045 + i * 0.012, z], "rot": [0, g, 0], "color": "#3B82F6"})
CARTEL_FIESTA = {"texto": "HAPPY B-DAY THEO!", "ancho": 9, "alto": 1.7, "poste": False, "color": "#F0569F", "colorTexto": "#FFFFFF", "torcido": -3}
FORT = {"texto": "FORT MAYBE", "ancho": 6, "alto": 1.8, "poste": False, "torcido": 6}

N, T, TF = "narrador", "theo", "theo_f"

# ------------------------------------------------------------------ 1. Gancho
plano(1, "In this world, every friendship has a BATTERY,", "pueblo",
      [P(N, -1.7, 3, 30, cara="feliz"), P(T, 1.7, 3, -30, "saludar", "feliz")],
      [B(0, 5.8, 3, 98)], C(0, 5.0, 3, 7.4, "acercar_brusco"))
plano(2, "and everybody can see how much charge is left.", "pueblo",
      [P("e1", -9.5, 3, 40, cara="feliz"), P("e2", -7.0, 3, -40, cara="feliz"),
       P("e3", -4.0, 3, 40, cara="neutra"), P("e4", -1.5, 3, -40, cara="incomodo"),
       P("hermana", 1.5, 3, 40, cara="rabia"), P("e5", 4.0, 3, -40, cara="rabia"),
       P("abuelo", 7.0, 3, 40, cara="feliz"), P("amigo_ajedrez", 9.5, 3, -40, cara="feliz")],
      [B(-8.25, 5.7, 3, 80, "p1", 2.6, 1.1), B(-2.75, 5.7, 3, 45, "p2", 2.6, 1.1),
       B(2.75, 5.7, 3, 15, "p3", 2.6, 1.1), B(8.25, 5.7, 3, 100, "p4", 2.6, 1.1)],
      C(-0.5, 4.2, 3, 15.5, "paneo_der", azimut=30, elevacion=9))
# ------------------------------------------------------------------ 2. Ejemplos del mundo
plano(3, "It floats between you like a little green bar.", "pueblo",
      [P(N, -1.7, 3, 30, "mirar_arriba", "feliz"), P(T, 1.7, 3, -30, "mirar_arriba", "feliz")],
      [B(0, 5.8, 3, 98)], C(0, 5.9, 3, 5.4, "acercar_lento"))
plano(4, "Laugh together, it goes up.", "parque",
      [P(N, -1.7, 2, 30, cara="risa", anim="reir"), P(T, 1.7, 2, -30, cara="risa", anim="reir")],
      [B(0, 5.8, 2, 70, claves=[[0, 70], [0.75, 96]])], C(0, 5.0, 2, 7.2, "acercar_lento", inclinacion=4))
plano(5, "Ignore a text, it drops.", "cuarto",
      [P("e1", 0.9, 1, 15, "celular", "indiferente")],
      [PEG("celular", "celular", "e1"), B(3.9, 4.3, 1, 60, claves=[[0, 62], [0.75, 31]])],
      C(2.3, 4.5, 1, 6.6, "acercar_lento", inclinacion=-3))
plano(6, "My grandpa and his chess buddy have been at one hundred percent", "sala",
      [PA("abuelo", "sofa_1", 22, "sentado", "decidido"), PA("amigo_ajedrez", "sofa_2", -22, "sentado", "decidido")],
      [U("ajedrez", "ajedrez", ancla="mesa"), B(-8, 5.0, -8.2, 100, "barra_vieja", telaranas=True)],
      C(-8, 4.6, -6, 8.6, "acercar_lento"))
plano(7, "since 1974.", "sala",
      [PA("abuelo", "sofa_1", 22, "sentado", "decidido"), PA("amigo_ajedrez", "sofa_2", -22, "sentado", "decidido")],
      [U("ajedrez", "ajedrez", ancla="mesa"), B(-8, 5.0, -8.2, 100, "barra_vieja", telaranas=True)],
      C(-8, 5.6, -8.2, 5.0, "acercar_brusco", inclinacion=3, elevacion=17))
plano(8, "They have never finished a game.", "sala",
      [PA("abuelo", "sofa_1", 22, SENTADO_DORMIDO_A, "dormido", anim="quieto"), PA("amigo_ajedrez", "sofa_2", -22, SENTADO_DORMIDO_B, "dormido", anim="quieto")],
      [U("ajedrez", "ajedrez", ancla="mesa"), U("telarana", "telarana", ancla="mesa", desplazar=[0.5, 0.75, 0.4]),
       B(-8, 5.0, -8.2, 100, "barra_vieja", telaranas=True)],
      C(-8, 3.6, -5, 7.8, "alejar_lento", elevacion=20))
plano(9, "My sister lost three friends in one group chat.", "cuarto",
      [P("hermana", 2, 1, 0, "celular", "susto", cambios=[[0.6, {"cara": "llanto"}]])],
      [PEG("celular", "celular", "hermana"),
       B(-0.7, 6.0, 1, 60, "r1", 2.4, 1.0, claves=[[0, 60], [0.22, 3], [1, 3]], anim="temblar"),
       B(2.0, 7.2, 1, 55, "r2", 2.4, 1.0, claves=[[0, 55], [0.2, 55], [0.42, 2], [1, 2]], anim="temblar"),
       B(4.7, 6.0, 1, 70, "r3", 2.4, 1.0, claves=[[0, 70], [0.4, 70], [0.62, 1], [1, 1]], anim="temblar")],
      C(2, 5.3, 1, 8.4, "acercar_brusco", inclinacion=-5))
plano(10, "You could hear the beeping from the kitchen.", "cocina",
      [PA(N, "silla_1", None, SENTADO_MIRA_ARRIBA, "incomodo", anim="quieto")],
      [U("tazon", "tazon_cereal", ancla="mesa")],
      C(0, 4.3, -2.6, 5.4, "temblor"))
plano(11, "My mom and the mailman are at forty percent.", "pueblo",
      [P("mama", -1.9, 3, 35, cara="feliz"), P("cartero", 1.9, 3, -35, "ofrecer", "feliz")],
      [PEG("carta", "carta", "cartero", rel=(0, -0.5, 0.2)), B(0, 5.8, 3, 40)],
      C(0, 5.0, 3, 7.6, "acercar_lento"))
plano(12, "Nobody knows how.", "pueblo",
      [P(N, -1.5, 3, 8, "encogerse", "confundido"), P("papa", 1.5, 3, -8, "encogerse", "confundido")],
      [], C(0, 4.5, 3, 6.0, "acercar_lento"))
plano(13, "Mom says he respects her mailbox.", "pueblo",
      [P("cartero", 1.7, 3.2, -42, "ofrecer", "orgulloso"), P("mama", -3.0, 2.0, 30, cara="enamorado")],
      [U("buzon", "cajas", -0.6, 0, 3.4, params=BUZON, giro=90), PEG("carta", "carta", "cartero", rel=(0, -0.5, 0.2))],
      C(-0.6, 4.1, 3.2, 7.4, "acercar_lento"))
# ------------------------------------------------------------------ 3. El angulo del narrador
plano(14, "Me and Theo were at ninety-eight.", "parque",
      [P(N, -1.75, 2, 12, CHOCAR_N, "sonrisa_enorme"), P(T, 1.75, 2, -12, CHOCAR_T, "sonrisa_enorme")],
      [B(0, 6.9, 2, 98)], C(0, 6.0, 2, 7.6, "acercar_lento"))
plano(15, "Always.", "parque",
      [P(N, -1.75, 2, 12, CHOCAR_N, "sonrisa_enorme"), P(T, 1.75, 2, -12, CHOCAR_T, "sonrisa_enorme")],
      [B(0, 6.9, 2, 98)], C(0, 7.5, 2, 4.8, "acercar_brusco"))
plano(16, "We built a treehouse", "patio",
      [P(N, 7.2, -3, 15, "senalar_arriba", "orgulloso"), P(T, 16.0, -2.5, -15, "brazos_arriba", "orgulloso", anim="saltar", amplitud=0.5)],
      [],
      C(12, 7.4, -8, 17, "subir"))
plano(17, "with one nail and a lot of hope.", "patio", [],
      [U("clavo", "clavo", ancla="clavo", params={"escala": 0.8})],
      CU("util:clavo", "C", "acercar_brusco", margen=1.5))
plano(18, "He named it Fort Maybe.", "patio",
      [P(T, 9.4, -2.2, 10, "senalar_arriba", "picaro")],
      [U("letrero", "letrero", ancla="letrero", params=FORT), U("clavo", "clavo", ancla="clavo", params={"escala": 0.8})],
      C(11.4, 9.9, -4.5, 9.4, "acercar_lento", inclinacion=-4))
plano(19, "Our bar never moved, so I stopped checking it.", "patio",
      [P(N, -6.2, 4, -28, "caminar", "feliz", anim="caminar", mover=[-1.6, 0, 1.6])],
      [B(-3.2, 5.4, 4, 98)], C(-5.6, 4.8, 4, 8.2, "alejar_lento"))
# ------------------------------------------------------------------ 4. Crisis
plano(20, "Then Theo joined the soccer team.", "cancha",
      [P(TF, 0, 6, 0, "saludar", "feliz")],
      [U("balon", "balon", 1.7, 0, 7.4)], C(0.3, 3.7, 6, 6.2, "acercar_brusco"), luz="dia_claro")
plano(21, "New friends.", "cancha",
      [P(TF, 0, 6.6, 0, "brazos_arriba", "risa", anim="saltar", amplitud=0.6),
       P("f1", -2.9, 5.2, 25, cara="risa", anim="reir"), P("f2", 2.9, 5.2, -25, cara="risa", anim="reir"),
       P("f3", -1.6, 3.4, 15, "brazos_arriba", "feliz", anim="saltar", amplitud=0.4), P("f4", 1.6, 3.4, -15, cara="feliz", anim="reir")],
      [U("balon", "balon", 0, 0, 8.4)], C(0, 4.3, 5, 9.4, "paneo_izq"), luz="dia_claro")
plano(22, "New jokes I wasn't in.", "pasillo",
      [P(T, 1.6, -6.0, 50, cara="risa", anim="reir"), P("e1", 4.8, -6.0, -50, cara="risa", anim="reir"), P("e3", 3.2, -8.0, 0, cara="risa", anim="reir"),
       P(N, -2.4, 1.6, -10, {"cuello": {"x": -16}}, "triste")],
      [], C(0.3, 4.3, -1.5, 9.6, "acercar_lento", inclinacion=-4, azimut=-8))
plano(23, "One Monday I finally looked up.", "pasillo",
      [P(N, 0, 0, 0, "cabeza_abajo", "triste", cambios=[[0.45, {"pose": "mirar_arriba", "cara": "neutra"}]])],
      [], C(0, 4.5, 0, 4.8, "subir"))
plano(24, "RED. TWO percent.", "pasillo",
      [P(N, 0, 0, 0, "mirar_arriba", "susto", anim="temblar")],
      [B(0, 6.3, 0, 2)], C(0, 6.0, 0, 5.4, "acercar_brusco", inclinacion=6),
      efecto={"tipo": "vibrar", "en": "util:barra"})
plano(25, "At ZERO, a friendship shuts off.", "pueblo", [],
      [B(0, 5.8, 3, 3, "barra0", claves=[[0, 3], [0.5, 0], [1, 0]], anim="quieto")],
      C(0, 6.5, 3, 5.0, "acercar_lento"), efecto="recuerdo")
plano(26, "You pass each other like strangers.", "pueblo",
      [P("extrano1", -4.6, 3.0, 38, "caminar", "vacia", anim="caminar", mover=[5.4, 0, 0]),
       P("extrano2", 4.6, 4.4, -38, "caminar", "vacia", anim="caminar", mover=[-5.4, 0, 0])],
      [B(0, 5.8, 3, 0, "barra0", anim="quieto")],
      C(0, 4.6, 3.6, 9.0, "fijo"), efecto="recuerdo")
plano(27, "My dad waves at a guy named Rick every morning.", "pueblo",
      [P("papa", -1.9, 3, 30, "saludar", "confundido"), P("rick", 1.9, 3, -30, cara="confundido")],
      [B(0, 5.8, 3, 0, "barra0", anim="quieto")], C(0, 5.0, 3, 7.6, "acercar_lento"))
plano(28, "Neither of them remembers why.", "pueblo",
      [P("rick", 1.9, 3, -12, "saludar", "confundido")],
      [], C(1.9, 4.5, 3, 4.8, "acercar_lento", inclinacion=4))
# ------------------------------------------------------------------ 5. Tres intentos
plano(29, "So I tried to charge it.", "cuarto",
      [P(N, 2, 1, 0, PUNO_ARRIBA, "decidido")], [], C(2, 4.6, 1, 4.8, "acercar_brusco"))
plano(30, "I bought his favorite chips.", "cafeteria",
      [P(N, -11.7, 5, 35, "ofrecer", "sonrisa_enorme"), P(T, -8.3, 5, -35, cara="neutra")],
      [PEG("papas", "bolsa_papas", N, rel=(0, -0.9, 0))], C(-10, 4.5, 5, 7.2, "acercar_lento"))
plano(31, "Three percent, then back to two.", "cafeteria",
      [P(N, -11.7, 5, 35, "mirar_arriba", "sonrisa_enorme", cambios=[[0.62, {"cara": "triste"}]]), P(T, -8.3, 5, -35, cara="neutra")],
      [B(-10, 5.8, 5, 2, claves=[[0, 2], [0.25, 3], [0.55, 3], [0.7, 2], [1, 2]])],
      C(-10, 6.1, 5, 5.2, "fijo"))
plano(32, "I laughed at everything he said,", "cafeteria",
      [P(N, -11.7, 5, 35, "gritar", "risa_forzada", anim="reir", amplitud=2.2), P(T, -8.3, 5, -35, cara="confundido")],
      [], C(-10, 4.5, 5, 7.0, "acercar_lento", inclinacion=5))
plano(33, "even \"pass the ketchup.\"", "cafeteria", [],
      [U("salsa", "botella_salsa", ancla="mesa_frente")], CU("util:salsa", "C", "acercar_brusco", margen=1.5))
plano(34, "Still two.", "cafeteria",
      [P(N, -10, 5, 0, {"cuello": {"x": -14}, "hombroDer": {"x": 6}, "hombroIzq": {"x": 6}}, "triste")],
      [B(-10, 6.0, 5, 2)], C(-10, 5.6, 5, 6.0, "fijo"))
plano(35, "I threw him a surprise party.", "sala",
      [P(N, 2, 1, 0, "brazos_arriba", "sonrisa_enorme", anim="saltar", amplitud=0.7)],
      [PEG("gorro", "gorro_fiesta", N, "cabeza_arriba", (0, -0.1, 0)),
       U("globos", "globos", 5.4, 0, -0.5, params={"cantidad": 5}), U("globos2", "globos", -1.6, 0, -0.5, params={"cantidad": 4}),
       U("cartel", "letrero", 2, 7.4, -2.5, params=CARTEL_FIESTA)],
      C(2, 6.2, 0, 9.6, "acercar_lento"), efecto={"tipo": "confeti", "en": "util:cartel"})
plano(36, "His birthday is in March.", "sala",
      [PA(T, "puerta", None, "de_pie", "confundido")], [], C(15, 4.5, -10.5, 4.8, "acercar_lento"))
plano(37, "It was October.", "sala", [],
      [U("calabaza", "calabaza", ancla="mesa")], CU("util:calabaza", "C", "acercar_brusco", margen=1.5))
plano(38, "One percent.", "sala",
      [P(N, 2, 1, 0, "mirar_arriba", "susto", anim="temblar")],
      [PEG("gorro", "gorro_fiesta", N, "cabeza_arriba", (0, -0.1, 0)), B(2, 7.3, 1, 1)],
      C(2, 6.9, 1, 5.8, "acercar_brusco", inclinacion=6))
# ------------------------------------------------------------------ 6. Cuarto intento
NOCHE = {"clima": "noche"}
plano(39, "That night the bar started beeping.", "cuarto",
      [PA(N, "cama_borde", 0, "sentado", "angustia", anim="quieto")],
      [B(-11, 6.4, -1.4, 1, anim="quieto")], C(-11, 6.0, -1.3, 6.4, "acercar_lento", elevacion=8),
      efecto={"tipo": "parpadeo", "en": "util:barra", "ritmo": 3}, **NOCHE)
plano(40, "I sat on my floor and stared at it.", "cuarto",
      [P(N, 1.0, 1.5, 20, SENTADO_PISO, "angustia", anim="quieto")],
      [B(4.3, 2.3, 1.5, 1, anim="flotar")], C(2.6, 3.0, 1.5, 7.0, "acercar_lento"),
      efecto={"tipo": "parpadeo", "en": "util:barra", "ritmo": 3}, **NOCHE)
plano(41, "And I noticed something I'd never checked.", "cuarto",
      [P(N, 1.0, 1.5, 12, SENTADO_PISO, "confundido", anim="quieto", cambios=[[0.55, {"cara": "susto"}]])],
      [], C(1.0, 3.2, 1.5, 4.4, "acercar_lento"), **NOCHE)
MIT = dict(id="barra_mitades", ancho=4.6, alto=1.7, mitades=True, izq=100, der=0, leyenda="")
plano(42, "The bar has TWO HALVES.", "cuarto", [],
      [B(2, 5.2, 1, 50, anim="latir", **MIT)], C(2, 6.0, 1, 6.0, "acercar_brusco"), **NOCHE)
plano(43, "His half was full.", "cuarto", [],
      [B(2, 5.2, 1, 50, anim="quieto", **MIT)], C(0.85, 6.05, 1, 3.3, "acercar_lento"), **NOCHE)
plano(44, "Mine was EMPTY.", "cuarto",
      [P(N, 3.2, 0.2, -8, "mirar_arriba", "susto")],
      [B(2, 5.2, 1, 50, anim="quieto", **MIT)], C(3.15, 5.2, 1, 4.6, "acercar_brusco", inclinacion=-5), **NOCHE)
plano(45, "Theo had invited me to every single game.", "pasillo",
      [P(T, -1.7, 0, 32, "ofrecer", "sonrisa_enorme"), P(N, 1.7, 0, -32, cara="indiferente")],
      [PEG("boleta", "boleta", T, rel=(0, -0.4, 0))], C(0, 4.4, 0, 7.0, "acercar_lento"), efecto="recuerdo")
plano(46, "I'd said no eleven times.", "pasillo",
      [P(T, -1.7, 0, 32, "cabeza_abajo", "triste"), P(N, 1.7, 0, -20, "de_pie", "indiferente", anim="negar")],
      [PEG("boleta", "boleta", T, rel=(0, -0.4, 0))], C(0, 4.4, 0, 6.8, "acercar_lento"), efecto="recuerdo")
plano(47, "I told him soccer was boring.", "pasillo",
      [P(N, 0.4, -0.6, 0, "encogerse", "indiferente")],
      [U("boletas", "cajas", 0.2, 0, 1.6, params=BOLETAS)], C(0.3, 2.9, 0.6, 6.4, "alejar_lento", elevacion=18), efecto="recuerdo")
plano(48, "Really, I just didn't want to watch him not need me.", "cancha",
      [P(TF, -0.2, 9, 0, "brazos_arriba", "risa", anim="saltar", amplitud=0.7),
       P("f1", -3.0, 8.4, 30, "brazos_arriba", "risa", anim="saltar", amplitud=0.5), P("f2", 3.1, 8.4, -30, cara="risa", anim="reir"),
       P(N, 1.5, -4.0, -10, {"cuello": {"x": -14}}, "triste")],
      [], C(0.4, 4.6, 4, 10.0, "acercar_lento", elevacion=20), luz="dia_claro", efecto="recuerdo")
LLUVIA = {"clima": "lluvia"}
plano(49, "So on Saturday, I went.", "cancha",
      [P(N, -2.6, -2.6, 55, "caminar", "decidido", anim="caminar", mover=[4.2, 0, 0])],
      [U("malla", "cajas", 0, 0, -1.4, params=MALLA)], C(0.4, 4.3, -2.4, 9.0, "alejar_lento"), **LLUVIA)
plano(50, "It was pouring.", "cancha", [],
      [U("malla", "cajas", 0, 0, -1.4, params=MALLA)], C(0, 6.5, -24, 17, "paneo_der", elevacion=12), **LLUVIA)
plano(51, "I stood at the fence, alone, soaked.", "cancha",
      [P(N, 1.9, -2.5, 0, AGARRADO, "incomodo", anim="temblar")],
      [U("malla", "cajas", 0, 0, -1.4, params=MALLA)], C(1.9, 3.9, -2, 6.4, "acercar_lento"), **LLUVIA)
plano(52, "And I yelled his name until my voice cracked.", "cancha",
      [P(N, 1.9, -2.5, 0, "gritar", "llanto", anim="temblar", amplitud=1.6)],
      [U("malla", "cajas", 0, 0, -1.4, params=MALLA)], C(1.9, 4.5, -2.5, 4.8, "temblor", inclinacion=5), **LLUVIA)
# ------------------------------------------------------------------ 7. Desenlace
plano(53, "He missed the shot. Completely.", "cancha",
      [P(TF, 28, 2, -18, PATEAR, "sonrisa_enorme", cambios=[[0.35, {"pose": "de_pie"}]])],
      [U("balon", "balon", 30.2, 0.3, 1.5, mover=[13, 0, -19], arco=9, anim="rodar")],
      C(31.5, 5.2, 0, 11.5, "paneo_der", azimut=-30, elevacion=10), **LLUVIA)
plano(54, "Because he was staring at me, grinning like an idiot.", "cancha",
      [P(TF, 28, 2, -70, "de_pie", "sonrisa_enorme")],
      [], C(28, 4.5, 2, 4.8, "acercar_lento", azimut=-62), **LLUVIA)
plano(55, "The bar didn't climb.", "cancha", [],
      [B(14, 5.6, 0, 2, anim="quieto")], C(14, 6.3, 0, 5.2, "temblor"),
      efecto={"tipo": "vibrar", "en": "util:barra", "fuerza": 0.2}, **LLUVIA)
plano(56, "It EXPLODED. Green light everywhere.", "cancha",
      [P(N, 12.3, 0, 30, "saltar", "susto", cambios=[[0.45, {"cara": "sonrisa_enorme"}]]),
       P(TF, 15.7, 0, -30, "saltar", "susto", cambios=[[0.45, {"cara": "sonrisa_enorme"}]])],
      [B(14, 6.6, 0, 100, anim="latir")], C(14, 6.3, 0, 8.6, "alejar_lento"),
      efecto={"tipo": "destello_verde", "en": "util:barra"}, **LLUVIA)
plano(57, "The scoreboard shorted out.", "cancha", [],
      [U("marcador", "marcador", 0, 0, -8, params={"local": 0, "visita": 9})],
      C(0, 8.2, -8, 10.5, "temblor"), efecto={"tipo": "chispas", "en": "util:marcador"}, **LLUVIA)
# ------------------------------------------------------------------ 8. Remate
plano(58, "They lost nine to nothing.", "cancha",
      [P("f1", -3.3, 4.6, 10, {"cuello": {"x": -16}}, "triste"), P("f2", -1.1, 5.4, 0, {"cuello": {"x": -14}}, "llanto", anim="llorar"),
       P("f3", 1.1, 4.6, 0, {"cuello": {"x": -16}}, "triste"), P("f4", 3.3, 5.4, -10, {"cuello": {"x": -12}}, "rabia")],
      [U("marcador", "marcador", 0, 0, -8, params={"local": 0, "visita": 9})],
      C(0, 5.9, 4, 11.5, "alejar_lento"), luz="atardecer")
plano(59, "We're at one hundred percent.", "parque",
      [P(N, -1.75, 2, 12, CHOCAR_N, "sonrisa_enorme", anim="reir"), P(T, 1.75, 2, -12, CHOCAR_T, "sonrisa_enorme", anim="reir")],
      [B(0, 6.9, 2, 100, anim="latir")], C(0, 6.0, 2, 7.6, "acercar_lento"), luz="atardecer")
plano(60, "Fort Maybe still has one nail.", "patio", [],
      [U("clavo", "clavo", ancla="clavo", params={"escala": 0.8}), U("letrero", "letrero", ancla="letrero", params=FORT)],
      C(12, 10.8, -5, 7.4, "acercar_lento"), luz="atardecer")
plano(61, "And I check the bar every day now.", "patio",
      [P(N, -7.7, 4, 30, "mirar_arriba", "feliz"), P(T, -4.3, 4, -30, "de_pie", "feliz")],
      [B(-6, 5.8, 4, 100)], C(-6, 5.0, 4, 7.4, "alejar_lento"), luz="atardecer")

pu.guardar()
