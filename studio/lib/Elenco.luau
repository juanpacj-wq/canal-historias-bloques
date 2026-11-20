-- Elenco.luau
-- Crea personajes por código en modo edición y los ubica, sienta y posa sin animación.
--
-- DOS ESTILOS (parámetro `estilo`):
--   "propio" (valor por defecto): personaje de bloques armado solo con Part, con proporciones
--       propias (cabeza grande y redonda, torso corto). No usa Humanoid ni recursos del
--       avatar clásico, por las pautas de marca que restringen ese avatar en contenido
--       comercial. Nombres de piezas propios: Raiz, Torso, Cabeza, BrazoIzq, BrazoDer,
--       PiernaIzq, PiernaDer.
--   "r6": rig R6 estándar (HumanoidRootPart, Torso, Head, Left Arm...) con Humanoid,
--       BodyColors, calcomanía "face" y, si se dan id, Shirt/Pants y accesorios.
-- Los dos estilos comparten las mismas seis articulaciones Motor6D (raiz, cuello, hombroDer,
-- hombroIzq, caderaDer, caderaIzq) y la misma tabla de poses.
--
-- CÓMO SE POSA: cada pose da ángulos en grados por articulación, en los ejes del torso
-- (el personaje mira hacia -Z, su derecha es +X, arriba es +Y):
--   x: flexión. Positivo levanta brazo o pierna hacia adelante; en el cuello, mira arriba.
--   y: giro sobre el eje vertical.   z: apertura lateral (positivo lleva hacia +X).
-- Se escribe Motor6D.C0 = CFrame.new(posBase) * CFrame.Angles(x, y, z) * rotBase, y el C0
-- original queda en el atributo "C0Base". Además, en modo rígido (por defecto) todas las
-- piezas van ancladas y la biblioteca calcula ella misma el CFrame de cada pieza a partir de
-- los Motor6D (Elenco.actualizar), así la pose no depende de que el motor de física resuelva
-- las articulaciones en modo edición.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- verificó la geometría de las poses en ambos estilos (por ejemplo, que en "brazos_arriba" la
-- mano queda por encima de la cabeza, que "senalar" lleva el brazo al frente y que "sentado"
-- deja las piernas horizontales y el torso a la altura correcta) y la validez de cada
-- propiedad asignada según el volcado oficial.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: el aspecto de los personajes; que el Humanoid del
-- estilo "r6" no muestre nombre ni barra de vida y pinte Shirt/Pants con piezas ancladas;
-- InsertService:LoadAsset para accesorios desde execute_luau (hilo con permisos
-- restringidos); los C0/C1 heredados del R6 estándar se escribieron de memoria (no afectan
-- la pose porque C0 y C1 comparten rotación, pero sí importarían al mezclar con animaciones).

local InsertService = game:GetService("InsertService")

local Base = require(script.Parent.Base)
local Caras = require(script.Parent.Caras)

local Elenco = {}

Elenco.ESTILO_POR_DEFECTO = "propio"

local function v(x: number, y: number, z: number): Vector3
	return Vector3.new(x, y, z)
end

-- Rotaciones heredadas de las articulaciones del R6 estándar.
local function rotCuello(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, -1, 0, 0, 0, 0, 1, 0, 1, 0)
end
local function rotDer(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, 0, 0, 1, 0, 1, 0, -1, 0, 0)
end
local function rotIzq(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z, 0, 0, -1, 0, 1, 0, 1, 0, 0)
end

