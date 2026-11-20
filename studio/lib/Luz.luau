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
