--!nolint LocalUnused
-- monolito.luau
-- GENERADO por studio/empaquetar.py. No lo edites a mano.
-- Respaldo para cuando execute_luau no pueda escribir Source ni hacer require de un
-- ModuleScript: trae todos los módulos en un solo bloque, sin crear ningún script.
-- Uso: pega este archivo completo en execute_luau y agrega tu código DESPUÉS de la
-- última línea; ahí ya existe la variable local `Historias` (el Director, con
-- Historias.Elenco, Historias.Caras, Historias.Escenarios, Historias.Luz,
-- Historias.Utileria, Historias.Camara y Historias.Base).
-- Limitación: como no hay ModuleScript, nada queda instalado en el lugar; los
-- lanzadores para grabar en modo juego sí necesitan la instalación con scripts.

local __fabricas: { [string]: (any, any) -> any } = {}
local __cargados: { [string]: any } = {}
local function __requerir(ref: any): any
	local nombre = (type(ref) == "table") and ref.__modulo or ref
	if __cargados[nombre] == nil then
		local guion = {
			Name = nombre,
			Parent = setmetatable({}, { __index = function(_, clave)
				return { __modulo = clave }
			end }),
		}
		__cargados[nombre] = __fabricas[nombre](guion, __requerir)
	end
	return __cargados[nombre]
end

__fabricas["Base"] = function(script: any, require: any): any
-- Base.luau
-- Utilidades compartidas por toda la biblioteca Historias: conversión de colores y
-- vectores que llegan desde JSON, creación de piezas, carpetas raíz, curvas de
-- suavizado, interpolación por claves y un generador pseudoaleatorio determinista.
--
-- COMPROBADO FUERA DE STUDIO: sintaxis y tipos con luau-analyze 0.746; toda la lógica
-- con el intérprete luau sobre un doble de la API generado del volcado oficial de
-- Studio 0.747 (version-63eb6055af4e4688), que valida nombres de clases, propiedades,
-- métodos y enumeraciones y el tipo de cada valor asignado.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: que ChangeHistoryService:SetWaypoint se pueda
-- llamar desde execute_luau (va protegido con pcall) y el aspecto de los materiales.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Base = {}

Base.VERSION = "1.0.0"
Base.RAIZ = "Historias" -- carpeta en workspace y en ReplicatedStorage
Base.BODEGA = "HistoriasBodega" -- carpeta en ReplicatedStorage para lo que no está en escena

-- Convierte "#RRGGBB", {r, g, b} (0 a 255) o Color3 en Color3.
function Base.color(valor: any, porDefecto: Color3?): Color3
	local tipo = typeof(valor)
	if tipo == "Color3" then
		return valor
	elseif tipo == "string" then
		local ok, c = pcall(Color3.fromHex, valor)
		if ok then
			return c
		end
	elseif tipo == "table" and #valor >= 3 then
		return Color3.fromRGB(valor[1], valor[2], valor[3])
	end
	return porDefecto or Color3.fromRGB(163, 162, 165)
end

-- Convierte {x, y, z}, un número o Vector3 en Vector3.
function Base.vec(valor: any, porDefecto: Vector3?): Vector3
	local tipo = typeof(valor)
	if tipo == "Vector3" then
		return valor
	elseif tipo == "table" then
		return Vector3.new(valor[1] or valor.x or 0, valor[2] or valor.y or 0, valor[3] or valor.z or 0)
	elseif tipo == "number" then
		return Vector3.new(valor, valor, valor)
	end
	return porDefecto or Vector3.zero
end

-- Gris con la misma luminosidad que el color dado (para la versión gris de los escenarios).
function Base.gris(c: Color3): Color3
	local l = math.clamp(0.3 * c.R + 0.59 * c.G + 0.11 * c.B, 0.3, 0.88)
	return Color3.new(l, l, l)
end

function Base.limitar(x: number, a: number, b: number): number
	return math.clamp(x, a, b)
end

function Base.mezcla(a: number, b: number, u: number): number
	return a + (b - a) * u
end

-- Curvas de suavizado sobre u en [0, 1].
function Base.suavizar(u: number, curva: string?): number
	u = math.clamp(u, 0, 1)
	if curva == "entrada_salida" then
		return u * u * (3 - 2 * u)
	elseif curva == "salida" then
		local v = 1 - u
		return 1 - v * v * v
	elseif curva == "entrada" then
		return u * u * u
	end
	return u
end

-- Interpola una lista de claves {{fraccion, valor}, ...} ordenada por fracción.
function Base.claves(lista: { { number } }, u: number): number
	local n = #lista
	if n == 0 then
		return 0
	end
	if u <= lista[1][1] then
		return lista[1][2]
	end
	for i = 2, n do
		local a, b = lista[i - 1], lista[i]
		if u <= b[1] then
			local tramo = b[1] - a[1]
			if tramo <= 0 then
				return b[2]
			end
			return Base.mezcla(a[2], b[2], (u - a[1]) / tramo)
		end
	end
	return lista[n][2]
end

-- Generador determinista (Park-Miller). Devuelve una función que entrega números en [0, 1).
function Base.azar(semilla: number): () -> number
	local estado = math.max(1, math.floor(semilla) % 2147483647)
	return function(): number
		estado = (estado * 48271) % 2147483647
		return estado / 2147483647
	end
end

-- Normaliza un nombre: minúsculas, sin tildes, espacios y guiones como "_".
local TILDES = {
	["á"] = "a", ["é"] = "e", ["í"] = "i", ["ó"] = "o", ["ú"] = "u", ["ü"] = "u", ["ñ"] = "n",
	["Á"] = "a", ["É"] = "e", ["Í"] = "i", ["Ó"] = "o", ["Ú"] = "u", ["Ü"] = "u", ["Ñ"] = "n",
}
function Base.normalizar(texto: string): string
	local s = tostring(texto)
	for con, sin in TILDES do
		s = string.gsub(s, con, sin)
	end
	s = string.lower(s)
	s = string.gsub(s, "[%s%-]+", "_")
	s = string.gsub(s, "^_+", "")
	s = string.gsub(s, "_+$", "")
	return s
end

-- Busca un hijo por nombre o lo crea (Folder por defecto).
function Base.carpeta(padre: Instance, nombre: string, clase: string?): Instance
	local existente = padre:FindFirstChild(nombre)
	if existente then
		return existente
	end
	local nueva = Instance.new(clase or "Folder")
	nueva.Name = nombre
	nueva.Parent = padre
	return nueva
end

-- workspace.Historias y sus subcarpetas (Escenarios, Elenco, Utileria).
function Base.raiz(): Instance
	return Base.carpeta(workspace, Base.RAIZ)
end

function Base.subcarpeta(nombre: string): Instance
	return Base.carpeta(Base.raiz(), nombre)
end

-- Carpeta donde se guarda lo que no debe verse en el plano actual.
function Base.bodega(): Instance
	return Base.carpeta(ReplicatedStorage, Base.BODEGA)
end

function Base.mover(inst: Instance, padre: Instance)
	if inst.Parent ~= padre then
		inst.Parent = padre
	end
end

local function material(valor: any): EnumItem
	if typeof(valor) == "EnumItem" then
		return valor
	end
	if typeof(valor) == "string" then
		local ok, m = pcall(function()
			return (Enum.Material :: any)[valor]
		end)
		if ok and m then
			return m
		end
	end
	return Enum.Material.SmoothPlastic
end
Base.material = material

-- Crea una pieza anclada. Campos de `p`:
--   nombre, tam (Vector3 o {x,y,z}), cf (CFrame) o pos, color, material (nombre o EnumItem),
--   forma: "bloque" | "bola" | "cilindro" (eje vertical) | "cilindro_x" | "cuna" | "esquina",
--   transparencia, sombra, anclada, colisiona, consultable, padre.
-- En "cilindro", tam = {diámetro, alto, diámetro}; la pieza se gira para quedar vertical,
-- porque el cilindro de Roblox tiene su eje a lo largo de X.
function Base.pieza(p: any): BasePart
	local forma = p.forma or "bloque"
	local parte: any
	if forma == "cuna" then
		parte = Instance.new("WedgePart")
	elseif forma == "esquina" then
		parte = Instance.new("CornerWedgePart")
	else
		parte = Instance.new("Part")
		if forma == "bola" then
			parte.Shape = Enum.PartType.Ball
		elseif forma == "ovalo" then
			-- Elipsoide: la bola de Roblox solo admite tamaño uniforme; la malla esférica no.
			local malla = Instance.new("SpecialMesh")
			malla.MeshType = Enum.MeshType.Sphere
			malla.Parent = parte
		elseif forma == "cilindro" or forma == "cilindro_x" then
			parte.Shape = Enum.PartType.Cylinder
		end
	end
	local tam = Base.vec(p.tam, Vector3.one)
	local cf: CFrame = p.cf or CFrame.new(Base.vec(p.pos))
	if forma == "cilindro" then
		tam = Vector3.new(tam.Y, tam.X, tam.Z)
		cf = cf * CFrame.Angles(0, 0, math.rad(90))
	end
	parte.Name = p.nombre or "Pieza"
	parte.Size = tam
	parte.CFrame = cf
	parte.Color = Base.color(p.color)
	parte.Material = material(p.material)
	parte.Transparency = p.transparencia or 0
	parte.Anchored = p.anclada ~= false
	parte.CanCollide = p.colisiona == true
	parte.CanTouch = false
	parte.CanQuery = p.consultable ~= false
	parte.CastShadow = p.sombra ~= false
	parte.TopSurface = Enum.SurfaceType.Smooth
	parte.BottomSurface = Enum.SurfaceType.Smooth
	if p.padre then
		parte.Parent = p.padre
	end
	return parte
end

-- Texto sobre una cara de una pieza (SurfaceGui con un TextLabel). Devuelve el TextLabel.
function Base.rotulo(parte: BasePart, cara: EnumItem, texto: string, colorTexto: any, nombre: string?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = nombre or "Rotulo"
	gui.Face = cara
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0.4
	local etiqueta = Instance.new("TextLabel")
	etiqueta.Name = "Texto"
	etiqueta.Size = UDim2.fromScale(1, 1)
	etiqueta.BackgroundTransparency = 1
	etiqueta.Font = Enum.Font.FredokaOne
	etiqueta.TextScaled = true
	etiqueta.TextColor3 = Base.color(colorTexto, Color3.new(1, 1, 1))
	etiqueta.Text = texto
	etiqueta.Parent = gui
	gui.Parent = parte
	return etiqueta
end

-- Marca un punto de deshacer en Studio (solo tiene sentido en modo edición).
function Base.marcar(descripcion: string)
	pcall(function()
		game:GetService("ChangeHistoryService"):SetWaypoint(descripcion)
	end)
end

-- Parámetros de rayo que excluyen una lista de instancias (y sus descendientes).
function Base.rayo(excluir: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluir
	return params
end

-- Borra todo lo que la biblioteca creó en el lugar (no toca los ModuleScript).
function Base.limpiar()
	local raiz = workspace:FindFirstChild(Base.RAIZ)
	if raiz then
		raiz:Destroy()
	end
	local bodega = ReplicatedStorage:FindFirstChild(Base.BODEGA)
	if bodega then
		bodega:Destroy()
	end
end

return Base
end

__fabricas["Caras"] = function(script: any, require: any): any
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
end

__fabricas["Elenco"] = function(script: any, require: any): any
-- Elenco.luau
-- Crea personajes por código en modo edición y los ubica, sienta y posa sin animación.
--
-- DOS ESTILOS (parámetro `estilo`):
--   "propio" (valor por defecto): personaje de bloques armado solo con Part, con proporciones
--       propias (cabeza grande y redonda, torso corto). No usa Humanoid ni recursos del
--       avatar clásico, por las pautas de marca que restringen ese avatar en contenido
--       comercial. Nombres de piezas propios: Raiz, Torso, Cabeza, BrazoIzq, BrazoDer,
--       PiernaIzq, PiernaDer.
--   "r6": rig R6 estándar (HumanoidRootPart, Torso, Head, Left Arm...) con Humanoid,
--       BodyColors, calcomanía "face" y, si se dan id, Shirt/Pants y accesorios.
-- Los dos estilos comparten las mismas seis articulaciones Motor6D (raiz, cuello, hombroDer,
-- hombroIzq, caderaDer, caderaIzq) y la misma tabla de poses.
--
-- CÓMO SE POSA: cada pose da ángulos en grados por articulación, en los ejes del torso
-- (el personaje mira hacia -Z, su derecha es +X, arriba es +Y):
--   x: flexión. Positivo levanta brazo o pierna hacia adelante; en el cuello, mira arriba.
--   y: giro sobre el eje vertical.   z: apertura lateral (positivo lleva hacia +X).
-- Se escribe Motor6D.C0 = CFrame.new(posBase) * CFrame.Angles(x, y, z) * rotBase, y el C0
-- original queda en el atributo "C0Base". Además, en modo rígido (por defecto) todas las
-- piezas van ancladas y la biblioteca calcula ella misma el CFrame de cada pieza a partir de
-- los Motor6D (Elenco.actualizar), así la pose no depende de que el motor de física resuelva
-- las articulaciones en modo edición.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- verificó la geometría de las poses en ambos estilos (por ejemplo, que en "brazos_arriba" la
-- mano queda por encima de la cabeza, que "senalar" lleva el brazo al frente y que "sentado"
-- deja las piernas horizontales y el torso a la altura correcta) y la validez de cada
-- propiedad asignada según el volcado oficial.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: el aspecto de los personajes; que el Humanoid del
-- estilo "r6" no muestre nombre ni barra de vida y pinte Shirt/Pants con piezas ancladas;
-- InsertService:LoadAsset para accesorios desde execute_luau (hilo con permisos
-- restringidos); los C0/C1 heredados del R6 estándar se escribieron de memoria (no afectan
-- la pose porque C0 y C1 comparten rotación, pero sí importarían al mezclar con animaciones).

local InsertService = game:GetService("InsertService")

local Base = require(script.Parent.Base)
local Caras = require(script.Parent.Caras)

local Elenco = {}

Elenco.ESTILO_POR_DEFECTO = "propio"

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- Rotaciones heredadas de las articulaciones del R6 estándar.
local function rotCuello(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, -1, 0, 0, 0, 0, 1, 0, 1, 0)
end
local function rotDer(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, 0, 0, 1, 0, 1, 0, -1, 0, 0)
end
local function rotIzq(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, 0, 0, -1, 0, 1, 0, 1, 0, 0)
end

-- Cada estilo: piezas (nombre, tamaño, zona de color) y articulaciones (nombre del Motor6D,
-- pieza que lo contiene, Part0, Part1, C0 y C1). Las medidas están en studs.
Elenco.ESTILOS = {
	propio = {
		raiz = "Raiz", torso = "Torso", cabeza = "Cabeza",
		alturaRaiz = 2.4, -- centro de la raíz sobre el piso con el personaje de pie
		bajarSentado = 1.15, bajarAcostado = 1.9,
		radioCabeza = 1.1,
		cara = { ancho = 1.5, alto = 1.5, adelante = 1.12, subir = -0.05 },
		partes = {
			{ nombre = "Raiz", tam = v(2, 1.6, 1), zona = "raiz" },
			{ nombre = "Torso", tam = v(2, 1.6, 1), zona = "camisa" },
			{ nombre = "Cabeza", tam = v(2.2, 2.2, 2.2), zona = "piel", forma = "bola" },
			{ nombre = "BrazoDer", tam = v(0.8, 1.7, 0.8), zona = "manga" },
			{ nombre = "BrazoIzq", tam = v(0.8, 1.7, 0.8), zona = "manga" },
			{ nombre = "PiernaDer", tam = v(0.9, 1.6, 0.9), zona = "pantalon" },
			{ nombre = "PiernaIzq", tam = v(0.9, 1.6, 0.9), zona = "pantalon" },
		},
		articulaciones = {
			raiz = { nombre = "Cintura", en = "Raiz", p0 = "Raiz", p1 = "Torso", c0 = CFrame.new(), c1 = CFrame.new() },
			cuello = { nombre = "Cuello", en = "Torso", p0 = "Torso", p1 = "Cabeza", c0 = CFrame.new(0, 0.8, 0), c1 = CFrame.new(0, -1, 0) },
			hombroDer = { nombre = "HombroDer", en = "Torso", p0 = "Torso", p1 = "BrazoDer", c0 = CFrame.new(1, 0.65, 0), c1 = CFrame.new(-0.4, 0.7, 0) },
			hombroIzq = { nombre = "HombroIzq", en = "Torso", p0 = "Torso", p1 = "BrazoIzq", c0 = CFrame.new(-1, 0.65, 0), c1 = CFrame.new(0.4, 0.7, 0) },
			caderaDer = { nombre = "CaderaDer", en = "Torso", p0 = "Torso", p1 = "PiernaDer", c0 = CFrame.new(0.5, -0.8, 0), c1 = CFrame.new(0, 0.8, 0) },
			caderaIzq = { nombre = "CaderaIzq", en = "Torso", p0 = "Torso", p1 = "PiernaIzq", c0 = CFrame.new(-0.5, -0.8, 0), c1 = CFrame.new(0, 0.8, 0) },
		},
	},
	r6 = {
		raiz = "HumanoidRootPart", torso = "Torso", cabeza = "Head",
		alturaRaiz = 3, bajarSentado = 1.5, bajarAcostado = 2.5,
		radioCabeza = 0.625,
		cara = { ancho = 1.15, alto = 1.15, adelante = 0.64, subir = 0 },
		partes = {
			{ nombre = "HumanoidRootPart", tam = v(2, 2, 1), zona = "raiz" },
			{ nombre = "Torso", tam = v(2, 2, 1), zona = "camisa" },
			{ nombre = "Head", tam = v(2, 1, 1), zona = "piel", malla = "cabeza" },
			{ nombre = "Right Arm", tam = v(1, 2, 1), zona = "manga" },
			{ nombre = "Left Arm", tam = v(1, 2, 1), zona = "manga" },
			{ nombre = "Right Leg", tam = v(1, 2, 1), zona = "pantalon" },
			{ nombre = "Left Leg", tam = v(1, 2, 1), zona = "pantalon" },
		},
		articulaciones = {
			raiz = { nombre = "RootJoint", en = "HumanoidRootPart", p0 = "HumanoidRootPart", p1 = "Torso", c0 = rotCuello(0, 0, 0), c1 = rotCuello(0, 0, 0) },
			cuello = { nombre = "Neck", en = "Torso", p0 = "Torso", p1 = "Head", c0 = rotCuello(0, 1, 0), c1 = rotCuello(0, -0.5, 0) },
			hombroDer = { nombre = "Right Shoulder", en = "Torso", p0 = "Torso", p1 = "Right Arm", c0 = rotDer(1, 0.5, 0), c1 = rotDer(-0.5, 0.5, 0) },
			hombroIzq = { nombre = "Left Shoulder", en = "Torso", p0 = "Torso", p1 = "Left Arm", c0 = rotIzq(-1, 0.5, 0), c1 = rotIzq(0.5, 0.5, 0) },
			caderaDer = { nombre = "Right Hip", en = "Torso", p0 = "Torso", p1 = "Right Leg", c0 = rotDer(1, -1, 0), c1 = rotDer(0.5, 1, 0) },
			caderaIzq = { nombre = "Left Hip", en = "Torso", p0 = "Torso", p1 = "Left Leg", c0 = rotIzq(-1, -1, 0), c1 = rotIzq(-0.5, 1, 0) },
		},
	},
}

local ORDEN = { "raiz", "cuello", "hombroDer", "hombroIzq", "caderaDer", "caderaIzq" }
Elenco.ARTICULACIONES = ORDEN

-- TABLA DE POSES. Ángulos en grados por articulación; dx/dy/dz desplazan el pivote (studs).
-- `bajar`: "sentado" o "acostado" baja el torso lo que corresponda al estilo; `subir`: studs.
Elenco.POSES = {
	de_pie = {},
	brazos_arriba = { hombroDer = { x = 180, z = 15 }, hombroIzq = { x = 180, z = -15 } },
	senalar = { hombroDer = { x = 90 } },
	senalar_arriba = { hombroDer = { x = 135 }, cuello = { x = 20 } },
	ofrecer = { hombroDer = { x = 80 }, cuello = { x = -5 } },
	saludar = { hombroDer = { z = 150 } },
	cabeza_abajo = { cuello = { x = -35 }, hombroDer = { x = -5 }, hombroIzq = { x = -5 } },
	derrotado = { raiz = { x = -8 }, cuello = { x = -30 }, hombroDer = { x = 8 }, hombroIzq = { x = 8 } },
	mirar_arriba = { cuello = { x = 30 } },
	negar = { cuello = { y = 28 } },
	correr = {
		raiz = { x = -10 }, hombroDer = { x = -50 }, hombroIzq = { x = 60 },
		caderaDer = { x = 45 }, caderaIzq = { x = -35 },
	},
	caminar = { hombroDer = { x = -20 }, hombroIzq = { x = 20 }, caderaDer = { x = 20 }, caderaIzq = { x = -20 } },
	sentado = { bajar = "sentado", caderaDer = { x = 90 }, caderaIzq = { x = 90 }, hombroDer = { x = 20 }, hombroIzq = { x = 20 } },
	acostado = { bajar = "acostado", raiz = { x = 90 } },
	de_espaldas = { raiz = { y = 180 } },
	saltar = {
		subir = 1.5, hombroDer = { x = 160, z = 25 }, hombroIzq = { x = 160, z = -25 },
		caderaDer = { x = 30 }, caderaIzq = { x = -20 },
	},
	abrazo = { hombroDer = { x = 80, z = -25 }, hombroIzq = { x = 80, z = 25 } },
	encogerse = { hombroDer = { z = 40, dy = 0.15 }, hombroIzq = { z = -40, dy = 0.15 }, cuello = { z = 10 } },
	gritar = { raiz = { x = -6 }, cuello = { x = 14 }, hombroDer = { x = -20, z = 35 }, hombroIzq = { x = -20, z = -35 } },
	celular = { hombroDer = { x = 70, z = -15 }, cuello = { x = -20 } },
}

----------------------------------------------------------------------------------------
-- Lógica pura de poses
----------------------------------------------------------------------------------------

-- C0 resultante de girar una articulación `a` = {x, y, z, dx, dy, dz} sobre su C0 base.
function Elenco.c0ConPose(base: CFrame, a: any?, subir: number?): CFrame
	local g = a or {}
	local pos = base.Position + Vector3.new(g.dx or 0, (g.dy or 0) + (subir or 0), g.dz or 0)
	return CFrame.new(pos) * CFrame.Angles(math.rad(g.x or 0), math.rad(g.y or 0), math.rad(g.z or 0)) * base.Rotation
end

-- Acepta el nombre de una pose o una tabla con el mismo formato. Devuelve tabla y aviso.
function Elenco.resolverPose(pose: any): (any, string?)
	if typeof(pose) == "table" then
		return pose, nil
	end
	if pose == nil then
		return Elenco.POSES.de_pie, nil
	end
	local clave = Base.normalizar(tostring(pose))
	local tabla = Elenco.POSES[clave]
	if tabla then
		return tabla, nil
	end
	return Elenco.POSES.de_pie, "pose inexistente: " .. tostring(pose)
end

----------------------------------------------------------------------------------------
-- Construcción
----------------------------------------------------------------------------------------

-- Peinados de piezas. Medidas en radios de cabeza; +Z es la nuca (el personaje mira a -Z).
local PELOS: { [string]: { any } } = {
	ninguno = {}, calvo = {},
	-- El "Casco" es una bola un poco mayor que la cabeza, corrida hacia arriba y hacia la
	-- nuca: deja la cara libre y da una línea de pelo redonda (comprobado en Studio; las tapas
	-- de bloque se veían como un sombrero cuadrado en los planos cercanos).
	corto = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
	},
	largo = {
		{ n = "Casco", tam = { 2.26, 2.26, 2.26 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Melena", tam = { 2.1, 2.3, 1.5 }, pos = { 0, -0.75, 0.62 }, forma = "ovalo" },
	},
	coletas = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "ColetaDer", tam = { 1.05, 1.05, 1.05 }, pos = { 1.3, 0.25, 0.35 }, forma = "bola" },
		{ n = "ColetaIzq", tam = { 1.05, 1.05, 1.05 }, pos = { -1.3, 0.25, 0.35 }, forma = "bola" },
	},
	copete = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Copete", tam = { 1.5, 0.75, 1.0 }, pos = { 0.15, 1.12, -0.5 }, forma = "ovalo" },
	},
	rizado = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Rizo1", tam = { 1.1, 1.1, 1.1 }, pos = { -0.75, 1.0, -0.1 }, forma = "bola" },
		{ n = "Rizo2", tam = { 1.2, 1.2, 1.2 }, pos = { 0, 1.2, 0.05 }, forma = "bola" },
		{ n = "Rizo3", tam = { 1.1, 1.1, 1.1 }, pos = { 0.75, 1.0, -0.1 }, forma = "bola" },
		{ n = "Rizo4", tam = { 1.1, 1.1, 1.1 }, pos = { -1.0, 0.45, 0.45 }, forma = "bola" },
		{ n = "Rizo5", tam = { 1.1, 1.1, 1.1 }, pos = { 1.0, 0.45, 0.45 }, forma = "bola" },
	},
	mono = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Mono", tam = { 1.0, 1.0, 1.0 }, pos = { 0, 1.45, 0.45 }, forma = "bola" },
	},
	abuelo = {
		{ n = "LadoDer", tam = { 0.95, 0.95, 0.95 }, pos = { 0.92, 0.25, 0.25 }, forma = "bola" },
		{ n = "LadoIzq", tam = { 0.95, 0.95, 0.95 }, pos = { -0.92, 0.25, 0.25 }, forma = "bola" },
		{ n = "Nuca", tam = { 1.7, 1.1, 0.9 }, pos = { 0, 0.1, 0.75 }, forma = "ovalo" },
	},
	gorra = {
		{ n = "Casco", tam = { 2.26, 2.26, 2.26 }, pos = { 0, 0.42, 0.2 }, forma = "bola" },
		{ n = "Visera", tam = { 1.7, 0.18, 1.0 }, pos = { 0, 0.62, -1.25 } },
	},
}
Elenco.PELOS = PELOS