-- Cada estilo: piezas (nombre, tamaño, zona de color) y articulaciones (nombre del Motor6D,
-- pieza que lo contiene, Part0, Part1, C0 y C1). Las medidas están en studs.
Elenco.ESTILOS = {
	propio = {
		raiz = "Raiz", torso = "Torso", cabeza = "Cabeza",
		alturaRaiz = 2.4, -- centro de la raíz sobre el piso con el personaje de pie
		bajarSentado = 1.15, bajarAcostado = 1.9,
		radioCabeza = 1.1,
		cara = { ancho = 1.5, alto = 1.5, adelante = 1.12, subir = -0.05 },
		partes = {
			{ nombre = "Raiz", tam = v(2, 1.6, 1), zona = "raiz" },
			{ nombre = "Torso", tam = v(2, 1.6, 1), zona = "camisa" },
			{ nombre = "Cabeza", tam = v(2.2, 2.2, 2.2), zona = "piel", forma = "bola" },
			{ nombre = "BrazoDer", tam = v(0.8, 1.7, 0.8), zona = "manga" },
			{ nombre = "BrazoIzq", tam = v(0.8, 1.7, 0.8), zona = "manga" },
			{ nombre = "PiernaDer", tam = v(0.9, 1.6, 0.9), zona = "pantalon" },
			{ nombre = "PiernaIzq", tam = v(0.9, 1.6, 0.9), zona = "pantalon" },
		},
		articulaciones = {
			raiz = { nombre = "Cintura", en = "Raiz", p0 = "Raiz", p1 = "Torso", c0 = CFrame.new(), c1 = CFrame.new() },
			cuello = { nombre = "Cuello", en = "Torso", p0 = "Torso", p1 = "Cabeza", c0 = CFrame.new(0, 0.8, 0), c1 = CFrame.new(0, -1, 0) },
			hombroDer = { nombre = "HombroDer", en = "Torso", p0 = "Torso", p1 = "BrazoDer", c0 = CFrame.new(1, 0.65, 0), c1 = CFrame.new(-0.4, 0.7, 0) },
			hombroIzq = { nombre = "HombroIzq", en = "Torso", p0 = "Torso", p1 = "BrazoIzq", c0 = CFrame.new(-1, 0.65, 0), c1 = CFrame.new(0.4, 0.7, 0) },
			caderaDer = { nombre = "CaderaDer", en = "Torso", p0 = "Torso", p1 = "PiernaDer", c0 = CFrame.new(0.5, -0.8, 0), c1 = CFrame.new(0, 0.8, 0) },
			caderaIzq = { nombre = "CaderaIzq", en = "Torso", p0 = "Torso", p1 = "PiernaIzq", c0 = CFrame.new(-0.5, -0.8, 0), c1 = CFrame.new(0, 0.8, 0) },
		},
	},
	r6 = {
		raiz = "HumanoidRootPart", torso = "Torso", cabeza = "Head",
		alturaRaiz = 3, bajarSentado = 1.5, bajarAcostado = 2.5,
		radioCabeza = 0.625,
		cara = { ancho = 1.15, alto = 1.15, adelante = 0.64, subir = 0 },
		partes = {
			{ nombre = "HumanoidRootPart", tam = v(2, 2, 1), zona = "raiz" },
			{ nombre = "Torso", tam = v(2, 2, 1), zona = "camisa" },
			{ nombre = "Head", tam = v(2, 1, 1), zona = "piel", malla = "cabeza" },
			{ nombre = "Right Arm", tam = v(1, 2, 1), zona = "manga" },
			{ nombre = "Left Arm", tam = v(1, 2, 1), zona = "manga" },
			{ nombre = "Right Leg", tam = v(1, 2, 1), zona = "pantalon" },
			{ nombre = "Left Leg", tam = v(1, 2, 1), zona = "pantalon" },
		},
		articulaciones = {
			raiz = { nombre = "RootJoint", en = "HumanoidRootPart", p0 = "HumanoidRootPart", p1 = "Torso", c0 = rotCuello(0, 0, 0), c1 = rotCuello(0, 0, 0) },
			cuello = { nombre = "Neck", en = "Torso", p0 = "Torso", p1 = "Head", c0 = rotCuello(0, 1, 0), c1 = rotCuello(0, -0.5, 0) },
			hombroDer = { nombre = "Right Shoulder", en = "Torso", p0 = "Torso", p1 = "Right Arm", c0 = rotDer(1, 0.5, 0), c1 = rotDer(-0.5, 0.5, 0) },
			hombroIzq = { nombre = "Left Shoulder", en = "Torso", p0 = "Torso", p1 = "Left Arm", c0 = rotIzq(-1, 0.5, 0), c1 = rotIzq(0.5, 0.5, 0) },
			caderaDer = { nombre = "Right Hip", en = "Torso", p0 = "Torso", p1 = "Right Leg", c0 = rotDer(1, -1, 0), c1 = rotDer(0.5, 1, 0) },
			caderaIzq = { nombre = "Left Hip", en = "Torso", p0 = "Torso", p1 = "Left Leg", c0 = rotIzq(-1, -1, 0), c1 = rotIzq(-0.5, 1, 0) },
		},
	},
}

