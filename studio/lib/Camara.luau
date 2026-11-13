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
