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