local ORDEN = { "raiz", "cuello", "hombroDer", "hombroIzq", "caderaDer", "caderaIzq" }
Elenco.ARTICULACIONES = ORDEN

-- TABLA DE POSES. Ángulos en grados por articulación; dx/dy/dz desplazan el pivote (studs).
-- `bajar`: "sentado" o "acostado" baja el torso lo que corresponda al estilo; `subir`: studs.
Elenco.POSES = {
	de_pie = {},
	brazos_arriba = { hombroDer = { x = 180, z = 15 }, hombroIzq = { x = 180, z = -15 } },
	senalar = { hombroDer = { x = 90 } },
	senalar_arriba = { hombroDer = { x = 135 }, cuello = { x = 20 } },
	ofrecer = { hombroDer = { x = 80 }, cuello = { x = -5 } },
	saludar = { hombroDer = { z = 150 } },
	cabeza_abajo = { cuello = { x = -35 }, hombroDer = { x = -5 }, hombroIzq = { x = -5 } },
	derrotado = { raiz = { x = -8 }, cuello = { x = -30 }, hombroDer = { x = 8 }, hombroIzq = { x = 8 } },
	mirar_arriba = { cuello = { x = 30 } },
	negar = { cuello = { y = 28 } },
	correr = {
		raiz = { x = -10 }, hombroDer = { x = -50 }, hombroIzq = { x = 60 },
		caderaDer = { x = 45 }, caderaIzq = { x = -35 },
	},
	caminar = { hombroDer = { x = -20 }, hombroIzq = { x = 20 }, caderaDer = { x = 20 }, caderaIzq = { x = -20 } },
	sentado = { bajar = "sentado", caderaDer = { x = 90 }, caderaIzq = { x = 90 }, hombroDer = { x = 20 }, hombroIzq = { x = 20 } },
	acostado = { bajar = "acostado", raiz = { x = 90 } },
	de_espaldas = { raiz = { y = 180 } },
	saltar = {
		subir = 1.5, hombroDer = { x = 160, z = 25 }, hombroIzq = { x = 160, z = -25 },
		caderaDer = { x = 30 }, caderaIzq = { x = -20 },
	},
	abrazo = { hombroDer = { x = 80, z = -25 }, hombroIzq = { x = 80, z = 25 } },
	encogerse = { hombroDer = { z = 40, dy = 0.15 }, hombroIzq = { z = -40, dy = 0.15 }, cuello = { z = 10 } },
	gritar = { raiz = { x = -6 }, cuello = { x = 14 }, hombroDer = { x = -20, z = 35 }, hombroIzq = { x = -20, z = -35 } },
	celular = { hombroDer = { x = 70, z = -15 }, cuello = { x = -20 } },
}

----------------------------------------------------------------------------------------
-- Lógica pura de poses
----------------------------------------------------------------------------------------

