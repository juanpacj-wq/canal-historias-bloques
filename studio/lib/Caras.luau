-- Caras.luau
-- Catálogo de 20 expresiones. Cada una se puede mostrar de dos maneras:
--   1. IMAGEN propia subida a Roblox: Caras.registrar("feliz", 123456) y luego Caras.aplicar.
--      Todos los id del catálogo están en 0 (por llenar); no hay ningún id inventado.
--   2. DIBUJO de respaldo, que no depende de subir nada: un SurfaceGui sobre un panel
--      invisible delante de la cabeza, armado con Frame, UICorner y UIStroke (ojos, cejas,
--      boca, lágrimas, espirales). Es lo que se usa mientras el id sea 0.
--
-- El lienzo lógico mide 200 x 200 unidades; (0, 0) es la esquina superior izquierda vista
-- desde el frente. Caras.componer(nombre) devuelve la lista de trazos como datos puros.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- comprobó que las 20 expresiones componen trazos dentro del lienzo, que los alias resuelven
-- y que dibujar/aplicar crean instancias con propiedades válidas según el volcado oficial.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: cómo se VE cada cara (proporciones, grosor del
-- trazo), que un SurfaceGui se muestre sobre una pieza con Transparency = 1, que
-- ClipsDescendants recorte bien los medios anillos (arcos) y que UIStroke quede por fuera
-- del marco como se asumió. Usa Caras.muestrario() y una captura para revisarlo de una vez.

local Base = require(script.Parent.Base)

local Caras = {}

Caras.LIENZO = 200 -- unidades lógicas
Caras.PIXELES = 400 -- resolución real del SurfaceGui

Caras.NOMBRES = {
	"neutra", "feliz", "risa", "triste", "llanto", "susto", "rabia", "confundido", "decidido",
	"enamorado", "dormido", "picaro", "mareado", "vacia", "sonrisa_enorme", "angustia",
	"risa_forzada", "indiferente", "orgulloso", "incomodo",
}

-- nombre -> id de imagen (0 = por llenar). Se llena con Caras.registrar.
Caras.CATALOGO = {} :: { [string]: number }
for _, nombre in Caras.NOMBRES do
	Caras.CATALOGO[nombre] = 0
end

-- Palabras del guion que apuntan a una expresión del catálogo.
Caras.ALIAS = {
	felices = "feliz", contento = "feliz", sonrisa = "feliz", esperanzado = "feliz", ilusionado = "feliz",
	neutro = "neutra", neutras = "neutra", serio = "neutra", serios = "neutra", tranquilo = "neutra",
	tristes = "triste", derrotado = "triste",
	grito = "llanto", llorando = "llanto",
	sorpresa = "susto", sorprendido = "susto", sorprendidos = "susto", ojos_muy_abiertos = "susto",
	golpe_de_realidad = "susto",
	enojado = "rabia", furioso = "rabia",
	curioso = "confundido", confundida = "confundido",
	decidida = "decidido",
	orgullosos = "orgulloso",
	emocionado = "sonrisa_enorme",
	vacias = "vacia", vacio = "vacia",
	incomoda = "incomodo",
	indiferentes = "indiferente",
}

local NEGRO = "#1B1B1F"
local BLANCO = "#FFFFFF"
local AZUL = "#4DA6FF"
local BOCA = "#5A1626"
local ROJO = "#E8334A"
local OJO_X = 34 -- separación de cada ojo respecto al centro
local OJO_Y = 84
local BOCA_Y = 142

