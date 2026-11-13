-- pruebas.luau
-- Pruebas de la biblioteca Historias con el intérprete `luau` y el doble de la API.
-- Las arma y ejecuta pruebas/ejecutar.py, que entrega: el doble, la tabla de la API y los
-- textos de cargar.luau, monolito.luau y ejemplos/001-puesta.json.
-- Cada prueba instala la biblioteca con el mismo cargar.luau que se inyecta en Studio.

local Doble, API, FUENTES = ...
local Vector3, CFrame = Doble.Vector3, Doble.CFrame

local total, fallas = 0, 0
local function prueba(nombre: string, fn: () -> ())
	total += 1
	local ok, err = pcall(fn)
	if ok then
		print("  ok     " .. nombre)
	else
		fallas += 1
		print("  FALLA  " .. nombre .. "\n         " .. tostring(err))
	end
end
local function afirma(cond: any, mensaje: string?)
	if not cond then
		error(mensaje or "afirmación falsa", 2)
	end
end
local function cerca(a: number, b: number, eps: number?, mensaje: string?)
	if math.abs(a - b) > (eps or 1e-4) then
		error(string.format("%s: se esperaba %.5f y se obtuvo %.5f", mensaje or "valor", b, a), 2)
	end
end

-- Lugar nuevo con la biblioteca instalada. Devuelve el doble y el módulo Director.
local function lugar(config: any?): (any, any)
	local d = Doble.crear(API, config)
	local resultado = d.ejecutar(FUENTES.cargar, "cargar")
	afirma(string.find(resultado, "instalada", 1, true), "cargar no instaló: " .. tostring(resultado))
	local H = d.ejecutar("return require(game:GetService('ReplicatedStorage').Historias.Director)", "prueba")
	return d, H
end

print("Doble de la API (control: debe rechazar lo que no existe)")
prueba("rechaza propiedad, enumeración, clase, método y tipo de valor inexistentes", function()
	local d = Doble.crear(API, {})
	local e = d.entorno
	local parte = e.Instance.new("Part")
	afirma(not pcall(function()
		parte.Colour = e.Color3.new(1, 0, 0)
	end), "propiedad inventada")
	afirma(not pcall(function()
		parte.Size = 5
	end), "tipo de valor incorrecto")
	afirma(not pcall(function()
		parte.Material = e.Enum.PartType.Ball
	end), "enumeración de otro tipo")
	afirma(not pcall(function()
		return e.Enum.Material.Plastico
	end), "elemento de enumeración inventado")
	afirma(not pcall(function()
		return e.Instance.new("Pieza")
	end), "clase inventada")
	afirma(not pcall(function()
		return parte:Explotar()
	end), "método inventado")
	afirma(not pcall(function()
		e.workspace.CurrentCamera.ViewportSize = e.Vector2.new(1, 1)
	end), "propiedad de solo lectura")
	afirma(not pcall(function()
		return e.game:GetService("ServicioFalso")
	end), "servicio inventado")
	parte.Size = e.Vector3.new(1, 2, 3)
	parte.Material = e.Enum.Material.Neon
end)