-- C0 resultante de girar una articulación `a` = {x, y, z, dx, dy, dz} sobre su C0 base.
function Elenco.c0ConPose(base: CFrame, a: any?, subir: number?): CFrame
	local g = a or {}
	local pos = base.Position + Vector3.new(g.dx or 0, (g.dy or 0) + (subir or 0), g.dz or 0)
	return CFrame.new(pos) * CFrame.Angles(math.rad(g.x or 0), math.rad(g.y or 0), math.rad(g.z or 0)) * base.Rotation
end

-- Acepta el nombre de una pose o una tabla con el mismo formato. Devuelve tabla y aviso.
function Elenco.resolverPose(pose: any): (any, string?)
	if typeof(pose) == "table" then
		return pose, nil
	end
	if pose == nil then
		return Elenco.POSES.de_pie, nil
	end
	local clave = Base.normalizar(tostring(pose))
	local tabla = Elenco.POSES[clave]
	if tabla then
		return tabla, nil
	end
	return Elenco.POSES.de_pie, "pose inexistente: " .. tostring(pose)
end

----------------------------------------------------------------------------------------
-- Construcción
----------------------------------------------------------------------------------------

-- Peinados de piezas. Medidas en radios de cabeza; +Z es la nuca (el personaje mira a -Z).
local PELOS: { [string]: { any } } = {
	ninguno = {}, calvo = {},
	-- El "Casco" es una bola un poco mayor que la cabeza, corrida hacia arriba y hacia la
	-- nuca: deja la cara libre y da una línea de pelo redonda (comprobado en Studio; las tapas
	-- de bloque se veían como un sombrero cuadrado en los planos cercanos).
	corto = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
	},
	largo = {
		{ n = "Casco", tam = { 2.26, 2.26, 2.26 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Melena", tam = { 2.1, 2.3, 1.5 }, pos = { 0, -0.75, 0.62 }, forma = "ovalo" },
	},
	coletas = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "ColetaDer", tam = { 1.05, 1.05, 1.05 }, pos = { 1.3, 0.25, 0.35 }, forma = "bola" },
		{ n = "ColetaIzq", tam = { 1.05, 1.05, 1.05 }, pos = { -1.3, 0.25, 0.35 }, forma = "bola" },
	},
	copete = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Copete", tam = { 1.5, 0.75, 1.0 }, pos = { 0.15, 1.12, -0.5 }, forma = "ovalo" },
	},
	rizado = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Rizo1", tam = { 1.1, 1.1, 1.1 }, pos = { -0.75, 1.0, -0.1 }, forma = "bola" },
		{ n = "Rizo2", tam = { 1.2, 1.2, 1.2 }, pos = { 0, 1.2, 0.05 }, forma = "bola" },
		{ n = "Rizo3", tam = { 1.1, 1.1, 1.1 }, pos = { 0.75, 1.0, -0.1 }, forma = "bola" },
		{ n = "Rizo4", tam = { 1.1, 1.1, 1.1 }, pos = { -1.0, 0.45, 0.45 }, forma = "bola" },
		{ n = "Rizo5", tam = { 1.1, 1.1, 1.1 }, pos = { 1.0, 0.45, 0.45 }, forma = "bola" },
	},
	mono = {
		{ n = "Casco", tam = { 2.24, 2.24, 2.24 }, pos = { 0, 0.36, 0.26 }, forma = "bola" },
		{ n = "Mono", tam = { 1.0, 1.0, 1.0 }, pos = { 0, 1.45, 0.45 }, forma = "bola" },
	},
	abuelo = {
		{ n = "LadoDer", tam = { 0.95, 0.95, 0.95 }, pos = { 0.92, 0.25, 0.25 }, forma = "bola" },
		{ n = "LadoIzq", tam = { 0.95, 0.95, 0.95 }, pos = { -0.92, 0.25, 0.25 }, forma = "bola" },
		{ n = "Nuca", tam = { 1.7, 1.1, 0.9 }, pos = { 0, 0.1, 0.75 }, forma = "ovalo" },
	},
	gorra = {
		{ n = "Casco", tam = { 2.26, 2.26, 2.26 }, pos = { 0, 0.42, 0.2 }, forma = "bola" },
		{ n = "Visera", tam = { 1.7, 0.18, 1.0 }, pos = { 0, 0.62, -1.25 } },
	},
}
Elenco.PELOS = PELOS

