-- cargar.luau
-- GENERADO por studio/empaquetar.py a partir de studio/lib/*.luau, studio/Director.luau y
-- studio/empaque/. No lo edites a mano: cambia los fuentes y vuelve a empaquetar.
--
-- Qué hace: instala o actualiza toda la biblioteca como ModuleScript dentro de
-- ReplicatedStorage.Historias y deja los dos lanzadores (Script en ServerScriptService y
-- LocalScript en StarterPlayer.StarterPlayerScripts). Está pensado para pegarse completo en
-- una sola llamada de execute_luau con datamodel_type = "Edit".
--
-- PERMISOS (comprobado en la referencia oficial y en el volcado de la API de Studio 0.747):
-- la propiedad Source de Script, LocalScript y ModuleScript exige la capacidad
-- "PluginOrOpenCloud" para leerla y escribirla, y ScriptEditorService:UpdateSourceAsync
-- exige seguridad de plugin (PluginSecurity). La documentación del servidor MCP no dice con
-- qué permisos corre execute_luau; reportes de la comunidad indican que corre con
-- capacidades restringidas, y la propia herramienta pide crear scripts con `multi_edit`.
-- Por eso este bloque intenta primero Source, luego UpdateSourceAsync, y si ninguno se
-- permite devuelve un mensaje claro: en ese caso instala con la herramienta `multi_edit`
-- usando studio/cargar_multi_edit.json, o usa studio/monolito.luau, que no necesita scripts.
--
-- Al actualizar, cada ModuleScript se reemplaza por una instancia nueva (no se edita la
-- vieja) para que `require` no devuelva una copia en caché de la versión anterior.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VERSION = "@@VERSION@@"
local FUENTES: { [string]: string } = {}
local LANZADORES: { [string]: string } = {}
--@@FUENTES@@

local ORDEN = { @@ORDEN@@ }

local function escribir(contenedor: any, fuente: string): (boolean, string?)
	local ok, err = pcall(function()
		contenedor.Source = fuente
	end)
	if ok then
		return true, nil
	end
	local ok2, err2 = pcall(function()
		game:GetService("ScriptEditorService"):UpdateSourceAsync(contenedor, function()
			return fuente
		end)
	end)
	if ok2 then
		return true, nil
	end
	return false, tostring(err) .. " / " .. tostring(err2)
end

local errores: { string } = {}
local instalados: { string } = {}

local function instalar(clase: string, nombre: string, padre: Instance, fuente: string)
	local nuevo = Instance.new(clase)
	nuevo.Name = nombre
	local ok, err = escribir(nuevo, fuente)
	if not ok then
		nuevo:Destroy()
		table.insert(errores, nombre .. ": " .. tostring(err))
		return
	end
	local viejo = padre:FindFirstChild(nombre)
	if viejo then
		viejo:Destroy()
	end
	nuevo.Parent = padre
	table.insert(instalados, nombre)
end

local carpeta = ReplicatedStorage:FindFirstChild("Historias")
if not carpeta then
	carpeta = Instance.new("Folder")
	carpeta.Name = "Historias"
	carpeta.Parent = ReplicatedStorage
end

for _, nombre in ORDEN do
	instalar("ModuleScript", nombre, carpeta, FUENTES[nombre])
end
instalar("Script", "HistoriasRodar", game:GetService("ServerScriptService"), LANZADORES.Rodar)
instalar("LocalScript", "HistoriasRodarCliente", game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), LANZADORES.RodarCliente)
carpeta:SetAttribute("Version", VERSION)

pcall(function()
	game:GetService("ChangeHistoryService"):SetWaypoint("Historias: instalar biblioteca " .. VERSION)
end)

if #errores > 0 then
	return "Historias " .. VERSION .. ": NO se pudo escribir Source en " .. #errores .. " script(s). "
		.. "Este hilo no tiene la capacidad PluginOrOpenCloud. Instala con la herramienta multi_edit "
		.. "(studio/cargar_multi_edit.json) o usa studio/monolito.luau. Primer error: " .. errores[1]
end
return "Historias " .. VERSION .. " instalada en ReplicatedStorage.Historias: " .. table.concat(instalados, ", ")