local function estiloDe(pj: Instance): any
	return Elenco.ESTILOS[pj:GetAttribute("Estilo") or "propio"] or Elenco.ESTILOS.propio
end

local function parte(pj: Instance, nombre: string): BasePart
	return pj:FindFirstChild(nombre) :: BasePart
end

local function pegar(pj: Model, cabeza: BasePart, pieza: BasePart, rel: CFrame, rigido: boolean)
	pieza.CFrame = cabeza.CFrame * rel
	pieza:SetAttribute("PegadoA", cabeza.Name)
	pieza:SetAttribute("Rel", rel)
	pieza.Anchored = rigido
	pieza.Massless = true
	if not rigido then
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = cabeza
		soldadura.Part1 = pieza
		soldadura.Parent = pieza
	end
	pieza.Parent = pj
end

-- Crea un personaje. Campos de `def` (todos opcionales salvo id o nombre):
--   id, nombre, estilo ("propio" | "r6"), piel, camisa, pantalon (colores "#RRGGBB"),
--   mangas ("cortas" = brazos color piel, "largas" = color camisa),
--   pelo = { tipo = "corto"|"largo"|"coletas"|"copete"|"abuelo"|"gorra"|"ninguno", color },
--   cabeza = "bola" | "bloque" (solo estilo propio), cara (expresión inicial),
--   rigido (true por defecto), padre.
--   Solo estilo "r6": camisa_id, pantalon_id (id de la IMAGEN de la plantilla de ropa, no
--   del artículo del catálogo; 0 = sin ropa), accesorios = { id, ... } (0 se ignora).
function Elenco.crear(def: any): Model
	local nombreEstilo = def.estilo or Elenco.ESTILO_POR_DEFECTO
	local estilo = Elenco.ESTILOS[nombreEstilo]
	if not estilo then
		nombreEstilo, estilo = "propio", Elenco.ESTILOS.propio
	end
	local rigido = def.rigido ~= false
	local padre = def.padre or Base.subcarpeta("Elenco")
	local nombre = def.nombre or def.id or "Personaje"
	local anterior = padre:FindFirstChild(nombre) or Base.bodega():FindFirstChild(nombre)
	if anterior then
		anterior:Destroy()
	end

	local colores = {
		piel = Base.color(def.piel, Color3.fromRGB(242, 201, 160)),
		camisa = Base.color(def.camisa, Color3.fromRGB(59, 130, 246)),
		pantalon = Base.color(def.pantalon, Color3.fromRGB(40, 48, 66)),
		raiz = Color3.new(1, 1, 1),
	}
	colores.manga = (def.mangas == "largas") and colores.camisa or colores.piel

	local pj = Instance.new("Model")
	pj.Name = nombre
	pj:SetAttribute("Estilo", nombreEstilo)
	pj:SetAttribute("Rigido", rigido)
	pj:SetAttribute("Cabeza", estilo.cabeza)
	pj:SetAttribute("RadioCabeza", estilo.radioCabeza)
	pj:SetAttribute("IdElenco", def.id or nombre)

	for _, p in estilo.partes do
		local forma, tam = p.forma, p.tam
		if p.nombre == estilo.cabeza and nombreEstilo == "propio" and def.cabeza == "bloque" then
			forma, tam = "bloque", v(2.1, 1.9, 1.9)
		end
		local pieza = Base.pieza({
			nombre = p.nombre, tam = tam, forma = forma, color = colores[p.zona],
			transparencia = (p.zona == "raiz") and 1 or 0, sombra = p.zona ~= "raiz",
			consultable = p.zona ~= "raiz",
			anclada = rigido or p.zona == "raiz",
		})
		if p.zona ~= "raiz" then
			pieza.Massless = true
		end
		if p.malla == "cabeza" then
			local malla = Instance.new("SpecialMesh")
			malla.MeshType = Enum.MeshType.Head
			malla.Scale = v(1.25, 1.25, 1.25)
			malla.Parent = pieza
			local calcomania = Instance.new("Decal")
			calcomania.Name = "face"
			calcomania.Face = Enum.NormalId.Front
			calcomania.Transparency = 1
			calcomania.Parent = pieza
		end
		pieza.Parent = pj
	end

	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = Instance.new("Motor6D")
		motor.Name = art.nombre
		motor.Part0 = parte(pj, art.p0)
		motor.Part1 = parte(pj, art.p1)
		motor.C0 = art.c0
		motor.C1 = art.c1
		motor:SetAttribute("C0Base", art.c0)
		motor:SetAttribute("Clave", clave)
		motor.Parent = parte(pj, art.en)
	end
	pj.PrimaryPart = parte(pj, estilo.raiz)

	local cabeza = parte(pj, estilo.cabeza)
	local cara = estilo.cara
	local adelante = cara.adelante
	if nombreEstilo == "propio" and def.cabeza == "bloque" then
		adelante = 0.97
	end
	cabeza:SetAttribute("CaraAncho", cara.ancho)
	cabeza:SetAttribute("CaraAlto", cara.alto)
	cabeza:SetAttribute("CaraAdelante", adelante)
	cabeza:SetAttribute("CaraSubir", cara.subir)

	local pelo = def.pelo or {}
	local tipoPelo = (typeof(pelo) == "string") and pelo or pelo.tipo or "corto"
	local colorPelo = Base.color((typeof(pelo) == "table") and pelo.color or nil, Color3.fromRGB(75, 46, 26))
	local r = estilo.radioCabeza
	for _, m in PELOS[tipoPelo] or PELOS.corto do
		local pieza = Base.pieza({
			nombre = "Pelo" .. m.n, tam = Base.vec(m.tam) * r, forma = m.forma, color = colorPelo,
			consultable = false,
		})
		pegar(pj, cabeza, pieza, CFrame.new(Base.vec(m.pos) * r), rigido)
	end

	if nombreEstilo == "r6" then
		local humanoide = Instance.new("Humanoid")
		humanoide.RigType = Enum.HumanoidRigType.R6
		humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoide.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoide.RequiresNeck = false
		humanoide.BreakJointsOnDeath = false
		humanoide.EvaluateStateMachine = false
		humanoide.Parent = pj
		local cuerpo = Instance.new("BodyColors")
		cuerpo.HeadColor3 = colores.piel
		cuerpo.TorsoColor3 = colores.camisa
		cuerpo.LeftArmColor3 = colores.manga
		cuerpo.RightArmColor3 = colores.manga
		cuerpo.LeftLegColor3 = colores.pantalon
		cuerpo.RightLegColor3 = colores.pantalon
		cuerpo.Parent = pj
		if (def.camisa_id or 0) ~= 0 then
			local camisa = Instance.new("Shirt")
			camisa.ShirtTemplate = "rbxassetid://" .. tostring(def.camisa_id)
			camisa.Parent = pj
		end
		if (def.pantalon_id or 0) ~= 0 then
			local pantalon = Instance.new("Pants")
			pantalon.PantsTemplate = "rbxassetid://" .. tostring(def.pantalon_id)
			pantalon.Parent = pj
		end
	end

	pj.Parent = padre
	Elenco.posar(pj, "de_pie")
	Elenco.ubicar(pj, CFrame.new(Base.vec(def.pos)))
	Caras.aplicar(pj, def.cara or "neutra")
	Elenco.actualizar(pj)

	if nombreEstilo == "r6" then
		for _, id in def.accesorios or {} do
			if id ~= 0 then
				Elenco.accesorio(pj, id)
			end
		end
	end
	return pj
end

-- Inserta un accesorio del catálogo por id (solo estilo "r6"). Devuelve éxito y mensaje.
function Elenco.accesorio(pj: Model, id: number): (boolean, string?)
	local humanoide = pj:FindFirstChildOfClass("Humanoid")
	if not humanoide then
		return false, "los accesorios por id solo aplican al estilo r6"
	end
	local ok, resultado = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not ok or not resultado then
		return false, "no se pudo cargar el recurso " .. tostring(id) .. ": " .. tostring(resultado)
	end
	local accesorio = resultado:FindFirstChildWhichIsA("Accessory", true)
	if not accesorio then
		resultado:Destroy()
		return false, "el recurso " .. tostring(id) .. " no trae un Accessory"
	end
	humanoide:AddAccessory(accesorio)
	resultado:Destroy()
	return true, nil
end

----------------------------------------------------------------------------------------
-- Poses y ubicación
----------------------------------------------------------------------------------------

-- Recalcula el CFrame de cada pieza a partir de los Motor6D (solo en modo rígido).
function Elenco.actualizar(pj: Model)
	if pj:GetAttribute("Rigido") ~= true then
		return
	end
	local estilo = estiloDe(pj)
	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = pj:FindFirstChild(art.nombre, true)
		if motor and motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			motor.Part1.CFrame = motor.Part0.CFrame * motor.C0 * motor.C1:Inverse()
		end
	end
	for _, d in pj:GetDescendants() do
		if d:IsA("BasePart") then
			local destino = d:GetAttribute("PegadoA")
			local rel = d:GetAttribute("Rel")
			if destino and rel then
				local ancla = pj:FindFirstChild(destino)
				if ancla and ancla:IsA("BasePart") then
					d.CFrame = ancla.CFrame * rel
				end
			end
		end
	end
end

-- Aplica una pose (nombre de Elenco.POSES o tabla). Devuelve un aviso si no existía.
function Elenco.posar(pj: Model, pose: any): string?
	local tabla, aviso = Elenco.resolverPose(pose)
	local estilo = estiloDe(pj)
	local subir = tabla.subir or 0
	if tabla.bajar == "sentado" then
		subir -= estilo.bajarSentado
	elseif tabla.bajar == "acostado" then
		subir -= estilo.bajarAcostado
	end
	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = pj:FindFirstChild(art.nombre, true)
		if motor and motor:IsA("Motor6D") then
			local base = motor:GetAttribute("C0Base")
			if typeof(base) ~= "CFrame" then
				base = motor.C0
				motor:SetAttribute("C0Base", base)
			end
			motor.C0 = Elenco.c0ConPose(base, tabla[clave], (clave == "raiz") and subir or 0)
		end
	end
	pj:SetAttribute("Pose", (typeof(pose) == "string") and pose or "personalizada")
	Elenco.actualizar(pj)
	return aviso
end

-- CFrame de pies: posición en el piso; `giro` en grados, 0 = mirando hacia +Z (la cámara),
-- positivo gira hacia +X.
function Elenco.cfPies(pos: any, giro: number?): CFrame
	return CFrame.new(Base.vec(pos)) * CFrame.Angles(0, math.rad(180 + (giro or 0)), 0)
end

-- Ubica al personaje con los pies en `cfPies` (posición y orientación).
function Elenco.ubicar(pj: Model, cfPies: CFrame)
	local estilo = estiloDe(pj)
	local destino = cfPies * CFrame.new(0, estilo.alturaRaiz, 0)
	if pj:GetAttribute("Rigido") == true then
		parte(pj, estilo.raiz).CFrame = destino
		Elenco.actualizar(pj)
	else
		pj:PivotTo(destino)
	end
end

function Elenco.pies(pj: Model): CFrame
	local estilo = estiloDe(pj)
	return parte(pj, estilo.raiz).CFrame * CFrame.new(0, -estilo.alturaRaiz, 0)
end

function Elenco.cabeza(pj: Model): BasePart
	return parte(pj, estiloDe(pj).cabeza)
end

function Elenco.parte(pj: Model, nombre: string): BasePart?
	local p = pj:FindFirstChild(nombre)
	return (p and p:IsA("BasePart")) and p or nil
end

-- CFrame de un punto útil del cuerpo para pegarle utilería: "mano_der", "mano_izq",
-- "cabeza_arriba" o "pecho". El eje -Z del resultado es el frente del personaje.
function Elenco.punto(pj: Model, nombre: string): CFrame?
	local estilo = estiloDe(pj)
	local art = estilo.articulaciones
	if nombre == "mano_der" or nombre == "mano_izq" then
		local brazo = parte(pj, (nombre == "mano_der") and art.hombroDer.p1 or art.hombroIzq.p1)
		return brazo.CFrame * CFrame.new(0, -brazo.Size.Y / 2, 0)
	elseif nombre == "cabeza_arriba" then
		local cabeza = parte(pj, estilo.cabeza)
		return cabeza.CFrame * CFrame.new(0, estilo.radioCabeza, 0)
	elseif nombre == "pecho" then
		local torso = parte(pj, estilo.torso)
		return torso.CFrame * CFrame.new(0, 0, -torso.Size.Z / 2)
	end
	local p = pj:FindFirstChild(nombre)
	return (p and p:IsA("BasePart")) and p.CFrame or nil
end

-- Gira al personaje sobre sus pies para que mire hacia un punto (ignora la altura).
function Elenco.mirarA(pj: Model, punto: Vector3)
	local pos = Elenco.pies(pj).Position
	local plano = Vector3.new(punto.X - pos.X, 0, punto.Z - pos.Z)
	if plano.Magnitude < 0.01 then
		return
	end
	Elenco.ubicar(pj, CFrame.lookAt(pos, pos + plano))
end

-- Sienta al personaje sobre un asiento: `cfAsiento` es el punto de apoyo (cara superior).
function Elenco.sentar(pj: Model, cfAsiento: CFrame)
	Elenco.posar(pj, "sentado")
	Elenco.ubicar(pj, cfAsiento)
end

function Elenco.cara(pj: Model, nombre: string): (string, string?)
	return Caras.aplicar(pj, nombre)
end

function Elenco.ocultar(pj: Model)
	Base.mover(pj, Base.bodega())
end

function Elenco.mostrar(pj: Model)
	Base.mover(pj, Base.subcarpeta("Elenco"))
end

-- Fila de personajes, uno por pose, para revisar todas las poses en una captura.
function Elenco.muestrario(estilo: string?, origen: Vector3?): Model
	local raiz = Base.raiz()
	local viejo = raiz:FindFirstChild("MuestrarioPoses")
	if viejo then
		viejo:Destroy()
	end
	local modelo = Instance.new("Model")
	modelo.Name = "MuestrarioPoses"
	modelo.Parent = raiz
	local nombres = {}
	for nombre in Elenco.POSES do
		table.insert(nombres, nombre)
	end
	table.sort(nombres)
	local base = origen or Vector3.new(0, 0, 0)
	for i, nombre in nombres do
		local col, fila = (i - 1) % 7, math.floor((i - 1) / 7)
		local pj = Elenco.crear({ id = "pose_" .. nombre, estilo = estilo, padre = modelo, cara = "feliz" })
		Elenco.posar(pj, nombre)
		Elenco.ubicar(pj, Elenco.cfPies(base + Vector3.new((col - 3) * 5, 0, -fila * 7), 0))
	end
	return modelo
end

return Elenco
end

__fabricas["Luz"] = function(script: any, require: any): any
-- Luz.luau
-- Preajustes de iluminación aplicables y reversibles: propiedades de Lighting más Atmosphere
-- y efectos de posproceso (Bloom, ColorCorrection, DepthOfField, SunRays).
--
-- Reversibilidad: la primera vez que se aplica un preajuste se guardan los valores
-- originales de Lighting como atributos (prefijo "HR_"), los efectos que ya existían se
-- apagan (los que tienen Enabled) o se mueven a la carpeta Lighting.Historias_Respaldo (la
-- Atmosphere, que no tiene Enabled). Luz.revertir() deja todo como estaba.
--
-- Los números son valores de partida propuestos, no recetas oficiales: se ajustan mirando
-- capturas (el informe investigacion/studio-mcp-y-paralelismo.md, sección 6, trae otra tabla).
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- comprobó que cada preajuste asigna solo propiedades existentes con el tipo correcto y que
-- aplicar seguido de revertir restaura los valores originales.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: el aspecto de cada preajuste; que
-- ColorCorrectionEffect.Brightness = 1 deje la pantalla blanca (la referencia lo afirma);
-- que LightingStyle se pueda escribir desde execute_luau.

local Lighting = game:GetService("Lighting")

local Base = require(script.Parent.Base)

local Luz = {}

local PROPIEDADES = {
	"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "GeographicLatitude", "ColorShift_Top",
	"ColorShift_Bottom", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
	"ExposureCompensation", "ShadowSoftness", "GlobalShadows", "LightingStyle",
	"PrioritizeLightingQuality",
}
local PREFIJO = "Historias_"
local RESPALDO = "Historias_Respaldo"

-- Cada preajuste: `luz` (propiedades de Lighting), `atm` (Atmosphere), `bloom`
-- {Intensity, Size, Threshold}, `color` {Brightness, Contrast, Saturation, TintColor},
-- `foco` {FarIntensity, FocusDistance, InFocusRadius, NearIntensity}, `rayos` {Intensity, Spread}.
Luz.PREAJUSTES = {
	atardecer = {
		luz = { ClockTime = 17.5, GeographicLatitude = 35, Brightness = 3, Ambient = "#50423A", OutdoorAmbient = "#806C5C",
			ColorShift_Top = "#FFC48C", ExposureCompensation = 0.2, ShadowSoftness = 0.15 },
		atm = { Density = 0.3, Offset = 0.25, Color = "#D7B996", Decay = "#966040", Glare = 0.5, Haze = 1.8 },
		bloom = { 0.6, 24, 1.5 }, color = { 0.02, 0.15, 0.15, "#FFEEDC" }, rayos = { 0.12, 0.6 },
		foco = { 0.2, 30, 20, 0 },
	},
	dia_claro = {
		luz = { ClockTime = 13.5, GeographicLatitude = 35, Brightness = 3, Ambient = "#565A60", OutdoorAmbient = "#868A90",
			ColorShift_Top = "#FFF6E6", ExposureCompensation = 0.1, ShadowSoftness = 0.2 },
		atm = { Density = 0.28, Offset = 0.25, Color = "#C7DCF0", Decay = "#6A7080", Glare = 0, Haze = 0.4 },
		bloom = { 0.5, 24, 1.7 }, color = { 0, 0.08, 0.12, "#FFFFFF" }, rayos = { 0.05, 0.6 },
		foco = { 0.15, 30, 25, 0 },
	},
	noche_azul = {
		luz = { ClockTime = 0.5, GeographicLatitude = 35, Brightness = 1.8, Ambient = "#4A5488", OutdoorAmbient = "#56609A",
			ColorShift_Top = "#6E82FF", ExposureCompensation = 0.45, ShadowSoftness = 0.4 },
		atm = { Density = 0.35, Offset = 0, Color = "#28325A", Decay = "#141830", Glare = 0, Haze = 1 },
		bloom = { 0.9, 32, 1.1 }, color = { -0.02, 0.2, -0.1, "#CDD7FF" },
		foco = { 0.2, 30, 20, 0 },
	},
	nevado = {
		luz = { ClockTime = 10.5, GeographicLatitude = 50, Brightness = 2.2, Ambient = "#78808C", OutdoorAmbient = "#969EAA",
			ColorShift_Top = "#E6F0FF", ExposureCompensation = 0.3, ShadowSoftness = 0.5 },
		atm = { Density = 0.4, Offset = 0.1, Color = "#EBF0FA", Decay = "#C8D2E1", Glare = 0.1, Haze = 2.2 },
		bloom = { 0.4, 24, 1.8 }, color = { 0.03, 0.05, -0.15, "#EEF5FF" }, rayos = { 0.03, 0.5 },
		foco = { 0.2, 30, 20, 0 },
	},
	lluvia = {
		luz = { ClockTime = 13, GeographicLatitude = 35, Brightness = 1.4, Ambient = "#6C7684", OutdoorAmbient = "#8A94A4",
			ColorShift_Top = "#BEC8D7", ExposureCompensation = 0.15, ShadowSoftness = 0.8 },
		atm = { Density = 0.42, Offset = 0, Color = "#8E9CB4", Decay = "#566074", Glare = 0, Haze = 2.4 },
		bloom = { 0.4, 24, 1.8 }, color = { 0, 0.12, -0.08, "#D2E0F4" },
		foco = { 0.25, 30, 18, 0 },
	},
	niebla = {
		luz = { ClockTime = 8, GeographicLatitude = 35, Brightness = 1.6, Ambient = "#6A7078", OutdoorAmbient = "#8A9098",
			ColorShift_Top = "#E0E6EE", ExposureCompensation = 0.1, ShadowSoftness = 0.8 },
		atm = { Density = 0.62, Offset = 0, Color = "#D2D8E0", Decay = "#AEB6C0", Glare = 0, Haze = 3 },
		bloom = { 0.3, 24, 2 }, color = { 0.02, 0, -0.3, "#F0F4F8" },
		foco = { 0.3, 25, 15, 0 },
	},
	interior_calido = {
		luz = { ClockTime = 14, GeographicLatitude = 35, Brightness = 2, Ambient = "#8A7A6A", OutdoorAmbient = "#9A8A7A",
			ColorShift_Top = "#FFD9A8", ExposureCompensation = 0.1, ShadowSoftness = 0.3 },
		atm = { Density = 0.2, Offset = 0, Color = "#E6D2B8", Decay = "#8A7868", Glare = 0, Haze = 0 },
		bloom = { 0.5, 24, 1.6 }, color = { 0.02, 0.08, 0.1, "#FFF2E0" },
		foco = { 0.15, 25, 20, 0 },
	},
	interior_noche = {
		luz = { ClockTime = 0, GeographicLatitude = 35, Brightness = 1.6, Ambient = "#6A74A8", OutdoorAmbient = "#6A74A8",
			ColorShift_Top = "#7088FF", ExposureCompensation = 0.55, ShadowSoftness = 0.5 },
		atm = { Density = 0.25, Offset = 0, Color = "#20284A", Decay = "#101428", Glare = 0, Haze = 0 },
		bloom = { 0.8, 30, 1.0 }, color = { 0, 0.12, -0.05, "#C8D4FF" },
		foco = { 0.2, 25, 18, 0 },
	},
}

