-- Director.luau
-- Director de planos: lee el plan (tiempos del audio) y la puesta en escena, prepara todo y
-- ejecuta cada plano en su tiempo exacto.
--
-- ENTRADAS
--   plan.json   (lo produce la herramienta de Python de la voz):
--     {"video": "...", "duracion": 98.4, "planos": [{"n": 1, "inicio": 0.0, "fin": 1.62,
--      "texto": "...", "escenario": "...", "en_pantalla": "...", "cara": "...", "camara": "M"}]}
--   puesta.json (lo escribe el chat de Claude a partir del plan; esquema completo en
--     studio/README.md). Los tiempos del plan MANDAN: si un plano aparece en los dos archivos,
--     inicio, fin y texto salen del plan y la puesta aporta lo demás. Sin plan, se usan los
--     tiempos que traiga la puesta.
--
-- MODOS
--   Director.preparar(plan, puesta, opciones) -> ctx   construye o reutiliza todo
--   Director.foto(ctx, n, fraccion)       salta al plano n y lo deja quieto (para screen_capture)
--   Director.ensayo(ctx)                  recorre todos los planos y reporta problemas
--   Director.reproducir(ctx, opciones)    destello de sincronía y secuencia en tiempo real
--
-- DÓNDE Y CÓMO CORRE
--   * foto y ensayo: en modo EDICIÓN, llamados desde execute_luau con datamodel_type "Edit".
--     No ponen CameraType en Scriptable (Studio lo restaura tras cada llamada).
--   * reproducir, para grabar: modo JUEGO con cliente (Play, lo que inicia start_stop_play),
--     desde un LocalScript en StarterPlayer.StarterPlayerScripts (studio/empaque/
--     RodarCliente.client.luau). Motivo: la cámara Scriptable, ocultar la interfaz (CoreGui,
--     barra superior) y el paso de render (BindToRenderStep) solo existen en el cliente, y
--     los cambios que hace el cliente son locales y se descartan al detener.
--   * Alternativa sin jugador ni interfaz: modo Run con un Script en ServerScriptService
--     (studio/empaque/Rodar.server.luau). Ahí no hay cliente, así que el Director usa
--     Heartbeat. Queda por comprobar que la cámara de Studio obedezca en ese modo.
--   * La línea de comandos (o execute_luau en edición) NO sirve para grabar: el código corre
--     en el hilo principal y no está comprobado que una conexión siga viva al terminar la
--     llamada.
--
-- TIEMPO: no se encadena task.wait. En cada cuadro se mide t = os.clock() - t0 y se decide
-- qué plano toca; el error por plano es de un cuadro como máximo y no se acumula.
--
-- DESTELLO DE SINCRONÍA: tras una espera previa, la pantalla queda en blanco durante 2
-- cuadros (ColorCorrection con Brightness = 1 y, en el cliente, un Frame a pantalla completa).
-- El INSTANTE CERO es el primer cuadro NO blanco después del destello: ahí empieza el plano 1
-- y ahí se alinea el segundo 0 del audio en el montaje.
--
-- COMPROBADO FUERA DE STUDIO: luau-analyze; con el intérprete luau y el doble de la API se
-- ejecutaron preparar, foto, ensayo y reproducir completos sobre la puesta real del guion 001
-- (49 planos) con un reloj simulado: cada plano entra en el cuadro que le corresponde, el
-- destello dura exactamente 2 cuadros y el ensayo detecta planos cortos, objetivos tapados y
-- referencias inexistentes sembradas a propósito.
-- PENDIENTE DE LA PRIMERA PRUEBA REAL: todo lo visual; que require funcione desde
-- execute_luau; el costo real de cambiar de escenario en un cuadro; SetCore("TopbarEnabled");
-- la cámara en modo Run; la duración real del destello en la grabación.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Base = require(script.Parent.Base)
local Camara = require(script.Parent.Camara)
local Caras = require(script.Parent.Caras)
local Elenco = require(script.Parent.Elenco)
local Escenarios = require(script.Parent.Escenarios)
local Luz = require(script.Parent.Luz)
local Utileria = require(script.Parent.Utileria)

local Director = {}

Director.DURACION_MINIMA = 0.6 -- segundos; el ensayo avisa de los planos más cortos
Director.Base, Director.Camara, Director.Caras, Director.Elenco = Base, Camara, Caras, Elenco
Director.Escenarios, Director.Luz, Director.Utileria = Escenarios, Luz, Utileria

----------------------------------------------------------------------------------------
-- Datos: decodificar, combinar y validar (lógica pura)
----------------------------------------------------------------------------------------

local function decodificar(valor: any): any
	if typeof(valor) == "string" then
		return HttpService:JSONDecode(valor)
	end
	return valor
end

