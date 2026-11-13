-- RodarCliente.client.luau
-- Lanzador para modo Play (el recomendado para grabar). Va como LocalScript en
-- StarterPlayer.StarterPlayerScripts. Solo actúa si el lugar se configuró con
-- Director.configurarLugar("play"). Todo lo que cambia es local al cliente y se descarta al
-- detener la prueba.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: todo este flujo (cámara Scriptable girada 90 grados,
-- interfaz oculta, destello de 2 cuadros).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local carpeta = ReplicatedStorage:WaitForChild("Historias")
if carpeta:GetAttribute("AutoRodar") == true and carpeta:GetAttribute("Modo") == "play" then
	local Director = require(carpeta:WaitForChild("Director"))
	Director.rodarDesdeDatos()
end
