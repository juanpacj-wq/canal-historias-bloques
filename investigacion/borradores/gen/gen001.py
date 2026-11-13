import json, sys
dest = sys.argv[1]
def pj(id, ancla, cara="neutra", pose="de_pie", **k):
    d = {"id": id, "ancla": ancla, "pose": pose, "cara": cara}; d.update(k); return d
def ut(id, tipo, ancla=None, params=None, **k):
    d = {"id": id, "tipo": tipo}
    if ancla: d["ancla"] = ancla
    if params is not None: d["params"] = params
    d.update(k); return d
def cam(objetivo, tipo, movimiento="fijo", **k):
    d = {"objetivo": objetivo, "tipo": tipo, "movimiento": movimiento}; d.update(k); return d
def barra(pct, ancla="barra", **k):
    params = k.pop("params", {"porcentaje": pct})
    return ut("barra", "bateria", ancla, params, **k)
SENTADO_MIRA_ARRIBA = {"bajar": "sentado", "caderaDer": {"x": 90}, "caderaIzq": {"x": 90}, "hombroDer": {"x": 20}, "hombroIzq": {"x": 20}, "cuello": {"x": 28}}
N, T = "narrador", "theo"
P = []
def plano(texto, escenario, personajes, utileria, camara, **k):
    d = {"n": len(P) + 1, "texto": texto, "escenario": escenario}
    for c in ("clima", "luz"):
        if c in k: d[c] = k.pop(c)
    d["personajes"] = personajes; d["utileria"] = utileria; d["camara"] = camara
    d.update(k); P.append(d)

MIT = {"mitades": True, "izq": 100, "der": 0, "leyenda": ""}
VIEJA = dict(params={"porcentaje": 100, "telaranas": True}, desplazar=[0, 6.2, -6.5])
plano("In this world, every friendship has a battery,", "pueblo",
      [pj(N, "A", "feliz", mira=T), pj(T, "B", "feliz", mira=N)], [barra(98)],
      cam([N, T, "util:barra"], "M", "acercar_lento"))
plano("and everybody can see how much charge is left.", "pueblo",
      [pj("extra1", "pareja_1a"), pj("extra2", "pareja_1b"), pj("extra3", "pareja_2a"), pj("extra4", "pareja_2b"),
       pj("hermana", "pareja_3a"), pj("extra5", "pareja_3b"), pj("abuelo", "pareja_4a"), pj("amigo_ajedrez", "pareja_4b")],
      [ut("barra_p1", "bateria", "barra_1", {"porcentaje": 80}), ut("barra_p2", "bateria", "barra_2", {"porcentaje": 45}),
       ut("barra_p3", "bateria", "barra_3", {"porcentaje": 15}), ut("barra_p4", "bateria", "barra_4", {"porcentaje": 100})],
      cam(["ancla:barra_2", "ancla:barra_3"], "G", "paneo_der", elevacion=10))
plano("It floats between you like a little green bar.", "pueblo",
      [pj(N, "A", "neutra"), pj(T, "B", "neutra")], [barra(98)], cam(["util:barra"], "C", "acercar_lento"))
plano("Laugh together, it goes up.", "parque",
      [pj(N, "A", "risa", mira=T), pj(T, "B", "risa", mira=N)],
      [barra(70, claves={"porcentaje": [[0, 70], [0.8, 95]]})], cam([N, T, "util:barra"], "M", "acercar_lento", inclinacion=4))
plano("Ignore a text, it drops.", "cuarto",
      [pj("extra1", "centro", "indiferente", "celular")],
      [ut("celular", "celular", pegado={"personaje": "extra1", "parte": "mano_der", "rel": [0, -0.4, 0.3]}),
       barra(60, claves={"porcentaje": [[0, 60], [0.8, 35]]})], cam(["extra1", "util:barra"], "M", "fijo"))
