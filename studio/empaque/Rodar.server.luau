-- Rodar.server.luau
-- Lanzador para modo Run (sin jugador). Va como Script en ServerScriptService.
-- Solo actúa si el lugar se configuró con Director.configurarLugar("run") y Studio está en
-- modo Run; en modo Play no hace nada (ahí rueda el LocalScript del cliente).
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: que la cámara de Studio obedezca a un Script de
-- servidor en modo Run.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local carpeta = ReplicatedStorage:WaitForChild("Historias")
if carpeta:GetAttribute("AutoRodar") == true and carpeta:GetAttribute("Modo") == "run" and RunService:IsRunMode() then
	local Director = require(carpeta:WaitForChild("Director"))
	Director.rodarDesdeDatos()
end