-- Definición de cada expresión. `ojos` aplica a los dos; `ojoDer` cambia solo el derecho.
Caras.DEFINICIONES = {
	neutra = { ojos = { tipo = "punto" }, boca = { tipo = "linea", ancho = 34 } },
	feliz = { ojos = { tipo = "punto" }, boca = { tipo = "sonrisa", ancho = 62 } },
	risa = { ojos = { tipo = "arco_feliz" }, boca = { tipo = "media_luna", ancho = 76, alto = 40 } },
	triste = { ojos = { tipo = "punto" }, cejas = { ang = -18 }, boca = { tipo = "triste", ancho = 50 } },
	llanto = {
		ojos = { tipo = "cerrado" }, cejas = { ang = -22 },
		boca = { tipo = "abierta", ancho = 46, alto = 34 }, extras = { "rio" },
	},
	susto = {
		ojos = { tipo = "grande", pupila = 12 }, cejas = { ang = -6, alt = -10 },
		boca = { tipo = "abierta", ancho = 28, alto = 38 }, extras = { "sudor" },
	},
	rabia = { ojos = { tipo = "punto" }, cejas = { ang = 26, alt = 6 }, boca = { tipo = "dientes", ancho = 58, alto = 24 } },
	confundido = {
		ojos = { tipo = "punto" }, cejas = { izq = { ang = -4, alt = -12 }, der = { ang = 14, alt = 4 } },
		boca = { tipo = "ondulada" }, extras = { "interrogacion" },
	},
	decidido = { ojos = { tipo = "punto" }, cejas = { ang = 16, alt = 4 }, boca = { tipo = "linea", ancho = 44, rot = -6 } },
	enamorado = { ojos = { tipo = "corazon" }, boca = { tipo = "sonrisa", ancho = 54 }, extras = { "rubor" } },
	dormido = { ojos = { tipo = "arco_dormido" }, boca = { tipo = "o" }, extras = { "zzz" } },
	picaro = {
		ojos = { tipo = "entrecerrado" }, cejas = { izq = { ang = 14, alt = 4 }, der = { ang = -8, alt = -8 } },
		boca = { tipo = "chueca" },
	},
	mareado = { ojos = { tipo = "espiral" }, boca = { tipo = "ondulada" } },
	vacia = { ojos = { tipo = "vacio" }, boca = { tipo = "linea", ancho = 26, color = "#8A8A92" } },
	sonrisa_enorme = {
		ojos = { tipo = "brillante" }, boca = { tipo = "media_luna", ancho = 104, alto = 50 }, extras = { "rubor" },
	},
	angustia = {
		ojos = { tipo = "grande", pupila = 10 }, cejas = { ang = -24, alt = -4 },
		boca = { tipo = "dientes", ancho = 60, alto = 22 }, extras = { "sudor", "sombra" },
	},
	risa_forzada = {
		ojos = { tipo = "arco_feliz" }, cejas = { ang = -14, alt = -2 },
		boca = { tipo = "dientes", ancho = 84, alto = 28 }, extras = { "sudor" },
	},
	indiferente = { ojos = { tipo = "entrecerrado" }, boca = { tipo = "linea", ancho = 30 } },
	orgulloso = { ojos = { tipo = "cerrado" }, cejas = { ang = 6, alt = -8 }, boca = { tipo = "sonrisa", ancho = 50 }, extras = { "brillo" } },
	incomodo = {
		ojos = { tipo = "lado", mira = 1 }, cejas = { ang = -10 },
		boca = { tipo = "ondulada" }, extras = { "sudor" },
	},
}

----------------------------------------------------------------------------------------
-- Composición (datos puros)
----------------------------------------------------------------------------------------

type Trazo = {
	forma: string, -- "marco" | "texto"
	x: number, y: number, w: number, h: number, -- centro y tamaño en unidades del lienzo
	rot: number?, color: string?, radio: number?, -- radio: 0 a 0.5 (escala de UICorner)
	trazo: number?, colorTrazo: string?, relleno: boolean?, alfa: number?,
	recorte: { number }?, -- {x, y, w, h} esquina superior izquierda: solo se ve lo de adentro
	texto: string?,
}

local function marco(x: number, y: number, w: number, h: number, color: string?, radio: number?, extra: any?): Trazo
	local t: any = { forma = "marco", x = x, y = y, w = w, h = h, color = color or NEGRO, radio = radio or 0 }
	if extra then
		for k, v in extra do
			t[k] = v
		end
	end
	return t
end