-- Preajuste sugerido según el clima del escenario y si es interior.
function Luz.sugerido(clima: string?, interior: boolean?): string
	local c = clima or "sol"
	if interior then
		return (c == "noche") and "interior_noche" or "interior_calido"
	end
	local mapa = { sol = "dia_claro", noche = "noche_azul", lluvia = "lluvia", nieve = "nevado", niebla = "niebla", atardecer = "atardecer" }
	return mapa[c] or "dia_claro"
end

local function efecto(clase: string, nombre: string): any
	local existente = Lighting:FindFirstChild(PREFIJO .. nombre)
	if existente then
		return existente
	end
	local nuevo = Instance.new(clase)
	nuevo.Name = PREFIJO .. nombre
	nuevo.Parent = Lighting
	return nuevo
end

-- Guarda el estado original y aparta los efectos ajenos (una sola vez).
local function respaldar()
	if Lighting:GetAttribute("HR_Guardado") == true then
		return
	end
	local L: any = Lighting
	for _, propiedad in PROPIEDADES do
		local ok, valor = pcall(function()
			return L[propiedad]
		end)
		if ok and valor ~= nil then
			-- Protegido: no todos los tipos de valor se pueden guardar como atributo.
			pcall(function()
				Lighting:SetAttribute("HR_" .. propiedad, valor)
			end)
		end
	end
	local carpeta = Base.carpeta(Lighting, RESPALDO)
	for _, hijo in Lighting:GetChildren() do
		if string.sub(hijo.Name, 1, #PREFIJO) ~= PREFIJO then
			if hijo:IsA("Atmosphere") then
				hijo.Parent = carpeta
			elseif hijo:IsA("PostEffect") and hijo.Enabled then
				hijo.Enabled = false
				hijo:SetAttribute("HR_Apagado", true)
			end
		end
	end
	Lighting:SetAttribute("HR_Guardado", true)
end

local function valorDe(propiedad: string, valor: any): any
	if typeof(valor) == "string" and string.sub(valor, 1, 1) == "#" then
		return Base.color(valor)
	end
	return valor
end

-- Aplica un preajuste por nombre. Devuelve true, o false y un aviso si no existe.
function Luz.aplicar(nombre: string): (boolean, string?)
	local p = Luz.PREAJUSTES[Base.normalizar(nombre)]
	if not p then
		return false, "luz inexistente: " .. tostring(nombre)
	end
	respaldar()
	local L: any = Lighting
	L.GlobalShadows = true
	pcall(function()
		L.LightingStyle = Enum.LightingStyle.Realistic
		L.PrioritizeLightingQuality = true
	end)
	L.ColorShift_Bottom = Color3.new(0, 0, 0)
	for propiedad, valor in p.luz do
		L[propiedad] = valorDe(propiedad, valor)
	end
	local atm = efecto("Atmosphere", "Atmosfera")
	for propiedad, valor in p.atm do
		atm[propiedad] = valorDe(propiedad, valor)
	end
	local bloom = efecto("BloomEffect", "Bloom")
	bloom.Intensity, bloom.Size, bloom.Threshold = p.bloom[1], p.bloom[2], p.bloom[3]
	local color = efecto("ColorCorrectionEffect", "Color")
	color.Brightness, color.Contrast, color.Saturation = p.color[1], p.color[2], p.color[3]
	color.TintColor = Base.color(p.color[4])
	local foco = efecto("DepthOfFieldEffect", "Foco")
	foco.FarIntensity, foco.FocusDistance, foco.InFocusRadius, foco.NearIntensity = p.foco[1], p.foco[2], p.foco[3], p.foco[4]
	local rayos = efecto("SunRaysEffect", "Rayos")
	if p.rayos then
		rayos.Enabled = true
		rayos.Intensity, rayos.Spread = p.rayos[1], p.rayos[2]
	else
		rayos.Enabled = false
	end
	Lighting:SetAttribute("HR_Preajuste", Base.normalizar(nombre))
	return true, nil
end

function Luz.actual(): string?
	return Lighting:GetAttribute("HR_Preajuste")
end

-- Ajusta el enfoque del DepthOfField a la distancia entre la cámara y el objetivo.
function Luz.enfocar(distancia: number, radio: number?)
	local foco = Lighting:FindFirstChild(PREFIJO .. "Foco")
	if foco and foco:IsA("DepthOfFieldEffect") then
		foco.FocusDistance = distancia
		foco.InFocusRadius = radio or math.max(8, distancia * 0.6)
	end
end

-- Pantalla en blanco para el destello de sincronía (ColorCorrection con Brightness = 1).
function Luz.blanco(activo: boolean)
	local e = efecto("ColorCorrectionEffect", "Destello")
	e.Brightness = activo and 1 or 0
	e.Contrast = 0
	e.Saturation = activo and -1 or 0
	e.Enabled = activo
end

-- Tinte temporal para efectos del director (recuerdo en sepia, destello de color).
-- Con color nil se apaga.
function Luz.tinte(color: any?, brillo: number?, saturacion: number?)
	local e = efecto("ColorCorrectionEffect", "Efecto")
	if color == nil then
		e.Enabled = false
		return
	end
	e.Enabled = true
	e.TintColor = Base.color(color)
	e.Brightness = brillo or 0
	e.Saturation = saturacion or 0
	e.Contrast = 0
end

-- Deshace todo: borra los efectos de la biblioteca y restaura Lighting y los efectos ajenos.
function Luz.revertir()
	for _, hijo in Lighting:GetChildren() do
		if string.sub(hijo.Name, 1, #PREFIJO) == PREFIJO and hijo.Name ~= RESPALDO then
			hijo:Destroy()
		elseif hijo:GetAttribute("HR_Apagado") == true and hijo:IsA("PostEffect") then
			hijo.Enabled = true
			hijo:SetAttribute("HR_Apagado", nil)
		end
	end
	local carpeta = Lighting:FindFirstChild(RESPALDO)
	if carpeta then
		for _, hijo in carpeta:GetChildren() do
			hijo.Parent = Lighting
		end
		carpeta:Destroy()
	end
	if Lighting:GetAttribute("HR_Guardado") == true then
		local L: any = Lighting
		for _, propiedad in PROPIEDADES do
			local valor = Lighting:GetAttribute("HR_" .. propiedad)
			if valor ~= nil then
				pcall(function()
					L[propiedad] = valor
				end)
				Lighting:SetAttribute("HR_" .. propiedad, nil)
			end
		end
	end
	Lighting:SetAttribute("HR_Guardado", nil)
	Lighting:SetAttribute("HR_Preajuste", nil)
end

return Luz
end

__fabricas["Utileria"] = function(script: any, require: any): any
-- Utileria.luau
-- Utilería hecha con piezas básicas y parametrizable. Cada objeto es un Model con una pieza
-- invisible "Base" como PrimaryPart en su origen (centro de la base), de modo que
-- modelo:PivotTo(cf) lo ubica con exactitud. El frente del objeto mira hacia +Z local.
--
--   Utileria.crear(tipo, params, padre?) -> Model
--   Utileria.actualizar(modelo, params)  -> cambia en sitio lo que admite cambios
--                                           (batería: porcentaje y color; letrero: texto;
--                                           marcador: goles)
-- Tipos: bateria, letrero, raton, globos, balon, arco, marcador, celular, carta, flor, mesa,
-- silla, cajas (genérico a partir de una tabla) y los prefabricados de Utileria.PREFABRICADOS
-- (clavo, bolsa_papas, botella_salsa, calabaza, tazon_cereal, ajedrez, gorro_fiesta, boleta,
-- telarana), que son tablas para el generador genérico.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- crearon todos los tipos, se verificó el cálculo del relleno de la batería (ancho, posición,
-- color por umbral, mitades) y la validez de cada propiedad según el volcado oficial.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: el aspecto de cada objeto, el tamaño del texto de los
-- rótulos y que Model:ScaleTo escale bien estos modelos.

local Base = require(script.Parent.Base)

local Utileria = {}

local function nuevo(nombre: string): (Model, BasePart)
	local modelo = Instance.new("Model")
	modelo.Name = nombre
	local base = Base.pieza({ nombre = "Base", tam = Vector3.new(0.2, 0.2, 0.2), transparencia = 1, sombra = false, consultable = false })
	base.Parent = modelo
	modelo.PrimaryPart = base
	return modelo, base
end

-- Agrega una pieza al modelo; `pos` es relativa al origen del objeto.
local function agregar(modelo: Model, p: any): BasePart
	local rot = p.rot and Base.vec(p.rot) or Vector3.zero
	p.cf = CFrame.new(Base.vec(p.pos)) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
	p.padre = modelo
	return Base.pieza(p)
end

----------------------------------------------------------------------------------------
-- Batería (objeto estrella del guion 001)
----------------------------------------------------------------------------------------

Utileria.COLOR_BATERIA = { alto = "#2BD94E", medio = "#F2B01E", bajo = "#E5383B", vacio = "#3A4152" }

-- Color del relleno según el porcentaje (más de 50 verde, de 20 a 50 ámbar, menos de 20 rojo).
function Utileria.colorBateria(porcentaje: number): string
	if porcentaje > 50 then
		return Utileria.COLOR_BATERIA.alto
	elseif porcentaje >= 20 then
		return Utileria.COLOR_BATERIA.medio
	end
	return Utileria.COLOR_BATERIA.bajo
end

-- Geometría del relleno: devuelve ancho y centro en X (relativos al objeto) de una barra que
-- ocupa `porcentaje` del tramo [x0, x1] creciendo desde x0. Mínimo visible: 2 % del tramo.
function Utileria.rellenoBateria(porcentaje: number, x0: number, x1: number): (number, number)
	local f = math.clamp(porcentaje, 0, 100) / 100
	local ancho = math.max((x1 - x0) * f, (x1 - x0) * 0.02)
	return ancho, x0 + ancho / 2
end

local function texto(porcentaje: number): string
	return tostring(math.floor(porcentaje + 0.5)) .. "%"
end

local function crearBateria(p: any): Model
	local ancho, alto = p.ancho or 4, p.alto or 1.6
	local modelo, _ = nuevo(p.nombre or "Bateria")
	modelo:SetAttribute("Tipo", "bateria")
	modelo:SetAttribute("Ancho", ancho)
	modelo:SetAttribute("Alto", alto)
	modelo:SetAttribute("Mitades", p.mitades == true)
	local cy = alto / 2
	agregar(modelo, { nombre = "Marco", tam = { ancho, alto, 0.5 }, pos = { 0, cy, 0 }, color = "#1F2430" })
	agregar(modelo, { nombre = "Borne", tam = { 0.25, alto * 0.45, 0.4 }, pos = { ancho / 2 + 0.125, cy, 0 }, color = "#1F2430" })
	agregar(modelo, { nombre = "Fondo", tam = { ancho - 0.4, alto - 0.4, 0.56 }, pos = { 0, cy, 0 }, color = Utileria.COLOR_BATERIA.vacio })
	if p.mitades then
		agregar(modelo, { nombre = "RellenoIzq", tam = { 1, alto - 0.5, 0.62 }, pos = { 0, cy, 0 }, material = "Neon" })
		agregar(modelo, { nombre = "RellenoDer", tam = { 1, alto - 0.5, 0.62 }, pos = { 0, cy, 0 }, material = "Neon" })
		agregar(modelo, { nombre = "Division", tam = { 0.12, alto, 0.66 }, pos = { 0, cy, 0 }, color = "#1F2430" })
	else
		agregar(modelo, { nombre = "Relleno", tam = { 1, alto - 0.5, 0.62 }, pos = { 0, cy, 0 }, material = "Neon" })
	end
	if p.texto ~= false then
		local pantalla = agregar(modelo, { nombre = "Pantalla", tam = { ancho - 0.6, alto - 0.6, 0.66 }, pos = { 0, cy, 0 },
			transparencia = 1, sombra = false, consultable = false })
		-- Borde oscuro en el texto: sin él, el número blanco se pierde sobre el relleno ámbar.
		for _, etiqueta in {
			Base.rotulo(pantalla, Enum.NormalId.Back, "", "#FFFFFF", "RotuloFrente"),
			Base.rotulo(pantalla, Enum.NormalId.Front, "", "#FFFFFF", "RotuloAtras"),
		} do
			local borde = Instance.new("UIStroke")
			borde.Color = Color3.fromRGB(20, 24, 34)
			borde.Thickness = 5
			borde.Parent = etiqueta
		end
	end
	if p.telaranas then
		for _, lado in { -1, 1 } do
			agregar(modelo, { nombre = "Telarana", tam = { 0.9, 0.04, 0.9 }, pos = { lado * (ancho / 2 - 0.2), alto - 0.05, 0.1 },
				rot = { 0, 45, lado * 35 }, color = "#E8E8EE", transparencia = 0.45, sombra = false })
			agregar(modelo, { nombre = "Hilo", tam = { 0.03, 0.9, 0.03 }, pos = { lado * (ancho / 2 + 0.1), alto + 0.3, 0 },
				rot = { 0, 0, lado * 30 }, color = "#E8E8EE", transparencia = 0.3, sombra = false })
		end
	end
	-- Resplandor: la barra ilumina lo que tiene cerca con el color de su carga.
	local resplandor = Instance.new("PointLight")
	resplandor.Name = "Resplandor"
	resplandor.Range = 9
	resplandor.Brightness = 0.4
	resplandor.Shadows = false
	resplandor.Parent = modelo.PrimaryPart
	Utileria.actualizar(modelo, p)
	return modelo
end

local function actualizarBateria(modelo: Model, p: any)
	local base = modelo.PrimaryPart :: BasePart
	local ancho = modelo:GetAttribute("Ancho") or 4
	local alto = modelo:GetAttribute("Alto") or 1.6
	local cy = alto / 2
	local x0, x1 = -ancho / 2 + 0.25, ancho / 2 - 0.25
	local function poner(nombre: string, pct: number, desde: number, hasta: number, color: any?)
		local relleno = modelo:FindFirstChild(nombre) :: BasePart?
		if not relleno then
			return
		end
		local w, cx = Utileria.rellenoBateria(pct, desde, hasta)
		relleno.Size = Vector3.new(w, relleno.Size.Y, relleno.Size.Z)
		relleno.CFrame = base.CFrame * CFrame.new(cx, cy, 0)
		relleno.Color = Base.color(color or Utileria.colorBateria(pct))
		relleno.Transparency = (pct <= 0 or p.apagada) and 1 or 0
	end
	local pct = p.porcentaje or modelo:GetAttribute("Porcentaje") or 100
	modelo:SetAttribute("Porcentaje", pct)
	if modelo:GetAttribute("Mitades") == true then
		-- Mitad izquierda: `izq` (0 a 100) crece desde el centro hacia la izquierda.
		local izq, der = p.izq or pct, p.der or pct
		local wI, _ = Utileria.rellenoBateria(izq, 0, -x0)
		local rI = modelo:FindFirstChild("RellenoIzq") :: BasePart?
		if rI then
			rI.Size = Vector3.new(wI, rI.Size.Y, rI.Size.Z)
			rI.CFrame = base.CFrame * CFrame.new(-0.06 - wI / 2, cy, 0)
			rI.Color = Base.color(p.colorIzq or p.color or Utileria.colorBateria(izq))
			rI.Transparency = (izq <= 0 or p.apagada) and 1 or 0
		end
		poner("RellenoDer", der, 0.06, x1, p.colorDer or p.color)
	else
		poner("Relleno", pct, x0, x1, p.color)
	end
	local resplandor = base:FindFirstChild("Resplandor")
	if resplandor and resplandor:IsA("PointLight") then
		local color = p.color
		if not color then
			if modelo:GetAttribute("Mitades") == true then
				color = Utileria.colorBateria(math.max(p.izq or pct, p.der or pct))
			else
				color = Utileria.colorBateria(pct)
			end
		end
		resplandor.Color = Base.color(color)
		resplandor.Enabled = not p.apagada
	end
	local pantalla = modelo:FindFirstChild("Pantalla")
	if pantalla then
		local leyenda = (p.leyenda ~= nil) and tostring(p.leyenda) or texto(pct)
		for _, gui in pantalla:GetChildren() do
			local etiqueta = gui:FindFirstChild("Texto")
			if etiqueta and etiqueta:IsA("TextLabel") then
				etiqueta.Text = leyenda
			end
		end
	end
end

----------------------------------------------------------------------------------------
-- Objeto genérico de cajas
----------------------------------------------------------------------------------------

-- p.piezas = { { nombre, tam = {x,y,z}, pos = {x,y,z}, rot = {x,y,z}?, color, material?,
--               forma = "bloque"|"bola"|"cilindro"|"cuna"?, transparencia? }, ... }
local function crearCajas(p: any): Model
	local modelo, _ = nuevo(p.nombre or "Objeto")
	modelo:SetAttribute("Tipo", "cajas")
	for i, d in p.piezas or {} do
		agregar(modelo, {
			nombre = d.nombre or ("Pieza" .. i), tam = d.tam, pos = d.pos, rot = d.rot, color = d.color,
			material = d.material, forma = d.forma, transparencia = d.transparencia, sombra = d.sombra,
		})
	end
	return modelo
end

Utileria.PREFABRICADOS = {
	clavo = { piezas = {
		{ nombre = "Cuerpo", tam = { 0.35, 2.2, 0.35 }, pos = { 0, 1.1, 0 }, color = "#9AA0A8", material = "Metal", forma = "cilindro" },
		{ nombre = "Cabeza", tam = { 1, 0.2, 1 }, pos = { 0, 2.3, 0 }, color = "#B4BAC2", material = "Metal", forma = "cilindro" },
	} },
	bolsa_papas = { piezas = {
		{ nombre = "Bolsa", tam = { 1.3, 1.7, 0.5 }, pos = { 0, 0.85, 0 }, color = "#F2C230" },
		{ nombre = "Franja", tam = { 1.32, 0.5, 0.52 }, pos = { 0, 0.9, 0 }, color = "#D8342B" },
		{ nombre = "Sello", tam = { 1.4, 0.15, 0.2 }, pos = { 0, 1.75, 0 }, color = "#C9A21F" },
	} },
	botella_salsa = { piezas = {
		{ nombre = "Cuerpo", tam = { 0.8, 1.5, 0.8 }, pos = { 0, 0.75, 0 }, color = "#C8281E", forma = "cilindro" },
		{ nombre = "Cuello", tam = { 0.4, 0.5, 0.4 }, pos = { 0, 1.75, 0 }, color = "#C8281E", forma = "cilindro" },
		{ nombre = "Tapa", tam = { 0.5, 0.3, 0.5 }, pos = { 0, 2.1, 0 }, color = "#F4F4F4", forma = "cilindro" },
		{ nombre = "Etiqueta", tam = { 0.84, 0.6, 0.84 }, pos = { 0, 0.8, 0 }, color = "#FFE9A8", forma = "cilindro" },
	} },
	calabaza = { piezas = {
		{ nombre = "Cuerpo", tam = { 2, 1.7, 2 }, pos = { 0, 0.85, 0 }, color = "#F08A1C", forma = "bola" },
		{ nombre = "Tallo", tam = { 0.3, 0.5, 0.3 }, pos = { 0, 1.8, 0 }, color = "#4E7A2C", forma = "cilindro" },
		{ nombre = "OjoIzq", tam = { 0.35, 0.35, 0.1 }, pos = { -0.4, 1.05, 0.93 }, rot = { 0, 0, 45 }, color = "#2A1A08" },
		{ nombre = "OjoDer", tam = { 0.35, 0.35, 0.1 }, pos = { 0.4, 1.05, 0.93 }, rot = { 0, 0, 45 }, color = "#2A1A08" },
		{ nombre = "Boca", tam = { 0.9, 0.2, 0.1 }, pos = { 0, 0.55, 0.95 }, color = "#2A1A08" },
	} },
	tazon_cereal = { piezas = {
		{ nombre = "Tazon", tam = { 1.6, 0.7, 1.6 }, pos = { 0, 0.35, 0 }, color = "#E9EDF5", forma = "cilindro" },
		{ nombre = "Leche", tam = { 1.4, 0.1, 1.4 }, pos = { 0, 0.7, 0 }, color = "#FFFFFF", forma = "cilindro" },
		{ nombre = "Cereal1", tam = { 0.3, 0.12, 0.3 }, pos = { -0.3, 0.78, 0.2 }, color = "#E8A33C", forma = "cilindro" },
		{ nombre = "Cereal2", tam = { 0.3, 0.12, 0.3 }, pos = { 0.3, 0.78, -0.1 }, color = "#D94F4F", forma = "cilindro" },
		{ nombre = "Cuchara", tam = { 0.15, 0.08, 1.3 }, pos = { 0.5, 0.85, 0.5 }, rot = { 20, 30, 0 }, color = "#B4BAC2", material = "Metal" },
	} },
	ajedrez = { piezas = {
		{ nombre = "Tablero", tam = { 2.4, 0.15, 2.4 }, pos = { 0, 0.08, 0 }, color = "#E9D9B5" },
		{ nombre = "Casillas1", tam = { 1.2, 0.16, 1.2 }, pos = { -0.6, 0.08, -0.6 }, color = "#5A3A22" },
		{ nombre = "Casillas2", tam = { 1.2, 0.16, 1.2 }, pos = { 0.6, 0.08, 0.6 }, color = "#5A3A22" },
		{ nombre = "ReyBlanco", tam = { 0.3, 0.8, 0.3 }, pos = { -0.6, 0.55, 0.6 }, color = "#F4F4F4", forma = "cilindro" },
		{ nombre = "ReyNegro", tam = { 0.3, 0.8, 0.3 }, pos = { 0.6, 0.55, -0.6 }, color = "#222226", forma = "cilindro" },
		{ nombre = "PeonBlanco", tam = { 0.25, 0.5, 0.25 }, pos = { 0.2, 0.4, 0.8 }, color = "#F4F4F4", forma = "cilindro" },
		{ nombre = "PeonNegro", tam = { 0.25, 0.5, 0.25 }, pos = { -0.2, 0.4, -0.8 }, color = "#222226", forma = "cilindro" },
	} },
	gorro_fiesta = { piezas = {
		{ nombre = "Ala", tam = { 0.9, 0.4, 0.9 }, pos = { 0, 0.2, 0 }, color = "#E94F9B", forma = "cilindro" },
		{ nombre = "Medio", tam = { 0.6, 0.4, 0.6 }, pos = { 0, 0.6, 0 }, color = "#F2C230", forma = "cilindro" },
		{ nombre = "Punta", tam = { 0.3, 0.4, 0.3 }, pos = { 0, 1.0, 0 }, color = "#E94F9B", forma = "cilindro" },
		{ nombre = "Pompon", tam = { 0.3, 0.3, 0.3 }, pos = { 0, 1.3, 0 }, color = "#FFFFFF", forma = "bola" },
	} },
	boleta = { piezas = {
		{ nombre = "Papel", tam = { 1.2, 0.6, 0.05 }, pos = { 0, 0.3, 0 }, color = "#FFE9A8" },
		{ nombre = "Franja", tam = { 0.25, 0.6, 0.06 }, pos = { -0.4, 0.3, 0 }, color = "#3B82F6" },
	} },
	telarana = { piezas = {
		{ nombre = "Tela", tam = { 1.4, 0.04, 1.4 }, pos = { 0, 0, 0 }, rot = { 90, 0, 45 }, color = "#E8E8EE", transparencia = 0.5, sombra = false },
		{ nombre = "Hilo1", tam = { 0.04, 1.9, 0.04 }, pos = { 0, 0, 0 }, rot = { 0, 0, 45 }, color = "#F4F4F8", sombra = false },
		{ nombre = "Hilo2", tam = { 0.04, 1.9, 0.04 }, pos = { 0, 0, 0 }, rot = { 0, 0, -45 }, color = "#F4F4F8", sombra = false },
	} },
}

----------------------------------------------------------------------------------------
-- Resto de tipos
----------------------------------------------------------------------------------------

local CONSTRUCTORES: { [string]: (p: any) -> Model } = {}

CONSTRUCTORES.bateria = crearBateria
CONSTRUCTORES.cajas = crearCajas

function CONSTRUCTORES.letrero(p)
	local ancho, alto, poste = p.ancho or 8, p.alto or 3, p.alturaPoste or 4
	local modelo, _ = nuevo(p.nombre or "Letrero")
	modelo:SetAttribute("Tipo", "letrero")
	if p.poste ~= false then
		agregar(modelo, { nombre = "Poste", tam = { 0.5, poste, 0.5 }, pos = { 0, poste / 2, 0 }, color = "#6B4A2E", material = "Wood" })
	else
		poste = 0
	end
	local tabla = agregar(modelo, { nombre = "Tabla", tam = { ancho, alto, 0.4 }, pos = { 0, poste + alto / 2, 0 },
		rot = { 0, 0, p.torcido or 0 }, color = p.color or "#C89B5E", material = "WoodPlanks" })
	Base.rotulo(tabla, Enum.NormalId.Back, p.texto or "", p.colorTexto or "#2A1A08", "RotuloFrente")
	Base.rotulo(tabla, Enum.NormalId.Front, p.texto or "", p.colorTexto or "#2A1A08", "RotuloAtras")
	return modelo
end

function CONSTRUCTORES.raton(p)
	local t = p.tam or 1
	local gris = p.color or "#9A9AA2"
	local modelo, _ = nuevo(p.nombre or "Raton")
	modelo:SetAttribute("Tipo", "raton")
	agregar(modelo, { nombre = "Cuerpo", tam = { 1 * t, 0.8 * t, 1.5 * t }, pos = { 0, 0.4 * t, 0 }, color = gris })
	agregar(modelo, { nombre = "Cabeza", tam = { 0.8 * t, 0.7 * t, 0.7 * t }, pos = { 0, 0.55 * t, 1.0 * t }, color = gris })
	for _, lado in { -1, 1 } do
		agregar(modelo, { nombre = "Oreja", tam = { 0.4 * t, 0.4 * t, 0.12 * t }, pos = { lado * 0.35 * t, 1.0 * t, 0.9 * t }, color = p.orejas or "#F2A0B4" })
		agregar(modelo, { nombre = "Ojo", tam = { 0.12 * t, 0.12 * t, 0.06 * t }, pos = { lado * 0.2 * t, 0.65 * t, 1.36 * t }, color = "#1B1B1F" })
	end
	agregar(modelo, { nombre = "Nariz", tam = { 0.16 * t, 0.14 * t, 0.1 * t }, pos = { 0, 0.5 * t, 1.38 * t }, color = "#F2A0B4" })
	agregar(modelo, { nombre = "Cola", tam = { 0.1 * t, 0.1 * t, 1.1 * t }, pos = { 0, 0.3 * t, -1.2 * t }, rot = { 15, 0, 0 }, color = "#F2A0B4" })
	return modelo
end

function CONSTRUCTORES.globos(p)
	local colores = p.colores or { "#E5383B", "#3B82F6", "#F2C230", "#3CD070", "#E94F9B" }
	local modelo, _ = nuevo(p.nombre or "Globos")
	modelo:SetAttribute("Tipo", "globos")
	local n = p.cantidad or 3
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 1.1
		local alto = 4 + ((i * 7) % 3) * 0.6
		agregar(modelo, { nombre = "Globo" .. i, tam = { 1.3, 1.6, 1.3 }, pos = { x, alto, 0 }, forma = "bola", color = colores[(i - 1) % #colores + 1] })
		agregar(modelo, { nombre = "Hilo" .. i, tam = { 0.05, alto - 0.8, 0.05 }, pos = { x * 0.5, (alto - 0.8) / 2, 0 },
			rot = { 0, 0, -math.deg(math.atan2(x * 0.5, alto)) }, color = "#F4F4F4", sombra = false })
	end
	return modelo
end

function CONSTRUCTORES.balon(p)
	local r = p.radio or 1
	local modelo, _ = nuevo(p.nombre or "Balon")
	modelo:SetAttribute("Tipo", "balon")
	agregar(modelo, { nombre = "Esfera", tam = { 2 * r, 2 * r, 2 * r }, pos = { 0, r, 0 }, forma = "bola", color = "#F4F4F4" })
	local manchas = { { 0, 1, 0 }, { 0.9, 0.3, 0.3 }, { -0.9, 0.3, 0.3 }, { 0, 0.3, 0.95 }, { 0, 0.3, -0.95 }, { 0, -0.95, 0.2 } }
	for i, m in manchas do
		agregar(modelo, { nombre = "Mancha" .. i, tam = { 0.7 * r, 0.7 * r, 0.7 * r }, pos = { m[1] * r * 0.72, r + m[2] * r * 0.72, m[3] * r * 0.72 },
			forma = "bola", color = "#1B1B1F" })
	end
	return modelo
end

function CONSTRUCTORES.arco(p)
	local ancho, alto, fondo = p.ancho or 12, p.alto or 6, p.fondo or 3
	local modelo, _ = nuevo(p.nombre or "Arco")
	modelo:SetAttribute("Tipo", "arco")
	for _, lado in { -1, 1 } do
		agregar(modelo, { nombre = "Poste", tam = { 0.4, alto, 0.4 }, pos = { lado * ancho / 2, alto / 2, 0 }, color = "#F4F4F4" })
		agregar(modelo, { nombre = "RedLado", tam = { 0.08, alto, fondo }, pos = { lado * ancho / 2, alto / 2, -fondo / 2 }, color = "#FFFFFF", transparencia = 0.7, sombra = false })
	end
	agregar(modelo, { nombre = "Travesano", tam = { ancho + 0.4, 0.4, 0.4 }, pos = { 0, alto, 0 }, color = "#F4F4F4" })
	agregar(modelo, { nombre = "RedFondo", tam = { ancho, alto, 0.08 }, pos = { 0, alto / 2, -fondo }, color = "#FFFFFF", transparencia = 0.7, sombra = false })
	agregar(modelo, { nombre = "RedTecho", tam = { ancho, 0.08, fondo }, pos = { 0, alto, -fondo / 2 }, color = "#FFFFFF", transparencia = 0.7, sombra = false })
	return modelo
end

local function textoMarcador(p: any): string
	return tostring(p["local"] or 0) .. " - " .. tostring(p.visita or 0)
end

function CONSTRUCTORES.marcador(p)
	local modelo, _ = nuevo(p.nombre or "Marcador")
	modelo:SetAttribute("Tipo", "marcador")
	local alturaPoste = p.alturaPoste or 6
	for _, lado in { -1, 1 } do
		agregar(modelo, { nombre = "Poste", tam = { 0.5, alturaPoste, 0.5 }, pos = { lado * 3, alturaPoste / 2, 0 }, color = "#4A4F5A", material = "Metal" })
	end
	agregar(modelo, { nombre = "Caja", tam = { 9, 4.4, 0.8 }, pos = { 0, alturaPoste + 2.2, 0 }, color = "#1B1F2A" })
	local titulo = agregar(modelo, { nombre = "Titulo", tam = { 8.4, 1, 0.9 }, pos = { 0, alturaPoste + 3.6, 0 }, color = "#1B1F2A" })
	Base.rotulo(titulo, Enum.NormalId.Back, p.titulo or "HOME    GUEST", "#F4F4F4")
	local pantalla = agregar(modelo, { nombre = "Pantalla", tam = { 8.4, 2.6, 0.9 }, pos = { 0, alturaPoste + 1.7, 0 }, color = "#0E1118" })
	Base.rotulo(pantalla, Enum.NormalId.Back, textoMarcador(p), p.colorTexto or "#FF5A3C")
	return modelo
end

function CONSTRUCTORES.celular(p)
	local modelo, _ = nuevo(p.nombre or "Celular")
	modelo:SetAttribute("Tipo", "celular")
	agregar(modelo, { nombre = "Cuerpo", tam = { 0.6, 1.1, 0.1 }, pos = { 0, 0.55, 0 }, color = p.color or "#22252E" })
	agregar(modelo, { nombre = "Pantalla", tam = { 0.5, 0.95, 0.04 }, pos = { 0, 0.55, 0.05 }, color = p.pantalla or "#9AD0FF", material = "Neon" })
	return modelo
end

function CONSTRUCTORES.carta(p)
	local modelo, _ = nuevo(p.nombre or "Carta")
	modelo:SetAttribute("Tipo", "carta")
	agregar(modelo, { nombre = "Sobre", tam = { 1.6, 1, 0.08 }, pos = { 0, 0.5, 0 }, color = p.color or "#FAF6EA" })
	agregar(modelo, { nombre = "Solapa", tam = { 1.13, 1.13, 0.05 }, pos = { 0, 1, 0.045 }, rot = { 0, 0, 45 }, color = "#EDE6D2" })
	agregar(modelo, { nombre = "Sello", tam = { 0.3, 0.3, 0.05 }, pos = { 0, 0.55, 0.07 }, rot = { 0, 0, 45 }, color = p.sello or "#E8334A" })
	return modelo
end

function CONSTRUCTORES.flor(p)
	local modelo, _ = nuevo(p.nombre or "Flor")
	modelo:SetAttribute("Tipo", "flor")
	local alto = p.alto or 2
	agregar(modelo, { nombre = "Tallo", tam = { 0.15, alto, 0.15 }, pos = { 0, alto / 2, 0 }, color = "#3F8F3A", forma = "cilindro" })
	agregar(modelo, { nombre = "Hoja", tam = { 0.6, 0.1, 0.3 }, pos = { 0.3, alto * 0.45, 0 }, rot = { 0, 0, 25 }, color = "#4FA548" })
	agregar(modelo, { nombre = "Centro", tam = { 0.5, 0.5, 0.5 }, pos = { 0, alto + 0.1, 0 }, forma = "bola", color = "#F2C230" })
	for i = 0, 4 do
		local a = math.rad(i * 72)
		agregar(modelo, { nombre = "Petalo" .. (i + 1), tam = { 0.5, 0.5, 0.3 }, pos = { math.cos(a) * 0.42, alto + 0.1 + math.sin(a) * 0.42, 0 },
			forma = "bola", color = p.color or "#E94F9B" })
	end
	return modelo
end

function CONSTRUCTORES.mesa(p)
	local ancho, fondo, alto = p.ancho or 5, p.fondo or 3, p.alto or 2.6
	local modelo, _ = nuevo(p.nombre or "Mesa")
	modelo:SetAttribute("Tipo", "mesa")
	modelo:SetAttribute("AlturaApoyo", alto)
	agregar(modelo, { nombre = "Tablero", tam = { ancho, 0.3, fondo }, pos = { 0, alto - 0.15, 0 }, color = p.color or "#A9713F", material = "Wood" })
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			agregar(modelo, { nombre = "Pata", tam = { 0.3, alto - 0.3, 0.3 }, pos = { x * (ancho / 2 - 0.3), (alto - 0.3) / 2, z * (fondo / 2 - 0.3) },
				color = p.color or "#8A5A30", material = "Wood" })
		end
	end
	return modelo
end

function CONSTRUCTORES.silla(p)
	local alto = p.alto or 1.5
	local modelo, _ = nuevo(p.nombre or "Silla")
	modelo:SetAttribute("Tipo", "silla")
	modelo:SetAttribute("AlturaApoyo", alto)
	local color = p.color or "#8A5A30"
	agregar(modelo, { nombre = "Asiento", tam = { 1.8, 0.25, 1.8 }, pos = { 0, alto - 0.125, 0 }, color = color, material = "Wood" })
	agregar(modelo, { nombre = "Espaldar", tam = { 1.8, 2, 0.25 }, pos = { 0, alto + 1, -0.78 }, color = color, material = "Wood" })
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			agregar(modelo, { nombre = "Pata", tam = { 0.22, alto - 0.25, 0.22 }, pos = { x * 0.75, (alto - 0.25) / 2, z * 0.75 }, color = color, material = "Wood" })
		end
	end
	return modelo
end

Utileria.TIPOS = {} :: { [string]: boolean }
for nombre in CONSTRUCTORES do
	Utileria.TIPOS[nombre] = true
end
for nombre in Utileria.PREFABRICADOS do
	Utileria.TIPOS[nombre] = true
end

function Utileria.existe(tipo: any): boolean
	return typeof(tipo) == "string" and Utileria.TIPOS[Base.normalizar(tipo)] == true
end

-- Crea un objeto. `params.escala` aplica Model:ScaleTo; `params.nombre` fija el nombre.
-- Si el tipo no existe devuelve un cubo magenta visible y un aviso.
function Utileria.crear(tipo: string, params: any?, padre: Instance?): (Model, string?)
	local p = params or {}
	local clave = Base.normalizar(tipo)
	local modelo: Model
	local aviso: string? = nil
	if CONSTRUCTORES[clave] then
		modelo = CONSTRUCTORES[clave](p)
	elseif Utileria.PREFABRICADOS[clave] then
		modelo = crearCajas({ nombre = p.nombre or clave, piezas = Utileria.PREFABRICADOS[clave].piezas })
	else
		aviso = "utilería inexistente: " .. tostring(tipo)
		modelo = crearCajas({ nombre = p.nombre or "Desconocido", piezas = {
			{ nombre = "Cubo", tam = { 1, 1, 1 }, pos = { 0, 0.5, 0 }, color = "#FF00FF", material = "Neon" },
		} })
	end
	if typeof(p.escala) == "number" and p.escala ~= 1 then
		modelo:ScaleTo(p.escala)
	end
	modelo.Parent = padre or Base.subcarpeta("Utileria")
	return modelo, aviso
end

-- Cambia en sitio lo que el tipo permita. Devuelve true si hubo algo que actualizar.
function Utileria.actualizar(modelo: Model, params: any?): boolean
	local p = params or {}
	local tipo = modelo:GetAttribute("Tipo")
	if tipo == "bateria" then
		actualizarBateria(modelo, p)
		return true
	elseif tipo == "letrero" and p.texto ~= nil then
		for _, d in modelo:GetDescendants() do
			if d:IsA("TextLabel") then
				d.Text = tostring(p.texto)
			end
		end
		return true
	elseif tipo == "marcador" and (p["local"] ~= nil or p.visita ~= nil or p.leyenda ~= nil) then
		local pantalla = modelo:FindFirstChild("Pantalla")
		local etiqueta = pantalla and pantalla:FindFirstChild("Texto", true)
		if etiqueta and etiqueta:IsA("TextLabel") then
			etiqueta.Text = (p.leyenda ~= nil) and tostring(p.leyenda) or textoMarcador(p)
		end
		return true
	end
	return false
end

return Utileria
end

__fabricas["Escenarios"] = function(script: any, require: any): any
-- Escenarios.luau
-- Constructores por piezas de los escenarios base. Convenciones:
--   * Cada escenario vive en su propio Model dentro de workspace.Historias.Escenarios, en una
--     celda de la cuadrícula cerca del origen (Escenarios.origen(clave)), para que todos
--     convivan en un mismo lugar sin pisarse.
--   * El piso queda en y = 0 de la celda. El FRENTE del escenario es +Z: la cámara mira hacia
--     -Z y los personajes, por defecto, miran hacia +Z. Los interiores son "dioramas": piso,
--     pared del fondo y paredes laterales, sin techo ni pared frontal.
--   * Dos versiones: "gris" (solo cajas grises, para revisar posiciones) y "detalle".
--   * Carpeta Anclas: piezas invisibles con nombre. Las de personaje ("A", "B", "C", "centro",
--     "multitud_1"...) guardan posición de pies y hacia dónde mira; las de utilería (atributo
--     Tipo = "punto", por ejemplo "barra" o "mesa") guardan dónde se apoya un objeto.
--     Carpeta Camaras: "cam_general", "cam_izq", "cam_der", "cam_alta".
--   * Clima ("sol", "noche", "lluvia", "nieve", "niebla"): ParticleEmitter en la carpeta
--     Clima y, con Luz, la Atmosphere y el preajuste de iluminación correspondiente.
--
-- Claves: pueblo, parque, cuarto, sala, cocina, salon, pasillo, cafeteria, cancha, patio,
-- bosque, calle_noche.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- construyeron los 12 escenarios en ambas versiones y los 5 climas, y se verificó que cada
-- uno queda dentro de su celda, que tiene las anclas A, B, C, centro, multitud y cámaras, y
-- que todas las propiedades asignadas existen en el volcado oficial.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: el aspecto (colores, escala, composición), la
-- densidad y dirección de lluvia y nieve con la textura de partícula por defecto, y el costo
-- de construir cada escenario dentro de una sola llamada de execute_luau.

local Base = require(script.Parent.Base)
local Luz = require(script.Parent.Luz)

local Escenarios = {}

Escenarios.CLAVES = {
	"pueblo", "parque", "cuarto", "sala", "cocina", "salon", "pasillo", "cafeteria", "cancha", "patio",
	"bosque", "calle_noche",
}
Escenarios.CLIMAS = { sol = true, noche = true, lluvia = true, nieve = true, niebla = true }
Escenarios.CELDA = 160 -- separación entre escenarios (studs)
Escenarios.COLUMNAS = 4

-- Nombres del guion que apuntan a una clave.
Escenarios.ALIAS = {
	pueblo_de_dia = "pueblo", calle = "pueblo", calle_de_noche = "calle_noche", cuarto_de_noche = "cuarto",
	colegio = "salon", colegio_salon = "salon", colegio_pasillo = "pasillo", colegio_cafeteria = "cafeteria",
	cancha_con_lluvia = "cancha", cancha_de_futbol = "cancha", casa_del_arbol = "patio",
}

function Escenarios.resolver(nombre: any): string?
	if typeof(nombre) ~= "string" then
		return nil
	end
	local clave = Base.normalizar(nombre)
	clave = Escenarios.ALIAS[clave] or clave
	if table.find(Escenarios.CLAVES, clave) then
		return clave
	end
	return nil
end

-- Origen de la celda de un escenario (centro del piso).
function Escenarios.origen(clave: string): CFrame
	local i = (table.find(Escenarios.CLAVES, clave) or 1) - 1
	local col, fila = i % Escenarios.COLUMNAS, math.floor(i / Escenarios.COLUMNAS)
	local filas = math.ceil(#Escenarios.CLAVES / Escenarios.COLUMNAS)
	return CFrame.new(
		(col - (Escenarios.COLUMNAS - 1) / 2) * Escenarios.CELDA,
		0,
		(fila - (filas - 1) / 2) * Escenarios.CELDA
	)
end

----------------------------------------------------------------------------------------
-- Contexto de construcción
----------------------------------------------------------------------------------------

local function contexto(modelo: Model, origen: CFrame, gris: boolean): any
	local c: any = { modelo = modelo, origen = origen, d = not gris }
	local piezas = Base.carpeta(modelo, "Piezas")
	local anclas = Base.carpeta(modelo, "Anclas")
	local camaras = Base.carpeta(modelo, "Camaras")

	local function crear(nombre: string, tam: any, pos: any, color: any, material: any?, forma: string?, extra: any?): BasePart
		local e = extra or {}
		local rot = e.rot and Base.vec(e.rot) or Vector3.zero
		local col = Base.color(color)
		return Base.pieza({
			nombre = nombre, tam = tam, forma = forma,
			cf = origen * CFrame.new(Base.vec(pos)) * CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z)),
			color = gris and Base.gris(col) or col,
			material = (gris and e.material ~= "Neon") and "SmoothPlastic" or material,
			transparencia = e.transparencia, sombra = e.sombra, consultable = e.consultable,
			padre = e.padre or piezas,
		})
	end
	function c.caja(nombre, tam, pos, color, material, extra)
		return crear(nombre, tam, pos, color, material, "bloque", extra)
	end
	function c.bola(nombre, tam, pos, color, material, extra)
		return crear(nombre, tam, pos, color, material, "bola", extra)
	end
	function c.cil(nombre, tam, pos, color, material, extra)
		return crear(nombre, tam, pos, color, material, "cilindro", extra)
	end
	-- Ancla de personaje: pies en `pos`; giro 0 = mira a +Z (la cámara), positivo gira hacia +X.
	function c.ancla(nombre: string, pos: any, giro: number?)
		local p = Base.pieza({
			nombre = nombre, tam = Vector3.new(1.2, 0.2, 1.2),
			cf = origen * CFrame.new(Base.vec(pos)) * CFrame.Angles(0, math.rad(180 + (giro or 0)), 0),
			color = "#FF8A00", material = "Neon", transparencia = gris and 0.3 or 1, sombra = false, consultable = false,
		})
		p:SetAttribute("Tipo", "personaje")
		p.Parent = anclas
	end
	-- Punto de apoyo para utilería: el frente del objeto queda hacia +Z girado `giro` grados.
	function c.punto(nombre: string, pos: any, giro: number?)
		local p = Base.pieza({
			nombre = nombre, tam = Vector3.new(0.6, 0.6, 0.6),
			cf = origen * CFrame.new(Base.vec(pos)) * CFrame.Angles(0, math.rad(giro or 0), 0),
			color = "#00C2FF", material = "Neon", transparencia = gris and 0.3 or 1, sombra = false, consultable = false,
		})
		p:SetAttribute("Tipo", "punto")
		p.Parent = anclas
	end
	function c.cam(nombre: string, pos: any, mira: any?)
		local desde = origen * Base.vec(pos)
		local hacia = origen * Base.vec(mira or { 0, 4, 0 })
		local p = Base.pieza({
			nombre = nombre, tam = Vector3.new(1, 1, 1.6), cf = CFrame.lookAt(desde, hacia),
			color = "#B000FF", material = "Neon", transparencia = gris and 0.3 or 1, sombra = false, consultable = false,
		})
		p.Parent = camaras
	end
	-- Luz puntual dentro de una pieza. `soloNoche` la enciende solo con clima "noche".
	function c.luz(parte: BasePart, color: any, alcance: number, brillo: number, soloNoche: boolean?)
		local l = Instance.new("PointLight")
		l.Color = Base.color(color)
		l.Range = alcance
		l.Brightness = brillo
		l.Shadows = false
		l:SetAttribute("SoloNoche", soloNoche == true)
		l.Enabled = soloNoche ~= true
		l.Parent = parte
	end
	return c
end

-- Anclas comunes a todos los escenarios, centradas en (cx, z).
local function anclasBasicas(c: any, cx: number, z: number, distCam: number?)
	c.ancla("A", { cx - 3, 0, z }, 35)
	c.ancla("B", { cx + 3, 0, z }, -35)
	c.ancla("C", { cx, 0, z - 3.5 }, 0)
	c.ancla("centro", { cx, 0, z }, 0)
	c.punto("barra", { cx, 6.3, z }, 0)
	c.punto("suelo", { cx, 0, z + 2.5 }, 0)
	for i = 1, 8 do
		local col, fila = (i - 1) % 4, math.floor((i - 1) / 4)
		c.ancla("multitud_" .. i, { cx + (col - 1.5) * 4.2 + fila * 1.6, 0, z - 6 - fila * 4 }, (col - 1.5) * -8)
	end
	local dist = distCam or 34
	c.cam("cam_general", { cx, 7, z + dist }, { cx, 4, z })
	c.cam("cam_izq", { cx - dist * 0.6, 6, z + dist * 0.8 }, { cx, 4, z })
	c.cam("cam_der", { cx + dist * 0.6, 6, z + dist * 0.8 }, { cx, 4, z })
	c.cam("cam_alta", { cx, dist * 0.7, z + dist * 0.75 }, { cx, 2, z })
end

local function exterior(c: any, ancho: number, fondo: number, color: string, material: string)
	c.modelo:SetAttribute("Interior", false)
	c.modelo:SetAttribute("Ancho", ancho)
	c.modelo:SetAttribute("Fondo", fondo)
	c.caja("Suelo", { ancho, 1, fondo }, { 0, -0.5, 0 }, color, material)
end

local function interior(c: any, ancho: number, fondo: number, alto: number, piso: string, pared: string, materialPiso: string?)
	c.modelo:SetAttribute("Interior", true)
	c.modelo:SetAttribute("Ancho", ancho)
	c.modelo:SetAttribute("Fondo", fondo)
	c.caja("Piso", { ancho, 1, fondo }, { 0, -0.5, 0 }, piso, materialPiso or "WoodPlanks")
	c.caja("ParedFondo", { ancho, alto, 1 }, { 0, alto / 2, -fondo / 2 - 0.5 }, pared)
	c.caja("ParedIzq", { 1, alto, fondo }, { -ancho / 2 - 0.5, alto / 2, 0 }, pared)
	c.caja("ParedDer", { 1, alto, fondo }, { ancho / 2 + 0.5, alto / 2, 0 }, pared)
	if c.d then
		c.caja("Zocalo", { ancho, 0.6, 0.3 }, { 0, 0.3, -fondo / 2 + 0.15 }, "#F4F1EA")
	end
end

local function arbol(c: any, x: number, z: number, alto: number?, copa: number?, color: string?)
	local h, r = alto or 6, copa or 8
	c.cil("Tronco", { 1.6, h, 1.6 }, { x, h / 2, z }, "#7A5230", "Wood")
	c.bola("Copa", { r, r, r }, { x, h + r * 0.35, z }, color or "#4FA548", "Grass")
end

-- Casa de bloques con techo a dos aguas (una caja girada 45 grados y hundida en el cuerpo).
local function casa(c: any, x: number, z: number, ancho: number, alto: number, color: string)
	c.caja("Casa", { ancho, alto, 10 }, { x, alto / 2, z }, color)
	local lado = ancho / math.sqrt(2)
	c.caja("Techo", { lado, lado, 10.6 }, { x, alto, z }, "#B5523B", "Brick", { rot = { 0, 0, 45 } })
	if c.d then
		c.caja("Puerta", { 2.4, 4.6, 0.3 }, { x, 2.3, z + 5.05 }, "#6B4A2E", "Wood")
		c.caja("Ventana", { 2.4, 2.4, 0.3 }, { x - ancho / 2 + 2.2, 5.4, z + 5.05 }, "#BFE3FF", "Glass")
		c.caja("Ventana", { 2.4, 2.4, 0.3 }, { x + ancho / 2 - 2.2, 5.4, z + 5.05 }, "#BFE3FF", "Glass")
	end
end

local function mesa(c: any, nombre: string, x: number, z: number, ancho: number, fondo: number, alto: number, color: string)
	c.caja(nombre, { ancho, 0.4, fondo }, { x, alto - 0.2, z }, color, "Wood")
	for _, sx in { -1, 1 } do
		c.caja("Pata", { 0.4, alto - 0.4, fondo - 0.6 }, { x + sx * (ancho / 2 - 0.4), (alto - 0.4) / 2, z }, color, "Wood")
	end
end

----------------------------------------------------------------------------------------
-- Constructores
----------------------------------------------------------------------------------------

local CONSTRUCTORES: { [string]: (c: any) -> () } = {}

function CONSTRUCTORES.pueblo(c)
	exterior(c, 120, 90, "#6CBF5A", "Grass")
	c.caja("Anden", { 120, 0.3, 8 }, { 0, 0.15, 3 }, "#CFC9BC", "Concrete")
	c.caja("Calle", { 120, 0.2, 14 }, { 0, 0.1, 14 }, "#4A4D55", "Asphalt")
	local colores = { "#F28B82", "#FBD46D", "#8AB4F8", "#B7E1A1", "#D7AEFB" }
	for i = 1, 5 do
		casa(c, (i - 3) * 20, -14, 13, 9, colores[i])
	end
	for i = 1, 4 do
		arbol(c, (i - 2.5) * 20, -7)
	end
	if c.d then
		for i = -5, 5 do
			c.caja("Linea", { 4, 0.05, 0.5 }, { i * 10, 0.22, 14 }, "#F4F1EA")
		end
		for _, x in { -30, 30 } do
			local poste = c.cil("Farol", { 0.5, 9, 0.5 }, { x, 4.5, 7.5 }, "#3A3D45", "Metal")
			local foco = c.bola("Foco", { 1.2, 1.2, 1.2 }, { x, 9.4, 7.5 }, "#FFE9A8", "Neon")
			c.luz(foco, "#FFD9A0", 30, 2, true)
			poste.Name = "Farol"
		end
	end
	anclasBasicas(c, 0, 3)
	c.ancla("cruce_1", { -9, 0, 5 }, 90)
	c.ancla("cruce_2", { 9, 0, 5 }, -90)
	for i = 1, 4 do
		local x = (i - 2.5) * 13
		c.ancla("pareja_" .. i .. "a", { x - 2.2, 0, 1 }, 60)
		c.ancla("pareja_" .. i .. "b", { x + 2.2, 0, 1 }, -60)
		c.punto("barra_" .. i, { x, 6.3, 1 }, 0)
	end
end

function CONSTRUCTORES.parque(c)
	exterior(c, 110, 90, "#74C365", "Grass")
	c.caja("Camino", { 110, 0.2, 7 }, { 0, 0.1, 6 }, "#D9C7A0", "Sand")
	for _, p in { { -26, -10 }, { -12, -20 }, { 14, -12 }, { 30, -22 }, { 40, -6 }, { -40, -18 } } do
		arbol(c, p[1], p[2], 7, 9)
	end
	c.cil("Estanque", { 16, 0.2, 16 }, { 22, 0.1, -30 }, "#6FC3F2", "Glass")
	c.caja("Banco", { 7, 0.5, 2 }, { -12, 1.5, -4 }, "#A9713F", "Wood")
	c.caja("BancoEspaldar", { 7, 1.8, 0.4 }, { -12, 2.6, -4.9 }, "#A9713F", "Wood")
	c.caja("BancoPatas", { 6, 1.3, 1.4 }, { -12, 0.65, -4 }, "#5A5F6A", "Metal")
	if c.d then
		local flores = Base.azar(11)
		for i = 1, 18 do
			local x, z = (flores() - 0.5) * 90, -8 - flores() * 30
			c.bola("Flor", { 0.8, 0.8, 0.8 }, { x, 0.5, z }, ({ "#E94F9B", "#F2C230", "#FFFFFF" })[i % 3 + 1])
		end
		c.caja("Columpio", { 8, 0.4, 0.4 }, { -32, 7, -8 }, "#D8342B", "Metal")
		for _, sx in { -1, 1 } do
			c.caja("ColumpioPata", { 0.4, 7, 0.4 }, { -32 + sx * 4, 3.5, -8 }, "#D8342B", "Metal")
		end
	end
	anclasBasicas(c, 0, 2)
	c.ancla("banco_1", { -13.6, 1.75, -4 }, 0)
	c.ancla("banco_2", { -10.4, 1.75, -4 }, 0)
end

function CONSTRUCTORES.cuarto(c)
	interior(c, 34, 26, 14, "#C49A6C", "#A9C4E2")
	c.caja("CamaBase", { 8, 1.4, 12 }, { -11, 0.7, -6.5 }, "#8A5A30", "Wood")
	c.caja("Colchon", { 7.6, 0.8, 11.6 }, { -11, 1.8, -6.5 }, "#F4F1EA", "Fabric")
	c.caja("Cabecera", { 8, 4, 0.6 }, { -11, 2.4, -12.6 }, "#8A5A30", "Wood")
	mesa(c, "Escritorio", 10, -10.5, 7, 3, 2.8, "#B98B5E")
	c.caja("Armario", { 5, 9, 2.4 }, { 1, 4.5, -11.6 }, "#9C6B3F", "Wood")
	if c.d then
		c.caja("Almohada", { 5, 0.6, 2.4 }, { -11, 2.4, -11 }, "#DDE6F2", "Fabric")
		c.caja("Cobija", { 7.7, 0.3, 7 }, { -11, 2.3, -4.2 }, "#5B8DEF", "Fabric")
		c.caja("Tapete", { 12, 0.1, 8 }, { 2, 0.05, 1 }, "#E8B4B8", "Fabric")
		local ventana = c.caja("Ventana", { 6, 5, 0.3 }, { 11, 9, -12.9 }, "#CFE8FF", "Neon", { material = "Neon" })
		ventana.Transparency = 0.2
		local lampara = c.bola("Lampara", { 1.2, 1.2, 1.2 }, { 12.5, 3.6, -11 }, "#FFE9A8", "Neon", { material = "Neon" })
		c.luz(lampara, "#FFD9A0", 22, 1.6, true)
		c.caja("Silla", { 2, 0.3, 2 }, { 10, 1.5, -7.4 }, "#5A5F6A")
	end
	anclasBasicas(c, 2, 1, 28)
	c.ancla("cama", { -11, 2.2, -6 }, 0)
	c.ancla("cama_borde", { -11, 2.2, -1.2 }, 0)
	c.ancla("escritorio", { 10, 0, -7 }, 180)
	c.punto("escritorio_mesa", { 10, 2.8, -10.5 }, 0)
end

function CONSTRUCTORES.sala(c)
	interior(c, 36, 26, 14, "#B98B5E", "#E8D9C0")
	c.caja("Sofa", { 10, 1.6, 4 }, { -8, 0.8, -9 }, "#5B8DEF", "Fabric")
	c.caja("SofaEspaldar", { 10, 3, 1 }, { -8, 2.6, -10.6 }, "#4A7ADB", "Fabric")
	mesa(c, "MesaCentro", -8, -2, 6, 3, 1.4, "#8A5A30")
	c.caja("MuebleTV", { 8, 2, 2 }, { 9, 1, -11.6 }, "#3A3D45", "Wood")
	c.caja("TV", { 7, 4, 0.4 }, { 9, 4.4, -11.8 }, "#15171C")
	c.caja("MarcoPuerta", { 5, 9, 0.6 }, { 15, 4.5, -12.8 }, "#6B4A2E", "Wood")
	if c.d then
		c.caja("Tapete", { 14, 0.1, 9 }, { -6, 0.05, -2 }, "#D9A66B", "Fabric")
		c.caja("Cuadro", { 4, 3, 0.2 }, { -8, 9, -12.9 }, "#F2C230")
		local lampara = c.bola("Lampara", { 1.6, 1.6, 1.6 }, { -15, 7, -10 }, "#FFE9A8", "Neon", { material = "Neon" })
		c.cil("LamparaPie", { 0.3, 6.4, 0.3 }, { -15, 3.2, -10 }, "#3A3D45", "Metal")
		c.luz(lampara, "#FFD9A0", 26, 1.4, false)
	end
	anclasBasicas(c, 2, 1, 28)
	c.ancla("sofa_1", { -10.5, 1.6, -8.6 }, 0)
	c.ancla("sofa_2", { -5.5, 1.6, -8.6 }, 0)
	c.ancla("puerta", { 15, 0, -10.5 }, 0)
	c.punto("mesa", { -8, 1.4, -2 }, 0)
	c.punto("fiesta", { 6, 0, -7 }, 0)
end

function CONSTRUCTORES.cocina(c)
	interior(c, 34, 24, 14, "#E6E0D4", "#F2E3B3", "CeramicTiles")
	c.caja("Meson", { 22, 3.2, 2.6 }, { -4, 1.6, -10.7 }, "#F4F1EA", "Marble")
	c.caja("Gabinetes", { 22, 3, 1.6 }, { -4, 9.5, -11.2 }, "#A9713F", "Wood")
	c.caja("Nevera", { 4, 8.5, 3 }, { 12, 4.25, -10.5 }, "#DDE3EA", "Metal")
	c.caja("Estufa", { 4, 3.3, 2.6 }, { -13, 1.65, -10.7 }, "#3A3D45", "Metal")
	mesa(c, "Mesa", 0, -1, 7, 3.6, 2.6, "#B98B5E")
	c.caja("Silla", { 2, 0.3, 2 }, { 0, 1.5, -3.8 }, "#8A5A30", "Wood")
	if c.d then
		c.caja("Ventana", { 6, 4, 0.3 }, { -4, 6.2, -11.9 }, "#CFE8FF", "Glass")
		c.caja("SillaEspaldar", { 2, 2.4, 0.3 }, { 0, 2.8, -4.7 }, "#8A5A30", "Wood")
		c.caja("Grifo", { 0.3, 1, 0.3 }, { 2, 3.7, -11.2 }, "#B4BAC2", "Metal")
	end
	anclasBasicas(c, 0, 4, 28)
	c.ancla("silla_1", { 0, 1.5, -3.6 }, 0)
	c.punto("mesa", { 0, 2.6, -1 }, 0)
end

function CONSTRUCTORES.salon(c)
	interior(c, 40, 28, 14, "#D9C7A0", "#F2EBD9")
	c.caja("Tablero", { 18, 6, 0.3 }, { 0, 7, -13.8 }, "#2F6B4F")
	mesa(c, "EscritorioProfesor", -12, -9, 7, 3, 2.8, "#8A5A30")
	local n = 0
	for fila = 0, 1 do
		for col = -1, 1 do
			n += 1
			local x, z = col * 8, -3 + fila * 6
			mesa(c, "Pupitre", x, z, 4, 2.4, 2.4, "#C89B5E")
			c.caja("SillaPupitre", { 2, 0.3, 2 }, { x, 1.5, z - 2.4 }, "#5B8DEF")
			c.ancla("pupitre_" .. n, { x, 1.5, z - 2.2 }, 0)
			c.punto("pupitre_mesa_" .. n, { x, 2.4, z }, 0)
		end
	end
	if c.d then
		c.caja("MarcoTablero", { 18.6, 0.4, 0.5 }, { 0, 3.9, -13.6 }, "#8A5A30", "Wood")
		c.caja("Reloj", { 1.6, 1.6, 0.2 }, { 14, 11, -13.9 }, "#FFFFFF")
	end
	anclasBasicas(c, 0, 9, 26)
	c.ancla("profesor", { -12, 0, -6 }, 0)
end

function CONSTRUCTORES.pasillo(c)
	interior(c, 64, 18, 13, "#D8D2C4", "#EDE6D6", "CeramicTiles")
	local colores = { "#3B82F6", "#E5383B" }
	for i = -9, 9 do
		c.caja("Casillero", { 2.8, 7.5, 1.6 }, { i * 3, 3.75, -8.2 }, colores[(i % 2) + 1], "Metal")
	end
	if c.d then
		for i = -9, 9 do
			c.caja("Manija", { 0.2, 0.8, 0.2 }, { i * 3 + 0.9, 3.8, -7.3 }, "#D7DCE4", "Metal")
		end
		c.caja("Franja", { 64, 0.6, 0.2 }, { 0, 9.5, -8.9 }, "#F2C230")
		c.caja("PuertaAula", { 4.5, 8.5, 0.5 }, { 30, 4.25, -8.7 }, "#6B4A2E", "Wood")
	end
	anclasBasicas(c, 0, 0, 26)
	c.ancla("aparte", { -12, 0, 1 }, 60)
	for i = 1, 4 do
		c.ancla("grupo_" .. i, { 8 + ((i - 1) % 2) * 3.6, 0, -1 - math.floor((i - 1) / 2) * 3 }, (i % 2 == 1) and 70 or -70)
	end
end

function CONSTRUCTORES.cafeteria(c)
	interior(c, 46, 30, 14, "#E0D8C8", "#F6E7C1", "CeramicTiles")
	c.caja("Mostrador", { 26, 3.4, 3 }, { 0, 1.7, -12.5 }, "#B4BAC2", "Metal")
	for _, x in { -10, 10 } do
		mesa(c, "MesaLarga", x, -1, 11, 3.4, 2.6, "#C89B5E")
		c.caja("Banco", { 11, 0.4, 1.6 }, { x, 1.3, -3.9 }, "#8A5A30", "Wood")
		c.caja("Banco", { 11, 0.4, 1.6 }, { x, 1.3, 1.9 }, "#8A5A30", "Wood")
	end
	if c.d then
		c.caja("Menu", { 10, 3, 0.2 }, { 0, 9, -14.9 }, "#20242C")
		for i = -2, 2 do
			c.caja("Bandeja", { 2.4, 0.15, 1.6 }, { i * 4.6, 3.5, -12.3 }, ({ "#E5383B", "#F2C230", "#3CD070" })[(i % 3) + 1])
		end
	end
	anclasBasicas(c, -10, 5, 28)
	c.ancla("banco_1", { -12.5, 1.5, -3.7 }, 0)
	c.ancla("banco_2", { -7.5, 1.5, -3.7 }, 0)
	c.punto("mesa", { -10, 2.6, -1 }, 0)
	c.punto("mesa_frente", { -10, 2.6, 0.2 }, 0)
end

function CONSTRUCTORES.cancha(c)
	exterior(c, 130, 90, "#4FA548", "Grass")
	for i = 1, 3 do
		c.caja("Grada" .. i, { 70, 2, 4 }, { 0, i * 2 - 1, -24 - i * 4 }, "#B4BAC2", "Concrete")
		c.caja("GradaBase" .. i, { 70, i * 2 - 2 + 0.01, 4 }, { 0, (i * 2 - 2) / 2, -24 - i * 4 }, "#8A9099", "Concrete")
	end
	for _, sx in { -1, 1 } do
		local x = sx * 46
		c.caja("ArcoPoste", { 0.5, 7, 0.5 }, { x, 3.5, -7 }, "#F4F4F4")
		c.caja("ArcoPoste", { 0.5, 7, 0.5 }, { x, 3.5, 7 }, "#F4F4F4")
		c.caja("ArcoTravesano", { 0.5, 0.5, 14.5 }, { x, 7, 0 }, "#F4F4F4")
		c.caja("ArcoRed", { 0.1, 7, 14 }, { x + sx * 3, 3.5, 0 }, "#FFFFFF", nil, { transparencia = 0.7, sombra = false })
	end
	if c.d then
		c.caja("LineaCentral", { 0.5, 0.05, 60 }, { 0, 0.03, 0 }, "#FFFFFF")
		c.cil("CirculoCentral", { 16, 0.04, 16 }, { 0, 0.02, 0 }, "#58B050")
		for _, sz in { -1, 1 } do
			c.caja("LineaBanda", { 96, 0.05, 0.5 }, { 0, 0.03, sz * 30 }, "#FFFFFF")
		end
		for _, sx in { -1, 1 } do
			c.caja("LineaFondo", { 0.5, 0.05, 60 }, { sx * 48, 0.03, 0 }, "#FFFFFF")
		end
	end
	anclasBasicas(c, 0, 6, 40)
	for i = 1, 6 do
		local fila = (i - 1) % 3 + 1
		c.ancla("tribuna_" .. i, { (i - 3.5) * 5, fila * 2, -24 - fila * 4 }, 0)
	end
	c.ancla("tribuna", { 0, 2, -28 }, 0)
	c.ancla("tiro", { 26, 0, 4 }, -90)
	c.punto("balon", { 30, 0, 5 }, 0)
	c.punto("balon_lejos", { 52, 0, 26 }, 0)
	c.punto("marcador", { 0, 6, -42 }, 0)
	c.cam("cam_arco", { 20, 5, 22 }, { 44, 3, 0 })
	c.cam("cam_tribuna", { 0, 6, 0 }, { 0, 5, -30 })
end

function CONSTRUCTORES.patio(c)
	exterior(c, 100, 80, "#74C365", "Grass")
	c.caja("CercaFondo", { 100, 4, 0.6 }, { 0, 2, -30 }, "#C89B5E", "WoodPlanks")
	c.caja("PisoCasa", { 30, 0.3, 12 }, { -32, 0.15, -22 }, "#CFC9BC", "Concrete")
	c.caja("ParedCasa", { 30, 14, 1 }, { -32, 7, -28.4 }, "#F2E3B3")
	c.cil("TroncoGrande", { 3.6, 17, 3.6 }, { 12, 8.5, -12 }, "#7A5230", "Wood")
	c.bola("CopaGrande", { 22, 18, 22 }, { 12, 27, -12 }, "#3F9A45", "Grass")
	local casita = Instance.new("Model")
	casita.Name = "CasaDelArbol"
	casita.Parent = c.modelo
	local e = { padre = casita, rot = { 0, 0, 5 } }
	c.caja("Plataforma", { 10, 0.6, 9 }, { 12, 9, -10 }, "#B98B5E", "WoodPlanks", e)
	c.caja("ParedFondo", { 9, 5, 0.5 }, { 12.3, 11.8, -14 }, "#C89B5E", "WoodPlanks", e)
	c.caja("ParedIzq", { 0.5, 5, 8 }, { 7.9, 12.2, -10 }, "#C89B5E", "WoodPlanks", e)
	c.caja("ParedDer", { 0.5, 5, 8 }, { 16.7, 11.4, -10 }, "#C89B5E", "WoodPlanks", e)
	c.caja("Techo", { 11, 0.6, 10 }, { 12.5, 14.6, -10 }, "#B5523B", "WoodPlanks", { padre = casita, rot = { 0, 0, -6 } })
	c.caja("TablaClavo", { 4, 0.5, 1.2 }, { 12, 9.6, -5.2 }, "#D9B27C", "WoodPlanks", { padre = casita })
	for i = 0, 5 do
		c.caja("Peldano", { 2.4, 0.3, 0.4 }, { 6.4, 1.4 + i * 1.4, -8 }, "#8A5A30", "Wood", { padre = casita })
	end
	if c.d then
		for _, sx in { -1, 1 } do
			c.caja("Larguero", { 0.3, 9.4, 0.3 }, { 6.4 + sx * 1.1, 4.6, -8 }, "#8A5A30", "Wood", { padre = casita })
		end
		c.caja("VentanaCasa", { 5, 4, 0.3 }, { -32, 8, -27.8 }, "#BFE3FF", "Glass")
		arbol(c, 38, -22, 6, 8)
	end
	anclasBasicas(c, -6, 4, 36)
	c.punto("clavo", { 12, 9.85, -5.2 }, 0)
	c.punto("letrero", { 12, 11.4, -4.7 }, 0)
	c.ancla("bajo_arbol_1", { 5, 0, -3 }, 20)
	c.ancla("bajo_arbol_2", { 10, 0, -2 }, -20)
	c.cam("cam_casita", { 12, 12, 16 }, { 12, 12, -10 })
end

function CONSTRUCTORES.bosque(c)
	exterior(c, 110, 90, "#3F6B3A", "Grass")
	local azar = Base.azar(7)
	local puestos = 0
	while puestos < 42 do
		local x, z = (azar() - 0.5) * 100, (azar() - 0.5) * 80
		if not (math.abs(x) < 10 and z > -10) then
			puestos += 1
			local h = 8 + azar() * 6
			c.cil("Tronco", { 1.8, h, 1.8 }, { x, h / 2, z }, "#5A3E28", "Wood")
			c.bola("Copa", { 9, 11, 9 }, { x, h + 3, z }, (azar() > 0.5) and "#2F6B3A" or "#3A7A45", "Grass")
		end
	end
	if c.d then
		for i = 1, 10 do
			local x, z = (azar() - 0.5) * 60, (azar() - 0.5) * 40
			c.bola("Roca", { 2 + azar() * 2, 1.4, 2 + azar() * 2 }, { x, 0.5, z - 12 }, "#8A9099", "Slate")
			if i % 2 == 0 then
				c.bola("Arbusto", { 3, 2.2, 3 }, { x + 4, 1, z - 14 }, "#3F8F3A", "Grass")
			end
		end
	end
	anclasBasicas(c, 0, 3)
end

function CONSTRUCTORES.calle_noche(c)
	exterior(c, 120, 80, "#3A3D45", "Asphalt")
	c.caja("Anden", { 120, 0.4, 9 }, { 0, 0.2, 0 }, "#8A8F99", "Concrete")
	local altos = { 22, 16, 26, 18, 24, 15 }
	for i = 1, 6 do
		local x = (i - 3.5) * 19
		c.caja("Edificio", { 17, altos[i], 12 }, { x, altos[i] / 2, -12 }, ({ "#3B4252", "#434C5E", "#2E3440" })[i % 3 + 1], "Concrete")
		if c.d then
			for piso = 1, math.floor(altos[i] / 5) do
				for _, dx in { -4.5, 0, 4.5 } do
					local encendida = (i + piso + dx) % 3 ~= 0
					c.caja("VentanaEdificio", { 2.6, 2.6, 0.2 }, { x + dx, piso * 5 - 1, -5.9 }, encendida and "#FFD76A" or "#1F232D",
						encendida and "Neon" or nil, { material = encendida and "Neon" or nil })
				end
			end
		end
	end
	for _, x in { -24, 0, 24 } do
		c.cil("Farol", { 0.5, 11, 0.5 }, { x, 5.5, -3.6 }, "#20242C", "Metal")
		local foco = c.bola("Foco", { 1.4, 1.4, 1.4 }, { x, 11.2, -3.2 }, "#FFE9A8", "Neon", { material = "Neon" })
		c.luz(foco, "#FFD9A0", 34, 2.4, false)
	end
	if c.d then
		for i = -5, 5 do
			c.caja("Linea", { 4, 0.05, 0.5 }, { i * 10, 0.03, 16 }, "#C9C4B8")
		end
	end
	c.modelo:SetAttribute("ClimaInicial", "noche")
	anclasBasicas(c, 0, 1)
	c.ancla("cruce_1", { -9, 0, 2 }, 90)
	c.ancla("cruce_2", { 9, 0, 2 }, -90)
end

----------------------------------------------------------------------------------------
-- API
----------------------------------------------------------------------------------------

-- Busca un escenario ya construido (en workspace o en la bodega).
function Escenarios.buscar(clave: string): Model?
	local m = Base.subcarpeta("Escenarios"):FindFirstChild(clave) or Base.bodega():FindFirstChild(clave)
	return (m and m:IsA("Model")) and m or nil
end

-- Construye (o reconstruye) un escenario. opciones = { version = "gris" | "detalle",
-- clima = "sol" | ..., luz = false para no tocar Lighting, origen = CFrame propio }.
function Escenarios.construir(nombre: string, opciones: any?): (Model?, string?)
	local o = opciones or {}
	local clave = Escenarios.resolver(nombre)
	if not clave then
		return nil, "escenario inexistente: " .. tostring(nombre)
	end
	local anterior = Escenarios.buscar(clave)
	if anterior then
		anterior:Destroy()
	end
	local version = (o.version == "gris") and "gris" or "detalle"
	local origen = o.origen or Escenarios.origen(clave)
	local modelo = Instance.new("Model")
	modelo.Name = clave
	modelo:SetAttribute("Clave", clave)
	modelo:SetAttribute("Version", version)
	modelo:SetAttribute("Origen", origen)
	local c = contexto(modelo, origen, version == "gris")
	CONSTRUCTORES[clave](c)
	local suelo = modelo:FindFirstChild("Suelo", true) or modelo:FindFirstChild("Piso", true)
	if suelo and suelo:IsA("BasePart") then
		modelo.PrimaryPart = suelo
	end
	modelo.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	modelo.Parent = Base.subcarpeta("Escenarios")
	Escenarios.clima(modelo, o.clima or modelo:GetAttribute("ClimaInicial") or "sol", { luz = o.luz == true })
	return modelo, nil
end

-- CFrame de un ancla o punto por nombre, y su tipo ("personaje" | "punto" | "camara").
function Escenarios.ancla(modelo: Model, nombre: string): (CFrame?, string?)
	for _, carpeta in { "Anclas", "Camaras" } do
		local f = modelo:FindFirstChild(carpeta)
		local p = f and f:FindFirstChild(nombre)
		if p and p:IsA("BasePart") then
			return p.CFrame, (carpeta == "Camaras") and "camara" or p:GetAttribute("Tipo")
		end
	end
	return nil, nil
end

-- Lista ordenada de las anclas "multitud_N".
function Escenarios.multitud(modelo: Model): { CFrame }
	local lista = {}
	local i = 1
	while true do
		local cf = Escenarios.ancla(modelo, "multitud_" .. i)
		if not cf then
			break
		end
		table.insert(lista, cf)
		i += 1
	end
	return lista
end

function Escenarios.nombresDeAnclas(modelo: Model): { string }
	local nombres = {}
	for _, carpeta in { "Anclas", "Camaras" } do
		local f = modelo:FindFirstChild(carpeta)
		if f then
			for _, p in f:GetChildren() do
				table.insert(nombres, p.Name)
			end
		end
	end
	table.sort(nombres)
	return nombres
end

local function emisor(placa: BasePart, nombre: string): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = nombre
	e.EmissionDirection = Enum.NormalId.Bottom
	e.LightEmission = 0.2
	e.LightInfluence = 1
	e.Parent = placa
	return e
end

-- Cambia el clima de un escenario: partículas, nieve en el piso, luces nocturnas y, con
-- opciones.luz = true, el preajuste de Luz sugerido (que incluye la Atmosphere).
function Escenarios.clima(modelo: Model, clima: string, opciones: any?): string?
	local o = opciones or {}
	local c = Base.normalizar(clima)
	local aviso = nil
	if not Escenarios.CLIMAS[c] then
		aviso = "clima inexistente: " .. tostring(clima)
		c = "sol"
	end
	local viejo = modelo:FindFirstChild("Clima")
	if viejo then
		viejo:Destroy()
	end
	local carpeta = Instance.new("Folder")
	carpeta.Name = "Clima"
	local esInterior = modelo:GetAttribute("Interior") == true
	local origen: CFrame = modelo:GetAttribute("Origen") or CFrame.new()
	local ancho, fondo = modelo:GetAttribute("Ancho") or 100, modelo:GetAttribute("Fondo") or 80
	if (c == "lluvia" or c == "nieve") and not esInterior then
		local placa = Base.pieza({
			nombre = "Nube", tam = Vector3.new(ancho * 0.8, 1, fondo * 0.8), cf = origen * CFrame.new(0, 42, 0),
			transparencia = 1, sombra = false, consultable = false, padre = carpeta,
		})
		if c == "lluvia" then
			local e = emisor(placa, "Lluvia")
			e.Rate = 900
			e.Lifetime = NumberRange.new(0.6, 0.8)
			e.Speed = NumberRange.new(75, 90)
			e.SpreadAngle = Vector2.new(3, 3)
			e.Size = NumberSequence.new(0.35)
			-- Negativo: alarga la gota a lo largo de su velocidad. Con el valor positivo las
			-- rayas salían atravesadas (comprobado en Studio).
			e.Squash = NumberSequence.new(-2.4)
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
			e.Transparency = NumberSequence.new(0.45)
			e.Color = ColorSequence.new(Color3.fromRGB(200, 220, 245))
		else
			local e = emisor(placa, "Nieve")
			e.Rate = 220
			e.Lifetime = NumberRange.new(7, 9)
			e.Speed = NumberRange.new(5, 8)
			e.SpreadAngle = Vector2.new(12, 12)
			e.Size = NumberSequence.new(0.3)
			e.Acceleration = Vector3.new(0.8, 0, 0.4)
			e.Transparency = NumberSequence.new(0.1)
			e.Color = ColorSequence.new(Color3.new(1, 1, 1))
			Base.pieza({
				nombre = "NieveSuelo", tam = Vector3.new(ancho, 0.3, fondo), cf = origen * CFrame.new(0, 0.15, 0),
				color = "#F4F8FC", material = "Snow", padre = carpeta,
			})
		end
	end
	carpeta.Parent = modelo
	for _, d in modelo:GetDescendants() do
		if d:IsA("Light") and d:GetAttribute("SoloNoche") == true then
			d.Enabled = (c == "noche")
		end
	end
	modelo:SetAttribute("Clima", c)
	if o.luz == true then
		Luz.aplicar(Luz.sugerido(c, esInterior))
	end
	return aviso
end

-- Preajuste de luz que le corresponde al escenario con su clima actual.
function Escenarios.luzSugerida(modelo: Model): string
	return Luz.sugerido(modelo:GetAttribute("Clima"), modelo:GetAttribute("Interior") == true)
end

-- Deja un solo escenario visible en workspace y guarda los demás en la bodega.
function Escenarios.activar(clave: string): Model?
	local activo = Escenarios.buscar(clave)
	local carpeta = Base.subcarpeta("Escenarios")
	for _, m in carpeta:GetChildren() do
		if m ~= activo then
			m.Parent = Base.bodega()
		end
	end
	if activo then
		Base.mover(activo, carpeta)
	end
	return activo
end

-- Devuelve todos los escenarios guardados a workspace (para trabajar en modo edición).
function Escenarios.mostrarTodos()
	local carpeta = Base.subcarpeta("Escenarios")
	for _, m in Base.bodega():GetChildren() do
		if m:GetAttribute("Clave") ~= nil then
			m.Parent = carpeta
		end
	end
end

return Escenarios
end

__fabricas["Camara"] = function(script: any, require: any): any
-- Camara.luau
-- Encuadres G (general), M (medio) y C (cerca) calculados a partir del objetivo, movimientos
-- por plano, modo vertical y verificador de objetivo tapado.
--
-- MODO VERTICAL (convención de giro, para que el montaje la revierta):
--   La cámara se gira +90 grados alrededor de su eje de visión:
--       cf = CFrame.lookAt(posicion, objetivo) * CFrame.Angles(0, 0, math.rad(90))
--   Con ese giro, el "arriba" de la escena apunta hacia la DERECHA de la pantalla: la imagen
--   grabada en horizontal se ve girada 90 grados en sentido horario (la cabeza de un
--   personaje de pie queda a la derecha). El montaje la endereza girando la grabación 90
--   grados en sentido ANTIHORARIO: `montar.py --rotar antihorario`, que en ffmpeg equivale a
--   `-vf transpose=2` (o `transpose=cclock`). Una grabación de 1920 x 1080 queda de
--   1080 x 1920.
--   En este modo Camera.FieldOfView (vertical de la pantalla) pasa a ser el campo
--   HORIZONTAL del video final; el campo vertical final es mayor (se calcula con el aspecto).
--   Camara.GIRO_VERTICAL y Camara.ROTAR_MONTAJE exponen la convención.
--
-- INCLINACIÓN (dutch): grados extra de giro sobre el mismo eje. Un valor positivo hace que
-- el contenido se vea girado en sentido horario en el video final.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API
-- (CFrame y Raycast simulados) se verificó la distancia de encuadre contra la fórmula del
-- campo de visión, que el objetivo queda centrado, la dirección del giro vertical (el eje
-- derecho de la cámara queda apuntando al "arriba" del mundo), la continuidad de los
-- movimientos y el verificador de tapado con una pared interpuesta.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: que el encuadre se vea bien (márgenes), el sentido
-- real del giro en la grabación, y que workspace.CurrentCamera acepte CFrame y FieldOfView
-- en modo edición sin poner CameraType en Scriptable (execute_luau restaura CameraType al
-- terminar y screen_capture falla con Scriptable, por eso en edición no se toca).

local RunService = game:GetService("RunService")

local Base = require(script.Parent.Base)

local Camara = {}

Camara.FOV = 40 -- Camera.FieldOfView (grados, vertical de la pantalla)
Camara.ASPECTO = 16 / 9 -- ancho / alto de la pantalla que se graba
Camara.GIRO_VERTICAL = 90 -- grados de giro en modo vertical
Camara.ROTAR_MONTAJE = "antihorario" -- cómo debe girar el montaje la grabación (transpose=2)

Camara.TIPOS = { G = true, M = true, C = true }
Camara.MOVIMIENTOS = {
	fijo = true, acercar_lento = true, alejar_lento = true, acercar_brusco = true, paneo_der = true,
	paneo_izq = true, subir = true, temblor = true,
}
-- Direcciones con nombre: azimut (0 = de frente, desde +Z; positivo hacia +X) y elevación.
Camara.DESDE = {
	frente = { 0, 4 }, izq = { -30, 5 }, der = { 30, 5 }, alta = { 0, 35 }, picado = { 0, 25 },
	contrapicado = { 0, -12 }, perfil_izq = { -80, 3 }, perfil_der = { 80, 3 }, atras = { 180, 6 },
}

----------------------------------------------------------------------------------------
-- Cálculo puro
----------------------------------------------------------------------------------------

-- Campos de visión del VIDEO FINAL (vertical, horizontal) en radianes.
function Camara.campos(fov: number, aspecto: number, vertical: boolean): (number, number)
	local a = math.rad(fov)
	local b = 2 * math.atan(math.tan(a / 2) * aspecto)
	if vertical then
		return b, a
	end
	return a, b
end

-- Distancia a la que un rectángulo alto x ancho llena el cuadro final.
function Camara.distancia(alto: number, ancho: number, fov: number, aspecto: number, vertical: boolean): number
	local v, h = Camara.campos(fov, aspecto, vertical)
	return math.max((alto / 2) / math.tan(v / 2), (ancho / 2) / math.tan(h / 2))
end

-- Vector unitario desde el objetivo hacia la cámara.
function Camara.direccion(azimut: number, elevacion: number): Vector3
	local a, e = math.rad(azimut), math.rad(elevacion)
	return Vector3.new(math.sin(a) * math.cos(e), math.sin(e), math.cos(a) * math.cos(e))
end

type Objetivo = { centro: Vector3, alto: number, ancho: number, instancias: { Instance } }

local function esPersonaje(inst: Instance): boolean
	return inst:IsA("Model") and inst:GetAttribute("Cabeza") ~= nil
end

-- Caja de encuadre de UNA cosa según el tipo de plano. En video vertical casi siempre manda
-- el ANCHO: el cuadro es angosto, así que "C" encuadra el ancho de la cabeza y "M" un poco
-- más (cabeza y torso; los brazos pueden quedar cortados, como en cualquier plano medio).
local function cajaDe(cosa: any, tipo: string): (Vector3, number, number, Instance?)
	local t = typeof(cosa)
	if t == "Vector3" then
		local lado = (tipo == "C") and 3 or (tipo == "M") and 6 or 16
		return cosa, lado, lado, nil
	elseif t == "CFrame" then
		local lado = (tipo == "C") and 3 or (tipo == "M") and 6 or 16
		return cosa.Position, lado, lado, nil
	end
	if esPersonaje(cosa) then
		local cabeza = cosa:FindFirstChild(cosa:GetAttribute("Cabeza")) :: BasePart
		local raiz = cosa.PrimaryPart :: BasePart
		local c = cabeza.Position
		local r: number = cosa:GetAttribute("RadioCabeza") or cabeza.Size.Y / 2
		if tipo == "C" then
			return c + Vector3.new(0, r * 0.1, 0), r * 3.2, r * 2.5, cosa
		elseif tipo == "M" then
			-- De la cintura (centro de la raíz) a un poco por encima de la cabeza.
			local medio = (c.Y - raiz.Position.Y) * 0.55 + r * 1.25
			return c:Lerp(raiz.Position, 0.45), medio * 2.3, r * 3.3, cosa
		end
		return raiz.Position + Vector3.new(0, 1.6, 0), 15, 12, cosa
	end
	local centro: Vector3, tam: Vector3
	if cosa:IsA("Model") then
		local cf, s = cosa:GetBoundingBox()
		centro, tam = cf.Position, s
	else
		centro, tam = cosa.Position, cosa.Size
	end
	local factor = (tipo == "C") and 1.35 or (tipo == "M") and 2.2 or 4.5
	local minimo = (tipo == "C") and 1.2 or (tipo == "M") and 3 or 12
	return centro, math.max(tam.Y * factor, minimo), math.max(math.max(tam.X, tam.Z) * factor, minimo), cosa
end

-- Une una o varias cosas (personajes, modelos, piezas, Vector3, CFrame) en un objetivo.
function Camara.objetivo(cosas: any, tipo: string): Objetivo
	local lista = (typeof(cosas) == "table") and cosas or { cosas }
	local centros, instancias = {}, {}
	local suma = Vector3.zero
	local alto, ancho = 0, 0
	for _, cosa in lista do
		local c, h, w, inst = cajaDe(cosa, tipo)
		table.insert(centros, c)
		suma += c
		alto, ancho = math.max(alto, h), math.max(ancho, w)
		if inst then
			table.insert(instancias, inst)
		end
	end
	local n = math.max(#centros, 1)
	local centro = suma / n
	local dx, dy = 0, 0
	for _, c in centros do
		dx = math.max(dx, math.sqrt((c.X - centro.X) ^ 2 + (c.Z - centro.Z) ^ 2))
		dy = math.max(dy, math.abs(c.Y - centro.Y))
	end
	return { centro = centro, alto = alto + 2 * dy, ancho = ancho + 2 * dx, instancias = instancias }
end

type Estado = {
	centro: Vector3, alto: number, ancho: number, distancia: number, azimut: number, elevacion: number,
	fov: number, vertical: boolean, inclinacion: number, movimiento: string, duracion: number,
	fija: CFrame?, instancias: { Instance },
}

-- Arma el estado de cámara de un plano. opciones = { movimiento, inclinacion, desde (nombre de
-- Camara.DESDE), azimut, elevacion, fov, margen (1 = justo; mayor aleja), vertical, duracion,
-- fija (CFrame de un ancla de cámara: se usa tal cual, mirando al objetivo) }.
function Camara.encuadrar(obj: Objetivo, tipo: string, opciones: any?): Estado
	local o = opciones or {}
	local desde = Camara.DESDE[o.desde or "frente"] or Camara.DESDE.frente
	local fov = o.fov or Camara.FOV
	local vertical = o.vertical ~= false
	local margen = o.margen or 1.12
	return {
		centro = obj.centro, alto = obj.alto, ancho = obj.ancho,
		distancia = Camara.distancia(obj.alto, obj.ancho, fov, Camara.ASPECTO, vertical) * margen,
		azimut = o.azimut or desde[1], elevacion = o.elevacion or desde[2],
		fov = fov, vertical = vertical, inclinacion = o.inclinacion or 0,
		movimiento = Camara.MOVIMIENTOS[o.movimiento or "fijo"] and (o.movimiento or "fijo") or "fijo",
		duracion = math.max(o.duracion or 1, 0.05),
		fija = o.fija, instancias = obj.instancias,
	}
end

-- CFrame y campo de visión de la cámara en el instante t (segundos desde el inicio del plano).
function Camara.cframeEn(e: Estado, t: number): (CFrame, number)
	local u = math.clamp(t / e.duracion, 0, 1)
	local dist, centro = e.distancia, e.centro
	local dir = Camara.direccion(e.azimut, e.elevacion)
	local derecha = Vector3.new(0, 1, 0):Cross(dir).Unit
	local mov = e.movimiento
	if mov == "acercar_lento" then
		dist *= Base.mezcla(1.06, 0.94, u)
	elseif mov == "alejar_lento" then
		dist *= Base.mezcla(0.94, 1.06, u)
	elseif mov == "acercar_brusco" then
		local golpe = Base.suavizar(t / 0.16, "salida")
		dist *= Base.mezcla(1.35, 1, golpe) * Base.mezcla(1, 0.97, u)
	elseif mov == "paneo_der" or mov == "paneo_izq" then
		local sentido = (mov == "paneo_der") and 1 or -1
		centro += derecha * (sentido * e.ancho * 0.12 * (Base.suavizar(u, "entrada_salida") - 0.5))
	elseif mov == "subir" then
		centro += Vector3.new(0, e.alto * 0.12 * (Base.suavizar(u, "entrada_salida") - 0.5), 0)
	elseif mov == "temblor" then
		local a = e.alto * 0.012
		centro += derecha * (a * math.sin(t * 61)) + Vector3.new(0, a * math.sin(t * 47 + 1.3), 0)
	end
	local pos: Vector3
	if e.fija then
		pos = e.fija.Position + (centro - e.fija.Position).Unit * (e.distancia - dist) * 0.5
	else
		pos = centro + dir * dist
	end
	local giro = (e.vertical and Camara.GIRO_VERTICAL or 0) + e.inclinacion
	return CFrame.lookAt(pos, centro) * CFrame.Angles(0, 0, math.rad(giro)), e.fov
end

----------------------------------------------------------------------------------------
-- Aplicación y verificación
----------------------------------------------------------------------------------------

-- Escribe la cámara actual. Solo pone CameraType = Scriptable cuando el juego está corriendo
-- (en modo edición no hace falta y Studio lo restaura después de cada execute_luau).
function Camara.aplicar(cf: CFrame, fov: number, foco: Vector3?)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	if RunService:IsRunning() and cam.CameraType ~= Enum.CameraType.Scriptable then
		cam.CameraType = Enum.CameraType.Scriptable
	end
	cam.CFrame = cf
	cam.FieldOfView = fov
	if foco then
		cam.Focus = CFrame.new(foco)
	end
end

local guardado: { cf: CFrame, fov: number, tipo: EnumItem }? = nil

function Camara.guardar()
	local cam = workspace.CurrentCamera
	if cam and not guardado then
		guardado = { cf = cam.CFrame, fov = cam.FieldOfView, tipo = cam.CameraType }
	end
end

function Camara.restaurar()
	local cam = workspace.CurrentCamera
	if cam and guardado then
		cam.CameraType = guardado.tipo
		cam.CFrame = guardado.cf
		cam.FieldOfView = guardado.fov
	end
	guardado = nil
end

-- Avisa si entre la cámara y el objetivo hay una pieza visible que tapa. Lanza un rayo
-- hasta el centro del objetivo (y otro un poco más arriba), ignorando el propio objetivo y
-- las piezas transparentes. Devuelve tapado (boolean) y el nombre completo de lo que tapa.
function Camara.verificar(cf: CFrame, e: Estado | Objetivo, ignorar: { Instance }?): (boolean, string?)
	local excluir: { Instance } = {}
	for _, inst in (e :: any).instancias or {} do
		table.insert(excluir, inst)
	end
	for _, inst in ignorar or {} do
		table.insert(excluir, inst)
	end
	local origen = cf.Position
	local centro: Vector3 = (e :: any).centro
	local puntos = { centro, centro + Vector3.new(0, (e :: any).alto * 0.2, 0) }
	for _, punto in puntos do
		local tramo = punto - origen
		if tramo.Magnitude > 0.5 then
			local dir = tramo.Unit * (tramo.Magnitude - 0.3)
			for _ = 1, 12 do
				local golpe = workspace:Raycast(origen, dir, Base.rayo(excluir))
				if not golpe then
					break
				end
				local pieza = golpe.Instance
				if pieza:IsA("BasePart") and pieza.Transparency < 0.6 then
					return true, pieza:GetFullName()
				end
				table.insert(excluir, pieza)
			end
		end
	end
	return false, nil
end

return Camara
end

__fabricas["Director"] = function(script: any, require: any): any
-- Director.luau
-- Director de planos: lee el plan (tiempos del audio) y la puesta en escena, prepara todo y
-- ejecuta cada plano en su tiempo exacto.
--
-- ENTRADAS
--   plan.json   (lo produce la herramienta de Python de la voz):
--     {"video": "...", "duracion": 98.4, "planos": [{"n": 1, "inicio": 0.0, "fin": 1.62,
--      "texto": "...", "escenario": "...", "en_pantalla": "...", "cara": "...", "camara": "M"}]}
--   puesta.json (lo escribe el chat de Claude a partir del plan; esquema completo en
--     studio/README.md). Los tiempos del plan MANDAN: si un plano aparece en los dos archivos,
--     inicio, fin y texto salen del plan y la puesta aporta lo demás. Sin plan, se usan los
--     tiempos que traiga la puesta.
--
-- MODOS
--   Director.preparar(plan, puesta, opciones) -> ctx   construye o reutiliza todo
--   Director.foto(ctx, n, fraccion)       salta al plano n y lo deja quieto (para screen_capture)
--   Director.ensayo(ctx)                  recorre todos los planos y reporta problemas
--   Director.reproducir(ctx, opciones)    destello de sincronía y secuencia en tiempo real
--
-- DÓNDE Y CÓMO CORRE
--   * foto y ensayo: en modo EDICIÓN, llamados desde execute_luau con datamodel_type "Edit".
--     No ponen CameraType en Scriptable (Studio lo restaura tras cada llamada).
--   * reproducir, para grabar: modo JUEGO con cliente (Play, lo que inicia start_stop_play),
--     desde un LocalScript en StarterPlayer.StarterPlayerScripts (studio/empaque/
--     RodarCliente.client.luau). Motivo: la cámara Scriptable, ocultar la interfaz (CoreGui,
--     barra superior) y el paso de render (BindToRenderStep) solo existen en el cliente, y
--     los cambios que hace el cliente son locales y se descartan al detener.
--   * Alternativa sin jugador ni interfaz: modo Run con un Script en ServerScriptService
--     (studio/empaque/Rodar.server.luau). Ahí no hay cliente, así que el Director usa
--     Heartbeat. Queda por comprobar que la cámara de Studio obedezca en ese modo.
--   * La línea de comandos (o execute_luau en edición) NO sirve para grabar: el código corre
--     en el hilo principal y no está comprobado que una conexión siga viva al terminar la
--     llamada.
--
-- TIEMPO: no se encadena task.wait. En cada cuadro se mide t = os.clock() - t0 y se decide
-- qué plano toca; el error por plano es de un cuadro como máximo y no se acumula.
--
-- DESTELLO DE SINCRONÍA: tras una espera previa, la pantalla queda en blanco durante 2
-- cuadros (ColorCorrection con Brightness = 1 y, en el cliente, un Frame a pantalla completa).
-- El INSTANTE CERO es el primer cuadro NO blanco después del destello: ahí empieza el plano 1
-- y ahí se alinea el segundo 0 del audio en el montaje.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- ejecutaron preparar, foto, ensayo y reproducir completos sobre la puesta real del guion 001
-- (49 planos) con un reloj simulado: cada plano entra en el cuadro que le corresponde, el
-- destello dura exactamente 2 cuadros y el ensayo detecta planos cortos, objetivos tapados y
-- referencias inexistentes sembradas a propósito.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: todo lo visual; que require funcione desde
-- execute_luau; el costo real de cambiar de escenario en un cuadro; SetCore("TopbarEnabled");
-- la cámara en modo Run; la duración real del destello en la grabación.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Base = require(script.Parent.Base)
local Camara = require(script.Parent.Camara)
local Caras = require(script.Parent.Caras)
local Elenco = require(script.Parent.Elenco)
local Escenarios = require(script.Parent.Escenarios)
local Luz = require(script.Parent.Luz)
local Utileria = require(script.Parent.Utileria)

local Director = {}

Director.DURACION_MINIMA = 0.6 -- segundos; el ensayo avisa de los planos más cortos
Director.Base, Director.Camara, Director.Caras, Director.Elenco = Base, Camara, Caras, Elenco
Director.Escenarios, Director.Luz, Director.Utileria = Escenarios, Luz, Utileria

----------------------------------------------------------------------------------------
-- Datos: decodificar, combinar y validar (lógica pura)
----------------------------------------------------------------------------------------

local function decodificar(valor: any): any
	if typeof(valor) == "string" then
		return HttpService:JSONDecode(valor)
	end
	return valor
end

local function lista(valor: any): { any }
	if valor == nil then
		return {}
	elseif typeof(valor) == "table" and (#valor > 0 or next(valor) == nil) then
		return valor
	end
	return { valor }
end

-- Une plan y puesta en una sola lista de planos ordenada por inicio.
function Director.combinar(plan: any, puesta: any): (any, { string })
	local avisos: { string } = {}
	local pl, pu = decodificar(plan), decodificar(puesta) or {}
	local porNumero = {}
	for _, p in pu.planos or {} do
		porNumero[p.n] = p
	end
	local planos = {}
	local anterior: any = nil
	local fuente = (pl and pl.planos) or pu.planos or {}
	for _, t in fuente do
		local p = porNumero[t.n]
		if not p then
			table.insert(avisos, "plano " .. tostring(t.n) .. ": no tiene puesta; se repite la del plano anterior")
			p = anterior or {}
		end
		local nuevo = table.clone(p)
		nuevo.n = t.n
		nuevo.inicio = t.inicio or p.inicio or 0
		nuevo.fin = t.fin or p.fin or nuevo.inicio
		nuevo.texto = t.texto or p.texto or ""
		table.insert(planos, nuevo)
		anterior = p
		porNumero[t.n] = nil
	end
	for n in porNumero do
		table.insert(avisos, "plano " .. tostring(n) .. ": está en la puesta pero no en el plan; se omite")
	end
	table.sort(planos, function(a, b)
		return a.inicio < b.inicio
	end)
	local duracion = (pl and pl.duracion) or pu.duracion or 0
	for _, p in planos do
		duracion = math.max(duracion, p.fin)
	end
	return {
		video = (pl and pl.video) or pu.video or "sin_nombre",
		duracion = duracion,
		vertical = pu.vertical ~= false,
		estilo = pu.estilo,
		elenco = pu.elenco or {},
		predeterminados = pu.predeterminados or {},
		planos = planos,
	}, avisos
end

-- Índice del plano vigente en el instante t, avanzando desde `desde`.
function Director.indiceEn(planos: { any }, t: number, desde: number?): number
	local i = math.max(desde or 1, 1)
	while planos[i + 1] and t >= planos[i + 1].inicio do
		i += 1
	end
	return i
end

local EFECTOS: { [string]: any } = {}

-- Revisa que todo nombre usado exista en los catálogos. Devuelve la lista de problemas.
function Director.validar(datos: any): { string }
	local problemas: { string } = {}
	local function falta(p: any, texto: string)
		table.insert(problemas, "plano " .. tostring(p.n) .. ": " .. texto)
	end
	for _, p in datos.planos do
		if not Escenarios.resolver(p.escenario) then
			falta(p, "escenario inexistente: " .. tostring(p.escenario))
		end
		if p.clima and not Escenarios.CLIMAS[Base.normalizar(p.clima)] then
			falta(p, "clima inexistente: " .. tostring(p.clima))
		end
		if p.luz and not Luz.PREAJUSTES[Base.normalizar(p.luz)] then
			falta(p, "luz inexistente: " .. tostring(p.luz))
		end
		for _, pj in p.personajes or {} do
			if not datos.elenco[pj.id] then
				falta(p, "personaje inexistente: " .. tostring(pj.id))
			end
			if pj.pose and typeof(pj.pose) == "string" and not Elenco.POSES[Base.normalizar(pj.pose)] then
				falta(p, "pose inexistente: " .. pj.pose)
			end
			if pj.cara and not Caras.resolver(pj.cara) then
				falta(p, "cara inexistente: " .. tostring(pj.cara))
			end
		end
		for _, u in p.utileria or {} do
			if not Utileria.existe(u.tipo) then
				falta(p, "utilería inexistente: " .. tostring(u.tipo))
			end
		end
		local cam = p.camara or {}
		if cam.tipo and not Camara.TIPOS[cam.tipo] then
			falta(p, "tipo de cámara inexistente: " .. tostring(cam.tipo))
		end
		if cam.movimiento and not Camara.MOVIMIENTOS[cam.movimiento] then
			falta(p, "movimiento inexistente: " .. tostring(cam.movimiento))
		end
		if cam.desde and not Camara.DESDE[cam.desde] then
			falta(p, "dirección de cámara inexistente: " .. tostring(cam.desde))
		end
		for _, ef in lista(p.efecto) do
			local tipo = (typeof(ef) == "table") and ef.tipo or ef
			if not EFECTOS[tostring(tipo)] then
				falta(p, "efecto inexistente: " .. tostring(tipo))
			end
		end
	end
	return problemas
end

----------------------------------------------------------------------------------------
-- Preparación
----------------------------------------------------------------------------------------

local function ceder(ctx: any)
	-- execute_luau corre en el hilo principal de Studio: se cede entre tandas para no congelarlo.
	if ctx.opciones.ceder ~= false then
		task.wait()
	end
end

-- Construye o reutiliza escenarios, elenco y utilería. opciones = { version = "detalle" |
-- "gris", reconstruir = false, ceder = true, estilo = "propio" | "r6" }.
function Director.preparar(plan: any, puesta: any, opciones: any?): any
	local o = opciones or {}
	local datos, avisos = Director.combinar(plan, puesta)
	local ctx: any = {
		datos = datos, planos = datos.planos, duracion = datos.duracion, vertical = datos.vertical,
		opciones = o, escenas = {}, elenco = {}, utileria = {}, avisos = avisos, estado = nil,
	}
	for _, problema in Director.validar(datos) do
		table.insert(avisos, problema)
	end
	local version = o.version or "detalle"
	for _, p in ctx.planos do
		local clave = Escenarios.resolver(p.escenario)
		if clave and not ctx.escenas[clave] then
			local existente = Escenarios.buscar(clave)
			if existente and existente:GetAttribute("Version") == version and not o.reconstruir then
				ctx.escenas[clave] = existente
			else
				ctx.escenas[clave] = Escenarios.construir(clave, { version = version, luz = false })
				ceder(ctx)
			end
		end
	end
	local estilo = o.estilo or datos.estilo or Elenco.ESTILO_POR_DEFECTO
	local carpetaElenco = Base.subcarpeta("Elenco")
	for id, def in datos.elenco do
		local existente = carpetaElenco:FindFirstChild(id) or Base.bodega():FindFirstChild(id)
		if existente and existente:GetAttribute("Estilo") == (def.estilo or estilo) and not o.reconstruir then
			ctx.elenco[id] = existente
		else
			local d = table.clone(def)
			d.id, d.nombre, d.estilo = id, id, def.estilo or estilo
			ctx.elenco[id] = Elenco.crear(d)
		end
	end
	ceder(ctx)
	local carpetaUtil = Base.subcarpeta("Utileria")
	for _, p in ctx.planos do
		for _, u in p.utileria or {} do
			if u.id and not ctx.utileria[u.id] then
				local nombre = "util_" .. tostring(u.id)
				local viejo = carpetaUtil:FindFirstChild(nombre) or Base.bodega():FindFirstChild(nombre)
				if viejo then
					viejo:Destroy()
				end
				local params = table.clone(u.params or {})
				params.nombre = nombre
				ctx.utileria[u.id] = Utileria.crear(u.tipo or "cajas", params, carpetaUtil)
			end
		end
	end
	Base.marcar("Historias: preparar " .. tostring(datos.video))
	return ctx
end

----------------------------------------------------------------------------------------
-- Aplicar un plano
----------------------------------------------------------------------------------------

local MEDIA_VUELTA = CFrame.Angles(0, math.pi, 0)

-- CFrame de pies (personaje) a partir de { ancla, pos, giro, desplazar }.
local function ubicacion(escena: Model, spec: any, paraUtileria: boolean, avisos: { string }, quien: string): CFrame
	local origen: CFrame = escena:GetAttribute("Origen") or CFrame.new()
	local cf: CFrame
	if spec.pos then
		if paraUtileria then
			cf = origen * CFrame.new(Base.vec(spec.pos)) * CFrame.Angles(0, math.rad(spec.giro or 0), 0)
		else
			cf = origen * Elenco.cfPies(spec.pos, spec.giro)
		end
	else
		local nombre = spec.ancla or "centro"
		local hallado, tipo = Escenarios.ancla(escena, nombre)
		if not hallado then
			table.insert(avisos, quien .. ": ancla inexistente: " .. tostring(nombre))
			hallado, tipo = Escenarios.ancla(escena, "centro")
			hallado = hallado or origen
		end
		cf = hallado :: CFrame
		-- Las anclas de personaje miran con -Z; los puntos de utilería, con +Z.
		if (tipo == "punto") ~= paraUtileria then
			cf = cf * MEDIA_VUELTA
		end
		if spec.giro then
			local base = paraUtileria and spec.giro or (180 + spec.giro)
			cf = CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(base), 0)
		end
	end
	if spec.desplazar then
		cf = cf + Base.vec(spec.desplazar)
	end
	return cf
end

-- Convierte una referencia de la puesta en algo que Camara.objetivo entiende.
--   "narrador" (id del elenco) | "util:barra" | "ancla:centro" | "escena:CasaDelArbol"
local function referencia(ctx: any, escena: Model, ref: any): any?
	if typeof(ref) == "table" and typeof(ref[1]) == "number" then
		-- Punto [x, y, z] relativo al origen del escenario.
		local origen: CFrame = escena:GetAttribute("Origen") or CFrame.new()
		return origen * Base.vec(ref)
	end
	if typeof(ref) ~= "string" then
		return nil
	end
	local prefijo, resto = string.match(ref, "^(%a+):(.+)$")
	if prefijo == "util" then
		return ctx.utileria[resto]
	elseif prefijo == "ancla" then
		local cf = Escenarios.ancla(escena, resto)
		return cf and cf.Position or nil
	elseif prefijo == "escena" then
		return escena:FindFirstChild(resto, true)
	end
	return ctx.elenco[ref] or ctx.utileria[ref] or (Escenarios.ancla(escena, ref) and (Escenarios.ancla(escena, ref) :: CFrame).Position)
end

local function emisorDe(parte: Instance, nombre: string, color: any): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = nombre
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.5, 1.1)
	e.Speed = NumberRange.new(10, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.5, 0)
	e.LightEmission = 1
	e.Color = ColorSequence.new(Base.color(color))
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Parent = parte
	return e
end

local function basePara(ctx: any, escena: Model, ef: any): Instance?
	local destino = referencia(ctx, escena, ef.en)
	if typeof(destino) == "Instance" then
		if destino:IsA("Model") then
			return destino.PrimaryPart
		end
		return destino
	end
	return escena.PrimaryPart
end

-- Efectos por plano. Cada uno: iniciar(ctx, escena, ef) -> datos; cuadro(datos, t); terminar(datos).
EFECTOS.recuerdo = {
	iniciar = function()
		Luz.tinte("#E8D2B0", 0.02, -0.7)
		return {}
	end,
	terminar = function()
		Luz.tinte(nil)
	end,
}
EFECTOS.destello_verde = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoDestello", "#6CFF9A")
		if e then
			e.Speed = NumberRange.new(25, 50)
			e:Emit(80)
		end
		return { emisor = e }
	end,
	cuadro = function(d, t)
		local k = math.max(0, 1 - t / 0.7)
		Luz.tinte(Color3.new(1, 1, 1):Lerp(Color3.fromRGB(120, 255, 160), k), 0.5 * k, 0)
	end,
	terminar = function(d)
		Luz.tinte(nil)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.chispas = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoChispas", "#FFD84D")
		if e then
			e:Emit(30)
		end
		return { emisor = e, ultimo = 0 }
	end,
	cuadro = function(d, t)
		if d.emisor and t - d.ultimo >= 0.25 then
			d.ultimo = t
			d.emisor:Emit(14)
		end
	end,
	terminar = function(d)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.confeti = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoConfeti", "#FFFFFF")
		if e then
			e.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(229, 56, 59)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(242, 194, 48)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246)),
			})
			e.LightEmission = 0
			e.Lifetime = NumberRange.new(1.5, 2.5)
			e.Rate = 60
			e:Emit(40)
		end
		return { emisor = e }
	end,
	terminar = function(d)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.vibrar = {
	iniciar = function(ctx, escena, ef)
		local m = referencia(ctx, escena, ef.en)
		if typeof(m) == "Instance" and m:IsA("Model") then
			return { modelo = m, base = m:GetPivot(), fuerza = ef.fuerza or 0.12 }
		end
		return {}
	end,
	cuadro = function(d, t)
		if d.modelo then
			d.modelo:PivotTo(d.base * CFrame.new(d.fuerza * math.sin(t * 70), d.fuerza * math.sin(t * 53 + 1), 0))
		end
	end,
	terminar = function(d)
		if d.modelo then
			d.modelo:PivotTo(d.base)
		end
	end,
}
EFECTOS.parpadeo = {
	iniciar = function(ctx, escena, ef)
		local m = referencia(ctx, escena, ef.en)
		return { modelo = (typeof(m) == "Instance" and m:IsA("Model")) and m or nil, estado = false, ritmo = ef.ritmo or 5 }
	end,
	cuadro = function(d, t)
		local apagada = math.floor(t * d.ritmo * 2) % 2 == 1
		if d.modelo and apagada ~= d.estado then
			d.estado = apagada
			Utileria.actualizar(d.modelo, { apagada = apagada })
		end
	end,
	terminar = function(d)
		if d.modelo then
			Utileria.actualizar(d.modelo, { apagada = false })
		end
	end,
}
Director.EFECTOS = EFECTOS

