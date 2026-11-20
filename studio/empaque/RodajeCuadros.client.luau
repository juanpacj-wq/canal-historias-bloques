-- RodajeCuadroACuadro (LocalScript en StarterPlayer.StarterPlayerScripts)
-- Rodaje cuadro a cuadro: no reproduce en tiempo real. Espera a que alguien escriba el
-- atributo "T" (segundos) en ReplicatedStorage.Historias, monta ese instante exacto de la
-- secuencia, deja pasar dos cuadros de dibujo y responde escribiendo "Hecho" con el mismo
-- valor. Un programa externo captura la pantalla entre un cuadro y el siguiente.
-- Solo actua si el atributo "Modo" es "cuadros".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local carpeta = ReplicatedStorage:WaitForChild("Historias")
if carpeta:GetAttribute("Modo") ~= "cuadros" then
	return
end

local H = require(carpeta:WaitForChild("Director"))
local datos = carpeta:WaitForChild("Datos")
local plan = datos:WaitForChild("Plan").Value
local puesta = datos:WaitForChild("Puesta").Value

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
pcall(function() game:GetService("UserInputService").MouseIconEnabled = false end)
task.spawn(function()
	for _ = 1, 40 do
		if pcall(function() StarterGui:SetCore("TopbarEnabled", false) end) then break end
		task.wait(0.25)
	end
end)

-- Pantalla de calibracion (magenta a pantalla completa) para ubicar la vista en el escritorio.
local jugador = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "RodajeCalibracion"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.ResetOnSpawn = false
local marco = Instance.new("Frame")
marco.Size = UDim2.fromScale(1, 1)
marco.BorderSizePixel = 0
marco.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
marco.Visible = false
marco.Parent = gui
gui.Parent = jugador:WaitForChild("PlayerGui")

local ctx = H.preparar((plan ~= "") and plan or nil, puesta, { version = "detalle", ceder = false })
local indice = 0
local ultimoReloj = os.clock()
local fps = carpeta:GetAttribute("Fps") or 30
local escala = 0.1

local function emisores()
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.TimeScale = escala
		end
	end
end

local function montar(t: number)
	local i = H.indiceEn(ctx.planos, t, 1)
	if i ~= indice then
		H.aplicarPlano(ctx, i)
		indice = i
		-- En cada plano con lluvia o nieve las particulas se dejan correr un momento en tiempo
		-- real, para que el plano empiece con ellas ya cayendo frente a la camara.
		local escena = ctx.estado and ctx.estado.escena
		local clima = escena and escena:GetAttribute("Clima")
		local carpetaClima = escena and escena:FindFirstChild("Clima")
		if carpetaClima and (clima == "lluvia" or clima == "nieve") then
			for _, d in carpetaClima:GetDescendants() do
				if d:IsA("ParticleEmitter") then
					d.TimeScale = 1
				end
			end
			task.wait(1.6)
		end
		emisores()
	end
	H.cuadro(ctx, t - ctx.planos[i].inicio)
	-- Las particulas corren en tiempo real: se frenan para que avancen 1/fps por cuadro.
	local ahora = os.clock()
	local real = math.clamp(ahora - ultimoReloj, 0.02, 2)
	ultimoReloj = ahora
	escala = escala * 0.8 + ((1 / fps) / real) * 0.2
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.TimeScale = escala
		end
	end
end

carpeta:GetAttributeChangedSignal("T"):Connect(function()
	local t = carpeta:GetAttribute("T")
	if typeof(t) ~= "number" then
		return
	end
	local ok, err = pcall(montar, t)
	if not ok then
		warn("[Rodaje] " .. tostring(err))
		carpeta:SetAttribute("Error", tostring(err))
	end
	RunService.RenderStepped:Wait()
	RunService.RenderStepped:Wait()
	carpeta:SetAttribute("Hecho", t)
end)
carpeta:GetAttributeChangedSignal("Calibrar"):Connect(function()
	marco.Visible = carpeta:GetAttribute("Calibrar") == true
end)

montar(0)
carpeta:SetAttribute("Listo", #ctx.planos)
print("[Rodaje] cuadro a cuadro listo: " .. #ctx.planos .. " planos, " .. tostring(ctx.duracion) .. " s")