-- Anillo (o medio anillo) hecho con un marco transparente y borde. `mitad`: "arriba" | "abajo" | nil.
local function anillo(cx: number, cy: number, w: number, h: number, grosor: number, mitad: string?, color: string?): Trazo
	local recorte = nil
	if mitad == "arriba" then
		recorte = { cx - w / 2, cy - h / 2, w, h / 2 }
	elseif mitad == "abajo" then
		recorte = { cx - w / 2, cy, w, h / 2 }
	end
	return marco(cx, cy, w - 2 * grosor, h - 2 * grosor, nil, 0.5, {
		relleno = false, trazo = grosor, colorTrazo = color or NEGRO, recorte = recorte,
	})
end

local OJOS: { [string]: (ops: { Trazo }, cx: number, cy: number, lado: number, p: any) -> () } = {}

function OJOS.punto(ops, cx, cy)
	table.insert(ops, marco(cx, cy, 20, 32, NEGRO, 0.5))
end
function OJOS.vacio(ops, cx, cy)
	table.insert(ops, marco(cx, cy, 20, 32, "#9A9AA2", 0.5))
end
function OJOS.brillante(ops, cx, cy)
	table.insert(ops, marco(cx, cy, 24, 36, NEGRO, 0.5))
	table.insert(ops, marco(cx - 4, cy - 8, 8, 10, BLANCO, 0.5))
end
function OJOS.grande(ops, cx, cy, _lado, p)
	table.insert(ops, marco(cx, cy, 36, 36, BLANCO, 0.5, { trazo = 4, colorTrazo = NEGRO }))
	local pupila = p.pupila or 16
	table.insert(ops, marco(cx + (p.dx or 0), cy + (p.dy or 0), pupila, pupila, NEGRO, 0.5))
end
function OJOS.lado(ops, cx, cy, _lado, p)
	table.insert(ops, marco(cx, cy, 34, 34, BLANCO, 0.5, { trazo = 4, colorTrazo = NEGRO }))
	table.insert(ops, marco(cx + 9 * (p.mira or 1), cy + 2, 14, 14, NEGRO, 0.5))
end
function OJOS.cerrado(ops, cx, cy)
	table.insert(ops, marco(cx, cy + 4, 36, 7, NEGRO, 0.5))
end
function OJOS.arco_feliz(ops, cx, cy)
	table.insert(ops, anillo(cx, cy + 8, 38, 38, 7, "arriba"))
end
function OJOS.arco_dormido(ops, cx, cy)
	table.insert(ops, anillo(cx, cy - 6, 38, 38, 7, "abajo"))
end
function OJOS.espiral(ops, cx, cy)
	table.insert(ops, anillo(cx, cy, 44, 44, 5))
	table.insert(ops, anillo(cx, cy, 24, 24, 5))
	table.insert(ops, marco(cx, cy, 6, 6, NEGRO, 0.5))
end
function OJOS.corazon(ops, cx, cy)
	local t = 34
	table.insert(ops, marco(cx, cy + t * 0.12, t * 0.6, t * 0.6, ROJO, 0, { rot = 45 }))
	table.insert(ops, marco(cx - t * 0.22, cy - t * 0.1, t * 0.62, t * 0.62, ROJO, 0.5))
	table.insert(ops, marco(cx + t * 0.22, cy - t * 0.1, t * 0.62, t * 0.62, ROJO, 0.5))
end
function OJOS.equis(ops, cx, cy)
	table.insert(ops, marco(cx, cy, 40, 8, NEGRO, 0.5, { rot = 45 }))
	table.insert(ops, marco(cx, cy, 40, 8, NEGRO, 0.5, { rot = -45 }))
end
function OJOS.entrecerrado(ops, cx, cy)
	table.insert(ops, marco(cx, cy + 4, 22, 22, NEGRO, 0.5, { recorte = { cx - 14, cy + 3, 28, 16 } }))
	table.insert(ops, marco(cx, cy + 2, 34, 6, NEGRO, 0.5))
end

local BOCAS: { [string]: (ops: { Trazo }, p: any) -> () } = {}

function BOCAS.linea(ops, p)
	table.insert(ops, marco(100, BOCA_Y, p.ancho or 34, 7, p.color or NEGRO, 0.5, { rot = p.rot or 0 }))