plano("My grandpa and his chess buddy have been at one hundred percent", "sala",
      [pj("abuelo", "sofa_1", "neutra", "sentado", giro=25), pj("amigo_ajedrez", "sofa_2", "neutra", "sentado", giro=-25)],
      [ut("ajedrez", "ajedrez", "mesa"), ut("barra_vieja", "bateria", "mesa", **VIEJA)],
      cam(["abuelo", "amigo_ajedrez", "util:barra_vieja"], "M", "acercar_lento"))
plano("since 1974.", "sala",
      [pj("abuelo", "sofa_1", "neutra", "sentado", giro=25), pj("amigo_ajedrez", "sofa_2", "neutra", "sentado", giro=-25)],
      [ut("ajedrez", "ajedrez", "mesa"), ut("barra_vieja", "bateria", "mesa", **VIEJA)],
      cam(["util:barra_vieja"], "C", "acercar_brusco"))
plano("My sister lost three friends in one group chat.", "cuarto",
      [pj("hermana", "centro", "susto", "celular")],
      [ut("celular", "celular", pegado={"personaje": "hermana", "parte": "mano_der", "rel": [0, -0.4, 0.3]}),
       ut("roja1", "bateria", "barra", {"porcentaje": 3, "ancho": 3, "alto": 1.2}, desplazar=[-4.2, 0.6, 0]),
       ut("roja2", "bateria", "barra", {"porcentaje": 2, "ancho": 3, "alto": 1.2}, desplazar=[0, 1.6, 0]),
       ut("roja3", "bateria", "barra", {"porcentaje": 1, "ancho": 3, "alto": 1.2}, desplazar=[4.2, 0.6, 0])],
      cam(["hermana", "util:roja2"], "M", "acercar_brusco", inclinacion=-5))
plano("You could hear the beeping from the kitchen.", "cocina",
      [pj(N, "silla_1", "incomodo", SENTADO_MIRA_ARRIBA)], [ut("tazon", "tazon_cereal", "mesa")],
      cam([N], "C", "acercar_lento"))
plano("Me and Theo were at ninety-eight.", "parque",
      [pj(N, "A", "feliz", mira="camara"), pj(T, "B", "feliz", mira="camara")], [barra(98)], cam([N, T, "util:barra"], "M", "acercar_lento"))
plano("Always.", "parque", [pj(N, "A", "feliz"), pj(T, "B", "feliz")], [barra(98)], cam(["util:barra"], "C", "fijo"))
plano("We built a treehouse with one nail", "patio",
      [pj(N, "bajo_arbol_1", "orgulloso", "senalar_arriba"), pj(T, "bajo_arbol_2", "orgulloso", "brazos_arriba")], [],
      cam(["escena:CasaDelArbol"], "M", "subir", margen=1.0))
plano("and a lot of hope.", "patio", [], [ut("clavo", "clavo", "clavo", {"escala": 0.8})], cam(["util:clavo"], "C", "acercar_brusco"))
plano("He named it Fort Maybe.", "patio",
      [pj(T, "bajo_arbol_2", "picaro", "senalar_arriba")],
      [ut("letrero", "letrero", "letrero", {"texto": "FORT MAYBE", "ancho": 6, "alto": 1.8, "poste": False, "torcido": 6})],
      cam(["util:letrero"], "M", "acercar_lento", inclinacion=-4))
plano("Our bar never moved, so I stopped checking it.", "patio",
      [pj(N, "A", "neutra", "de_espaldas")], [barra(98, desplazar=[3, 0, 0])], cam([N, "util:barra"], "M", "alejar_lento"))
plano("Then Theo joined the soccer team.", "cancha",
      [pj(T, "centro", "feliz", "saludar")], [ut("balon", "balon", "suelo")], cam([T], "M", "acercar_brusco"))
plano("New friends.", "cancha",
      [pj(T, "centro", "risa"), pj("extra1", "A", "risa", mira=T), pj("extra2", "B", "risa", mira=T),
       pj("extra3", "multitud_2", "feliz", mira=T), pj("extra4", "multitud_3", "feliz", mira=T)],
      [ut("balon", "balon", "suelo")], cam([T, "extra1", "extra2"], "G", "paneo_izq"))