local function lista(valor: any): { any }
	if valor == nil then
		return {}
	elseif typeof(valor) == "table" and (#valor > 0 or next(valor) == nil) then
		return valor
	end
	return { valor }
end

-- Une plan y puesta en una sola lista de planos ordenada por inicio.
function Director.combinar(plan: any, puesta: any): (any, { string })
	local avisos: { string } = {}
	local pl, pu = decodificar(plan), decodificar(puesta) or {}
	local porNumero = {}
	for _, p in pu.planos or {} do
		porNumero[p.n] = p
	end
	local planos = {}
	local anterior: any = nil
	local fuente = (pl and pl.planos) or pu.planos or {}
	for _, t in fuente do
		local p = porNumero[t.n]
		if not p then
			table.insert(avisos, "plano " .. tostring(t.n) .. ": no tiene puesta; se repite la del plano anterior")
			p = anterior or {}
		end
		local nuevo = table.clone(p)
		nuevo.n = t.n
		nuevo.inicio = t.inicio or p.inicio or 0
		nuevo.fin = t.fin or p.fin or nuevo.inicio
		nuevo.texto = t.texto or p.texto or ""
		table.insert(planos, nuevo)
		anterior = p
		porNumero[t.n] = nil
	end
	for n in porNumero do
		table.insert(avisos, "plano " .. tostring(n) .. ": está en la puesta pero no en el plan; se omite")
	end
	table.sort(planos, function(a, b)
		return a.inicio < b.inicio
	end)
	local duracion = (pl and pl.duracion) or pu.duracion or 0
	for _, p in planos do
		duracion = math.max(duracion, p.fin)
	end
	return {
		video = (pl and pl.video) or pu.video or "sin_nombre",
		duracion = duracion,
		vertical = pu.vertical ~= false,
		estilo = pu.estilo,
		elenco = pu.elenco or {},
		predeterminados = pu.predeterminados or {},
		planos = planos,
	}, avisos
end

-- Índice del plano vigente en el instante t, avanzando desde `desde`.
function Director.indiceEn(planos: { any }, t: number, desde: number?): number
	local i = math.max(desde or 1, 1)
	while planos[i + 1] and t >= planos[i + 1].inicio do
		i += 1
	end
	return i
end

local EFECTOS: { [string]: any } = {}

-- Revisa que todo nombre usado exista en los catálogos. Devuelve la lista de problemas.
function Director.validar(datos: any): { string }
	local problemas: { string } = {}
	local function falta(p: any, texto: string)
		table.insert(problemas, "plano " .. tostring(p.n) .. ": " .. texto)
	end
	for _, p in datos.planos do
		if not Escenarios.resolver(p.escenario) then
			falta(p, "escenario inexistente: " .. tostring(p.escenario))
		end
		if p.clima and not Escenarios.CLIMAS[Base.normalizar(p.clima)] then
			falta(p, "clima inexistente: " .. tostring(p.clima))
		end
		if p.luz and not Luz.PREAJUSTES[Base.normalizar(p.luz)] then
			falta(p, "luz inexistente: " .. tostring(p.luz))
		end
		for _, pj in p.personajes or {} do
			if not datos.elenco[pj.id] then
				falta(p, "personaje inexistente: " .. tostring(pj.id))
			end
			if pj.pose and typeof(pj.pose) == "string" and not Elenco.POSES[Base.normalizar(pj.pose)] then
				falta(p, "pose inexistente: " .. pj.pose)
			end
			if pj.cara and not Caras.resolver(pj.cara) then
				falta(p, "cara inexistente: " .. tostring(pj.cara))
			end
		end
		for _, u in p.utileria or {} do
			if not Utileria.existe(u.tipo) then
				falta(p, "utilería inexistente: " .. tostring(u.tipo))
			end
		end
		local cam = p.camara or {}
		if cam.tipo and not Camara.TIPOS[cam.tipo] then
			falta(p, "tipo de cámara inexistente: " .. tostring(cam.tipo))
		end
		if cam.movimiento and not Camara.MOVIMIENTOS[cam.movimiento] then
			falta(p, "movimiento inexistente: " .. tostring(cam.movimiento))
		end
		if cam.desde and not Camara.DESDE[cam.desde] then
			falta(p, "dirección de cámara inexistente: " .. tostring(cam.desde))
		end
		for _, ef in lista(p.efecto) do
			local tipo = (typeof(ef) == "table") and ef.tipo or ef
			if not EFECTOS[tostring(tipo)] then
				falta(p, "efecto inexistente: " .. tostring(tipo))
			end
		end
	end
	return problemas
end

----------------------------------------------------------------------------------------
-- Preparación
----------------------------------------------------------------------------------------

local function ceder(ctx: any)
	-- execute_luau corre en el hilo principal de Studio: se cede entre tandas para no congelarlo.
	if ctx.opciones.ceder ~= false then
		task.wait()
	end
end

-- Construye o reutiliza escenarios, elenco y utilería. opciones = { version = "detalle" |
-- "gris", reconstruir = false, ceder = true, estilo = "propio" | "r6" }.
function Director.preparar(plan: any, puesta: any, opciones: any?): any
	local o = opciones or {}
	local datos, avisos = Director.combinar(plan, puesta)
	local ctx: any = {
		datos = datos, planos = datos.planos, duracion = datos.duracion, vertical = datos.vertical,
		opciones = o, escenas = {}, elenco = {}, utileria = {}, avisos = avisos, estado = nil,
	}
	for _, problema in Director.validar(datos) do
		table.insert(avisos, problema)
	end
	local version = o.version or "detalle"
	for _, p in ctx.planos do
		local clave = Escenarios.resolver(p.escenario)
		if clave and not ctx.escenas[clave] then
			local existente = Escenarios.buscar(clave)
			if existente and existente:GetAttribute("Version") == version and not o.reconstruir then
				ctx.escenas[clave] = existente
			else
				ctx.escenas[clave] = Escenarios.construir(clave, { version = version, luz = false })
				ceder(ctx)
			end
		end
	end
	local estilo = o.estilo or datos.estilo or Elenco.ESTILO_POR_DEFECTO
	local carpetaElenco = Base.subcarpeta("Elenco")
	for id, def in datos.elenco do
		local existente = carpetaElenco:FindFirstChild(id) or Base.bodega():FindFirstChild(id)
		if existente and existente:GetAttribute("Estilo") == (def.estilo or estilo) and not o.reconstruir then
			ctx.elenco[id] = existente
		else
			local d = table.clone(def)
			d.id, d.nombre, d.estilo = id, id, def.estilo or estilo
			ctx.elenco[id] = Elenco.crear(d)
		end
	end
	ceder(ctx)
	local carpetaUtil = Base.subcarpeta("Utileria")
	for _, p in ctx.planos do
		for _, u in p.utileria or {} do
			if u.id and not ctx.utileria[u.id] then
				local nombre = "util_" .. tostring(u.id)
				local viejo = carpetaUtil:FindFirstChild(nombre) or Base.bodega():FindFirstChild(nombre)
				if viejo then
					viejo:Destroy()
				end
				local params = table.clone(u.params or {})
				params.nombre = nombre
				ctx.utileria[u.id] = Utileria.crear(u.tipo or "cajas", params, carpetaUtil)
			end
		end
	end
	Base.marcar("Historias: preparar " .. tostring(datos.video))
	return ctx
end

----------------------------------------------------------------------------------------
-- Aplicar un plano
----------------------------------------------------------------------------------------

local MEDIA_VUELTA = CFrame.Angles(0, math.pi, 0)

-- CFrame de pies (personaje) a partir de { ancla, pos, giro, desplazar }.
local function ubicacion(escena: Model, spec: any, paraUtileria: boolean, avisos: { string }, quien: string): CFrame
	local origen: CFrame = escena:GetAttribute("Origen") or CFrame.new()
	local cf: CFrame
	if spec.pos then
		if paraUtileria then
			cf = origen * CFrame.new(Base.vec(spec.pos)) * CFrame.Angles(0, math.rad(spec.giro or 0), 0)
		else
			cf = origen * Elenco.cfPies(spec.pos, spec.giro)
		end
	else
		local nombre = spec.ancla or "centro"
		local hallado, tipo = Escenarios.ancla(escena, nombre)
		if not hallado then
			table.insert(avisos, quien .. ": ancla inexistente: " .. tostring(nombre))
			hallado, tipo = Escenarios.ancla(escena, "centro")
			hallado = hallado or origen
		end
		cf = hallado :: CFrame
		-- Las anclas de personaje miran con -Z; los puntos de utilería, con +Z.
		if (tipo == "punto") ~= paraUtileria then
			cf = cf * MEDIA_VUELTA
		end
		if spec.giro then
			local base = paraUtileria and spec.giro or (180 + spec.giro)
			cf = CFrame.new(cf.Position) * CFrame.Angles(0, math.rad(base), 0)
		end
	end
	if spec.desplazar then
		cf = cf + Base.vec(spec.desplazar)
	end
	return cf
end

-- Convierte una referencia de la puesta en algo que Camara.objetivo entiende.
--   "narrador" (id del elenco) | "util:barra" | "ancla:centro" | "escena:CasaDelArbol"
local function referencia(ctx: any, escena: Model, ref: any): any?
	if typeof(ref) ~= "string" then
		return nil
	end
	local prefijo, resto = string.match(ref, "^(%a+):(.+)$")
	if prefijo == "util" then
		return ctx.utileria[resto]
	elseif prefijo == "ancla" then
		local cf = Escenarios.ancla(escena, resto)
		return cf and cf.Position or nil
	elseif prefijo == "escena" then
		return escena:FindFirstChild(resto, true)
	end
	return ctx.elenco[ref] or ctx.utileria[ref] or (Escenarios.ancla(escena, ref) and (Escenarios.ancla(escena, ref) :: CFrame).Position)
end

local function emisorDe(parte: Instance, nombre: string, color: any): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = nombre
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.5, 1.1)
	e.Speed = NumberRange.new(10, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.5, 0)
	e.LightEmission = 1
	e.Color = ColorSequence.new(Base.color(color))
	e.Acceleration = Vector3.new(0, -30, 0)
	e.Parent = parte
	return e