end
function BOCAS.sonrisa(ops, p)
	local ancho = p.ancho or 60
	table.insert(ops, anillo(100, BOCA_Y - 10, ancho, ancho * 0.8, 7, "abajo"))
end
function BOCAS.triste(ops, p)
	local ancho = p.ancho or 50
	table.insert(ops, anillo(100, BOCA_Y + 18, ancho, ancho * 0.8, 7, "arriba"))
end
function BOCAS.abierta(ops, p)
	table.insert(ops, marco(100, BOCA_Y + 2, (p.ancho or 40) - 8, (p.alto or 30) - 8, BOCA, 0.5, { trazo = 4, colorTrazo = NEGRO }))
end
function BOCAS.o(ops)
	table.insert(ops, marco(100, BOCA_Y + 2, 14, 18, BOCA, 0.5, { trazo = 4, colorTrazo = NEGRO }))
end
function BOCAS.media_luna(ops, p)
	local ancho, alto = p.ancho or 76, p.alto or 40
	local arriba = BOCA_Y - 10
	local recorte = { 100 - ancho / 2, arriba, ancho, alto + 2 }
	table.insert(ops, marco(100, arriba, ancho - 8, alto * 2 - 8, BOCA, 0.5, { trazo = 4, colorTrazo = NEGRO, recorte = recorte }))
	table.insert(ops, marco(100, arriba + alto * 0.78, ancho * 0.42, alto * 0.5, "#F08A9B", 0.5, { recorte = recorte }))
	table.insert(ops, marco(100, arriba + 6, ancho * 0.66, 10, BLANCO, 0.3))
	table.insert(ops, marco(100, arriba, ancho, 6, NEGRO, 0.5))
end
function BOCAS.dientes(ops, p)
	local ancho, alto = p.ancho or 58, p.alto or 24
	table.insert(ops, marco(100, BOCA_Y, ancho - 8, alto - 8, BLANCO, 0.35, { trazo = 4, colorTrazo = NEGRO }))
	table.insert(ops, marco(100, BOCA_Y, ancho - 8, 3, NEGRO))
	for i = -1, 1 do
		table.insert(ops, marco(100 + i * (ancho - 8) / 4, BOCA_Y, 3, alto - 8, NEGRO))
	end
end
function BOCAS.ondulada(ops)
	for i = 0, 3 do
		table.insert(ops, marco(73 + i * 18, BOCA_Y, 22, 6, NEGRO, 0.5, { rot = (i % 2 == 0) and 28 or -28 }))
	end
end
function BOCAS.chueca(ops)
	table.insert(ops, marco(104, BOCA_Y, 42, 7, NEGRO, 0.5, { rot = -12 }))
	table.insert(ops, marco(127, BOCA_Y - 11, 7, 14, NEGRO, 0.5, { rot = 20 }))
end

local EXTRAS: { [string]: (ops: { Trazo }) -> () } = {}

function EXTRAS.rubor(ops)
	table.insert(ops, marco(40, 116, 26, 14, "#FF8FA3", 0.5, { alfa = 0.35 }))
	table.insert(ops, marco(160, 116, 26, 14, "#FF8FA3", 0.5, { alfa = 0.35 }))
end
function EXTRAS.sudor(ops)
	table.insert(ops, marco(170, 52, 14, 22, AZUL, 0.5))
end
function EXTRAS.rio(ops)
	table.insert(ops, marco(100 - OJO_X - 6, 132, 14, 70, AZUL, 0.5, { alfa = 0.1 }))
	table.insert(ops, marco(100 + OJO_X + 6, 132, 14, 70, AZUL, 0.5, { alfa = 0.1 }))
end
function EXTRAS.gota(ops)
	table.insert(ops, marco(100 - OJO_X - 4, 114, 12, 20, AZUL, 0.5))
end
function EXTRAS.sombra(ops)
	for i = 0, 3 do
		table.insert(ops, marco(64 + i * 24, 26, 5, 30 - (i % 2) * 8, "#5B6B8C", 0.5))
	end