plano("New jokes I wasn't in.", "pasillo",
      [pj(T, "grupo_1", "risa"), pj("extra1", "grupo_2", "risa"), pj("extra2", "grupo_3", "risa"), pj("extra3", "grupo_4", "risa"),
       pj(N, "aparte", "triste", "cabeza_abajo")], [], cam([N], "M", "acercar_lento", inclinacion=-5))
plano("One Monday I finally looked up.", "pasillo",
      [pj(N, "centro", "neutra", "mirar_arriba")], [barra(2)], cam([N], "C", "subir"))
plano("Red. Two percent.", "pasillo",
      [pj(N, "centro", "susto", "mirar_arriba")], [barra(2)], cam(["util:barra"], "C", "acercar_brusco", inclinacion=6))
plano("At zero, a friendship shuts off, and you pass each other like strangers.", "pueblo",
      [pj("extrano1", "cruce_1", "vacia", "caminar"), pj("extrano2", "cruce_2", "vacia", "caminar")],
      [barra(0, params={"porcentaje": 0, "apagada": True}, desplazar=[0, 0, 2])],
      cam(["extrano1", "extrano2"], "G", "alejar_lento"), efecto="recuerdo")
plano("So I tried to charge it.", "cuarto", [pj(N, "centro", "decidido")], [], cam([N], "C", "acercar_brusco"))
plano("I bought his favorite chips.", "cafeteria",
      [pj(N, "A", "feliz", "ofrecer", mira=T), pj(T, "B", "neutra", mira=N)],
      [ut("papas", "bolsa_papas", pegado={"personaje": N, "parte": "mano_der", "rel": [0, -0.9, 0]})],
      cam([N, T], "M", "acercar_lento"))
plano("Three percent, then back to two.", "cafeteria",
      [pj(N, "A", "feliz"), pj(T, "B", "neutra")],
      [barra(2, claves={"porcentaje": [[0, 2], [0.3, 3], [0.6, 3], [0.85, 2]]})], cam(["util:barra"], "C", "fijo"))
plano("I laughed at everything he said,", "cafeteria",
      [pj(N, "A", "risa_forzada", "gritar", mira=T), pj(T, "B", "confundido", mira=N)], [],
      cam([N, T], "M", "acercar_lento", inclinacion=5))
plano("even \"pass the ketchup.\"", "cafeteria", [], [ut("salsa", "botella_salsa", "mesa_frente")],
      cam(["util:salsa"], "C", "acercar_brusco"))
plano("Still two.", "cafeteria", [pj(N, "A", "triste", "derrotado")], [barra(2)], cam([N, "util:barra"], "M", "fijo"))
plano("I threw him a surprise party.", "sala",
      [pj(N, "centro", "sonrisa_enorme", "brazos_arriba")],
      [ut("gorro", "gorro_fiesta", pegado={"personaje": N, "parte": "cabeza_arriba", "rel": [0, -0.1, 0]}),
       ut("globos", "globos", "fiesta", {"cantidad": 5})],
      cam([N, "util:globos"], "G", "acercar_lento", margen=0.8), efecto={"tipo": "confeti", "en": "util:globos"})
plano("His birthday is in March.", "sala", [pj(T, "puerta", "confundido")], [], cam([T], "C", "acercar_lento"))
plano("It was October.", "sala", [], [ut("calabaza", "calabaza", "mesa")], cam(["util:calabaza"], "C", "acercar_brusco"))
plano("One percent.", "sala", [pj(N, "centro", "susto")], [barra(1)], cam([N, "util:barra"], "M", "acercar_brusco", inclinacion=6))
plano("That night the bar started beeping.", "cuarto",
      [pj(N, "cama", "angustia", "acostado")], [barra(1, ancla="cama", desplazar=[0, 4.5, 2])],
      cam([N, "util:barra"], "M", "acercar_lento", desde="picado"), clima="noche", efecto={"tipo": "parpadeo", "en": "util:barra"})