end

local function basePara(ctx: any, escena: Model, ef: any): Instance?
	local destino = referencia(ctx, escena, ef.en)
	if typeof(destino) == "Instance" then
		if destino:IsA("Model") then
			return destino.PrimaryPart
		end
		return destino
	end
	return escena.PrimaryPart
end

-- Efectos por plano. Cada uno: iniciar(ctx, escena, ef) -> datos; cuadro(datos, t); terminar(datos).
EFECTOS.recuerdo = {
	iniciar = function()
		Luz.tinte("#E8D2B0", 0.02, -0.7)
		return {}
	end,
	terminar = function()
		Luz.tinte(nil)
	end,
}
EFECTOS.destello_verde = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoDestello", "#6CFF9A")
		if e then
			e.Speed = NumberRange.new(25, 50)
			e:Emit(80)
		end
		return { emisor = e }
	end,
	cuadro = function(d, t)
		local k = math.max(0, 1 - t / 0.7)
		Luz.tinte(Color3.new(1, 1, 1):Lerp(Color3.fromRGB(120, 255, 160), k), 0.5 * k, 0)
	end,
	terminar = function(d)
		Luz.tinte(nil)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.chispas = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoChispas", "#FFD84D")
		if e then
			e:Emit(30)
		end
		return { emisor = e, ultimo = 0 }
	end,
	cuadro = function(d, t)
		if d.emisor and t - d.ultimo >= 0.25 then
			d.ultimo = t
			d.emisor:Emit(14)
		end
	end,
	terminar = function(d)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.confeti = {
	iniciar = function(ctx, escena, ef)
		local parte = basePara(ctx, escena, ef)
		local e = parte and emisorDe(parte, "EfectoConfeti", "#FFFFFF")
		if e then
			e.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(229, 56, 59)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(242, 194, 48)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246)),
			})
			e.LightEmission = 0
			e.Lifetime = NumberRange.new(1.5, 2.5)
			e.Rate = 60
			e:Emit(40)
		end
		return { emisor = e }
	end,
	terminar = function(d)
		if d.emisor then
			d.emisor:Destroy()
		end
	end,
}
EFECTOS.vibrar = {
	iniciar = function(ctx, escena, ef)
		local m = referencia(ctx, escena, ef.en)
		if typeof(m) == "Instance" and m:IsA("Model") then
			return { modelo = m, base = m:GetPivot(), fuerza = ef.fuerza or 0.12 }
		end
		return {}
	end,
	cuadro = function(d, t)
		if d.modelo then
			d.modelo:PivotTo(d.base * CFrame.new(d.fuerza * math.sin(t * 70), d.fuerza * math.sin(t * 53 + 1), 0))
		end
	end,
	terminar = function(d)
		if d.modelo then
			d.modelo:PivotTo(d.base)
		end
	end,
}
EFECTOS.parpadeo = {
	iniciar = function(ctx, escena, ef)
		local m = referencia(ctx, escena, ef.en)
		return { modelo = (typeof(m) == "Instance" and m:IsA("Model")) and m or nil, estado = false, ritmo = ef.ritmo or 5 }
	end,
	cuadro = function(d, t)
		local apagada = math.floor(t * d.ritmo * 2) % 2 == 1
		if d.modelo and apagada ~= d.estado then
			d.estado = apagada
			Utileria.actualizar(d.modelo, { apagada = apagada })
		end
	end,
	terminar = function(d)
		if d.modelo then
			Utileria.actualizar(d.modelo, { apagada = false })
		end
	end,
}
Director.EFECTOS = EFECTOS