end
function EXTRAS.brillo(ops)
	table.insert(ops, marco(166, 40, 6, 24, "#FFD84D", 0.5))
	table.insert(ops, marco(166, 40, 24, 6, "#FFD84D", 0.5))
end
function EXTRAS.zzz(ops)
	table.insert(ops, { forma = "texto", x = 160, y = 40, w = 40, h = 40, color = "#4D6CFF", texto = "Z" } :: any)
	table.insert(ops, { forma = "texto", x = 184, y = 18, w = 24, h = 24, color = "#4D6CFF", texto = "z" } :: any)
end
function EXTRAS.interrogacion(ops)
	table.insert(ops, { forma = "texto", x = 172, y = 34, w = 44, h = 52, color = NEGRO, texto = "?" } :: any)
end

local function ceja(ops: { Trazo }, cx: number, lado: number, c: any)
	-- `ang` positivo baja el extremo interior (ceño fruncido); negativo lo sube (tristeza).
	local ang = c.ang or 0
	table.insert(ops, marco(cx, OJO_Y - 30 + (c.alt or 0), 36, 7, NEGRO, 0.5, { rot = (lado < 0) and ang or -ang }))
end

-- Nombre canónico de una expresión (acepta tildes, mayúsculas y alias) o nil.
function Caras.resolver(nombre: any): string?
	if typeof(nombre) ~= "string" then
		return nil
	end
	local clave = Base.normalizar(nombre)
	if Caras.DEFINICIONES[clave] then
		return clave
	end
	local alias = Caras.ALIAS[clave]
	if alias and Caras.DEFINICIONES[alias] then
		return alias
	end
	return nil
end

-- Lista de trazos de una expresión. Si el nombre no existe usa "neutra".
function Caras.componer(nombre: string): { Trazo }
	local def: any = Caras.DEFINICIONES[Caras.resolver(nombre) or "neutra"]
	local ops: { Trazo } = {}
	for _, extra in def.extras or {} do
		if extra == "rio" or extra == "rubor" or extra == "sombra" then
			EXTRAS[extra](ops)
		end
	end
	for _, lado in { -1, 1 } do
		local p = (lado > 0 and def.ojoDer) or def.ojos
		local dibujar = OJOS[p.tipo] or OJOS.punto
		dibujar(ops, 100 + lado * OJO_X, OJO_Y, lado, p)
		if def.cejas then
			local c = def.cejas
			ceja(ops, 100 + lado * OJO_X, lado, (lado < 0 and c.izq) or (lado > 0 and c.der) or c)
		end
	end
	local boca = BOCAS[def.boca.tipo] or BOCAS.linea
	boca(ops, def.boca)
	for _, extra in def.extras or {} do
		if extra ~= "rio" and extra ~= "rubor" and extra ~= "sombra" and EXTRAS[extra] then
			EXTRAS[extra](ops)
		end
	end
	return ops
end

----------------------------------------------------------------------------------------
-- Instancias
----------------------------------------------------------------------------------------

local function escala(x: number, y: number): UDim2
	return UDim2.fromScale(x / Caras.LIENZO, y / Caras.LIENZO)
end