plano("And I noticed something I'd never checked.", "cuarto",
      [pj(N, "cama_borde", "confundido", "sentado")], [barra(1, ancla="cama", desplazar=[0, 4.5, 2])],
      cam([N], "C", "acercar_lento"), clima="noche")
plano("The bar has two halves.", "cuarto", [], [ut("barra_mitades", "bateria", "barra", MIT)],
      cam(["util:barra_mitades"], "C", "acercar_lento"), clima="noche")
plano("His half was full.", "cuarto", [], [ut("barra_mitades", "bateria", "barra", MIT)],
      cam(["util:barra_mitades"], "C", "paneo_izq"), clima="noche")
plano("Mine was empty.", "cuarto",
      [pj(N, "centro", "susto", desplazar=[0, 0, -2.5])], [ut("barra_mitades", "bateria", "barra", MIT)],
      cam([N, "util:barra_mitades"], "M", "paneo_der"), clima="noche")
plano("Theo had invited me to every single game.", "pasillo",
      [pj(T, "A", "feliz", "ofrecer", mira=N), pj(N, "B", "indiferente")],
      [ut("boleta", "boleta", pegado={"personaje": T, "parte": "mano_der", "rel": [0, -0.4, 0]})],
      cam([T], "M", "acercar_lento"), efecto="recuerdo")
plano("I'd said no eleven times.", "pasillo",
      [pj(T, "A", "triste", "cabeza_abajo"), pj(N, "B", "indiferente", "negar")], [],
      cam([N, T], "M", "fijo"), efecto="recuerdo")
plano("So on Saturday, I went.", "cancha", [pj(N, "tribuna", "decidido")], [],
      cam([N], "G", "acercar_lento", margen=0.7), clima="lluvia")
plano("I stood in the rain and yelled his name until my voice cracked.", "cancha",
      [pj(N, "tribuna", "llanto", "gritar")], [], cam([N], "C", "acercar_lento", inclinacion=5), clima="lluvia")
plano("He missed the shot. Completely.", "cancha",
      [pj(T, "tiro", "neutra", "correr")], [ut("balon", "balon", "balon_lejos")],
      cam([T, "util:balon"], "G", "paneo_der", desde="der"), clima="lluvia")
plano("Because he was staring at me, grinning like an idiot.", "cancha",
      [pj(T, "tiro", "sonrisa_enorme", mira="ancla:tribuna")], [], cam([T], "C", "acercar_lento", azimut=160, elevacion=4), clima="lluvia")
plano("The bar didn't climb.", "cancha", [], [barra(2)],
      cam(["util:barra"], "C", "temblor"), clima="lluvia", efecto={"tipo": "vibrar", "en": "util:barra"})
plano("It exploded. Green light everywhere.", "cancha",
      [pj(N, "A", "susto", "saltar"), pj(T, "B", "susto", "saltar")], [barra(100)],
      cam([N, T, "util:barra"], "G", "alejar_lento", margen=0.6), clima="lluvia", efecto={"tipo": "destello_verde", "en": "util:barra"})
plano("The scoreboard shorted out.", "cancha", [], [ut("marcador", "marcador", "marcador", {"local": 0, "visita": 9})],
      cam(["util:marcador"], "M", "temblor", elevacion=2), clima="lluvia", efecto={"tipo": "chispas", "en": "util:marcador"})
plano("They lost nine to nothing.", "cancha",
      [pj("extra1", "A", "triste", "derrotado"), pj("extra2", "B", "triste", "derrotado"), pj("extra3", "C", "triste", "cabeza_abajo"),
       pj("extra4", "multitud_2", "triste", "derrotado")],
      [ut("marcador", "marcador", "marcador", {"local": 0, "visita": 9})], cam(["extra1", "extra2", "extra3"], "G", "alejar_lento", margen=0.7))
plano("We're at one hundred percent.", "parque",
      [pj(N, "A", "feliz", "abrazo", mira=T), pj(T, "B", "feliz", "abrazo", mira=N)], [barra(100)],
      cam([N, T, "util:barra"], "M", "acercar_lento"), luz="atardecer")