print("Instalación")
prueba("cargar.luau crea los 8 ModuleScript y los 2 lanzadores", function()
	local d = lugar()
	local rs = d.game:GetService("ReplicatedStorage")
	for _, n in { "Base", "Caras", "Elenco", "Luz", "Utileria", "Escenarios", "Camara", "Director" } do
		afirma(rs.Historias:FindFirstChild(n) and rs.Historias[n]:IsA("ModuleScript"), "falta " .. n)
	end
	afirma(d.game:GetService("ServerScriptService").HistoriasRodar:IsA("Script"))
	afirma(d.game:GetService("StarterPlayer").StarterPlayerScripts.HistoriasRodarCliente:IsA("LocalScript"))
	afirma(rs.Historias:GetAttribute("Version") == "1.0.0")
end)
prueba("cargar.luau dos veces reemplaza los módulos (actualización)", function()
	local d = lugar()
	local antes = d.game:GetService("ReplicatedStorage").Historias.Base
	d.ejecutar(FUENTES.cargar, "cargar")
	local despues = d.game:GetService("ReplicatedStorage").Historias.Base
	afirma(antes ~= despues, "no se reemplazó la instancia")
	afirma(#d.game:GetService("ReplicatedStorage").Historias:GetChildren() == 8)
end)
prueba("sin permiso para escribir Source, cargar.luau lo explica y no deja scripts a medias", function()
	local d = Doble.crear(API, { plugin = false })
	local resultado = d.ejecutar(FUENTES.cargar, "cargar")
	afirma(string.find(resultado, "NO se pudo", 1, true), resultado)
	afirma(string.find(resultado, "multi_edit", 1, true), resultado)
	afirma(#d.game:GetService("ReplicatedStorage").Historias:GetChildren() == 0)
end)
prueba("monolito.luau funciona sin ModuleScript ni require", function()
	local d = Doble.crear(API, { plugin = false })
	local H = d.ejecutar(FUENTES.monolito .. "\nreturn Historias", "monolito")
	afirma(#H.Caras.NOMBRES == 20)
	local pj = H.Elenco.crear({ id = "prueba" })
	afirma(pj:IsA("Model"))
end)

print("Base")
prueba("colores, vectores, claves, azar y normalización", function()
	local _, H = lugar()
	local B = H.Base
	cerca(B.color("#FF8000").G, 128 / 255)
	cerca(B.color({ 255, 0, 0 }).R, 1)
	cerca(B.vec({ 1, 2, 3 }).Y, 2)
	cerca(B.claves({ { 0, 2 }, { 0.5, 3 }, { 1, 2 } }, 0.25), 2.5)
	cerca(B.claves({ { 0, 2 }, { 0.5, 3 } }, 0.9), 3)
	local a, b = B.azar(7), B.azar(7)
	for _ = 1, 20 do
		local x = a()
		afirma(x == b() and x >= 0 and x < 1, "azar no determinista o fuera de rango")
	end
	afirma(B.normalizar("Sonrisa Enorme") == "sonrisa_enorme")
	afirma(B.normalizar("Pícaro") == "picaro")
	cerca(B.suavizar(0.5, "entrada_salida"), 0.5)
	cerca(B.suavizar(1, "salida"), 1)
end)
prueba("cilindro vertical: intercambia tamaño y gira 90 grados", function()
	local _, H = lugar()
	local p = H.Base.pieza({ forma = "cilindro", tam = { 2, 10, 2 }, pos = { 0, 5, 0 } })
	cerca(p.Size.X, 10)
	cerca(math.abs(p.CFrame.RightVector.Y), 1, 1e-6, "el eje X de la pieza debe quedar vertical")
end)

print("Caras")
prueba("las 20 expresiones componen trazos dentro del lienzo", function()
	local _, H = lugar()
	afirma(#H.Caras.NOMBRES == 20)
	for _, nombre in H.Caras.NOMBRES do
		local ops = H.Caras.componer(nombre)
		afirma(#ops >= 3, nombre .. " tiene muy pocos trazos")
		for _, op in ops do
			afirma(op.x - op.w / 2 >= -2 and op.x + op.w / 2 <= 202, nombre .. ": trazo fuera en X")
			afirma(op.y - op.h / 2 >= -2 and op.y + op.h / 2 <= 202, nombre .. ": trazo fuera en Y")
		end
	end
end)
prueba("alias del guion y nombres con tilde", function()
	local _, H = lugar()
	for alias, canon in { Felices = "feliz", ["Risa forzada"] = "risa_forzada", ["Pícaro"] = "picaro", Serios = "neutra",
		["Golpe de realidad"] = "susto", ["Sonrisa enorme"] = "sonrisa_enorme", ["Vacías"] = "vacia" } do
		afirma(H.Caras.resolver(alias) == canon, alias .. " -> " .. tostring(H.Caras.resolver(alias)))
	end
	afirma(H.Caras.resolver("no_existe") == nil)
end)
prueba("aplicar dibuja con SurfaceGui; registrar cambia a imagen", function()
	local _, H = lugar()
	local pj = H.Elenco.crear({ id = "a" })
	local modo = H.Caras.aplicar(pj, "llanto")
	afirma(modo == "dibujo")
	local gui = pj.Cabeza.CaraPanel.Cara
	afirma(gui:IsA("SurfaceGui") and #gui:GetChildren() >= 5)
	local modo2, aviso = H.Caras.aplicar(pj, "inventada")
	afirma(modo2 == "dibujo" and aviso ~= nil)
	afirma(H.Caras.registrar("feliz", 123456))
	afirma(H.Caras.aplicar(pj, "feliz") == "imagen")
	afirma(gui.Imagen.ImageContent.Uri == "rbxassetid://123456")
	local r6 = H.Elenco.crear({ id = "b", estilo = "r6" })
	afirma(H.Caras.aplicar(r6, "feliz") == "imagen")
	afirma(r6.Head.face.ColorMapContent.Uri == "rbxassetid://123456")
end)

print("Elenco")
for _, estilo in { "propio", "r6" } do
	prueba("estilo " .. estilo .. ": rig completo, de pie sobre el piso", function()
		local d, H = lugar()
		local E = H.Elenco
		local def = E.ESTILOS[estilo]
		local pj = E.crear({ id = "p", estilo = estilo, pelo = { tipo = "largo", color = "#222222" } })
		afirma(pj:GetAttribute("Estilo") == estilo)
		for _, p in def.partes do
			afirma(pj:FindFirstChild(p.nombre), "falta " .. p.nombre)
		end
		local motores = 0
		for _, x in pj:GetDescendants() do
			if x:IsA("Motor6D") then
				motores += 1
			end
		end
		afirma(motores == 6, "deben ser 6 Motor6D y hay " .. motores)
		afirma((pj:FindFirstChildOfClass("Humanoid") ~= nil) == (estilo == "r6"), "Humanoid solo en r6")
		E.ubicar(pj, CFrame.new(10, 0, -5))
		local centro, tam = d.cajaMundo(pj[def.articulaciones.caderaDer.p1])
		cerca(centro.Y - tam.Y / 2, 0, 1e-4, "los pies deben tocar el piso")
		cerca(pj[def.raiz].Position.X, 10)
		afirma(E.cabeza(pj).Position.Y > pj[def.torso].Position.Y + 1, "la cabeza va sobre el torso")
		cerca(E.pies(pj).Position.Y, 0)
	end)
	prueba("estilo " .. estilo .. ": poses (brazos arriba, señalar, sentado, de espaldas, cabeza abajo)", function()
		local d, H = lugar()
		local E = H.Elenco
		local def = E.ESTILOS[estilo]
		local pj = E.crear({ id = "p", estilo = estilo })
		E.ubicar(pj, CFrame.new(0, 0, 0)) -- sin giro: mira hacia -Z
		local torso = pj[def.torso]
		local brazo = pj[def.articulaciones.hombroDer.p1]
		local motor = pj:FindFirstChild(def.articulaciones.hombroDer.nombre, true)
		local base = motor.C0

		afirma(E.posar(pj, "brazos_arriba") == nil)
		afirma(E.punto(pj, "mano_der").Position.Y > E.cabeza(pj).Position.Y, "la mano debe quedar sobre el centro de la cabeza")
		afirma(E.punto(pj, "mano_izq").Position.Y > E.cabeza(pj).Position.Y)
		afirma(motor.C0 ~= base, "posar debe modificar el C0 del Motor6D")
		afirma(motor:GetAttribute("C0Base") == base, "el C0 original queda en el atributo")

		E.posar(pj, "senalar")
		local mano = E.punto(pj, "mano_der").Position
		afirma(mano.Z < torso.Position.Z - 1, "señalar lleva la mano hacia adelante (-Z)")
		cerca(brazo.CFrame.UpVector.Y, 0, 1e-6, "el brazo queda horizontal")

		E.posar(pj, "sentado")
		local pierna = pj[def.articulaciones.caderaDer.p1]
		cerca(pierna.CFrame.UpVector.Y, 0, 1e-6, "pierna horizontal")
		local c, t = d.cajaMundo(pierna)
		cerca(c.Y - t.Y / 2, 0, 1e-4, "la pierna se apoya en el asiento")
		afirma(c.Z < torso.Position.Z, "las piernas van hacia adelante")
		cerca(torso.Position.Y, def.alturaRaiz - def.bajarSentado)

		E.posar(pj, "de_espaldas")
		cerca(torso.CFrame.LookVector.Z, 1, 1e-6, "el torso mira hacia +Z")
		E.posar(pj, "cabeza_abajo")
		afirma(E.cabeza(pj).CFrame.LookVector.Y < -0.3, "la cabeza mira hacia abajo")

		E.posar(pj, "de_pie")
		afirma(motor.C0 == base, "de_pie restaura el C0 original")
		local _, aviso = E.resolverPose("no_existe")
		afirma(aviso ~= nil)
		for nombre in E.POSES do
			afirma(E.posar(pj, nombre) == nil, "pose con error: " .. nombre)
		end
	end)
	prueba("estilo " .. estilo .. ": giro, mirada y panel de la cara pegado a la cabeza", function()
		local _, H = lugar()
		local E = H.Elenco
		local def = E.ESTILOS[estilo]
		local pj = E.crear({ id = "p", estilo = estilo })
		E.ubicar(pj, E.cfPies({ 4, 0, 2 }, 0))
		cerca(pj[def.torso].CFrame.LookVector.Z, 1, 1e-6, "giro 0 mira hacia +Z")
		E.mirarA(pj, Vector3.new(14, 9, 2))
		cerca(pj[def.torso].CFrame.LookVector.X, 1, 1e-6, "mira hacia +X")
		E.posar(pj, "cabeza_abajo")
		local cabeza = E.cabeza(pj)
		local panel = cabeza.CaraPanel
		local esperado = cabeza.CFrame * panel:GetAttribute("Rel")
		afirma((panel.Position - esperado.Position).Magnitude < 1e-6, "el panel sigue a la cabeza")
		afirma(panel.CFrame.LookVector:Dot(cabeza.CFrame.LookVector) > 0.999)
	end)
end
prueba("estilo por defecto es propio; modo no rígido también se arma", function()
	local _, H = lugar()
	afirma(H.Elenco.crear({ id = "x" }):GetAttribute("Estilo") == "propio")
	local suelto = H.Elenco.crear({ id = "y", rigido = false })
	afirma(suelto.Raiz.Anchored == true and suelto.Torso.Anchored == false)
	afirma(suelto.Cabeza.CaraPanel:FindFirstChildOfClass("WeldConstraint") ~= nil)
	H.Elenco.posar(suelto, "saltar")
end)
prueba("accesorio por id: falla con mensaje claro si no hay red o no es r6", function()
	local _, H = lugar()
	local ok, mensaje = H.Elenco.accesorio(H.Elenco.crear({ id = "x" }), 1)
	afirma(ok == false and string.find(mensaje, "r6", 1, true))
	local ok2, mensaje2 = H.Elenco.accesorio(H.Elenco.crear({ id = "z", estilo = "r6" }), 1)
	afirma(ok2 == false and string.find(mensaje2, "no se pudo cargar", 1, true))
end)

print("Luz")
prueba("cada preajuste se aplica; revertir restaura Lighting y los efectos previos", function()
	local d, H = lugar()
	local L = d.game:GetService("Lighting")
	L.Brightness = 2.5
	L.ClockTime = 9
	local atm = d.entorno.Instance.new("Atmosphere")
	atm.Parent = L
	local bloom = d.entorno.Instance.new("BloomEffect")
	bloom.Parent = L
	for nombre in H.Luz.PREAJUSTES do
		local ok, aviso = H.Luz.aplicar(nombre)
		afirma(ok, tostring(aviso))
		afirma(H.Luz.actual() == nombre)
	end
	afirma(bloom.Enabled == false and atm.Parent ~= L, "los efectos ajenos se apartan")
	afirma(L:FindFirstChild("Historias_Atmosfera"))
	afirma(H.Luz.aplicar("no_existe") == false)
	H.Luz.blanco(true)
	cerca(L.Historias_Destello.Brightness, 1)
	H.Luz.revertir()
	cerca(L.Brightness, 2.5)
	cerca(L.ClockTime, 9)
	afirma(bloom.Enabled == true and atm.Parent == L)
	afirma(L:FindFirstChild("Historias_Atmosfera") == nil and L:FindFirstChild("Historias_Respaldo") == nil)
	afirma(H.Luz.sugerido("noche", true) == "interior_noche" and H.Luz.sugerido("lluvia", false) == "lluvia")
end)

print("Utilería")
prueba("batería: relleno, color por umbral, texto y mitades", function()
	local _, H = lugar()
	local U = H.Utileria
	local w, cx = U.rellenoBateria(50, -2, 2)
	cerca(w, 2)
	cerca(cx, -1)
	afirma(U.colorBateria(98) == U.COLOR_BATERIA.alto and U.colorBateria(35) == U.COLOR_BATERIA.medio and U.colorBateria(2) == U.COLOR_BATERIA.bajo)
	local b = U.crear("bateria", { porcentaje = 98 })
	afirma(b.Pantalla.RotuloFrente.Texto.Text == "98%")
	local ancho98 = b.Relleno.Size.X
	b:PivotTo(CFrame.new(10, 5, 0))
	U.actualizar(b, { porcentaje = 2 })
	afirma(b.Relleno.Size.X < ancho98 / 10)
	afirma(b.Pantalla.RotuloFrente.Texto.Text == "2%")
	cerca(b.Relleno.Color.R, H.Base.color(U.COLOR_BATERIA.bajo).R)
	afirma(b.Relleno.Position.X < 10 and b.Relleno.Position.X > 8, "el relleno queda pegado al borde izquierdo del objeto movido")
	local m = U.crear("bateria", { mitades = true, izq = 100, der = 0, nombre = "M" })
	afirma(m.RellenoIzq.Transparency == 0 and m.RellenoDer.Transparency == 1)
	afirma(m.RellenoIzq.Position.X < 0)
end)
prueba("todos los tipos se crean; el tipo inexistente avisa", function()
	local d, H = lugar()
	local n = 0
	for tipo in H.Utileria.TIPOS do
		local modelo, aviso = H.Utileria.crear(tipo, { nombre = "u_" .. tipo, piezas = {} })
		afirma(aviso == nil and modelo.PrimaryPart ~= nil, tipo)
		n += 1
	end
	afirma(n >= 22, "tipos: " .. n)
	local _, aviso = H.Utileria.crear("nave_espacial")
	afirma(aviso ~= nil)
	local raton = H.Utileria.crear("raton", { nombre = "gigante", escala = 5 })
	local _, tam = d.cajaMundo(raton)
	afirma(tam.Z > 10, "el ratón escalado debe ser grande")
	local l = H.Utileria.crear("letrero", { texto = "FORT MAYBE" })
	afirma(l.Tabla.RotuloFrente.Texto.Text == "FORT MAYBE")
	H.Utileria.actualizar(l, { texto = "HOLA" })
	afirma(l.Tabla.RotuloFrente.Texto.Text == "HOLA")
end)

print("Escenarios")
prueba("los 12 escenarios, en gris y en detalle, caben en su celda y traen sus anclas", function()
	local d, H = lugar()
	local Es = H.Escenarios
	afirma(#Es.CLAVES == 12)
	for _, clave in Es.CLAVES do
		for _, version in { "gris", "detalle" } do
			local m, aviso = Es.construir(clave, { version = version })
			afirma(m, tostring(aviso))
			local origen = Es.origen(clave)
			afirma(origen.Position.Magnitude < 400, clave .. " queda lejos del origen")
			local centro, tam = d.cajaMundo(m.Piezas)
			afirma(math.abs(centro.X - origen.X) + tam.X / 2 <= Es.CELDA / 2 + 1, clave .. " se sale de la celda en X")
			afirma(math.abs(centro.Z - origen.Z) + tam.Z / 2 <= Es.CELDA / 2 + 1, clave .. " se sale de la celda en Z")
			for _, ancla in { "A", "B", "C", "centro", "barra", "multitud_1", "multitud_8", "cam_general", "cam_izq", "cam_der", "cam_alta" } do
				afirma(Es.ancla(m, ancla), clave .. " sin ancla " .. ancla)
			end
			afirma(#Es.multitud(m) == 8)
			local a = Es.ancla(m, "A")
			afirma(a.LookVector.Z > 0.5, "el ancla A mira hacia la cámara (+Z)")
			if version == "gris" then
				for _, p in m.Piezas:GetChildren() do
					afirma(math.abs(p.Color.R - p.Color.G) < 1e-6 and math.abs(p.Color.G - p.Color.B) < 1e-6, clave .. ": pieza no gris " .. p.Name)
				end
			end
			afirma(m:GetAttribute("Version") == version)
		end
	end
end)
prueba("climas: lluvia y nieve con ParticleEmitter solo en exteriores; activar oculta los demás", function()
	local d, H = lugar()
	local Es = H.Escenarios
	local cancha = Es.construir("cancha")
	local cuarto = Es.construir("cuarto")
	afirma(Es.clima(cancha, "lluvia") == nil)
	afirma(cancha.Clima.Nube.Lluvia:IsA("ParticleEmitter"))
	Es.clima(cancha, "nieve")
	afirma(cancha.Clima.Nube.Nieve:IsA("ParticleEmitter") and cancha.Clima:FindFirstChild("NieveSuelo"))
	Es.clima(cuarto, "lluvia")
	afirma(#cuarto.Clima:GetChildren() == 0, "en interiores no llueve")
	Es.clima(cuarto, "noche", { luz = true })
	afirma(H.Luz.actual() == "interior_noche")
	afirma(d.game:GetService("Lighting"):FindFirstChild("Historias_Atmosfera"))
	afirma(Es.clima(cancha, "granizo") ~= nil)
	for _, c in { "sol", "noche", "lluvia", "nieve", "niebla" } do
		afirma(Es.clima(cancha, c) == nil)
	end
	Es.activar("cuarto")
	afirma(cuarto.Parent == d.entorno.workspace.Historias.Escenarios and cancha.Parent ~= cuarto.Parent)
	Es.mostrarTodos()
	afirma(cancha.Parent == cuarto.Parent)
	afirma(Es.resolver("Colegio, pasillo") == nil and Es.resolver("Pueblo de día") == "pueblo" and Es.resolver("colegio pasillo") == "pasillo")
end)

print("Cámara")
prueba("distancia de encuadre y campos de visión en vertical y horizontal", function()
	local _, H = lugar()
	local C = H.Camara
	local v, h = C.campos(40, 16 / 9, true)
	cerca(math.deg(h), 40, 1e-6)
	cerca(math.deg(v), math.deg(2 * math.atan(math.tan(math.rad(20)) * 16 / 9)), 1e-6)
	local dist = C.distancia(4, 1, 40, 16 / 9, true)
	cerca(dist, 2 / math.tan(v / 2), 1e-6)
	afirma(C.distancia(4, 1, 40, 16 / 9, false) > dist, "en horizontal hay que alejarse más para el mismo alto")
	afirma(C.distancia(1, 6, 40, 16 / 9, true) > C.distancia(1, 1, 40, 16 / 9, true), "el ancho también limita")
end)
prueba("modo vertical: el eje derecho de la cámara apunta al arriba del mundo", function()
	local _, H = lugar()
	local C = H.Camara
	local obj = C.objetivo(Vector3.new(0, 4, 0), "M")
	local e = C.encuadrar(obj, "M", { elevacion = 0, vertical = true, duracion = 2 })
	local cf, fov = C.cframeEn(e, 0)
	cerca(cf.RightVector.Y, 1, 1e-6, "con giro +90 la derecha de la pantalla es el arriba de la escena")
	cerca(cf.LookVector.Z, -1, 1e-6, "desde el frente la cámara mira hacia -Z")
	cerca(fov, 40)
	local plano = C.encuadrar(obj, "M", { elevacion = 0, vertical = false })
	cerca(C.cframeEn(plano, 0).UpVector.Y, 1, 1e-6)
	local inclinada = C.encuadrar(obj, "M", { elevacion = 0, vertical = false, inclinacion = 10 })
	cerca(C.cframeEn(inclinada, 0).RightVector.Y, math.sin(math.rad(10)), 1e-6)
	afirma(C.GIRO_VERTICAL == 90 and C.ROTAR_MONTAJE == "antihorario")
end)
prueba("el objetivo queda centrado y los movimientos son continuos", function()
	local _, H = lugar()
	local C = H.Camara
	local a = H.Elenco.crear({ id = "a" })
	local b = H.Elenco.crear({ id = "b" })
	H.Elenco.ubicar(a, H.Elenco.cfPies({ -3, 0, 0 }, 0))
	H.Elenco.ubicar(b, H.Elenco.cfPies({ 3, 0, 0 }, 0))
	local dC = C.encuadrar(C.objetivo(a, "C"), "C").distancia
	local dM = C.encuadrar(C.objetivo(a, "M"), "M").distancia
	local dG = C.encuadrar(C.objetivo(a, "G"), "G").distancia
	afirma(dC < dM and dM < dG, "C < M < G")
	afirma(C.encuadrar(C.objetivo({ a, b }, "M"), "M").distancia > dM, "dos personajes piden más distancia")
	for mov in C.MOVIMIENTOS do
		local e = C.encuadrar(C.objetivo({ a, b }, "M"), "M", { movimiento = mov, duracion = 1.5 })
		afirma(e.movimiento == mov)
		local previo = C.cframeEn(e, 0.2)
		for i = 1, 78 do
			local cf = C.cframeEn(e, 0.2 + i / 60)
			afirma((cf.Position - previo.Position).Magnitude < e.distancia * 0.05, mov .. ": salto entre cuadros")
			if mov ~= "temblor" and string.sub(mov, 1, 5) ~= "paneo" and mov ~= "subir" then
				local alCentro = (e.centro - cf.Position).Unit
				afirma(alCentro:Dot(cf.LookVector) > 0.9999, mov .. ": el objetivo no está centrado")
			end
			previo = cf
		end
	end
	local brusco = C.encuadrar(C.objetivo(a, "C"), "C", { movimiento = "acercar_brusco", duracion = 1 })
	afirma((C.cframeEn(brusco, 0).Position - brusco.centro).Magnitude > (C.cframeEn(brusco, 0.3).Position - brusco.centro).Magnitude * 1.2)
end)
prueba("verificador: detecta una pared entre la cámara y el objetivo e ignora lo transparente", function()
	local d, H = lugar()
	local C = H.Camara
	local a = H.Elenco.crear({ id = "a" })
	H.Elenco.ubicar(a, H.Elenco.cfPies({ 0, 0, 0 }, 0))
	local e = C.encuadrar(C.objetivo(a, "M"), "M")
	local cf = C.cframeEn(e, 0)
	afirma(C.verificar(cf, e) == false, "sin obstáculos no debe avisar")
	local pared = H.Base.pieza({ nombre = "Pared", tam = { 20, 20, 1 }, pos = { 0, 5, 2.5 }, padre = d.entorno.workspace })
	local tapado, por = C.verificar(cf, e)
	afirma(tapado == true and string.find(por, "Pared", 1, true), tostring(por))
	pared.Transparency = 1
	afirma(C.verificar(cf, e) == false, "una pieza transparente no tapa")
	pared.Transparency = 0
	pared.CFrame = CFrame.new(0, 5, -8)
	afirma(C.verificar(cf, e) == false, "lo que está detrás del objetivo no tapa")
end)

print("Director")
local function planDe(puesta: any, escala: number): any
	local planos = {}
	for _, p in puesta.planos do
		table.insert(planos, { n = p.n, inicio = p.inicio * escala, fin = p.fin * escala, texto = p.texto .. " (plan)" })
	end
	return { video = puesta.video, duracion = puesta.duracion * escala, planos = planos }
end
prueba("combinar: los tiempos y el texto del plan mandan; indiceEn encuentra el plano", function()
	local _, H = lugar()
	local puesta = Doble.decodificarJSON(FUENTES.puesta001)
	local datos, avisos = H.combinar(planDe(puesta, 0.5), FUENTES.puesta001)
	afirma(#datos.planos == 49 and #avisos == 0)
	cerca(datos.duracion, 49.2)
	cerca(datos.planos[2].inicio, puesta.planos[2].inicio * 0.5)
	afirma(string.find(datos.planos[1].texto, "(plan)", 1, true))
	afirma(datos.planos[1].camara.tipo == "M")
	local solo = H.combinar(nil, FUENTES.puesta001)
	cerca(solo.duracion, 98.4)
	afirma(H.indiceEn(solo.planos, 0) == 1)
	afirma(H.indiceEn(solo.planos, solo.planos[10].inicio) == 10)
	afirma(H.indiceEn(solo.planos, solo.planos[10].inicio - 0.001) == 9)
	afirma(H.indiceEn(solo.planos, 500) == 49)
	local _, falta = H.combinar({ planos = { { n = 1, inicio = 0, fin = 1 }, { n = 99, inicio = 1, fin = 2 } } }, { planos = { { n = 1 }, { n = 5 } } })
	afirma(#falta == 2, "debe avisar del plano sin puesta y del sobrante")
end)
prueba("la puesta del guion 001 es válida contra los catálogos", function()
	local _, H = lugar()
	local problemas = H.validar((H.combinar(nil, FUENTES.puesta001)))
	afirma(#problemas == 0, table.concat(problemas, "; "))
end)

local ctx001: any, d001: any, H001: any
prueba("preparar la puesta 001: 9 escenarios, 12 personajes, utilería", function()
	d001, H001 = lugar()
	ctx001 = H001.preparar(nil, FUENTES.puesta001, { ceder = false })
	local n = 0
	for _ in ctx001.escenas do
		n += 1
	end
	afirma(n == 9, "escenarios: " .. n)
	n = 0
	for _, pj in ctx001.elenco do
		n += 1
		afirma(pj:GetAttribute("Estilo") == "propio")
	end
	afirma(n == 12, "personajes: " .. n)
	afirma(ctx001.utileria.barra and ctx001.utileria.barra_mitades and ctx001.utileria.marcador)
	afirma(#ctx001.avisos == 0, table.concat(ctx001.avisos, "; "))
end)
prueba("ensayo de la puesta 001: sin referencias inexistentes; reporta los planos cortos", function()
	local informe = H001.ensayo(ctx001)
	afirma(informe.total == 49)
	afirma(#informe.inexistentes == 0, table.concat(informe.inexistentes, "; "))
	afirma(#informe.cortos == 1 and string.find(informe.cortos[1], "plano 11", 1, true), table.concat(informe.cortos, "; "))
	print("         tapados en el doble: " .. #informe.tapados .. (#informe.tapados > 0 and (" -> " .. table.concat(informe.tapados, " | ")) or ""))
end)
prueba("foto: salta a un plano y deja escena, personajes, utilería y cámara", function()
	local r = H001.foto(ctx001, 24, 0.5)
	afirma(r.n == 24 and #r.avisos == 0, table.concat(r.avisos or {}, "; "))
	local ws = d001.entorno.workspace
	afirma(ws.Historias.Escenarios:FindFirstChild("cafeteria") and #ws.Historias.Escenarios:GetChildren() == 1, "solo el escenario activo queda en workspace")
	afirma(ws.Historias.Elenco:FindFirstChild("narrador") and ws.Historias.Elenco:FindFirstChild("theo"))
	afirma(ws.Historias.Elenco:FindFirstChild("hermana") == nil, "los ausentes se guardan")
	local barra = ctx001.utileria.barra
	afirma(barra.Parent == ws.Historias.Utileria)
	afirma(barra.Pantalla.RotuloFrente.Texto.Text == "3%", "a mitad del plano 24 la barra marca 3: " .. barra.Pantalla.RotuloFrente.Texto.Text)
	local cam = ws.CurrentCamera
	cerca(cam.FieldOfView, 40)
	afirma(cam.CameraType ~= d001.entorno.Enum.CameraType.Scriptable, "en edición no se toca CameraType")
	afirma(math.abs(cam.CFrame.RightVector.Y) > 0.9, "cámara girada (vertical)")
	afirma(#r.camara.posicion == 3 and r.camara.vertical == true)
	local r2 = H001.foto(ctx001, 32)
	afirma(d001.game:GetService("Lighting"):GetAttribute("HR_Preajuste") == "interior_noche", "plano 32: cuarto de noche")
	afirma(ctx001.elenco.narrador:GetAttribute("Pose") == "acostado" and #r2.avisos == 0)
	afirma(H001.foto(ctx001, 500).error ~= nil)
	local r3 = H001.foto(ctx001, 23)
	local papas, mano = ctx001.utileria.papas, H001.Elenco.punto(ctx001.elenco.narrador, "mano_der")
	afirma((papas:GetPivot().Position - mano.Position).Magnitude < 1.2 and #r3.avisos == 0, "la bolsa va en la mano")
	local r1 = H001.foto(ctx001, 1)
	local n, t = ctx001.elenco.narrador, ctx001.elenco.theo
	afirma(n.Torso.CFrame.LookVector.X > 0.9 and t.Torso.CFrame.LookVector.X < -0.9 and #r1.avisos == 0, "se miran de frente")
end)
prueba("ensayo detecta lo sembrado: referencias inexistentes, plano corto y objetivo tapado", function()
	local d, H = lugar()
	local puesta = {
		video = "sembrado", elenco = { ana = {} },
		planos = {
			{ n = 1, inicio = 0, fin = 2, escenario = "parque", personajes = { { id = "ana", ancla = "A", cara = "feliz" } },
				camara = { objetivo = { "ana" }, tipo = "M" } },
			{ n = 2, inicio = 2, fin = 2.3, escenario = "parque", personajes = { { id = "ana", ancla = "no_hay", pose = "volar", cara = "zzz" } },
				utileria = { { id = "x", tipo = "nave" } }, camara = { objetivo = { "fantasma" }, tipo = "M", movimiento = "girar" },
				efecto = "explosion_nuclear", luz = "discoteca" },
			{ n = 3, inicio = 2.3, fin = 4, escenario = "luna", personajes = { { id = "beto", ancla = "A" } }, camara = { objetivo = { "ana" }, tipo = "C" } },
			{ n = 4, inicio = 4, fin = 6, escenario = "parque", personajes = { { id = "ana", ancla = "centro" } }, camara = { objetivo = { "ana" }, tipo = "M" } },
		},
	}
	local ctx = H.preparar(nil, puesta, { ceder = false })
	local origen = H.Escenarios.origen("parque")
	H.Base.pieza({ nombre = "Muro", tam = { 30, 30, 1 }, cf = origen * CFrame.new(0, 5, 4.5), padre = ctx.escenas.parque.Piezas })
	local informe = H.ensayo(ctx)
	local todo = table.concat(informe.inexistentes, "\n")
	for _, esperado in { "ancla inexistente: no_hay", "pose inexistente: volar", "cara inexistente: zzz", "utilería inexistente: nave",
		"movimiento inexistente: girar", "efecto inexistente: explosion_nuclear", "luz inexistente: discoteca",
		"escenario inexistente: luna", "personaje inexistente: beto", "objetivo de cámara inexistente o fuera del plano: fantasma" } do
		afirma(string.find(todo, esperado, 1, true), "no reportó: " .. esperado .. "\n" .. todo)
	end
	afirma(#informe.cortos == 1 and string.find(informe.cortos[1], "plano 2", 1, true))
	afirma(#informe.tapados >= 2 and string.find(table.concat(informe.tapados, "\n"), "Muro", 1, true), table.concat(informe.tapados, "\n"))
	afirma(string.find(table.concat(d.registro, "\n"), "ensayo de sembrado", 1, true), "el informe va a la consola")
end)

local function rodar(config: any, usarPlan: boolean)
	local d, H = lugar(config)
	local puesta = Doble.decodificarJSON(FUENTES.puesta001)
	local plan = usarPlan and planDe(puesta, 0.25) or nil
	local ctx = H.preparar(plan, FUENTES.puesta001, { ceder = false })
	local L = d.game:GetService("Lighting")
	local blancos, cuadro, primerBlanco, ultimoBlanco = 0, 0, nil, nil
	local terminado = false
	local control = H.reproducir(ctx, { previa = 0.5, alTerminar = function()
		terminado = true
	end })
	local dt = 1 / 60
	local entradas: { [number]: number } = {}
	local previo = 1
	while not terminado and cuadro < 60 * 200 do
		d.avanzar(dt)
		cuadro += 1
		local e = L:FindFirstChild("Historias_Destello")
		if e and e.Enabled then
			blancos += 1
			primerBlanco = primerBlanco or cuadro
			ultimoBlanco = cuadro
		end
		if control.fase == "rodando" and control.indice ~= previo then
			previo = control.indice
			entradas[control.indice] = d.reloj - control.t0
		end
	end
	return d, H, ctx, control, { blancos = blancos, primerBlanco = primerBlanco, ultimoBlanco = ultimoBlanco, cuadros = cuadro, entradas = entradas, dt = dt, terminado = terminado }
end
for _, caso in {
	{ nombre = "modo Play (cliente, paso de render)", config = { cliente = true, corriendo = true }, plan = false },
	{ nombre = "modo Run (servidor, Heartbeat) con tiempos del plan", config = { cliente = false, corriendo = true }, plan = true },
} do
	prueba("reproducir en " .. caso.nombre .. ": destello de 2 cuadros y cada plano en su cuadro", function()
		local d, _, ctx, control, m = rodar(caso.config, caso.plan)
		afirma(m.terminado, "no terminó")
		-- El blanco se enciende en un paso y se apaga dos pasos después: se ve en 2 cuadros.
		afirma(m.blancos == 2, "cuadros en blanco: " .. m.blancos)
		afirma(control.t0 ~= nil and #ctx.planos == 49)
		local maximo = 0
		for i = 2, 49 do
			local real = m.entradas[i]
			afirma(real ~= nil, "nunca entró el plano " .. i)
			local desvio = real - ctx.planos[i].inicio
			afirma(desvio >= -1e-9 and desvio <= m.dt + 1e-9, string.format("plano %d entró con desvío de %.4f s", i, desvio))
			maximo = math.max(maximo, desvio)
		end
		afirma(control.desvioMaximo <= m.dt + 1e-9)
		local esperados = (0.5 + ctx.duracion + 0.5) * 60
		afirma(math.abs(m.cuadros - esperados) < 8, "cuadros totales " .. m.cuadros .. " frente a " .. esperados)
		local cam = d.entorno.workspace.CurrentCamera
		afirma(cam.CameraType == d.entorno.Enum.CameraType.Scriptable, "con el juego corriendo la cámara queda Scriptable")
		local registro = table.concat(d.registro, "\n")
		afirma(string.find(registro, "fin de 001", 1, true), "falta el informe final")
		if caso.config.cliente then
			local gui = d.game:GetService("Players").LocalPlayer.PlayerGui
			afirma(gui:FindFirstChild("HistoriasDestello") == nil, "el ScreenGui del destello se retira al terminar")
			afirma(d.noSimulados["StarterGui:SetCoreGuiEnabled"] == 1 and d.noSimulados["StarterGui:SetCore"] == 1, "oculta la interfaz")
		end
		print(string.format("         %d cuadros simulados a 60 por segundo; desvío máximo de entrada %.2f ms", m.cuadros, maximo * 1000))
	end)
end
prueba("un cuadro largo (tirón de 0.4 s) no acumula deriva: los planos siguientes entran a tiempo", function()
	local d, H = lugar({ cliente = true, corriendo = true })
	local ctx = H.preparar(nil, FUENTES.puesta001, { ceder = false })
	local control = H.reproducir(ctx, { previa = 0 })
	for _ = 1, 4 do
		d.avanzar(1 / 60)
	end
	afirma(control.fase == "rodando")
	for _ = 1, 120 do
		d.avanzar(1 / 60)
	end
	d.avanzar(0.4)
	local i = control.indice
	local objetivo = ctx.planos[i + 3].inicio
	while d.reloj - control.t0 < objetivo - 1e-9 do
		d.avanzar(1 / 60)
	end
	afirma(control.indice == i + 3, "tras el tirón debía estar en el plano " .. (i + 3) .. " y está en " .. control.indice)
	afirma(control.entradas[i + 3] - objetivo <= 1 / 60 + 1e-9)
	control.detener()
	afirma(control.fase == "terminado")
end)
prueba("guardarDatos, configurarLugar y los lanzadores (cliente y servidor)", function()
	local d, H = lugar({ cliente = true, corriendo = true })
	H.guardarDatos(nil, FUENTES.puesta001)
	H.configurarLugar("play")
	afirma(d.game:GetService("Players").CharacterAutoLoads == false)
	local rs = d.game:GetService("ReplicatedStorage")
	afirma(rs.Historias.Datos.Puesta.Value == FUENTES.puesta001 and rs.Historias:GetAttribute("Modo") == "play")
	local lanzador = d.game:GetService("StarterPlayer").StarterPlayerScripts.HistoriasRodarCliente
	d.ejecutar(lanzador.Source, "RodarCliente", lanzador)
	afirma(string.find(table.concat(d.registro, "\n"), "rodando 001", 1, true), "el lanzador del cliente debe iniciar la reproducción")
	local servidor = d.game:GetService("ServerScriptService").HistoriasRodar
	local antes = #d.registro
	d.ejecutar(servidor.Source, "Rodar", servidor)
	afirma(#d.registro == antes, "en modo Play el lanzador del servidor no hace nada")
	H.restaurar()
end)
prueba("restaurar devuelve todo a workspace y revierte la luz", function()
	H001.foto(ctx001, 40)
	H001.restaurar(ctx001)
	local ws = d001.entorno.workspace
	afirma(#ws.Historias.Escenarios:GetChildren() == 9 and #ws.Historias.Elenco:GetChildren() == 12)
	afirma(d001.game:GetService("Lighting"):GetAttribute("HR_Preajuste") == nil)
end)

local nombres = {}
for clave in d001.noSimulados do
	table.insert(nombres, clave)
end
table.sort(nombres)
print("\nMétodos de Roblox llamados cuyo nombre existe en el volcado pero cuyo efecto NO se simula:")
print("  " .. table.concat(nombres, ", "))
print(string.format("\n%d pruebas, %d fallas", total, fallas))
if fallas > 0 then
	error("hay pruebas fallidas", 0)
end
return true