local function instanciar(op: Trazo, padre: Instance, z: number)
	local contenedor = padre
	local ox, oy, cw, ch = 0, 0, Caras.LIENZO, Caras.LIENZO
	local recorte = op.recorte
	if recorte then
		local caja = Instance.new("Frame")
		caja.Name = "Recorte"
		caja.BackgroundTransparency = 1
		caja.BorderSizePixel = 0
		caja.ClipsDescendants = true
		caja.Position = escala(recorte[1], recorte[2])
		caja.Size = escala(recorte[3], recorte[4])
		caja.ZIndex = z
		caja.Parent = padre
		contenedor = caja
		ox, oy, cw, ch = recorte[1], recorte[2], recorte[3], recorte[4]
	end
	local pos = UDim2.fromScale((op.x - ox) / cw, (op.y - oy) / ch)
	local tam = UDim2.fromScale(op.w / cw, op.h / ch)
	if op.forma == "texto" then
		local t = Instance.new("TextLabel")
		t.Name = "Texto"
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = pos
		t.Size = tam
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Base.color(op.color)
		t.Text = op.texto or ""
		t.ZIndex = z
		t.Parent = contenedor
		return
	end
	local m = Instance.new("Frame")
	m.Name = "Trazo"
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.Position = pos
	m.Size = tam
	m.Rotation = op.rot or 0
	m.BorderSizePixel = 0
	m.BackgroundColor3 = Base.color(op.color)
	m.BackgroundTransparency = (op.relleno == false) and 1 or (op.alfa or 0)
	m.ZIndex = z
	if (op.radio or 0) > 0 then
		local esquina = Instance.new("UICorner")
		esquina.CornerRadius = UDim.new(op.radio, 0)
		esquina.Parent = m
	end
	if op.trazo then
		local borde = Instance.new("UIStroke")
		borde.Thickness = op.trazo * Caras.PIXELES / Caras.LIENZO
		borde.Color = Base.color(op.colorTrazo or NEGRO)
		borde.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		borde.Parent = m
	end
	m.Parent = contenedor
end

-- Medidas del panel de la cara. Elenco las fija por estilo con atributos en la cabeza
-- (CaraAncho, CaraAlto, CaraAdelante, CaraSubir); si no existen se deducen del tamaño.
local function medidas(cabeza: BasePart): (number, number, number, number)
	local t = cabeza.Size
	local ancho = cabeza:GetAttribute("CaraAncho") or math.min(t.X, t.Y) * 0.8
	local alto = cabeza:GetAttribute("CaraAlto") or ancho
	local adelante = cabeza:GetAttribute("CaraAdelante") or (t.Z / 2 + 0.02)
	local subir = cabeza:GetAttribute("CaraSubir") or 0
	return ancho, alto, adelante, subir
end

-- Devuelve (o crea) el panel invisible delante de la cabeza y su SurfaceGui.
function Caras.panel(cabeza: BasePart): (BasePart, SurfaceGui)
	local panel = cabeza:FindFirstChild("CaraPanel") :: BasePart?
	if not panel then
		local ancho, alto, adelante, subir = medidas(cabeza)
		local rel = CFrame.new(0, subir, -adelante)
		local nuevo = Base.pieza({
			nombre = "CaraPanel", tam = Vector3.new(ancho, alto, 0.05), cf = cabeza.CFrame * rel,
			transparencia = 1, sombra = false, consultable = false, anclada = cabeza.Anchored,
		})
		nuevo.Massless = true
		-- Elenco reubica en cada pose las piezas con estos dos atributos (modo rígido).
		nuevo:SetAttribute("PegadoA", cabeza.Name)
		nuevo:SetAttribute("Rel", rel)
		if not cabeza.Anchored then
			local soldadura = Instance.new("WeldConstraint")
			soldadura.Part0 = cabeza
			soldadura.Part1 = nuevo
			soldadura.Parent = nuevo
		end
		nuevo.Parent = cabeza
		panel = nuevo
	end
	local gui = (panel :: BasePart):FindFirstChild("Cara") :: SurfaceGui?
	if not gui then
		local nuevo = Instance.new("SurfaceGui")
		nuevo.Name = "Cara"
		nuevo.Face = Enum.NormalId.Front
		nuevo.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		nuevo.CanvasSize = Vector2.new(Caras.PIXELES, Caras.PIXELES)
		nuevo.LightInfluence = 0.5
		nuevo.ClipsDescendants = true
		nuevo.Parent = panel
		gui = nuevo
	end
	return panel :: BasePart, gui :: SurfaceGui
end

-- Dibuja la expresión con marcos sobre la cabeza. Devuelve el SurfaceGui.
function Caras.dibujar(cabeza: BasePart, nombre: string): SurfaceGui
	local _, gui = Caras.panel(cabeza)
	gui:ClearAllChildren()
	for i, op in Caras.componer(nombre) do
		instanciar(op, gui, i)
	end
	return gui
end

