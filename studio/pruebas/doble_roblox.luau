--!nolint DeprecatedApi
-- doble_roblox.luau
-- Doble de pruebas de la API de Roblox para ejecutar la biblioteca con el intérprete `luau`
-- fuera de Studio. NO es Roblox: no dibuja nada ni simula física. Sirve para comprobar
--   * que cada clase, propiedad, método, evento y enumeración que usa la biblioteca EXISTE
--     (contra pruebas/api_roblox.luau, generado del volcado oficial de la API de Studio);
--   * que cada valor asignado a una propiedad tiene el TIPO que declara el volcado;
--   * la lógica: matemática de CFrame y Vector3, árbol de instancias, atributos, rayos
--     contra cajas orientadas, JSON y el reloj de cuadros (Heartbeat, paso de render).
-- Lo que el volcado no describe (tipos de datos como CFrame o Color3, y el comportamiento
-- real del motor) está escrito a mano siguiendo la referencia oficial y puede diferir.
--
-- Uso: local Doble = <este archivo>; local d = Doble.crear(API, { cliente, corriendo, plugin })
--      d.entorno es la tabla de globales para setfenv; d.avanzar(dt) simula un cuadro.

local Doble = {}

local function tipoDe(v: any): string
	local mt = (type(v) == "table") and getmetatable(v)
	if mt and rawget(mt, "__type") then
		return mt.__type
	end
	return typeof(v)
end
Doble.tipoDe = tipoDe

----------------------------------------------------------------------------------------
-- Tipos de datos
----------------------------------------------------------------------------------------

local V3 = { __type = "Vector3" }
local function vec3(x: number?, y: number?, z: number?): any
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
local V3m = {}
function V3m.Dot(a, b)
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end
function V3m.Cross(a, b)
	return vec3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function V3m.Lerp(a, b, t)
	return vec3(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t, a.Z + (b.Z - a.Z) * t)
end
function V3m.FuzzyEq(a, b, eps)
	return (a - b).Magnitude <= (eps or 1e-5)
end
V3.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return vec3(v.X / m, v.Y / m, v.Z / m)
	end
	local m = V3m[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of Vector3", 2)
end
V3.__add = function(a, b)
	return vec3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3.__sub = function(a, b)
	return vec3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3.__unm = function(a)
	return vec3(-a.X, -a.Y, -a.Z)
end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return vec3(a * b.X, a * b.Y, a * b.Z)
	elseif type(b) == "number" then
		return vec3(a.X * b, a.Y * b, a.Z * b)
	end
	return vec3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then
		return vec3(a.X / b, a.Y / b, a.Z / b)
	end
	return vec3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3.__tostring = function(a)
	return string.format("%.3f, %.3f, %.3f", a.X, a.Y, a.Z)
end
local Vector3 = {
	new = vec3, zero = vec3(0, 0, 0), one = vec3(1, 1, 1),
	xAxis = vec3(1, 0, 0), yAxis = vec3(0, 1, 0), zAxis = vec3(0, 0, 1),
}

local V2 = { __type = "Vector2" }
V2.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y)
	end
	error(tostring(k) .. " is not a valid member of Vector2", 2)
end
V2.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y
end
local Vector2 = {
	new = function(x: number?, y: number?)
		return setmetatable({ X = x or 0, Y = y or 0 }, V2)
	end,
}
Vector2.zero = Vector2.new(0, 0)

-- CFrame: posición (x, y, z) y matriz de rotación por filas r[1..9].
local CF = { __type = "CFrame" }
local function cf(x, y, z, r): any
	return setmetatable({ x = x, y = y, z = z, r = r }, CF)
end
local IDENT = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function mulR(a, b)
	local c = {}
	for i = 0, 2 do
		for j = 1, 3 do
			c[i * 3 + j] = a[i * 3 + 1] * b[j] + a[i * 3 + 2] * b[3 + j] + a[i * 3 + 3] * b[6 + j]
		end
	end
	return c
end
local function rotV(r, x, y, z)
	return r[1] * x + r[2] * y + r[3] * z, r[4] * x + r[5] * y + r[6] * z, r[7] * x + r[8] * y + r[9] * z