local function terminarEfectos(ctx: any)
	local estado = ctx.estado
	if estado then
		for _, activo in estado.efectos do
			if activo.def.terminar then
				activo.def.terminar(activo.datos)
			end
		end
		estado.efectos = {}
	end
end

-- Deja el plano i montado (escenario, clima, luz, personajes, utilería, efectos) y calcula
-- el estado de cámara. No mueve la cámara: eso lo hace Director.cuadro. Devuelve los avisos.
function Director.aplicarPlano(ctx: any, i: number): { string }
	local p = ctx.planos[i]
	local avisos: { string } = {}
	local quien = "plano " .. tostring(p.n)
	terminarEfectos(ctx)

	local pred = ctx.datos.predeterminados
	local clave = Escenarios.resolver(p.escenario or pred.escenario)
	if not clave or not ctx.escenas[clave] then
		table.insert(avisos, quien .. ": escenario inexistente: " .. tostring(p.escenario))
		clave = next(ctx.escenas)
	end
	local escena: Model = ctx.escenas[clave]
	if not escena then
		ctx.estado = { indice = i, camara = nil, animados = {}, efectos = {} }
		return avisos
	end
	if ctx.claveActiva ~= clave or escena.Parent ~= Base.subcarpeta("Escenarios") then
		Escenarios.activar(clave :: string)
		ctx.claveActiva = clave
	end
	local clima = Base.normalizar(p.clima or pred.clima or escena:GetAttribute("ClimaInicial") or "sol")
	if escena:GetAttribute("Clima") ~= clima then
		local aviso = Escenarios.clima(escena, clima)
		if aviso then
			table.insert(avisos, quien .. ": " .. aviso)
		end
	end
	local luz = Base.normalizar(p.luz or pred.luz or Escenarios.luzSugerida(escena))
	if Luz.actual() ~= luz then
		local ok, aviso = Luz.aplicar(luz)
		if not ok then
			table.insert(avisos, quien .. ": " .. tostring(aviso))
			Luz.aplicar(Escenarios.luzSugerida(escena))
		end
	end

	-- Personajes
	local presentes = {}
	for _, spec in p.personajes or {} do
		local pj: Model = ctx.elenco[spec.id]
		if not pj then
			table.insert(avisos, quien .. ": personaje inexistente: " .. tostring(spec.id))
		else
			presentes[spec.id] = spec
			Elenco.mostrar(pj)
			local aviso = Elenco.posar(pj, spec.pose)
			if aviso then
				table.insert(avisos, quien .. ": " .. aviso)
			end
			Elenco.ubicar(pj, ubicacion(escena, spec, false, avisos, quien))
			local _, avisoCara = Caras.aplicar(pj, spec.cara or "neutra")
			if avisoCara then
				table.insert(avisos, quien .. ": " .. avisoCara)
			end
		end
	end
	for id, pj in ctx.elenco do
		if not presentes[id] then
			Elenco.ocultar(pj)
		end
	end

	-- Utilería
	local animados = {}
	local pegados = {}
	local visibles = {}
	local carpetaUtil = Base.subcarpeta("Utileria")
	for _, spec in p.utileria or {} do
		local modelo: Model = ctx.utileria[spec.id]
		if not modelo then
			table.insert(avisos, quien .. ": utilería sin crear: " .. tostring(spec.id))
		else
			visibles[spec.id] = true
			Base.mover(modelo, carpetaUtil)
			local cf: CFrame
			local pegado = spec.pegado
			local dueno = pegado and ctx.elenco[pegado.personaje]
			local punto = dueno and presentes[pegado.personaje] and Elenco.punto(dueno, pegado.parte or "mano_der")
			if punto then
				cf = punto * MEDIA_VUELTA * CFrame.new(Base.vec(pegado.rel))
				table.insert(pegados, { modelo = modelo, dueno = dueno, pegado = pegado })
			else
				if pegado then
					table.insert(avisos, quien .. ": no se pudo pegar " .. tostring(spec.id) .. " a " .. tostring(pegado.personaje))
				end
				cf = ubicacion(escena, spec, true, avisos, quien)
			end
			modelo:PivotTo(cf)
			if spec.params then
				Utileria.actualizar(modelo, spec.params)
			end
			if spec.claves then
				table.insert(animados, { modelo = modelo, claves = spec.claves, params = spec.params or {}, ultimo = {} })
			end
		end
	end
	for id, modelo in ctx.utileria do
		if not visibles[id] then
			Base.mover(modelo, Base.bodega())
		end
	end

	-- Cámara
	local cam = p.camara or {}
	local tipo = Camara.TIPOS[cam.tipo] and cam.tipo or "M"
	local cosas = {}
	for _, ref in lista(cam.objetivo) do
		local cosa = referencia(ctx, escena, ref)
		local visible = cosa ~= nil
		if typeof(cosa) == "Instance" and ctx.elenco[ref] and not presentes[ref] then
			visible = false
		end
		if visible then
			table.insert(cosas, cosa)
		else
			table.insert(avisos, quien .. ": objetivo de cámara inexistente o fuera del plano: " .. tostring(ref))
		end
	end
	if #cosas == 0 then
		local centro = Escenarios.ancla(escena, "centro")
		table.insert(cosas, (centro and centro.Position or (escena:GetAttribute("Origen") :: CFrame).Position) + Vector3.new(0, 3, 0))
	end
	local fija = nil
	if cam.ancla then
		fija = Escenarios.ancla(escena, cam.ancla)
		if not fija then
			table.insert(avisos, quien .. ": ancla de cámara inexistente: " .. tostring(cam.ancla))
		end
	end
	local estadoCamara = Camara.encuadrar(Camara.objetivo(cosas, tipo), tipo, {
		movimiento = cam.movimiento, inclinacion = cam.inclinacion, desde = cam.desde, azimut = cam.azimut,
		elevacion = cam.elevacion, fov = cam.fov, margen = cam.margen, vertical = ctx.vertical,
		duracion = p.fin - p.inicio, fija = fija,
	})

	-- Miradas (después de ubicar a todos y de saber dónde queda la cámara)
	local posCamara = Camara.cframeEn(estadoCamara, 0).Position
	for id, spec in presentes do
		if spec.mira then
			local destino: any = nil
			if spec.mira == "camara" then
				destino = posCamara
			else
				destino = referencia(ctx, escena, spec.mira)
				if typeof(destino) == "Instance" then
					destino = destino:GetPivot().Position
				end
			end
			if typeof(destino) == "Vector3" then
				Elenco.mirarA(ctx.elenco[id], destino)
			else
				table.insert(avisos, quien .. ": mirada inexistente: " .. tostring(spec.mira))
			end
		end
	end

	-- La utilería pegada a un personaje se reubica por si la mirada lo giró.
	for _, g in pegados do
		local punto = Elenco.punto(g.dueno, g.pegado.parte or "mano_der")
		if punto then
			g.modelo:PivotTo(punto * MEDIA_VUELTA * CFrame.new(Base.vec(g.pegado.rel)))
		end
	end

	-- Efectos
	local efectos = {}
	for _, ef in lista(p.efecto) do
		local spec = (typeof(ef) == "table") and ef or { tipo = ef }
		local def = EFECTOS[tostring(spec.tipo)]
		if def then
			table.insert(efectos, { def = def, datos = def.iniciar(ctx, escena, spec) })
		else
			table.insert(avisos, quien .. ": efecto inexistente: " .. tostring(spec.tipo))
		end
	end

	ctx.estado = { indice = i, camara = estadoCamara, animados = animados, efectos = efectos, escena = escena }
	return avisos