local function terminarEfectos(ctx: any)
	local estado = ctx.estado
	if estado then
		for _, activo in estado.efectos do
			if activo.def.terminar then
				activo.def.terminar(activo.datos)
			end
		end
		estado.efectos = {}
	end
end

-- Deja el plano i montado (escenario, clima, luz, personajes, utilería, efectos) y calcula
-- el estado de cámara. No mueve la cámara: eso lo hace Director.cuadro. Devuelve los avisos.
function Director.aplicarPlano(ctx: any, i: number): { string }
	local p = ctx.planos[i]
	local avisos: { string } = {}
	local quien = "plano " .. tostring(p.n)
	terminarEfectos(ctx)

	local pred = ctx.datos.predeterminados
	local clave = Escenarios.resolver(p.escenario or pred.escenario)
	if not clave or not ctx.escenas[clave] then
		table.insert(avisos, quien .. ": escenario inexistente: " .. tostring(p.escenario))
		clave = next(ctx.escenas)
	end
	local escena: Model = ctx.escenas[clave]
	if not escena then
		ctx.estado = { indice = i, camara = nil, animados = {}, efectos = {} }
		return avisos
	end
	if ctx.claveActiva ~= clave or escena.Parent ~= Base.subcarpeta("Escenarios") then
		Escenarios.activar(clave :: string)
		ctx.claveActiva = clave
	end
	local clima = Base.normalizar(p.clima or pred.clima or escena:GetAttribute("ClimaInicial") or "sol")
	if escena:GetAttribute("Clima") ~= clima then
		local aviso = Escenarios.clima(escena, clima)
		if aviso then
			table.insert(avisos, quien .. ": " .. aviso)
		end
	end
	local luz = Base.normalizar(p.luz or pred.luz or Escenarios.luzSugerida(escena))
	if Luz.actual() ~= luz then
		local ok, aviso = Luz.aplicar(luz)
		if not ok then
			table.insert(avisos, quien .. ": " .. tostring(aviso))
			Luz.aplicar(Escenarios.luzSugerida(escena))
		end
	end

	-- Personajes
	local presentes = {}
	for _, spec in p.personajes or {} do
		local pj: Model = ctx.elenco[spec.id]
		if not pj then
			table.insert(avisos, quien .. ": personaje inexistente: " .. tostring(spec.id))
		else
			presentes[spec.id] = spec
			Elenco.mostrar(pj)
			local aviso = Elenco.posar(pj, spec.pose)
			if aviso then
				table.insert(avisos, quien .. ": " .. aviso)
			end
			Elenco.ubicar(pj, ubicacion(escena, spec, false, avisos, quien))
			local _, avisoCara = Caras.aplicar(pj, spec.cara or "neutra")
			if avisoCara then
				table.insert(avisos, quien .. ": " .. avisoCara)
			end
		end
	end
	for id, pj in ctx.elenco do
		if not presentes[id] then
			Elenco.ocultar(pj)
		end
	end

	-- Utilería
	local animados = {}
	local pegados = {}
	local visibles = {}
	local carpetaUtil = Base.subcarpeta("Utileria")
	for _, spec in p.utileria or {} do
		local modelo: Model = ctx.utileria[spec.id]
		if not modelo then
			table.insert(avisos, quien .. ": utilería sin crear: " .. tostring(spec.id))
		else
			visibles[spec.id] = true
			Base.mover(modelo, carpetaUtil)
			local cf: CFrame
			local pegado = spec.pegado
			local dueno = pegado and ctx.elenco[pegado.personaje]
			local punto = dueno and presentes[pegado.personaje] and Elenco.punto(dueno, pegado.parte or "mano_der")
			if punto then
				cf = punto * MEDIA_VUELTA * CFrame.new(Base.vec(pegado.rel))
				table.insert(pegados, { modelo = modelo, dueno = dueno, pegado = pegado })
			else
				if pegado then
					table.insert(avisos, quien .. ": no se pudo pegar " .. tostring(spec.id) .. " a " .. tostring(pegado.personaje))
				end
				cf = ubicacion(escena, spec, true, avisos, quien)
			end
			modelo:PivotTo(cf)
			if spec.params then
				Utileria.actualizar(modelo, spec.params)
			end
			if spec.claves then
				table.insert(animados, { modelo = modelo, claves = spec.claves, params = spec.params or {}, ultimo = {} })
			end
		end
	end
	for id, modelo in ctx.utileria do
		if not visibles[id] then
			Base.mover(modelo, Base.bodega())
		end
	end

	-- Cámara
	local cam = p.camara or {}
	local tipo = Camara.TIPOS[cam.tipo] and cam.tipo or "M"
	local cosas = {}
	for _, ref in lista(cam.objetivo) do
		local cosa = referencia(ctx, escena, ref)
		local visible = cosa ~= nil
		if typeof(cosa) == "Instance" and ctx.elenco[ref] and not presentes[ref] then
			visible = false
		end
		if visible then
			table.insert(cosas, cosa)
		else
			table.insert(avisos, quien .. ": objetivo de cámara inexistente o fuera del plano: " .. tostring(ref))
		end
	end
	if #cosas == 0 then
		local centro = Escenarios.ancla(escena, "centro")
		table.insert(cosas, (centro and centro.Position or (escena:GetAttribute("Origen") :: CFrame).Position) + Vector3.new(0, 3, 0))
	end
	local fija = nil
	if cam.ancla then
		fija = Escenarios.ancla(escena, cam.ancla)
		if not fija then
			table.insert(avisos, quien .. ": ancla de cámara inexistente: " .. tostring(cam.ancla))
		end
	end
	-- Ajustes finos del encuadre: "ancho" / "alto" (studs que deben caber en el cuadro final;
	-- con solo "ancho" manda el ancho) y "desplazar" [dx, dy, dz] sobre el centro calculado.
	local objetivoCamara = Camara.objetivo(cosas, tipo)
	if cam.ancho or cam.alto then
		objetivoCamara.ancho = cam.ancho or 0
		objetivoCamara.alto = cam.alto or 0
	end
	if cam.desplazar then
		objetivoCamara.centro += Base.vec(cam.desplazar)
	end
	local estadoCamara = Camara.encuadrar(objetivoCamara, tipo, {
		movimiento = cam.movimiento, inclinacion = cam.inclinacion, desde = cam.desde, azimut = cam.azimut,
		elevacion = cam.elevacion, fov = cam.fov, margen = cam.margen, vertical = ctx.vertical,
		duracion = p.fin - p.inicio, fija = fija,
	})

	-- Lluvia cercana: la nube del escenario cubre toda la celda y deja muy pocas gotas frente
	-- a la cámara (comprobado en Studio). Se agrega una nube pequeña y densa sobre el encuadre.
	local carpetaClima = escena:FindFirstChild("Clima")
	if carpetaClima and clima == "lluvia" and escena:GetAttribute("Interior") ~= true then
		local placa = carpetaClima:FindFirstChild("LluviaCerca") :: BasePart?
		if not placa then
			placa = Base.pieza({
				nombre = "LluviaCerca", tam = Vector3.new(30, 1, 26), transparencia = 1, sombra = false,
				consultable = false, padre = carpetaClima,
			})
			local e = Instance.new("ParticleEmitter")
			e.Name = "Lluvia"
			e.EmissionDirection = Enum.NormalId.Bottom
			e.Rate = 5000
			e.Lifetime = NumberRange.new(0.45, 0.6)
			e.Speed = NumberRange.new(62, 74)
			e.SpreadAngle = Vector2.new(4, 4)
			e.Size = NumberSequence.new(0.5)
			e.Squash = NumberSequence.new(-3.2)
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
			e.Transparency = NumberSequence.new(0.25)
			e.Color = ColorSequence.new(Color3.fromRGB(215, 230, 255))
			e.LightEmission = 0.35
			e.LightInfluence = 0.6
			e.Parent = placa
		end
		(placa :: BasePart).CFrame = CFrame.new(estadoCamara.centro + Vector3.new(0, 26, 4))
	end

	-- Miradas (después de ubicar a todos y de saber dónde queda la cámara)
	local posCamara = Camara.cframeEn(estadoCamara, 0).Position
	for id, spec in presentes do
		if spec.mira then
			local destino: any = nil
			if spec.mira == "camara" then
				destino = posCamara
			else
				destino = referencia(ctx, escena, spec.mira)
				if typeof(destino) == "Instance" then
					destino = destino:GetPivot().Position
				end
			end
			if typeof(destino) == "Vector3" then
				Elenco.mirarA(ctx.elenco[id], destino)
			else
				table.insert(avisos, quien .. ": mirada inexistente: " .. tostring(spec.mira))
			end
		end
	end

	-- La utilería pegada a un personaje se reubica por si la mirada lo giró.
	for _, g in pegados do
		local punto = Elenco.punto(g.dueno, g.pegado.parte or "mano_der")
		if punto then
			g.modelo:PivotTo(punto * MEDIA_VUELTA * CFrame.new(Base.vec(g.pegado.rel)))
		end
	end

	-- Vida: movimiento dentro del plano (Director.cuadro lo aplica en cada cuadro).
	--   personaje: "anim" (respirar por defecto, quieto, saltar, reir, temblar, caminar, negar,
	--   asentir, llorar), "mover" [dx, dy, dz] recorrido durante el plano, "cambios"
	--   [[fraccion, { cara = ..., pose = ... }], ...] para cambiar de cara o pose a mitad de plano.
	--   utilería: "anim" (flotar por defecto en baterías, quieto, girar, rebotar, latir) y
	--   "mover" [dx, dy, dz] con "arco" (altura extra en la mitad del recorrido).
	local vivos = {}
	local orden = 0
	for id, spec in presentes do
		orden += 1
		local pj = ctx.elenco[id]
		table.insert(vivos, {
			pj = pj, base = Elenco.pies(pj), anim = Base.normalizar(tostring(spec.anim or "respirar")),
			mover = spec.mover and Base.vec(spec.mover) or nil, fase = orden * 1.7,
			cambios = spec.cambios, hecho = 0, amplitud = spec.amplitud or 1,
		})
	end
	local utilVivos = {}
	for _, spec in p.utileria or {} do
		local modelo: Model = ctx.utileria[spec.id]
		if modelo and not spec.pegado then
			local porDefecto = (modelo:GetAttribute("Tipo") == "bateria") and "flotar" or "quieto"
			local anim = Base.normalizar(tostring(spec.anim or porDefecto))
			if anim ~= "quieto" or spec.mover then
				orden += 1
				table.insert(utilVivos, {
					modelo = modelo, base = modelo:GetPivot(), anim = anim, fase = orden * 1.3,
					mover = spec.mover and Base.vec(spec.mover) or nil, arco = spec.arco or 0,
					amplitud = spec.amplitud or 1,
				})
			end
		end
	end

	-- Efectos
	local efectos = {}
	for _, ef in lista(p.efecto) do
		local spec = (typeof(ef) == "table") and ef or { tipo = ef }
		local def = EFECTOS[tostring(spec.tipo)]
		if def then
			table.insert(efectos, { def = def, datos = def.iniciar(ctx, escena, spec) })
		else
			table.insert(avisos, quien .. ": efecto inexistente: " .. tostring(spec.tipo))
		end
	end

	ctx.estado = {
		indice = i, camara = estadoCamara, animados = animados, efectos = efectos, escena = escena,
		vivos = vivos, utilVivos = utilVivos, pegados = pegados,
	}
	return avisos