end
local function traspuesta(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
local function rotX(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function rotY(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rotZ(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
local function aCuaternion(r: { number }): (number, number, number, number)
	local tr = r[1] + r[5] + r[9]
	local w: number, x: number, y: number, z: number
	if tr > 0 then
		local s = math.sqrt(tr + 1) * 2
		w, x, y, z = s / 4, (r[8] - r[6]) / s, (r[3] - r[7]) / s, (r[4] - r[2]) / s
	elseif r[1] > r[5] and r[1] > r[9] then
		local s = math.sqrt(1 + r[1] - r[5] - r[9]) * 2
		w, x, y, z = (r[8] - r[6]) / s, s / 4, (r[2] + r[4]) / s, (r[3] + r[7]) / s
	elseif r[5] > r[9] then
		local s = math.sqrt(1 + r[5] - r[1] - r[9]) * 2
		w, x, y, z = (r[3] - r[7]) / s, (r[2] + r[4]) / s, s / 4, (r[6] + r[8]) / s
	else
		local s = math.sqrt(1 + r[9] - r[1] - r[5]) * 2
		w, x, y, z = (r[4] - r[2]) / s, (r[3] + r[7]) / s, (r[6] + r[8]) / s, s / 4
	end
	return w, x, y, z
end
local function deCuaternion(w, x, y, z)
	return {
		1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w),
		2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w),
		2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y),
	}
end
local CFm = {}
function CFm.Inverse(a)
	local t = traspuesta(a.r)
	local x, y, z = rotV(t, -a.x, -a.y, -a.z)
	return cf(x, y, z, t)
end
function CFm.ToWorldSpace(a, b)
	return a * b
end
function CFm.ToObjectSpace(a, b)
	return a:Inverse() * b
end
function CFm.PointToWorldSpace(a, v)
	return a * v
end
function CFm.PointToObjectSpace(a, v)
	return a:Inverse() * v
end
function CFm.VectorToWorldSpace(a, v)
	return vec3(rotV(a.r, v.X, v.Y, v.Z))
end
function CFm.VectorToObjectSpace(a, v)
	return vec3(rotV(traspuesta(a.r), v.X, v.Y, v.Z))
end
function CFm.GetComponents(a)
	return a.x, a.y, a.z, table.unpack(a.r)
end
function CFm.Lerp(a, b, t)
	local w1, x1, y1, z1 = aCuaternion(a.r)
	local w2, x2, y2, z2 = aCuaternion(b.r)
	local dot = w1 * w2 + x1 * x2 + y1 * y2 + z1 * z2
	if dot < 0 then
		w2, x2, y2, z2, dot = -w2, -x2, -y2, -z2, -dot
	end
	local k1, k2 = 1 - t, t
	if dot < 0.9995 then
		local ang = math.acos(dot)
		k1, k2 = math.sin((1 - t) * ang) / math.sin(ang), math.sin(t * ang) / math.sin(ang)
	end
	local w, x, y, z = w1 * k1 + w2 * k2, x1 * k1 + x2 * k2, y1 * k1 + y2 * k2, z1 * k1 + z2 * k2
	local n = math.sqrt(w * w + x * x + y * y + z * z)
	return cf(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, deCuaternion(w / n, x / n, y / n, z / n))
end
CF.__index = function(a, k)
	local r = rawget(a, "r")
	if k == "Position" then
		return vec3(a.x, a.y, a.z)
	elseif k == "X" then
		return a.x
	elseif k == "Y" then
		return a.y
	elseif k == "Z" then
		return a.z
	elseif k == "Rotation" then
		return cf(0, 0, 0, r)
	elseif k == "RightVector" or k == "XVector" then
		return vec3(r[1], r[4], r[7])
	elseif k == "UpVector" or k == "YVector" then
		return vec3(r[2], r[5], r[8])
	elseif k == "ZVector" then
		return vec3(r[3], r[6], r[9])
	elseif k == "LookVector" then
		return vec3(-r[3], -r[6], -r[9])
	end
	local m = CFm[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of CFrame", 2)
end
CF.__mul = function(a, b)
	if tipoDe(b) == "Vector3" then
		local x, y, z = rotV(a.r, b.X, b.Y, b.Z)
		return vec3(x + a.x, y + a.y, z + a.z)
	end
	local x, y, z = rotV(a.r, b.x, b.y, b.z)
	return cf(x + a.x, y + a.y, z + a.z, mulR(a.r, b.r))
end
CF.__add = function(a, v)
	return cf(a.x + v.X, a.y + v.Y, a.z + v.Z, a.r)
end
CF.__sub = function(a, v)
	return cf(a.x - v.X, a.y - v.Y, a.z - v.Z, a.r)
end
CF.__eq = function(a, b)
	if a.x ~= b.x or a.y ~= b.y or a.z ~= b.z then
		return false
	end
	for i = 1, 9 do
		if a.r[i] ~= b.r[i] then
			return false
		end
	end
	return true
end
local function lookAt(desde, hacia, arriba)
	local look = (hacia - desde).Unit
	local up = arriba or vec3(0, 1, 0)
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = vec3(1, 0, 0)
	end
	right = right.Unit
	local up2 = right:Cross(look)
	return cf(desde.X, desde.Y, desde.Z, { right.X, up2.X, -look.X, right.Y, up2.Y, -look.Y, right.Z, up2.Z, -look.Z })
end
local CFrame = {
	identity = cf(0, 0, 0, IDENT),
	new = function(...)
		local n = select("#", ...)
		local a, b = ...
		if n == 0 then
			return cf(0, 0, 0, IDENT)
		elseif n == 1 then
			return cf(a.X, a.Y, a.Z, IDENT)
		elseif n == 2 then
			return lookAt(a, b)
		elseif n == 3 then
			return cf(a, b, select(3, ...), IDENT)
		elseif n == 7 then
			local x, y, z, qx, qy, qz, qw = ...
			return cf(x, y, z, deCuaternion(qw, qx, qy, qz))
		elseif n == 12 then
			local t = { ... }
			return cf(t[1], t[2], t[3], { table.unpack(t, 4, 12) })
		end
		error("CFrame.new: cantidad de argumentos no simulada: " .. n, 2)
	end,
	Angles = function(x, y, z)
		return cf(0, 0, 0, mulR(mulR(rotX(x), rotY(y)), rotZ(z)))
	end,
	fromEulerAnglesYXZ = function(x, y, z)
		return cf(0, 0, 0, mulR(mulR(rotY(y), rotX(x)), rotZ(z)))
	end,
	lookAt = lookAt,
}
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ

local C3 = { __type = "Color3" }
local function color3(r: number?, g: number?, b: number?): any
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end
local C3m = {}
function C3m.Lerp(a, b, t)
	return color3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end
function C3m.ToHex(a)
	return string.format("%02X%02X%02X", math.round(a.R * 255), math.round(a.G * 255), math.round(a.B * 255))
end
C3.__index = function(_, k)
	local m = C3m[k]
	if m then
		return m
	end
	error(tostring(k) .. " is not a valid member of Color3", 2)
end
C3.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
local Color3 = {
	new = color3,
	fromRGB = function(r, g, b)
		return color3(r / 255, g / 255, b / 255)
	end,
	fromHex = function(hex)
		local h = string.gsub(hex, "^#", "")
		if #h == 3 then
			h = string.gsub(h, "(.)", "%1%1")
		end
		if #h ~= 6 or string.find(h, "[^%x]") then
			error("Unable to convert characters to hex value", 2)
		end
		return color3(tonumber(string.sub(h, 1, 2), 16) / 255, tonumber(string.sub(h, 3, 4), 16) / 255, tonumber(string.sub(h, 5, 6), 16) / 255)
	end,
}

local function simple(nombre: string, campos: { string })
	local mt = { __type = nombre }
	mt.__index = function(_, k)
		error(tostring(k) .. " is not a valid member of " .. nombre, 2)
	end
	mt.__eq = function(a, b)
		for _, c in campos do
			if rawget(a, c) ~= rawget(b, c) then
				return false
			end
		end
		return true
	end
	return function(valores: { [string]: any })
		return setmetatable(valores, mt)
	end
end
local nuevoUDim = simple("UDim", { "Scale", "Offset" })
local UDim = {
	new = function(s: number?, o: number?)
		return nuevoUDim({ Scale = s or 0, Offset = o or 0 })
	end,
}
local nuevoUDim2 = simple("UDim2", { "X", "Y" })
local UDim2 = {
	new = function(a, b, c, d)
		if tipoDe(a) == "UDim" then
			return nuevoUDim2({ X = a, Y = b })
		end
		return nuevoUDim2({ X = UDim.new(a, b), Y = UDim.new(c, d) })
	end,
	fromScale = function(x, y)
		return nuevoUDim2({ X = UDim.new(x, 0), Y = UDim.new(y, 0) })
	end,
	fromOffset = function(x, y)
		return nuevoUDim2({ X = UDim.new(0, x), Y = UDim.new(0, y) })
	end,
}
local nuevoRango = simple("NumberRange", { "Min", "Max" })
local NumberRange = {
	new = function(a: number, b: number?)
		return nuevoRango({ Min = a, Max = b or a })
	end,
}
local nuevoNSK = simple("NumberSequenceKeypoint", { "Time", "Value", "Envelope" })
local NumberSequenceKeypoint = {
	new = function(t, v, e)
		return nuevoNSK({ Time = t, Value = v, Envelope = e or 0 })
	end,
}
local nuevaNS = simple("NumberSequence", {})
local NumberSequence = {
	new = function(a, b)
		if type(a) == "table" and tipoDe(a) == "table" then
			return nuevaNS({ Keypoints = a })
		end
		return nuevaNS({ Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) } })
	end,
}
local nuevoCSK = simple("ColorSequenceKeypoint", { "Time", "Value" })
local ColorSequenceKeypoint = {
	new = function(t, c)
		assert(tipoDe(c) == "Color3", "ColorSequenceKeypoint.new espera Color3")
		return nuevoCSK({ Time = t, Value = c })
	end,
}
local nuevaCS = simple("ColorSequence", {})
local ColorSequence = {
	new = function(a, b)
		if tipoDe(a) == "table" then
			return nuevaCS({ Keypoints = a })
		end
		assert(tipoDe(a) == "Color3", "ColorSequence.new espera Color3")
		return nuevaCS({ Keypoints = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a) } })
	end,
}
local nuevoContent = simple("Content", { "Uri" })
local Content = {
	fromAssetId = function(id: number)
		assert(type(id) == "number", "Content.fromAssetId espera un número")
		return nuevoContent({ Uri = "rbxassetid://" .. tostring(id), SourceType = "Uri" })
	end,
	fromUri = function(uri: string)
		return nuevoContent({ Uri = uri, SourceType = "Uri" })
	end,
}
local RP = { __type = "RaycastParams" }
RP.__index = function(_, k)
	if k == "AddToFilter" then
		return function(self, cosa)
			table.insert(self.FilterDescendantsInstances, cosa)
		end
	end
	error(tostring(k) .. " is not a valid member of RaycastParams", 2)