plano("Fort Maybe still has one nail.", "patio", [],
      [ut("clavo", "clavo", "clavo", {"escala": 0.8}),
       ut("letrero", "letrero", "letrero", {"texto": "FORT MAYBE", "ancho": 6, "alto": 1.8, "poste": False, "torcido": 6})],
      cam(["util:clavo"], "C", "acercar_lento"), luz="atardecer")
plano("And I check the bar every day now.", "patio",
      [pj(N, "A", "feliz", "mirar_arriba"), pj(T, "B", "feliz", mira=N)], [barra(100)],
      cam([N, T, "util:barra"], "M", "acercar_lento"), luz="atardecer")
assert len(P) == 49, len(P)
# Tiempos ESTIMADOS: proporcionales al numero de palabras, hasta completar 98.4 s.
total = 98.4
palabras = [len(p["texto"].split()) for p in P]
t = 0.0
for p, w in zip(P, palabras):
    p2 = {"n": p["n"], "inicio": round(t, 2)}
    t += total * w / sum(palabras)
    p2["fin"] = round(t, 2)
    for k, v in p.items():
        if k != "n": p2[k] = v
    p.clear(); p.update(p2)
P[-1]["fin"] = total
def per(piel, camisa, pantalon, pelo, colorPelo, **k):
    d = {"piel": piel, "camisa": camisa, "pantalon": pantalon, "pelo": {"tipo": pelo, "color": colorPelo}}; d.update(k); return d
elenco = {
 "narrador": per("#F2C9A0", "#3B82F6", "#28303F", "corto", "#4B2E1A"),
 "theo": per("#D9A066", "#E5383B", "#1F2937", "copete", "#1B1B1F"),
 "hermana": per("#F2C9A0", "#E94F9B", "#5B4B8A", "coletas", "#4B2E1A"),
 "abuelo": per("#E8BE96", "#8A9A5B", "#6B4A2E", "abuelo", "#D9D9DE", mangas="largas"),
 "amigo_ajedrez": per("#B9784B", "#C89B5E", "#3A3D45", "abuelo", "#F4F4F4", mangas="largas"),
 "extra1": per("#F2D3B3", "#3CD070", "#28303F", "corto", "#C98A2B"),
 "extra2": per("#8D5A3B", "#F2C230", "#1F2937", "corto", "#1B1B1F"),
 "extra3": per("#F2C9A0", "#B07CF2", "#28303F", "largo", "#7A3B1E"),
 "extra4": per("#D9A066", "#F28B30", "#3A3D45", "gorra", "#22252E"),
 "extra5": per("#F2D3B3", "#30B8C9", "#28303F", "largo", "#E8C36A"),
 "extrano1": per("#9A9AA2", "#7C7C84", "#5A5A62", "corto", "#55555C"),
 "extrano2": per("#A4A4AC", "#70707A", "#4E4E56", "copete", "#4A4A52"),
}
cab = {
 "video": "001-friendships-have-a-battery", "esquema": 1, "vertical": True, "estilo": "propio",
 "tiempos": "ESTIMADOS por numero de palabras hasta 98.4 s; cuando exista el plan con los tiempos reales del audio, el Director los toma del plan (plano por n) e ignora estos",
 "duracion": total, "predeterminados": {"clima": "sol"},
}
out = ["{"]
for k, v in cab.items():
    out.append(f' {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)},')
out.append(' "elenco": {')
out.append(",\n".join(f'  {json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}' for k, v in elenco.items()))
out.append(' },')
out.append(' "planos": [')
out.append(",\n".join("  " + json.dumps(p, ensure_ascii=False) for p in P))
out.append(' ]')
out.append("}")
txt = "\n".join(out) + "\n"
json.loads(txt)
open(dest, "w", encoding="utf-8", newline="\n").write(txt)
print(len(P), "planos", len(txt), "bytes; cortos:", [p["n"] for p in P if p["fin"] - p["inicio"] < 0.6])