end

local TAU = math.pi * 2

-- Desplazamiento (Vector3) y giro (CFrame) de un personaje según su animación en el instante t.
local function vidaPersonaje(anim: string, t: number, fase: number, k: number): (Vector3, CFrame)
	if anim == "quieto" then
		return Vector3.zero, CFrame.new()
	elseif anim == "saltar" then
		return Vector3.new(0, math.abs(math.sin(math.pi * 2.3 * t)) * 0.9 * k, 0), CFrame.new()
	elseif anim == "reir" then
		return Vector3.new(0, math.abs(math.sin(math.pi * 5 * t + fase)) * 0.16 * k, 0), CFrame.Angles(0, 0, math.rad(3 * k) * math.sin(TAU * 2.5 * t + fase))
	elseif anim == "temblar" then
		return Vector3.new(0.05 * k * math.sin(t * 63 + fase), 0, 0.03 * k * math.sin(t * 51)), CFrame.new()
	elseif anim == "caminar" then
		return Vector3.new(0, math.abs(math.sin(math.pi * 3.4 * t + fase)) * 0.14 * k, 0), CFrame.Angles(0, 0, math.rad(4 * k) * math.sin(math.pi * 3.4 * t + fase))
	elseif anim == "negar" then
		return Vector3.zero, CFrame.Angles(0, math.rad(16 * k) * math.sin(TAU * 1.9 * t), 0)
	elseif anim == "asentir" then
		return Vector3.new(0, -0.07 * k * (1 - math.cos(TAU * 1.8 * t)), 0), CFrame.Angles(math.rad(-4 * k) * (1 - math.cos(TAU * 1.8 * t)), 0, 0)
	elseif anim == "llorar" then
		return Vector3.new(0, 0.05 * k * math.sin(TAU * 3.2 * t), 0), CFrame.Angles(math.rad(-3 * k), 0, math.rad(1.5 * k) * math.sin(TAU * 3.2 * t))
	end
	-- respirar: sube y baja apenas, con un balanceo mínimo; evita que el plano parezca una foto.
	return Vector3.new(0, 0.045 * k * math.sin(TAU * 0.85 * t + fase), 0), CFrame.Angles(0, 0, math.rad(0.8 * k) * math.sin(TAU * 0.5 * t + fase))