local function estiloDe(pj: Instance): any
	return Elenco.ESTILOS[pj:GetAttribute("Estilo") or "propio"] or Elenco.ESTILOS.propio
end

local function parte(pj: Instance, nombre: string): BasePart
	return pj:FindFirstChild(nombre) :: BasePart
end

local function pegar(pj: Model, cabeza: BasePart, pieza: BasePart, rel: CFrame, rigido: boolean)
	pieza.CFrame = cabeza.CFrame * rel
	pieza:SetAttribute("PegadoA", cabeza.Name)
	pieza:SetAttribute("Rel", rel)
	pieza.Anchored = rigido
	pieza.Massless = true
	if not rigido then
		local soldadura = Instance.new("WeldConstraint")
		soldadura.Part0 = cabeza
		soldadura.Part1 = pieza
		soldadura.Parent = pieza
	end
	pieza.Parent = pj
end

-- Crea un personaje. Campos de `def` (todos opcionales salvo id o nombre):
--   id, nombre, estilo ("propio" | "r6"), piel, camisa, pantalon (colores "#RRGGBB"),
--   mangas ("cortas" = brazos color piel, "largas" = color camisa),
--   pelo = { tipo = "corto"|"largo"|"coletas"|"copete"|"abuelo"|"gorra"|"ninguno", color },
--   cabeza = "bola" | "bloque" (solo estilo propio), cara (expresión inicial),
--   rigido (true por defecto), padre.
--   Solo estilo "r6": camisa_id, pantalon_id (id de la IMAGEN de la plantilla de ropa, no
--   del artículo del catálogo; 0 = sin ropa), accesorios = { id, ... } (0 se ignora).
function Elenco.crear(def: any): Model
	local nombreEstilo = def.estilo or Elenco.ESTILO_POR_DEFECTO
	local estilo = Elenco.ESTILOS[nombreEstilo]
	if not estilo then
		nombreEstilo, estilo = "propio", Elenco.ESTILOS.propio
	end
	local rigido = def.rigido ~= false
	local padre = def.padre or Base.subcarpeta("Elenco")
	local nombre = def.nombre or def.id or "Personaje"
	local anterior = padre:FindFirstChild(nombre) or Base.bodega():FindFirstChild(nombre)
	if anterior then
		anterior:Destroy()
	end

	local colores = {
		piel = Base.color(def.piel, Color3.fromRGB(242, 201, 160)),
		camisa = Base.color(def.camisa, Color3.fromRGB(59, 130, 246)),
		pantalon = Base.color(def.pantalon, Color3.fromRGB(40, 48, 66)),
		raiz = Color3.new(1, 1, 1),
	}
	colores.manga = (def.mangas == "largas") and colores.camisa or colores.piel

	local pj = Instance.new("Model")
	pj.Name = nombre
	pj:SetAttribute("Estilo", nombreEstilo)
	pj:SetAttribute("Rigido", rigido)
	pj:SetAttribute("Cabeza", estilo.cabeza)
	pj:SetAttribute("RadioCabeza", estilo.radioCabeza)
	pj:SetAttribute("IdElenco", def.id or nombre)

	for _, p in estilo.partes do
		local forma, tam = p.forma, p.tam
		if p.nombre == estilo.cabeza and nombreEstilo == "propio" and def.cabeza == "bloque" then
			forma, tam = "bloque", v(2.1, 1.9, 1.9)
		end
		local pieza = Base.pieza({
			nombre = p.nombre, tam = tam, forma = forma, color = colores[p.zona],
			transparencia = (p.zona == "raiz") and 1 or 0, sombra = p.zona ~= "raiz",
			consultable = p.zona ~= "raiz",
			anclada = rigido or p.zona == "raiz",
		})
		if p.zona ~= "raiz" then
			pieza.Massless = true
		end
		if p.malla == "cabeza" then
			local malla = Instance.new("SpecialMesh")
			malla.MeshType = Enum.MeshType.Head
			malla.Scale = v(1.25, 1.25, 1.25)
			malla.Parent = pieza
			local calcomania = Instance.new("Decal")
			calcomania.Name = "face"
			calcomania.Face = Enum.NormalId.Front
			calcomania.Transparency = 1
			calcomania.Parent = pieza
		end
		pieza.Parent = pj
	end

	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = Instance.new("Motor6D")
		motor.Name = art.nombre
		motor.Part0 = parte(pj, art.p0)
		motor.Part1 = parte(pj, art.p1)
		motor.C0 = art.c0
		motor.C1 = art.c1
		motor:SetAttribute("C0Base", art.c0)
		motor:SetAttribute("Clave", clave)
		motor.Parent = parte(pj, art.en)
	end
	pj.PrimaryPart = parte(pj, estilo.raiz)

	local cabeza = parte(pj, estilo.cabeza)
	local cara = estilo.cara
	local adelante = cara.adelante
	if nombreEstilo == "propio" and def.cabeza == "bloque" then
		adelante = 0.97
	end
	cabeza:SetAttribute("CaraAncho", cara.ancho)
	cabeza:SetAttribute("CaraAlto", cara.alto)
	cabeza:SetAttribute("CaraAdelante", adelante)
	cabeza:SetAttribute("CaraSubir", cara.subir)

	local pelo = def.pelo or {}
	local tipoPelo = (typeof(pelo) == "string") and pelo or pelo.tipo or "corto"
	local colorPelo = Base.color((typeof(pelo) == "table") and pelo.color or nil, Color3.fromRGB(75, 46, 26))
	local r = estilo.radioCabeza
	for _, m in PELOS[tipoPelo] or PELOS.corto do
		local pieza = Base.pieza({
			nombre = "Pelo" .. m.n, tam = Base.vec(m.tam) * r, forma = m.forma, color = colorPelo,
			consultable = false,
		})
		pegar(pj, cabeza, pieza, CFrame.new(Base.vec(m.pos) * r), rigido)
	end

	if nombreEstilo == "r6" then
		local humanoide = Instance.new("Humanoid")
		humanoide.RigType = Enum.HumanoidRigType.R6
		humanoide.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoide.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		humanoide.RequiresNeck = false
		humanoide.BreakJointsOnDeath = false
		humanoide.EvaluateStateMachine = false
		humanoide.Parent = pj
		local cuerpo = Instance.new("BodyColors")
		cuerpo.HeadColor3 = colores.piel
		cuerpo.TorsoColor3 = colores.camisa
		cuerpo.LeftArmColor3 = colores.manga
		cuerpo.RightArmColor3 = colores.manga
		cuerpo.LeftLegColor3 = colores.pantalon
		cuerpo.RightLegColor3 = colores.pantalon
		cuerpo.Parent = pj
		if (def.camisa_id or 0) ~= 0 then
			local camisa = Instance.new("Shirt")
			camisa.ShirtTemplate = "rbxassetid://" .. tostring(def.camisa_id)
			camisa.Parent = pj
		end
		if (def.pantalon_id or 0) ~= 0 then
			local pantalon = Instance.new("Pants")
			pantalon.PantsTemplate = "rbxassetid://" .. tostring(def.pantalon_id)
			pantalon.Parent = pj
		end
	end

	pj.Parent = padre
	Elenco.posar(pj, "de_pie")
	Elenco.ubicar(pj, CFrame.new(Base.vec(def.pos)))
	Caras.aplicar(pj, def.cara or "neutra")
	Elenco.actualizar(pj)

	if nombreEstilo == "r6" then
		for _, id in def.accesorios or {} do
			if id ~= 0 then
				Elenco.accesorio(pj, id)
			end
		end
	end
	return pj
