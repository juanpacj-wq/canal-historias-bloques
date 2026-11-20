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