end

local function vidaUtileria(anim: string, t: number, fase: number, k: number): (Vector3, CFrame)
	if anim == "flotar" then
		return Vector3.new(0, 0.11 * k * math.sin(TAU * 0.55 * t + fase), 0), CFrame.Angles(0, 0, math.rad(1.2 * k) * math.sin(TAU * 0.4 * t + fase))
	elseif anim == "girar" then
		return Vector3.zero, CFrame.Angles(0, TAU * 0.6 * t * k, 0)
	elseif anim == "rodar" then
		return Vector3.zero, CFrame.Angles(-TAU * 1.4 * t * k, 0, 0)
	elseif anim == "rebotar" then
		return Vector3.new(0, math.abs(math.sin(math.pi * 2.2 * t + fase)) * 0.7 * k, 0), CFrame.new()
	elseif anim == "latir" then
		return Vector3.new(0, 0.05 * k * math.sin(TAU * 2.4 * t), 0), CFrame.Angles(0, 0, math.rad(2.5 * k) * math.sin(TAU * 2.4 * t))
	elseif anim == "temblar" then
		return Vector3.new(0.06 * k * math.sin(t * 67 + fase), 0.05 * k * math.sin(t * 53), 0), CFrame.new()
	end
	return Vector3.zero, CFrame.new()