end

-- Inserta un accesorio del catálogo por id (solo estilo "r6"). Devuelve éxito y mensaje.
function Elenco.accesorio(pj: Model, id: number): (boolean, string?)
	local humanoide = pj:FindFirstChildOfClass("Humanoid")
	if not humanoide then
		return false, "los accesorios por id solo aplican al estilo r6"
	end
	local ok, resultado = pcall(function()
		return InsertService:LoadAsset(id)
	end)
	if not ok or not resultado then
		return false, "no se pudo cargar el recurso " .. tostring(id) .. ": " .. tostring(resultado)
	end
	local accesorio = resultado:FindFirstChildWhichIsA("Accessory", true)
	if not accesorio then
		resultado:Destroy()
		return false, "el recurso " .. tostring(id) .. " no trae un Accessory"
	end
	humanoide:AddAccessory(accesorio)
	resultado:Destroy()
	return true, nil
end

----------------------------------------------------------------------------------------
-- Poses y ubicación
----------------------------------------------------------------------------------------

-- Recalcula el CFrame de cada pieza a partir de los Motor6D (solo en modo rígido).
function Elenco.actualizar(pj: Model)
	if pj:GetAttribute("Rigido") ~= true then
		return
	end
	local estilo = estiloDe(pj)
	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = pj:FindFirstChild(art.nombre, true)
		if motor and motor:IsA("Motor6D") and motor.Part0 and motor.Part1 then
			motor.Part1.CFrame = motor.Part0.CFrame * motor.C0 * motor.C1:Inverse()
		end
	end
	for _, d in pj:GetDescendants() do
		if d:IsA("BasePart") then
			local destino = d:GetAttribute("PegadoA")
			local rel = d:GetAttribute("Rel")
			if destino and rel then
				local ancla = pj:FindFirstChild(destino)
				if ancla and ancla:IsA("BasePart") then
					d.CFrame = ancla.CFrame * rel
				end
			end
		end
	end