-- Registra el id de la imagen propia de una expresión. Con `script` real también lo guarda
-- como atributo del ModuleScript para que sobreviva entre llamadas de execute_luau.
function Caras.registrar(nombre: string, id: number): boolean
	local clave = Caras.resolver(nombre)
	if not clave or typeof(id) ~= "number" then
		return false
	end
	Caras.CATALOGO[clave] = id
	if typeof(script) == "Instance" then
		pcall(function()
			script:SetAttribute("id_" .. clave, id)
		end)
	end
	return true
end

if typeof(script) == "Instance" then
	for _, nombre in Caras.NOMBRES do
		local id = script:GetAttribute("id_" .. nombre)
		if typeof(id) == "number" then
			Caras.CATALOGO[nombre] = id
		end
	end
end

local function cabezaDe(objetivo: Instance): BasePart?
	if objetivo:IsA("BasePart") then
		return objetivo
	end
	local nombre = objetivo:GetAttribute("Cabeza") or "Head"
	local c = objetivo:FindFirstChild(nombre)
	if c and c:IsA("BasePart") then
		return c
	end
	return nil
end

-- Pone una expresión a un personaje (Model) o a una cabeza (BasePart).
-- Devuelve el modo usado ("imagen" o "dibujo") y, si el nombre no existía, un aviso.
function Caras.aplicar(objetivo: Instance, nombre: string): (string, string?)
	local cabeza = cabezaDe(objetivo)
	if not cabeza then
		return "ninguno", "sin cabeza: " .. objetivo.Name
	end
	local clave = Caras.resolver(nombre)
	local aviso = nil
	if not clave then
		aviso = "cara inexistente: " .. tostring(nombre)
		clave = "neutra"
	end
	cabeza:SetAttribute("Cara", clave)
	local id = Caras.CATALOGO[clave :: string] or 0
	local calcomania = cabeza:FindFirstChild("face")
	if id ~= 0 then
		local _, gui = Caras.panel(cabeza)
		gui:ClearAllChildren()
		if calcomania and calcomania:IsA("Decal") then
			calcomania.ColorMapContent = Content.fromAssetId(id)
			calcomania.Transparency = 0
		else
			local imagen = Instance.new("ImageLabel")
			imagen.Name = "Imagen"
			imagen.Size = UDim2.fromScale(1, 1)
			imagen.BackgroundTransparency = 1
			imagen.ImageContent = Content.fromAssetId(id)
			imagen.Parent = gui
		end
		return "imagen", aviso
	end
	if calcomania and calcomania:IsA("Decal") then
		calcomania.Transparency = 1
	end
	Caras.dibujar(cabeza, clave :: string)
	return "dibujo", aviso
end

-- Fila de cabezas de prueba, una por expresión, para revisarlas todas en una captura.
function Caras.muestrario(origen: CFrame?): Model
	local base = origen or CFrame.new(0, 3, 0)
	local raiz = Base.raiz()
	local viejo = raiz:FindFirstChild("MuestrarioCaras")
	if viejo then
		viejo:Destroy()
	end
	local modelo = Instance.new("Model")
	modelo.Name = "MuestrarioCaras"
	for i, nombre in Caras.NOMBRES do
		local col, fila = (i - 1) % 5, math.floor((i - 1) / 5)
		local cabeza = Base.pieza({
			nombre = nombre, tam = Vector3.new(2, 2, 2), color = "#F2C9A0",
			-- El frente de la pieza es -Z; se gira para que la cara mire hacia +Z (la cámara).
			cf = base * CFrame.new((col - 2) * 3, -fila * 3.4, 0) * CFrame.Angles(0, math.rad(180), 0),
		})
		cabeza.Parent = modelo
		Caras.dibujar(cabeza, nombre)
		Base.rotulo(
			Base.pieza({ nombre = "Etiqueta", tam = Vector3.new(2.6, 0.5, 0.1), color = "#20242C", padre = modelo,
				cf = base * CFrame.new((col - 2) * 3, -fila * 3.4 - 1.4, 0) }),
			Enum.NormalId.Back, nombre, "#FFFFFF"
		)
	end
	modelo.Parent = raiz
	return modelo
end

return Caras