end

-- Actualiza lo que cambia en cada cuadro: cámara, utilería animada y efectos.
-- `t` son los segundos transcurridos desde el inicio del plano vigente.
function Director.cuadro(ctx: any, t: number)
	local estado = ctx.estado
	if not estado or not estado.camara then
		return
	end
	local e = estado.camara
	local cf, fov = Camara.cframeEn(e, t)
	Camara.aplicar(cf, fov, e.centro)
	Luz.enfocar((cf.Position - e.centro).Magnitude, math.max(8, e.alto))
	local u = math.clamp(t / e.duracion, 0, 1)
	for _, v in estado.vivos or {} do
		if v.cambios then
			for k, cambio in v.cambios do
				if k > v.hecho and u >= (cambio[1] or 0) then
					v.hecho = k
					local c = cambio[2] or {}
					if c.pose then
						Elenco.posar(v.pj, c.pose)
					end
					if c.cara then
						Caras.aplicar(v.pj, c.cara)
					end
					if c.anim then
						v.anim = Base.normalizar(tostring(c.anim))
					end
				end
			end
		end
		local d, giro = vidaPersonaje(v.anim, t, v.fase, v.amplitud)
		if v.mover then
			d += v.mover * Base.suavizar(u, "entrada_salida")
		end
		Elenco.ubicar(v.pj, (v.base + d) * giro)
	end
	for _, g in estado.pegados or {} do
		local punto = Elenco.punto(g.dueno, g.pegado.parte or "mano_der")
		if punto then
			g.modelo:PivotTo(punto * MEDIA_VUELTA * CFrame.new(Base.vec(g.pegado.rel)))
		end
	end
	for _, v in estado.utilVivos or {} do
		local d, giro = vidaUtileria(v.anim, t, v.fase, v.amplitud)
		if v.mover then
			d += v.mover * u + Vector3.new(0, v.arco * 4 * u * (1 - u), 0)
		end
		v.modelo:PivotTo((v.base + d) * giro)
	end
	for _, a in estado.animados do
		local cambio = false
		local params = table.clone(a.params)
		for campo, claves in a.claves do
			local valor = Base.claves(claves, u)
			if campo == "porcentaje" or campo == "izq" or campo == "der" then
				valor = math.floor(valor * 10 + 0.5) / 10
			end
			params[campo] = valor
			if a.ultimo[campo] ~= valor then
				a.ultimo[campo] = valor
				cambio = true
			end
		end
		if cambio then
			Utileria.actualizar(a.modelo, params)
		end
	end
	for _, activo in estado.efectos do
		if activo.def.cuadro then
			activo.def.cuadro(activo.datos, t)
		end
	end