end

-- Aplica una pose (nombre de Elenco.POSES o tabla). Devuelve un aviso si no existía.
function Elenco.posar(pj: Model, pose: any): string?
	local tabla, aviso = Elenco.resolverPose(pose)
	local estilo = estiloDe(pj)
	local subir = tabla.subir or 0
	if tabla.bajar == "sentado" then
		subir -= estilo.bajarSentado
	elseif tabla.bajar == "acostado" then
		subir -= estilo.bajarAcostado
	end
	for _, clave in ORDEN do
		local art = estilo.articulaciones[clave]
		local motor = pj:FindFirstChild(art.nombre, true)
		if motor and motor:IsA("Motor6D") then
			local base = motor:GetAttribute("C0Base")
			if typeof(base) ~= "CFrame" then
				base = motor.C0
				motor:SetAttribute("C0Base", base)
			end
			motor.C0 = Elenco.c0ConPose(base, tabla[clave], (clave == "raiz") and subir or 0)
		end
	end
	pj:SetAttribute("Pose", (typeof(pose) == "string") and pose or "personalizada")
	Elenco.actualizar(pj)
	return aviso
end

-- CFrame de pies: posición en el piso; `giro` en grados, 0 = mirando hacia +Z (la cámara),
-- positivo gira hacia +X.
function Elenco.cfPies(pos: any, giro: number?): CFrame
	return CFrame.new(Base.vec(pos)) * CFrame.Angles(0, math.rad(180 + (giro or 0)), 0)
end

-- Ubica al personaje con los pies en `cfPies` (posición y orientación).
function Elenco.ubicar(pj: Model, cfPies: CFrame)
	local estilo = estiloDe(pj)
	local destino = cfPies * CFrame.new(0, estilo.alturaRaiz, 0)
	if pj:GetAttribute("Rigido") == true then
		parte(pj, estilo.raiz).CFrame = destino
		Elenco.actualizar(pj)
	else
		pj:PivotTo(destino)
	end