end

-- Actualiza lo que cambia en cada cuadro: cámara, utilería animada y efectos.
-- `t` son los segundos transcurridos desde el inicio del plano vigente.
function Director.cuadro(ctx: any, t: number)
	local estado = ctx.estado
	if not estado or not estado.camara then
		return
	end
	local e = estado.camara
	local cf, fov = Camara.cframeEn(e, t)
	Camara.aplicar(cf, fov, e.centro)
	Luz.enfocar((cf.Position - e.centro).Magnitude, math.max(8, e.alto))
	local u = math.clamp(t / e.duracion, 0, 1)
	for _, a in estado.animados do
		local cambio = false
		local params = table.clone(a.params)
		for campo, claves in a.claves do
			local valor = Base.claves(claves, u)
			if campo == "porcentaje" or campo == "izq" or campo == "der" then
				valor = math.floor(valor * 10 + 0.5) / 10
			end
			params[campo] = valor
			if a.ultimo[campo] ~= valor then
				a.ultimo[campo] = valor
				cambio = true
			end
		end
		if cambio then
			Utileria.actualizar(a.modelo, params)
		end
	end
	for _, activo in estado.efectos do
		if activo.def.cuadro then
			activo.def.cuadro(activo.datos, t)
		end
	end
end

local function indiceDeNumero(ctx: any, n: number): number?
	for i, p in ctx.planos do
		if p.n == n then
			return i
		end
	end
	return nil
