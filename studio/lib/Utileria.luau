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