end

function Elenco.pies(pj: Model): CFrame
	local estilo = estiloDe(pj)
	return parte(pj, estilo.raiz).CFrame * CFrame.new(0, -estilo.alturaRaiz, 0)
end

function Elenco.cabeza(pj: Model): BasePart
	return parte(pj, estiloDe(pj).cabeza)
end

function Elenco.parte(pj: Model, nombre: string): BasePart?
	local p = pj:FindFirstChild(nombre)
	return (p and p:IsA("BasePart")) and p or nil
end

-- CFrame de un punto útil del cuerpo para pegarle utilería: "mano_der", "mano_izq",
-- "cabeza_arriba" o "pecho". El eje -Z del resultado es el frente del personaje.
function Elenco.punto(pj: Model, nombre: string): CFrame?
	local estilo = estiloDe(pj)
	local art = estilo.articulaciones
	if nombre == "mano_der" or nombre == "mano_izq" then
		local brazo = parte(pj, (nombre == "mano_der") and art.hombroDer.p1 or art.hombroIzq.p1)
		return brazo.CFrame * CFrame.new(0, -brazo.Size.Y / 2, 0)
	elseif nombre == "cabeza_arriba" then
		local cabeza = parte(pj, estilo.cabeza)
		return cabeza.CFrame * CFrame.new(0, estilo.radioCabeza, 0)
	elseif nombre == "pecho" then
		local torso = parte(pj, estilo.torso)
		return torso.CFrame * CFrame.new(0, 0, -torso.Size.Z / 2)
	end
	local p = pj:FindFirstChild(nombre)
	return (p and p:IsA("BasePart")) and p.CFrame or nil
end

-- Gira al personaje sobre sus pies para que mire hacia un punto (ignora la altura).
function Elenco.mirarA(pj: Model, punto: Vector3)
	local pos = Elenco.pies(pj).Position
	local plano = Vector3.new(punto.X - pos.X, 0, punto.Z - pos.Z)
	if plano.Magnitude < 0.01 then
		return
	end
	Elenco.ubicar(pj, CFrame.lookAt(pos, pos + plano))
end

-- Sienta al personaje sobre un asiento: `cfAsiento` es el punto de apoyo (cara superior).
function Elenco.sentar(pj: Model, cfAsiento: CFrame)
	Elenco.posar(pj, "sentado")
	Elenco.ubicar(pj, cfAsiento)
end

function Elenco.cara(pj: Model, nombre: string): (string, string?)
	return Caras.aplicar(pj, nombre)
end

function Elenco.ocultar(pj: Model)
	Base.mover(pj, Base.bodega())
end

function Elenco.mostrar(pj: Model)
	Base.mover(pj, Base.subcarpeta("Elenco"))
end

-- Fila de personajes, uno por pose, para revisar todas las poses en una captura.
function Elenco.muestrario(estilo: string?, origen: Vector3?): Model
	local raiz = Base.raiz()
	local viejo = raiz:FindFirstChild("MuestrarioPoses")
	if viejo then
		viejo:Destroy()
	end
	local modelo = Instance.new("Model")
	modelo.Name = "MuestrarioPoses"
	modelo.Parent = raiz
	local nombres = {}
	for nombre in Elenco.POSES do
		table.insert(nombres, nombre)
	end
	table.sort(nombres)
	local base = origen or Vector3.new(0, 0, 0)
	for i, nombre in nombres do
		local col, fila = (i - 1) % 7, math.floor((i - 1) / 7)
		local pj = Elenco.crear({ id = "pose_" .. nombre, estilo = estilo, padre = modelo, cara = "feliz" })
		Elenco.posar(pj, nombre)
		Elenco.ubicar(pj, Elenco.cfPies(base + Vector3.new((col - 3) * 5, 0, -fila * 7), 0))
	end
	return modelo
end

return Elenco