end

local function v3(v: Vector3): { number }
	local function r(x: number): number
		return math.floor(x * 100 + 0.5) / 100
	end
	return { r(v.X), r(v.Y), r(v.Z) }
end

----------------------------------------------------------------------------------------
-- Modo foto
----------------------------------------------------------------------------------------

-- Salta al plano número `n` y lo deja quieto en `fraccion` (0 a 1; por defecto 0.5) de su
-- duración. Devuelve una tabla corta para el chat: texto, avisos, si el objetivo está
-- tapado y la posición de cámara (sirve para camera_position / look_at_position de
-- screen_capture, que no conserva ni el giro vertical ni el campo de visión).
function Director.foto(ctx: any, n: number, fraccion: number?): any
	local i = indiceDeNumero(ctx, n)
	if not i then
		return { error = "no existe el plano " .. tostring(n) }
	end
	local avisos = Director.aplicarPlano(ctx, i)
	local p = ctx.planos[i]
	local t = (p.fin - p.inicio) * (fraccion or 0.5)
	Director.cuadro(ctx, t)
	local e = ctx.estado.camara
	local resultado: any = { n = p.n, texto = p.texto, duracion = p.fin - p.inicio, avisos = avisos }
	if e then
		local cf = Camara.cframeEn(e, t)
		local tapado, por = Camara.verificar(cf, e)
		resultado.tapado, resultado.tapado_por = tapado, por
		resultado.camara = { posicion = v3(cf.Position), mira = v3(e.centro), fov = e.fov, vertical = e.vertical }
	end
	return resultado