end
RP.__newindex = function(self, k, v)
	error(tostring(k) .. " is not a valid member of RaycastParams", 2)
end

----------------------------------------------------------------------------------------
-- JSON (para HttpService:JSONDecode)
----------------------------------------------------------------------------------------

local function decodificarJSON(texto: string): any
	local pos = 1
	local function espacios()
		pos = string.find(texto, "[^ \t\r\n]", pos) or (#texto + 1)
	end
	local valor
	local function cadena(): string
		local partes = {}
		pos += 1
		while true do
			local c = string.sub(texto, pos, pos)
			if c == "" then
				error("JSON: cadena sin cerrar")
			elseif c == '"' then
				pos += 1
				return table.concat(partes)
			elseif c == "\\" then
				local e = string.sub(texto, pos + 1, pos + 1)
				local mapa = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ["/"] = "/", ["\\"] = "\\", ['"'] = '"' }
				if e == "u" then
					table.insert(partes, utf8.char(tonumber(string.sub(texto, pos + 2, pos + 5), 16) :: number))
					pos += 6
				else
					table.insert(partes, mapa[e] or e)
					pos += 2
				end
			else
				local fin = string.find(texto, '["\\]', pos) or (#texto + 1)
				table.insert(partes, string.sub(texto, pos, fin - 1))
				pos = fin
			end
		end
	end
	function valor(): any
		espacios()
		local c = string.sub(texto, pos, pos)
		if c == "{" then
			local t = {}
			pos += 1
			espacios()
			if string.sub(texto, pos, pos) == "}" then
				pos += 1
				return t
			end
			while true do
				espacios()
				local clave = cadena()
				espacios()
				assert(string.sub(texto, pos, pos) == ":", "JSON: falta ':' en " .. pos)
				pos += 1
				t[clave] = valor()
				espacios()
				local s = string.sub(texto, pos, pos)
				pos += 1
				if s == "}" then
					return t
				end
				assert(s == ",", "JSON: falta ',' en " .. pos)
			end
		elseif c == "[" then
			local t = {}
			pos += 1
			espacios()
			if string.sub(texto, pos, pos) == "]" then
				pos += 1
				return t
			end
			while true do
				table.insert(t, valor())
				espacios()
				local s = string.sub(texto, pos, pos)
				pos += 1
				if s == "]" then
					return t
				end
				assert(s == ",", "JSON: falta ',' en " .. pos)
			end
		elseif c == '"' then
			return cadena()
		elseif string.sub(texto, pos, pos + 3) == "true" then
			pos += 4
			return true
		elseif string.sub(texto, pos, pos + 4) == "false" then
			pos += 5
			return false
		elseif string.sub(texto, pos, pos + 3) == "null" then
			pos += 4
			return nil
		end
		local num = string.match(texto, "^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
		assert(num and num ~= "", "JSON: valor inesperado en " .. pos)
		pos += #num
		return tonumber(num)
	end
	local resultado = valor()
	espacios()
	assert(pos > #texto, "JSON: sobra texto en " .. pos)
	return resultado
end
Doble.decodificarJSON = decodificarJSON
Doble.Vector3, Doble.CFrame, Doble.Color3 = Vector3, CFrame, Color3

----------------------------------------------------------------------------------------
-- Entorno
----------------------------------------------------------------------------------------

local PREDETERMINADOS_VERDADEROS = {
	CanCollide = true, CanQuery = true, CanTouch = true, Enabled = true, Visible = true, CastShadow = true,
	Archivable = true, GlobalShadows = true, ResetOnSpawn = true, CharacterAutoLoads = true,
}
local ATRIBUTOS_VALIDOS = {
	string = true, boolean = true, number = true, UDim = true, UDim2 = true, Color3 = true, Vector2 = true,
	Vector3 = true, CFrame = true, NumberSequence = true, ColorSequence = true, NumberRange = true,
}

function Doble.crear(API: any, config: any?): any
	local cfg = config or {}
	local d: any = { reloj = 100, registro = {}, noSimulados = {}, cuadros = 0 }
	local D: { [any]: any } = setmetatable({}, { __mode = "k" }) :: any
	local INST = { __type = "Instance" }
	local Metodos: { [string]: any } = {}
	local servicios: { [string]: any } = {}
	local modulos: { [any]: any } = {}
	local entorno: any

	local function miembro(clase: string, nombre: string): (string?, string?)
		local c = clase
		while c and API.clases[c] do
			local m = API.clases[c].m[nombre]
			if m then
				return m, c
			end
			c = API.clases[c].s
		end
		return nil, nil
	end
	local function esUna(clase: string, objetivo: string): boolean
		local c = clase
		while c and API.clases[c] do
			if c == objetivo then
				return true
			end
			c = API.clases[c].s
		end
		return false
	end

	-- Enumeraciones validadas contra el volcado.
	local enumCache: { [string]: any } = {}
	local ITEM = { __type = "EnumItem" }
	ITEM.__tostring = function(i)
		return "Enum." .. i.EnumType .. "." .. i.Name
	end
	local Enum = setmetatable({}, {
		__index = function(_, nombre)
			if not API.enums[nombre] then
				error(tostring(nombre) .. " is not a valid member of \"Enum\" (o no está en api_roblox.luau: regenera con generar_api.py)", 2)
			end
			if not enumCache[nombre] then
				local items = {}
				for valor, n in API.enums[nombre] do
					items[n] = setmetatable({ Name = n, Value = valor - 1, EnumType = nombre }, ITEM)
				end
				enumCache[nombre] = setmetatable({}, {
					__index = function(_, item)
						if item == "GetEnumItems" then
							return function()
								local l = {}
								for _, i in items do
									table.insert(l, i)
								end
								return l
							end
						end
						return items[item] or error(tostring(item) .. " is not a valid member of \"Enum." .. nombre .. "\"", 2)
					end,
				})
			end
			return enumCache[nombre]
		end,
	})

	local function senal(): any
		local s = { conexiones = {} }
		function s:Connect(fn)
			local c = { Connected = true }
			function c:Disconnect()
				c.Connected = false
				local i = table.find(s.conexiones, c)
				if i then
					table.remove(s.conexiones, i)
				end
			end
			c.fn = fn
			table.insert(s.conexiones, c)
			return c
		end
		function s:Once(fn)
			local c
			c = s:Connect(function(...)
				c:Disconnect()
				fn(...)
			end)
			return c
		end
		function s:Wait() end
		function s:disparar(...)
			for _, c in table.clone(s.conexiones) do
				if c.Connected then
					c.fn(...)
				end
			end
		end
		return s
	end

	local function comprobarTipo(clase: string, prop: string, cat: string, tipo: string, valor: any)
		local t = tipoDe(valor)
		local ok
		if cat == "Primitive" then
			if tipo == "bool" then
				ok = t == "boolean"
			elseif tipo == "string" then
				ok = t == "string"
			else
				ok = t == "number"
			end
		elseif cat == "Enum" then
			ok = t == "EnumItem" and valor.EnumType == tipo
		elseif cat == "Class" then
			ok = valor == nil or (t == "Instance" and esUna(D[valor].clase, tipo))
		elseif tipo == "ContentId" or tipo == "ProtectedString" or tipo == "BinaryString" then
			ok = t == "string"
		else
			ok = t == tipo
		end
		if not ok then
			error(string.format("tipo incorrecto: %s.%s espera %s (%s) y recibió %s", clase, prop, tipo, cat, t), 3)
		end
	end

	local function predeterminado(clase: string, prop: string, cat: string, tipo: string): any
		if prop == "Name" then
			return clase
		elseif prop == "Size" and esUna(clase, "BasePart") then
			return vec3(4, 1.2, 2)
		elseif prop == "ViewportSize" then
			return Vector2.new(1920, 1080)
		elseif prop == "FieldOfView" then
			return 70
		elseif prop == "CameraType" then
			return Enum.CameraType.Fixed
		elseif prop == "ClockTime" then
			return 14
		elseif cat == "Primitive" then
			if tipo == "bool" then
				return PREDETERMINADOS_VERDADEROS[prop] == true
			elseif tipo == "string" then
				return ""
			end
			return 0
		elseif tipo == "Vector3" then
			return vec3(0, 0, 0)
		elseif tipo == "Vector2" then
			return Vector2.new(0, 0)
		elseif tipo == "CFrame" then
			return cf(0, 0, 0, IDENT)
		elseif tipo == "Color3" then
			return color3(0.5, 0.5, 0.5)
		elseif tipo == "UDim2" then
			return UDim2.new(0, 0, 0, 0)
		elseif tipo == "ContentId" or tipo == "ProtectedString" then
			return ""
		elseif cat == "Enum" then
			return (Enum :: any)[tipo][API.enums[tipo][1]]
		end
		return nil
	end

	local function nueva(clase: string): any
		local obj = setmetatable({}, INST)
		D[obj] = { clase = clase, props = {}, hijos = {}, padre = nil, attrs = {}, senales = {} }
		return obj
	end

	INST.__index = function(obj, k)
		local dat = D[obj]
		if k == "ClassName" then
			return dat.clase
		elseif k == "Parent" then
			return dat.padre
		end
		local m = miembro(dat.clase, k)
		if m then
			local tipo = string.sub(m, 1, 1)
			if tipo == "P" then
				local _, cat, nombreTipo = string.match(m, "^(P)|([^|]*)|([^|]*)|")
				if k == "Position" and esUna(dat.clase, "BasePart") then
					return (obj.CFrame :: any).Position
				end
				local valor = dat.props[k]
				if valor == nil then
					return predeterminado(dat.clase, k, cat, nombreTipo)
				end
				return valor
			elseif tipo == "F" then
				local c: string? = dat.clase
				while c do
					local impl = Metodos[c .. ":" .. k]
					if impl then
						return impl
					end
					c = API.clases[c] and API.clases[c].s
				end
				local clave = dat.clase .. ":" .. k
				d.noSimulados[clave] = (d.noSimulados[clave] or 0) + 1
				return function() end
			elseif tipo == "E" then
				dat.senales[k] = dat.senales[k] or senal()
				return dat.senales[k]
			end
		end
		for _, h in dat.hijos do
			if D[h].props.Name == k or (D[h].props.Name == nil and D[h].clase == k) then
				return h
			end
		end
		error(string.format("%s is not a valid member of %s \"%s\"", tostring(k), dat.clase, tostring(dat.props.Name or dat.clase)), 2)
	end

	local function desprender(obj)
		local dat = D[obj]
		if dat.padre then
			local hijos = D[dat.padre].hijos
			local i = table.find(hijos, obj)
			if i then
				table.remove(hijos, i)
			end
			dat.padre = nil
		end
	end

	INST.__newindex = function(obj, k, v)
		local dat = D[obj]
		if dat.destruido and k == "Parent" and v ~= nil then
			error("The Parent property of " .. tostring(dat.props.Name) .. " is locked (instancia destruida)", 2)
		end
		if k == "Parent" then
			if v ~= nil and tipoDe(v) ~= "Instance" then
				error("Parent espera una Instance", 2)
			end
			desprender(obj)
			if v then
				dat.padre = v
				table.insert(D[v].hijos, obj)
			end
			return
		end
		local m, declarante = miembro(dat.clase, k)
		if not m or string.sub(m, 1, 1) ~= "P" then
			error(string.format("%s is not a valid member of %s \"%s\"", tostring(k), dat.clase, tostring(dat.props.Name or dat.clase)), 2)
		end
		local cat, tipo, banderas = string.match(m, "^P|([^|]*)|([^|]*)|(.*)$")
		if string.find(banderas, "R") then
			error(string.format("Unable to assign property %s. Property is read only", k), 2)
		end
		if (string.find(banderas, "K") or string.find(banderas, "S")) and cfg.plugin == false then
			error(string.format("The current thread cannot write '%s' (lacking capability PluginOrOpenCloud)", k), 2)
		end
		comprobarTipo(declarante :: string, k, cat, tipo, v)
		if k == "Position" and esUna(dat.clase, "BasePart") then
			local actual = obj.CFrame
			dat.props.CFrame = cf(v.X, v.Y, v.Z, actual.r)
			return
		end
		dat.props[k] = v
	end
	INST.__tostring = function(obj)
		return tostring(D[obj].props.Name or D[obj].clase)
	end

	-- Métodos simulados -------------------------------------------------------------
	local function descendientes(obj, lista)
		for _, h in D[obj].hijos do
			table.insert(lista, h)
			descendientes(h, lista)
		end
		return lista
	end
	Metodos["Instance:GetChildren"] = function(self)
		return table.clone(D[self].hijos)
	end
	Metodos["Instance:GetDescendants"] = function(self)
		return descendientes(self, {})
	end
	Metodos["Instance:FindFirstChild"] = function(self, nombre, recursivo)
		for _, h in D[self].hijos do
			if h.Name == nombre then
				return h
			end
		end
		if recursivo then
			for _, h in descendientes(self, {}) do
				if h.Name == nombre then
					return h
				end
			end
		end
		return nil
	end
	Metodos["Instance:WaitForChild"] = function(self, nombre)
		local h = self:FindFirstChild(nombre)
		if not h then
			error("WaitForChild esperaría para siempre: " .. tostring(nombre) .. " en " .. self:GetFullName(), 2)
		end
		return h
	end
	Metodos["Instance:FindFirstChildOfClass"] = function(self, clase)
		for _, h in D[self].hijos do
			if D[h].clase == clase then
				return h
			end
		end
		return nil
	end
	Metodos["Instance:FindFirstChildWhichIsA"] = function(self, clase, recursivo)
		for _, h in (recursivo and descendientes(self, {}) or D[self].hijos) do
			if esUna(D[h].clase, clase) then
				return h
			end
		end
		return nil
	end
	Metodos["Instance:IsA"] = function(self, clase)
		if not API.clases[clase] then
			error("IsA: la clase " .. tostring(clase) .. " no está en api_roblox.luau (¿existe?)", 2)
		end
		return esUna(D[self].clase, clase)
	end
	Metodos["Instance:IsDescendantOf"] = function(self, otro)
		local p = D[self].padre
		while p do
			if p == otro then
				return true
			end
			p = D[p].padre
		end
		return false
	end
	Metodos["Instance:GetFullName"] = function(self)
		local partes = {}
		local p = self
		while p and D[p].clase ~= "DataModel" do
			table.insert(partes, 1, p.Name)
			p = D[p].padre
		end
		return table.concat(partes, ".")
	end
	Metodos["Instance:Destroy"] = function(self)
		for _, h in table.clone(D[self].hijos) do
			h:Destroy()
		end
		desprender(self)
		D[self].destruido = true
	end
	Metodos["Instance:ClearAllChildren"] = function(self)
		for _, h in table.clone(D[self].hijos) do
			h:Destroy()
		end
	end
	Metodos["Instance:SetAttribute"] = function(self, nombre, valor)
		if type(nombre) ~= "string" or #nombre > 100 or string.find(nombre, "[^%w%._/%-]") then
			error("nombre de atributo inválido: " .. tostring(nombre), 2)
		end
		if valor ~= nil and not ATRIBUTOS_VALIDOS[tipoDe(valor)] then
			error("tipo de atributo no admitido: " .. tipoDe(valor), 2)
		end
		D[self].attrs[nombre] = valor
	end
	Metodos["Instance:GetAttribute"] = function(self, nombre)
		return D[self].attrs[nombre]
	end
	Metodos["Instance:GetAttributes"] = function(self)
		return table.clone(D[self].attrs)
	end
	Metodos["Instance:Clone"] = function(self)
		local mapa = {}
		local function copiar(o)
			local c = nueva(D[o].clase)
			mapa[o] = c
			D[c].props = table.clone(D[o].props)
			D[c].attrs = table.clone(D[o].attrs)
			for _, h in D[o].hijos do
				local ch = copiar(h)
				D[ch].padre = c
				table.insert(D[c].hijos, ch)
			end
			return c
		end
		local raiz = copiar(self)
		for _, c in mapa do
			for k, v in D[c].props do
				if mapa[v] then
					D[c].props[k] = mapa[v]
				end
			end
		end
		return raiz
	end

	local function partesDe(obj): { any }
		local lista = {}
		if esUna(D[obj].clase, "BasePart") then
			table.insert(lista, obj)
		end
		for _, h in descendientes(obj, {}) do
			if esUna(D[h].clase, "BasePart") then
				table.insert(lista, h)
			end
		end
		return lista
	end
	local function cajaMundo(partes: { any }): (any, any)
		local minX, minY, minZ, maxX, maxY, maxZ = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge
		for _, p in partes do
			local c, s = p.CFrame, p.Size
			local r = c.r
			local ex = (math.abs(r[1]) * s.X + math.abs(r[2]) * s.Y + math.abs(r[3]) * s.Z) / 2
			local ey = (math.abs(r[4]) * s.X + math.abs(r[5]) * s.Y + math.abs(r[6]) * s.Z) / 2
			local ez = (math.abs(r[7]) * s.X + math.abs(r[8]) * s.Y + math.abs(r[9]) * s.Z) / 2
			minX, maxX = math.min(minX, c.x - ex), math.max(maxX, c.x + ex)
			minY, maxY = math.min(minY, c.y - ey), math.max(maxY, c.y + ey)
			minZ, maxZ = math.min(minZ, c.z - ez), math.max(maxZ, c.z + ez)
		end
		if #partes == 0 then
			return vec3(0, 0, 0), vec3(0, 0, 0)
		end
		return vec3((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2), vec3(maxX - minX, maxY - minY, maxZ - minZ)
	end
	d.cajaMundo = function(obj)
		return cajaMundo(partesDe(obj))
	end
	Metodos["Model:GetBoundingBox"] = function(self)
		local centro, tam = cajaMundo(partesDe(self))
		return cf(centro.X, centro.Y, centro.Z, IDENT), tam
	end
	Metodos["Model:GetExtentsSize"] = function(self)
		local _, tam = cajaMundo(partesDe(self))
		return tam
	end
	Metodos["PVInstance:GetPivot"] = function(self)
		if esUna(D[self].clase, "BasePart") then
			return self.CFrame
		end
		local primaria = D[self].props.PrimaryPart
		if primaria then
			return primaria.CFrame
		end
		local centro = cajaMundo(partesDe(self))
		return cf(centro.X, centro.Y, centro.Z, IDENT)
	end
	Metodos["PVInstance:PivotTo"] = function(self, destino)
		assert(tipoDe(destino) == "CFrame", "PivotTo espera CFrame")
		if esUna(D[self].clase, "BasePart") then
			self.CFrame = destino
			return
		end
		local delta = destino * self:GetPivot():Inverse()
		for _, p in partesDe(self) do
			p.CFrame = delta * p.CFrame
		end
	end
	Metodos["Model:GetScale"] = function(self)
		return D[self].escala or 1
	end
	Metodos["Model:ScaleTo"] = function(self, escala)
		local f = escala / (D[self].escala or 1)
		local pivote = self:GetPivot()
		for _, p in partesDe(self) do
			local rel = pivote:Inverse() * p.CFrame
			p.Size = p.Size * f
			p.CFrame = pivote * cf(rel.x * f, rel.y * f, rel.z * f, rel.r)
		end
		D[self].escala = escala
	end
	Metodos["ParticleEmitter:Emit"] = function(self, n)
		D[self].emitidas = (D[self].emitidas or 0) + (n or 16)
	end
	Metodos["Humanoid:AddAccessory"] = function(self, accesorio)
		accesorio.Parent = self.Parent
	end
	Metodos["InsertService:LoadAsset"] = function()
		error("HTTP 403 (doble de pruebas: sin red)", 2)
	end
	Metodos["HttpService:JSONDecode"] = function(_, texto)
		return decodificarJSON(texto)
	end
	Metodos["ScriptEditorService:UpdateSourceAsync"] = function(_, guion, fn)
		if cfg.plugin == false then
			error("The current thread cannot call 'UpdateSourceAsync' (lacking capability Plugin)", 2)
		end
		D[guion].props.Source = fn(D[guion].props.Source or "")
	end
	Metodos["ServiceProvider:GetService"] = function(_, nombre)
		local c = API.clases[nombre]
		if not c or not c.servicio then
			error("'" .. tostring(nombre) .. "' is not a valid Service name (o no está en api_roblox.luau)", 2)
		end
		if not servicios[nombre] then
			local s = nueva(nombre)
			D[s].props.Name = nombre
			D[s].padre = d.game
			table.insert(D[d.game].hijos, s)
			servicios[nombre] = s
		end
		return servicios[nombre]
	end
	Metodos["RunService:IsStudio"] = function()
		return true
	end
	Metodos["RunService:IsRunning"] = function()
		return cfg.corriendo == true
	end
	Metodos["RunService:IsEdit"] = function()
		return cfg.corriendo ~= true
	end
	Metodos["RunService:IsClient"] = function()
		return cfg.cliente == true or cfg.corriendo ~= true
	end
	Metodos["RunService:IsServer"] = function()
		return cfg.cliente ~= true
	end
	Metodos["RunService:IsRunMode"] = function()
		return cfg.corriendo == true and cfg.cliente ~= true
	end
	local pasosRender: { [string]: any } = {}
	Metodos["RunService:BindToRenderStep"] = function(_, nombre, prioridad, fn)
		if not (cfg.cliente and cfg.corriendo) then
			error("BindToRenderStep can only be called from the client", 2)
		end
		assert(type(prioridad) == "number", "BindToRenderStep: la prioridad debe ser un número")
		pasosRender[nombre] = fn
	end
	Metodos["RunService:UnbindFromRenderStep"] = function(_, nombre)
		pasosRender[nombre] = nil
	end

	-- Rayo contra cajas orientadas (ignora la forma real de bolas y cilindros).
	Metodos["WorldRoot:Raycast"] = function(self, origen, direccion, params)
		assert(tipoDe(origen) == "Vector3" and tipoDe(direccion) == "Vector3", "Raycast espera Vector3")
		local excluir = params and params.FilterDescendantsInstances or {}
		local mejor, mejorT = nil, math.huge
		for _, p in partesDe(self) do
			local salta = not p.CanQuery
			for _, e in excluir do
				if p == e or p:IsDescendantOf(e) then
					salta = true
					break
				end
			end
			if not salta then
				local inv = p.CFrame:Inverse()
				local o, dir = inv * origen, inv:VectorToWorldSpace(direccion)
				local h = p.Size / 2
				local t0, t1 = 0, 1
				local golpea = true
				for _, eje in { "X", "Y", "Z" } do
					local oo, dd, hh = o[eje], dir[eje], h[eje]
					if math.abs(dd) < 1e-9 then
						if math.abs(oo) > hh then
							golpea = false
							break
						end
					else
						local a, b = (-hh - oo) / dd, (hh - oo) / dd
						if a > b then
							a, b = b, a
						end
						t0, t1 = math.max(t0, a), math.min(t1, b)
						if t0 > t1 then
							golpea = false
							break
						end
					end
				end
				if golpea and t0 < mejorT then
					mejor, mejorT = p, t0
				end
			end
		end
		if not mejor then
			return nil
		end
		return {
			Instance = mejor, Position = origen + direccion * mejorT, Distance = direccion.Magnitude * mejorT,
			Normal = vec3(0, 1, 0), Material = mejor.Material,
		}
	end

	local Instance = {
		new = function(clase: string, padre: any?)
			local c = API.clases[clase]
			if not c then
				error("Unable to create an Instance of type \"" .. tostring(clase) .. "\" (no existe o no está en api_roblox.luau)", 2)
			end
			if not c.creable then
				error("Unable to create an Instance of type \"" .. clase .. "\" (no es creable)", 2)
			end
			local obj = nueva(clase)
			if padre then
				obj.Parent = padre
			end
			return obj
		end,
	}

	-- Árbol base -----------------------------------------------------------------------
	d.game = nueva("DataModel")
	D[d.game].props.Name = "Game"
	local function servicio(nombre: string)
		return (d.game :: any):GetService(nombre)
	end
	local ws = servicio("Workspace")
	local camara = nueva("Camera")
	camara.Parent = ws
	D[ws].props.CurrentCamera = camara
	for _, s in { "Lighting", "ReplicatedStorage", "ServerScriptService", "StarterGui", "RunService", "Players", "HttpService" } do
		servicio(s)
	end
	local sp = servicio("StarterPlayer")
	local sps = nueva("StarterPlayerScripts")
	sps.Parent = sp
	if cfg.cliente then
		local jugador = nueva("Player")
		D[jugador].props.Name = "Jugador"
		jugador.Parent = servicio("Players")
		D[servicio("Players")].props.LocalPlayer = jugador
		local gui = nueva("PlayerGui")
		gui.Parent = jugador
	end

	-- Reloj y tareas -------------------------------------------------------------------
	local pendientes: { any } = {}
	function d.avanzar(dt: number?)
		d.reloj += dt or (1 / 60)
		d.cuadros += 1
		for _, fn in table.clone(pasosRender) do
			fn(dt or (1 / 60))
		end
		local rs: any = servicios.RunService
		for _, nombre in { "PreRender", "RenderStepped", "PreSimulation", "Stepped", "PostSimulation", "Heartbeat" } do
			local s = D[rs].senales[nombre]
			if s then
				s:disparar(dt or (1 / 60))
			end
		end
		for i = #pendientes, 1, -1 do
			if pendientes[i].cuando <= d.reloj then
				local p = table.remove(pendientes, i)
				p.fn()
			end
		end
	end
	local tarea = {
		wait = function(t: number?)
			d.reloj += math.max(t or 0, 1 / 60)
			return t or (1 / 60)
		end,
		spawn = function(fn, ...)
			fn(...)
		end,
		defer = function(fn, ...)
			fn(...)
		end,
		delay = function(t, fn)
			table.insert(pendientes, { cuando = d.reloj + t, fn = fn })
		end,
	}

	entorno = setmetatable({
		game = d.game, workspace = ws, Instance = Instance, Enum = Enum, task = tarea,
		Vector3 = Vector3, Vector2 = Vector2, CFrame = CFrame, Color3 = Color3, UDim = UDim, UDim2 = UDim2,
		NumberRange = NumberRange, NumberSequence = NumberSequence, NumberSequenceKeypoint = NumberSequenceKeypoint,
		ColorSequence = ColorSequence, ColorSequenceKeypoint = ColorSequenceKeypoint, Content = Content,
		RaycastParams = {
			new = function()
				return setmetatable({}, { __type = "RaycastParams", __index = RP.__index })
			end,
		},
		typeof = tipoDe,
		type = function(v)
			local t = tipoDe(v)
			if t == "Vector3" then
				return "vector"
			elseif t ~= typeof(v) then
				return "userdata"
			end
			return type(v)
		end,
		os = setmetatable({
			clock = function()
				return d.reloj
			end,
		}, { __index = os }),
		tick = function()
			return d.reloj
		end,
		time = function()
			return d.reloj
		end,
		print = function(...)
			local partes = {}
			for i = 1, select("#", ...) do
				partes[i] = tostring((select(i, ...)))
			end
			table.insert(d.registro, table.concat(partes, " "))
		end,
		warn = function(...)
			table.insert(d.registro, "WARN " .. tostring((...)))
		end,
	}, { __index = getfenv(0) })

	-- require de ModuleScript: compila Source con el mismo entorno y `script` propio.
	local function ejecutar(fuente: string, nombre: string, guion: any?): any
		local fn, err = loadstring(fuente, "=" .. nombre)
		if not fn then
			error("error de sintaxis en " .. nombre .. ": " .. tostring(err), 0)
		end
		setfenv(fn, setmetatable({ script = guion }, { __index = entorno }))
		return fn()
	end
	entorno.require = function(modulo)
		if tipoDe(modulo) ~= "Instance" or not esUna(D[modulo].clase, "ModuleScript") then
			error("require espera un ModuleScript", 2)
		end
		if modulos[modulo] == nil then
			modulos[modulo] = ejecutar(D[modulo].props.Source or "", modulo.Name, modulo)
		end
		return modulos[modulo]
	end

	d.entorno = entorno
	d.ejecutar = ejecutar
	d.datos = D
	d.vec3 = vec3
	return d
end

return Doble