end

local function indiceDeNumero(ctx: any, n: number): number?
	for i, p in ctx.planos do
		if p.n == n then
			return i
		end
	end
	return nil
end

local function v3(v: Vector3): { number }
	local function r(x: number): number
		return math.floor(x * 100 + 0.5) / 100
	end
	return { r(v.X), r(v.Y), r(v.Z) }
end

----------------------------------------------------------------------------------------
-- Modo foto
----------------------------------------------------------------------------------------

-- Salta al plano número `n` y lo deja quieto en `fraccion` (0 a 1; por defecto 0.5) de su
-- duración. Devuelve una tabla corta para el chat: texto, avisos, si el objetivo está
-- tapado y la posición de cámara (sirve para camera_position / look_at_position de
-- screen_capture, que no conserva ni el giro vertical ni el campo de visión).
function Director.foto(ctx: any, n: number, fraccion: number?): any
	local i = indiceDeNumero(ctx, n)
	if not i then
		return { error = "no existe el plano " .. tostring(n) }
	end
	local avisos = Director.aplicarPlano(ctx, i)
	local p = ctx.planos[i]
	local t = (p.fin - p.inicio) * (fraccion or 0.5)
	Director.cuadro(ctx, t)
	local e = ctx.estado.camara
	local resultado: any = { n = p.n, texto = p.texto, duracion = p.fin - p.inicio, avisos = avisos }
	if e then
		local cf = Camara.cframeEn(e, t)
		local tapado, por = Camara.verificar(cf, e)
		resultado.tapado, resultado.tapado_por = tapado, por
		resultado.camara = { posicion = v3(cf.Position), mira = v3(e.centro), fov = e.fov, vertical = e.vertical }
	end
	return resultado
end

----------------------------------------------------------------------------------------
-- Modo ensayo
----------------------------------------------------------------------------------------

-- Recorre todos los planos sin reproducir y reporta por consola (y devuelve) los que duran
-- menos de DURACION_MINIMA, los que tienen el objetivo tapado y los que referencian algo
-- inexistente.
function Director.ensayo(ctx: any): any
	local informe = { cortos = {}, tapados = {}, inexistentes = {}, total = #ctx.planos }
	for _, aviso in ctx.avisos do
		table.insert(informe.inexistentes, aviso)
	end
	local vistos = {}
	for _, aviso in informe.inexistentes do
		vistos[aviso] = true
	end
	for i, p in ctx.planos do
		local duracion = p.fin - p.inicio
		if duracion < Director.DURACION_MINIMA then
			table.insert(informe.cortos, string.format("plano %s: dura %.2f s", tostring(p.n), duracion))
		end
		for _, aviso in Director.aplicarPlano(ctx, i) do
			if not vistos[aviso] then
				vistos[aviso] = true
				table.insert(informe.inexistentes, aviso)
			end
		end
		local e = ctx.estado.camara
		if e then
			for _, t in { 0, duracion } do
				local cf = Camara.cframeEn(e, t)
				local tapado, por = Camara.verificar(cf, e)
				if tapado then
					table.insert(informe.tapados, string.format("plano %s: objetivo tapado por %s", tostring(p.n), tostring(por)))
					break
				end
			end
		end
		if i % 10 == 0 then
			ceder(ctx)
		end
	end
	terminarEfectos(ctx)
	print(string.format("[Historias] ensayo de %s: %d planos, %d cortos, %d tapados, %d referencias inexistentes",
		tostring(ctx.datos.video), informe.total, #informe.cortos, #informe.tapados, #informe.inexistentes))
	for _, grupo in { informe.cortos, informe.tapados, informe.inexistentes } do
		for _, linea in grupo do
			print("[Historias]   " .. linea)
		end
	end
	return informe
end

----------------------------------------------------------------------------------------
-- Modo reproducir
----------------------------------------------------------------------------------------

local function ocultarInterfaz()
	local StarterGui = game:GetService("StarterGui")
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	pcall(function()
		game:GetService("UserInputService").MouseIconEnabled = false
	end)
	task.spawn(function()
		for _ = 1, 20 do
			local ok = pcall(function()
				StarterGui:SetCore("TopbarEnabled", false)
			end)
			if ok then
				break
			end
			task.wait(0.25)
		end
	end)
end

local function pantallaDestello(color: Color3): Frame?
	local jugador = game:GetService("Players").LocalPlayer
	local gui = jugador and jugador:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	local pantalla = Instance.new("ScreenGui")
	pantalla.Name = "HistoriasDestello"
	pantalla.IgnoreGuiInset = true
	pantalla.DisplayOrder = 10000
	pantalla.ResetOnSpawn = false
	local marco = Instance.new("Frame")
	marco.Name = "Blanco"
	marco.Size = UDim2.fromScale(1, 1)
	marco.BorderSizePixel = 0
	marco.BackgroundColor3 = color
	marco.Visible = false
	marco.Parent = pantalla
	pantalla.Parent = gui
	return marco
end

-- Reproduce la secuencia completa. opciones = { previa = 2 (segundos quietos en el plano 1
-- antes del destello), cuadrosDestello = 2, colorDestello = "#FFFFFF", cola = 0.5,
-- alTerminar = function(informe) }. Devuelve un control con detener() y el campo `fase`.
function Director.reproducir(ctx: any, opciones: any?): any
	local o = opciones or {}
	local previa, cuadrosDestello, cola = o.previa or 2, o.cuadrosDestello or 2, o.cola or 0.5
	local color = Base.color(o.colorDestello, Color3.new(1, 1, 1))
	local esCliente = RunService:IsClient() and RunService:IsRunning()
	local planos = ctx.planos
	local control: any = { fase = "previa", indice = 1, entradas = {}, t0 = nil, desvioMaximo = 0 }
	if #planos == 0 then
		control.fase = "terminado"
		return control
	end

	Camara.guardar()
	if esCliente then
		ocultarInterfaz()
	end
	local marco = esCliente and pantallaDestello(color) or nil
	local function destello(activo: boolean)
		Luz.blanco(activo)
		if marco then
			marco.Visible = activo
		end
	end

	Director.aplicarPlano(ctx, 1)
	Director.cuadro(ctx, 0)

	local inicioFase = os.clock()
	local cuadros = 0
	local conexion: RBXScriptConnection? = nil
	local NOMBRE = "HistoriasDirector"

	local function terminar()
		if control.fase == "terminado" then
			return
		end
		control.fase = "terminado"
		if conexion then
			conexion:Disconnect()
		elseif esCliente then
			pcall(function()
				RunService:UnbindFromRenderStep(NOMBRE)
			end)
		end
		destello(false)
		terminarEfectos(ctx)
		if marco and marco.Parent then
			marco.Parent:Destroy()
		end
		for i, t in control.entradas do
			control.desvioMaximo = math.max(control.desvioMaximo, t - planos[i].inicio)
		end
		print(string.format("[Historias] fin de %s: %d planos, desvío máximo de entrada %.1f ms",
			tostring(ctx.datos.video), #planos, control.desvioMaximo * 1000))
		if o.alTerminar then
			o.alTerminar(control)
		end
	end

	local function paso()
		local ahora = os.clock()
		if control.fase == "previa" then
			if ahora - inicioFase >= previa then
				control.fase = "destello"
				cuadros = 0
				destello(true)
			end
		elseif control.fase == "destello" then
			cuadros += 1
			if cuadros >= cuadrosDestello then
				destello(false)
				control.t0 = ahora -- instante cero: primer cuadro no blanco
				control.fase = "rodando"
				control.entradas[1] = 0
				Director.cuadro(ctx, 0)
			end
		elseif control.fase == "rodando" then
			local t = ahora - control.t0
			if t >= ctx.duracion then
				control.fase = "cola"
				inicioFase = ahora
				return
			end
			local nuevo = Director.indiceEn(planos, t, control.indice)
			if nuevo ~= control.indice then
				control.indice = nuevo
				Director.aplicarPlano(ctx, nuevo)
				control.entradas[nuevo] = t
			end
			Director.cuadro(ctx, t - planos[control.indice].inicio)
		elseif control.fase == "cola" then
			if ahora - inicioFase >= cola then
				terminar()
			end
		end
	end

	if esCliente then
		RunService:BindToRenderStep(NOMBRE, Enum.RenderPriority.Camera.Value + 1, paso)
	else
		conexion = RunService.Heartbeat:Connect(paso)
	end
	control.detener = terminar
	print(string.format("[Historias] rodando %s: %d planos, %.2f s, vertical=%s (montaje: girar %s)",
		tostring(ctx.datos.video), #planos, ctx.duracion, tostring(ctx.vertical), Camara.ROTAR_MONTAJE))
	return control
end

----------------------------------------------------------------------------------------
-- Datos guardados en el lugar y utilidades de sesión
----------------------------------------------------------------------------------------

local function carpetaHistorias(): Instance
	if typeof(script) == "Instance" and script.Parent then
		return script.Parent
	end
	return Base.carpeta(ReplicatedStorage, Base.RAIZ)
end

-- Guarda plan y puesta (texto JSON) como StringValue en ReplicatedStorage.Historias.Datos,
-- para que los lanzadores los lean al iniciar el juego. `plan` puede ser nil.
function Director.guardarDatos(plan: string?, puesta: string)
	local datos = Base.carpeta(carpetaHistorias(), "Datos")
	for nombre, texto in { Plan = plan or "", Puesta = puesta } do
		local valor = Base.carpeta(datos, nombre, "StringValue") :: StringValue
		valor.Value = texto
	end
end

-- Configura el lugar para grabar. modo = "play" (cliente, recomendado) o "run".
function Director.configurarLugar(modo: string?)
	local carpeta = carpetaHistorias()
	carpeta:SetAttribute("AutoRodar", true)
	carpeta:SetAttribute("Modo", modo or "play")
	if (modo or "play") == "play" then
		game:GetService("Players").CharacterAutoLoads = false
	end
end

-- Lo que llaman los lanzadores: lee los datos guardados, prepara y reproduce.
function Director.rodarDesdeDatos(opciones: any?): any
	local datos = carpetaHistorias():FindFirstChild("Datos")
	local plan = datos and datos:FindFirstChild("Plan")
	local puesta = datos and datos:FindFirstChild("Puesta")
	if not (puesta and puesta:IsA("StringValue")) or puesta.Value == "" then
		warn("[Historias] no hay puesta guardada; usa Director.guardarDatos primero")
		return nil
	end
	local textoPlan = (plan and plan:IsA("StringValue") and plan.Value ~= "") and plan.Value or nil
	local ctx = Director.preparar(textoPlan, puesta.Value, opciones)
	return Director.reproducir(ctx, opciones)
end

-- Deja el lugar como para seguir editando: todos los escenarios y personajes visibles,
-- efectos apagados, luz y cámara originales.
function Director.restaurar(ctx: any?)
	if ctx then
		terminarEfectos(ctx)
		for _, pj in ctx.elenco do
			Elenco.mostrar(pj)
		end
		for _, modelo in ctx.utileria do
			Base.mover(modelo, Base.subcarpeta("Utileria"))
		end
		ctx.claveActiva = nil
	end
	Escenarios.mostrarTodos()
	Luz.revertir()
	Camara.restaurar()
end

return Director
end

local Historias = __requerir("Director")
-- Tu código va debajo de esta línea, por ejemplo:  return Historias.Caras.NOMBRES