end

----------------------------------------------------------------------------------------
-- Modo ensayo
----------------------------------------------------------------------------------------

-- Recorre todos los planos sin reproducir y reporta por consola (y devuelve) los que duran
-- menos de DURACION_MINIMA, los que tienen el objetivo tapado y los que referencian algo
-- inexistente.
function Director.ensayo(ctx: any): any
	local informe = { cortos = {}, tapados = {}, inexistentes = {}, total = #ctx.planos }
	for _, aviso in ctx.avisos do
		table.insert(informe.inexistentes, aviso)
	end
	local vistos = {}
	for _, aviso in informe.inexistentes do
		vistos[aviso] = true
	end
	for i, p in ctx.planos do
		local duracion = p.fin - p.inicio
		if duracion < Director.DURACION_MINIMA then
			table.insert(informe.cortos, string.format("plano %s: dura %.2f s", tostring(p.n), duracion))
		end
		for _, aviso in Director.aplicarPlano(ctx, i) do
			if not vistos[aviso] then
				vistos[aviso] = true
				table.insert(informe.inexistentes, aviso)
			end
		end
		local e = ctx.estado.camara
		if e then
			for _, t in { 0, duracion } do
				local cf = Camara.cframeEn(e, t)
				local tapado, por = Camara.verificar(cf, e)
				if tapado then
					table.insert(informe.tapados, string.format("plano %s: objetivo tapado por %s", tostring(p.n), tostring(por)))
					break
				end
			end
		end
		if i % 10 == 0 then
			ceder(ctx)
		end
	end
	terminarEfectos(ctx)
	print(string.format("[Historias] ensayo de %s: %d planos, %d cortos, %d tapados, %d referencias inexistentes",
		tostring(ctx.datos.video), informe.total, #informe.cortos, #informe.tapados, #informe.inexistentes))
	for _, grupo in { informe.cortos, informe.tapados, informe.inexistentes } do
		for _, linea in grupo do
			print("[Historias]   " .. linea)
		end
	end
	return informe
end

----------------------------------------------------------------------------------------
-- Modo reproducir
----------------------------------------------------------------------------------------

local function ocultarInterfaz()
	local StarterGui = game:GetService("StarterGui")
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	pcall(function()
		game:GetService("UserInputService").MouseIconEnabled = false
	end)
	task.spawn(function()
		for _ = 1, 20 do
			local ok = pcall(function()
				StarterGui:SetCore("TopbarEnabled", false)
			end)
			if ok then
				break
			end
			task.wait(0.25)
		end
	end)
end

local function pantallaDestello(color: Color3): Frame?
	local jugador = game:GetService("Players").LocalPlayer
	local gui = jugador and jugador:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	local pantalla = Instance.new("ScreenGui")
	pantalla.Name = "HistoriasDestello"
	pantalla.IgnoreGuiInset = true
	pantalla.DisplayOrder = 10000
	pantalla.ResetOnSpawn = false
	local marco = Instance.new("Frame")
	marco.Name = "Blanco"
	marco.Size = UDim2.fromScale(1, 1)
	marco.BorderSizePixel = 0
	marco.BackgroundColor3 = color
	marco.Visible = false
	marco.Parent = pantalla
	pantalla.Parent = gui
	return marco
end

-- Reproduce la secuencia completa. opciones = { previa = 2 (segundos quietos en el plano 1
-- antes del destello), cuadrosDestello = 2, colorDestello = "#FFFFFF", cola = 0.5,
-- alTerminar = function(informe) }. Devuelve un control con detener() y el campo `fase`.
function Director.reproducir(ctx: any, opciones: any?): any
	local o = opciones or {}
	local previa, cuadrosDestello, cola = o.previa or 2, o.cuadrosDestello or 2, o.cola or 0.5
	local color = Base.color(o.colorDestello, Color3.new(1, 1, 1))
	local esCliente = RunService:IsClient() and RunService:IsRunning()
	local planos = ctx.planos
	local control: any = { fase = "previa", indice = 1, entradas = {}, t0 = nil, desvioMaximo = 0 }
	if #planos == 0 then
		control.fase = "terminado"
		return control
	end

	Camara.guardar()
	if esCliente then
		ocultarInterfaz()
	end
	local marco = esCliente and pantallaDestello(color) or nil
	local function destello(activo: boolean)
		Luz.blanco(activo)
		if marco then
			marco.Visible = activo
		end
	end

	Director.aplicarPlano(ctx, 1)
	Director.cuadro(ctx, 0)

	local inicioFase = os.clock()
	local cuadros = 0
	local conexion: RBXScriptConnection? = nil
	local NOMBRE = "HistoriasDirector"

	local function terminar()
		if control.fase == "terminado" then
			return
		end
		control.fase = "terminado"
		if conexion then
			conexion:Disconnect()
		elseif esCliente then
			pcall(function()
				RunService:UnbindFromRenderStep(NOMBRE)
			end)
		end
		destello(false)
		terminarEfectos(ctx)
		if marco and marco.Parent then
			marco.Parent:Destroy()
		end
		for i, t in control.entradas do
			control.desvioMaximo = math.max(control.desvioMaximo, t - planos[i].inicio)
		end
		print(string.format("[Historias] fin de %s: %d planos, desvío máximo de entrada %.1f ms",
			tostring(ctx.datos.video), #planos, control.desvioMaximo * 1000))
		if o.alTerminar then
			o.alTerminar(control)
		end
	end

	local function paso()
		local ahora = os.clock()
		if control.fase == "previa" then
			if ahora - inicioFase >= previa then
				control.fase = "destello"
				cuadros = 0
				destello(true)
			end
		elseif control.fase == "destello" then
			cuadros += 1
			if cuadros >= cuadrosDestello then
				destello(false)
				control.t0 = ahora -- instante cero: primer cuadro no blanco
				control.fase = "rodando"
				control.entradas[1] = 0
				Director.cuadro(ctx, 0)
			end
		elseif control.fase == "rodando" then
			local t = ahora - control.t0
			if t >= ctx.duracion then
				control.fase = "cola"
				inicioFase = ahora
				return
			end
			local nuevo = Director.indiceEn(planos, t, control.indice)
			if nuevo ~= control.indice then
				control.indice = nuevo
				Director.aplicarPlano(ctx, nuevo)
				control.entradas[nuevo] = t
			end
			Director.cuadro(ctx, t - planos[control.indice].inicio)
		elseif control.fase == "cola" then
			if ahora - inicioFase >= cola then
				terminar()
			end
		end
	end

	if esCliente then
		RunService:BindToRenderStep(NOMBRE, Enum.RenderPriority.Camera.Value + 1, paso)
	else
		conexion = RunService.Heartbeat:Connect(paso)
	end
	control.detener = terminar
	print(string.format("[Historias] rodando %s: %d planos, %.2f s, vertical=%s (montaje: girar %s)",
		tostring(ctx.datos.video), #planos, ctx.duracion, tostring(ctx.vertical), Camara.ROTAR_MONTAJE))
	return control
end

----------------------------------------------------------------------------------------
-- Datos guardados en el lugar y utilidades de sesión
----------------------------------------------------------------------------------------

local function carpetaHistorias(): Instance
	if typeof(script) == "Instance" and script.Parent then
		return script.Parent
	end
	return Base.carpeta(ReplicatedStorage, Base.RAIZ)
end

-- Guarda plan y puesta (texto JSON) como StringValue en ReplicatedStorage.Historias.Datos,
-- para que los lanzadores los lean al iniciar el juego. `plan` puede ser nil.
function Director.guardarDatos(plan: string?, puesta: string)
	local datos = Base.carpeta(carpetaHistorias(), "Datos")
	for nombre, texto in { Plan = plan or "", Puesta = puesta } do
		local valor = Base.carpeta(datos, nombre, "StringValue") :: StringValue
		valor.Value = texto
	end
end

-- Configura el lugar para grabar. modo = "play" (cliente, recomendado) o "run".
function Director.configurarLugar(modo: string?)
	local carpeta = carpetaHistorias()
	carpeta:SetAttribute("AutoRodar", true)
	carpeta:SetAttribute("Modo", modo or "play")
	if (modo or "play") == "play" then
		game:GetService("Players").CharacterAutoLoads = false
	end
end

-- Lo que llaman los lanzadores: lee los datos guardados, prepara y reproduce.
function Director.rodarDesdeDatos(opciones: any?): any
	local datos = carpetaHistorias():FindFirstChild("Datos")
	local plan = datos and datos:FindFirstChild("Plan")
	local puesta = datos and datos:FindFirstChild("Puesta")
	if not (puesta and puesta:IsA("StringValue")) or puesta.Value == "" then
		warn("[Historias] no hay puesta guardada; usa Director.guardarDatos primero")
		return nil
	end
	local textoPlan = (plan and plan:IsA("StringValue") and plan.Value ~= "") and plan.Value or nil
	local ctx = Director.preparar(textoPlan, puesta.Value, opciones)
	return Director.reproducir(ctx, opciones)
end

-- Deja el lugar como para seguir editando: todos los escenarios y personajes visibles,
-- efectos apagados, luz y cámara originales.
function Director.restaurar(ctx: any?)
	if ctx then
		terminarEfectos(ctx)
		for _, pj in ctx.elenco do
			Elenco.mostrar(pj)
		end
		for _, modelo in ctx.utileria do
			Base.mover(modelo, Base.subcarpeta("Utileria"))
		end
		ctx.claveActiva = nil
	end
	Escenarios.mostrarTodos()
	Luz.revertir()
	Camara.restaurar()
end

return Director
