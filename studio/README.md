# studio: biblioteca Historias y director de planos

Biblioteca Luau reutilizable para producir los cortos del canal dentro de Roblox Studio,
pensada para que un chat de Claude Code la inyecte por el servidor MCP de Studio y la use
video tras video. Todo el contenido visual se arma con piezas propias (`Part`): no usa el
logo ni marcas de Roblox, ni ids del catálogo inventados.

**Estado: nada de esto se ha ejecutado dentro de Roblox Studio.** En el equipo donde se
escribió, Studio no abre. Se comprobó todo lo que se puede comprobar por fuera (ver
"Qué se comprobó") y la sección "Lo que NO se pudo probar" dice exactamente qué falta.

## Arquitectura

| Archivo | Qué hace |
|---|---|
| `lib/Base.luau` | Utilidades comunes: colores y vectores desde JSON, creación de piezas, carpetas raíz, curvas, interpolación por claves, azar determinista. |
| `lib/Caras.luau` | 20 expresiones. Catálogo nombre a id de imagen (todos en 0, por llenar) con `registrar(nombre, id)`, y dibujo de respaldo con `SurfaceGui`, `Frame`, `UICorner` y `UIStroke`. |
| `lib/Elenco.luau` | Personajes en dos estilos: `"propio"` (por defecto: bloques con proporciones propias, sin Humanoid) y `"r6"` (rig R6 estándar). Ubicar, sentar, mirar y 20 poses estáticas sobre los `Motor6D`. |
| `lib/Luz.luau` | 8 preajustes de `Lighting` con `Atmosphere`, Bloom, ColorCorrection, DepthOfField y SunRays, aplicables y reversibles. Destello blanco y tintes para efectos. |
| `lib/Utileria.luau` | Utilería parametrizable: batería, letrero, ratón, globos, balón, arco, marcador, celular, carta, flor, mesa, silla, objeto genérico de cajas y 9 prefabricados. |
| `lib/Escenarios.luau` | 12 escenarios por piezas, versión gris y detallada, anclas con nombre, cámaras con nombre y 5 climas. |
| `lib/Camara.luau` | Encuadres G, M y C, 8 movimientos, inclinación, modo vertical y verificador de objetivo tapado con `workspace:Raycast`. |
| `Director.luau` | Une plan y puesta, prepara todo y ejecuta: modos foto, ensayo y reproducir. |
| `empaque/` | Plantilla de `cargar.luau` y los dos lanzadores (`Rodar.server.luau`, `RodarCliente.client.luau`). |
| `empaquetar.py` | Genera `cargar.luau`, `cargar_multi_edit.json` y `monolito.luau` a partir de los fuentes. |
| `cargar.luau` | GENERADO. Un solo bloque para `execute_luau` que instala todo en `ReplicatedStorage.Historias`. |
| `cargar_multi_edit.json` | GENERADO. La misma instalación como llamadas de la herramienta `multi_edit`. |
| `monolito.luau` | GENERADO. Toda la biblioteca en un bloque, sin crear scripts ni usar `require`. |
| `ejemplos/001-puesta.json` | Puesta en escena completa de los 49 planos del guion 001. |
| `pruebas/` | Doble de la API de Roblox, tabla de la API generada del volcado oficial, pruebas y scripts para repetir el análisis. |
| `.luaurc` | Globales de Roblox para `luau-analyze`. |

Dependencias entre módulos (cada uno solo requiere a los anteriores):
`Base`, `Caras`, `Elenco`, `Luz`, `Utileria`, `Escenarios`, `Camara`, `Director`.

En el lugar de Studio todo queda así:

- `ReplicatedStorage.Historias`: los 8 `ModuleScript` y la carpeta `Datos` (plan y puesta
  como `StringValue`).
- `workspace.Historias.Escenarios`, `.Elenco`, `.Utileria`: lo que está en escena.
- `ReplicatedStorage.HistoriasBodega`: lo que no participa en el plano actual.
- `ServerScriptService.HistoriasRodar` y
  `StarterPlayer.StarterPlayerScripts.HistoriasRodarCliente`: los lanzadores.
- En `Lighting`, todo lo que crea la biblioteca se llama `Historias_...`.

## Instalación en un lugar nuevo

Hay tres vías. Usa la primera que funcione; la primera prueba en Studio dirá cuál es.

1. **`cargar.luau` en una llamada de `execute_luau`** (`datamodel_type = "Edit"`). Crea los
   `ModuleScript` asignando `Source`. Devuelve un texto que empieza por
   `Historias 1.0.0 instalada...` o explica por qué no pudo.
2. **`multi_edit`**, un script por llamada, con el contenido de `cargar_multi_edit.json`. Es
   la vía que la propia herramienta `execute_luau` recomienda para crear scripts.
3. **`monolito.luau`**: pega el archivo completo en `execute_luau` y agrega tu código
   después de la última línea (ahí existe la variable `Historias`). No instala nada; sirve
   para construir, posar y revisar en edición, no para los lanzadores de grabación.

**Permisos para escribir `Source`** (comprobado en la referencia oficial y en el volcado de
la API de Studio 0.747): `Script.Source`, `LocalScript.Source` y `ModuleScript.Source`
exigen la capacidad `PluginOrOpenCloud` para leer y escribir, y
`ScriptEditorService:UpdateSourceAsync` exige seguridad de plugin. La documentación del
servidor MCP no dice con qué permisos corre `execute_luau`; reportes de la comunidad
indican que corre con capacidades restringidas, que hubo versiones donde no podía hacer
`require` ni asignar `Parent` a scripts, y la descripción de la herramienta pide no usarla
para editar código. Por eso `cargar.luau` intenta `Source`, luego `UpdateSourceAsync`, y si
ninguno se permite lo dice y remite a las vías 2 y 3.

Después de cambiar cualquier fuente: `python studio/empaquetar.py` y vuelve a instalar.
`cargar.luau` reemplaza cada `ModuleScript` por una instancia nueva para que `require` no
devuelva una copia vieja en caché.

## Orden de uso, video tras video

1. Genera la voz y el plan de planos (`plan.json`) con la herramienta de Python del audio.
2. El chat escribe `puesta.json` a partir del plan (esquema abajo).
3. Instala o actualiza la biblioteca (sección anterior).
4. En edición, prepara y ensaya:

```lua
-- execute_luau, datamodel_type = "Edit"
local H = require(game.ReplicatedStorage.Historias.Director)
local ctx = H.preparar(PLAN_JSON, PUESTA_JSON, { version = "gris" })  -- primero en gris
local informe = H.ensayo(ctx)
return informe
```

   El ensayo devuelve tres listas: `cortos` (planos de menos de 0,6 s), `tapados` (hay una
   pieza entre la cámara y el objetivo) e `inexistentes` (nombres que no existen: anclas,
   poses, caras, personajes, utilería, movimientos, efectos, luz, escenario).
5. Revisa plano por plano con el modo foto y `screen_capture`:

```lua
local H = require(game.ReplicatedStorage.Historias.Director)
local ctx = H.preparar(PLAN_JSON, PUESTA_JSON, { version = "gris" })
return H.foto(ctx, 12)   -- deja montado el plano 12 y devuelve avisos y la cámara
```

   Como cada llamada de `execute_luau` empieza de cero, `preparar` se repite; reutiliza lo
   que ya está construido si la versión coincide (usa `reconstruir = true` para forzar).
6. Cuando las posiciones estén bien, repite con `version = "detalle"`.
7. Guarda los datos y configura el lugar para grabar:

```lua
local H = require(game.ReplicatedStorage.Historias.Director)
H.guardarDatos(PLAN_JSON, PUESTA_JSON)
H.configurarLugar("play")
return "listo"
```

8. Inicia la grabación de pantalla, luego la prueba (`start_stop_play`). El lanzador del
   cliente espera 2 segundos en el plano 1, lanza el destello y reproduce. Al terminar
   imprime el desvío máximo de entrada de los planos.
9. En el montaje: cortar en el primer cuadro no blanco después del destello, girar 90
   grados en sentido antihorario si se grabó en vertical, y alinear el audio en ese punto.
10. Para seguir editando el lugar: `H.restaurar()` devuelve todo a `workspace` y revierte
    la luz. `H.configurarLugar` deja `Players.CharacterAutoLoads` en falso; vuelve a
    ponerlo en verdadero si el lugar se va a usar para otra cosa.

## Modos y dónde vive cada script

| Modo | Dónde corre | Para qué |
|---|---|---|
| `foto`, `ensayo`, `preparar` | Edición, desde `execute_luau` (`Edit`) | Construir y revisar. No ponen `CameraType` en `Scriptable`: Studio lo restaura después de cada `execute_luau` y `screen_capture` falla con ese tipo de cámara. |
| `reproducir` (recomendado) | Modo juego con cliente (Play), `LocalScript` en `StarterPlayer.StarterPlayerScripts` | Grabar. La cámara `Scriptable`, ocultar la interfaz y el paso de render (`BindToRenderStep`) solo existen en el cliente. Los cambios son locales y se descartan al detener. |
| `reproducir` (alternativa) | Modo Run, `Script` en `ServerScriptService` | Grabar sin jugador ni interfaz. Usa `Heartbeat`. Falta comprobar que la cámara de Studio obedezca en ese modo. Se activa con `H.configurarLugar("run")`. |
| Línea de comandos | No se usa para grabar | El código corre en el hilo principal y no está comprobado que una conexión siga viva al terminar la llamada. |

El tiempo se mide con `os.clock()` en cada cuadro contra un instante cero fijo; no se
encadenan esperas, así que el error por plano es de un cuadro como máximo y no se acumula.

**Destello de sincronía.** Tras la espera previa, la pantalla queda en blanco 2 cuadros
(`ColorCorrectionEffect` con `Brightness = 1` y, en el cliente, un `Frame` blanco a
pantalla completa). El instante cero es el primer cuadro NO blanco: ahí empieza el plano 1.
Opciones de `reproducir`: `previa`, `cuadrosDestello`, `colorDestello`, `cola`.

## Convenciones

- **Todo cerca del origen.** Cada escenario vive en una celda de una cuadrícula de 4 por 3
  con 160 studs de separación; ninguno queda a más de 400 studs del origen.
- **Un `Model` por escenario**, con las carpetas `Piezas`, `Anclas`, `Camaras` y `Clima`.
  El piso está en `y = 0` de la celda.
- **El frente es +Z.** La cámara mira hacia -Z. Los interiores son dioramas sin techo ni
  pared frontal.
- **Giro de personajes:** `giro = 0` mira hacia la cámara (+Z); positivo gira hacia +X.
- **Anclas de personaje:** `A`, `B`, `C`, `centro`, `multitud_1` a `multitud_8`, más las
  propias de cada escenario. **Puntos de utilería:** `barra`, `suelo`, `mesa`, etc.
  **Cámaras:** `cam_general`, `cam_izq`, `cam_der`, `cam_alta`.
- **Versión gris primero.** En gris las anclas se ven (naranja: personaje; azul: utilería;
  morado: cámara); en detalle son invisibles.
- **Solo el escenario activo está en `workspace`**; los demás, y los personajes y objetos
  que no salen en el plano, se guardan en `ReplicatedStorage.HistoriasBodega`.
- **Nombres:** claves en minúscula, sin tildes y con guion bajo (`calle_noche`,
  `sonrisa_enorme`). La biblioteca normaliza tildes, mayúsculas y espacios.
- **Utilería:** el frente del objeto es su +Z local y su origen es el centro de la base.
- **Cada plano es autosuficiente:** declara todo lo que se ve. Lo que no se nombra se
  oculta. Así el modo foto puede saltar a cualquier plano.

## Esquema de `puesta.json`

```text
{
  "video": texto,                 nombre del video
  "esquema": 1,
  "vertical": true | false,       por defecto true (cámara girada 90 grados)
  "estilo": "propio" | "r6",      por defecto "propio"
  "duracion": número,             opcional si hay plan
  "predeterminados": { "clima": ..., "luz": ..., "escenario": ... },
  "elenco": {
    "<id>": {
      "piel": "#RRGGBB", "camisa": "#RRGGBB", "pantalon": "#RRGGBB",
      "mangas": "cortas" | "largas",
      "pelo": { "tipo": "corto" | "largo" | "coletas" | "copete" | "abuelo" | "gorra" | "ninguno", "color": "#RRGGBB" },
      "cabeza": "bola" | "bloque",          solo estilo propio
      "estilo": "propio" | "r6",            opcional, por personaje
      "camisa_id": 0, "pantalon_id": 0, "accesorios": [0]   solo estilo r6; 0 = por llenar
    }
  },
  "planos": [
    {
      "n": número,                 enlaza con el plan
      "inicio": s, "fin": s, "texto": texto,    los pisa el plan si existe
      "escenario": clave,          pueblo, parque, cuarto, sala, cocina, salon, pasillo,
                                   cafeteria, cancha, patio, bosque, calle_noche
      "clima": "sol" | "noche" | "lluvia" | "nieve" | "niebla",
      "luz": preajuste,            opcional; si falta se deduce del clima y del escenario
      "personajes": [
        { "id": id del elenco,
          "ancla": nombre de ancla   o   "pos": [x, y, z] relativo al origen del escenario,
          "giro": grados,          opcional; reemplaza la orientación del ancla
          "desplazar": [dx, dy, dz],
          "pose": nombre de pose   o   tabla de ángulos por articulación,
          "cara": nombre de expresión,
          "mira": id de otro personaje | "camara" | "ancla:NOMBRE" | "util:ID" }
      ],
      "utileria": [
        { "id": texto único,       un mismo id es el mismo objeto en todos los planos
          "tipo": tipo de utilería,
          "params": { ... },       al crear; en batería, letrero y marcador también actualiza
          "ancla": nombre   o   "pos": [x, y, z],   "giro": grados, "desplazar": [dx, dy, dz],
          "pegado": { "personaje": id, "parte": "mano_der" | "mano_izq" | "cabeza_arriba" | "pecho", "rel": [x, y, z] },
          "claves": { "porcentaje": [[fracción, valor], ...] } }   animación dentro del plano
      ],
      "camara": {
        "objetivo": [ id | "util:ID" | "ancla:NOMBRE" | "escena:NOMBRE" , ... ],
        "tipo": "G" | "M" | "C",
        "movimiento": "fijo" | "acercar_lento" | "alejar_lento" | "acercar_brusco" |
                      "paneo_der" | "paneo_izq" | "subir" | "temblor",
        "inclinacion": grados,     giro leve del horizonte (dutch)
        "desde": "frente" | "izq" | "der" | "alta" | "picado" | "contrapicado" |
                 "perfil_izq" | "perfil_der" | "atras",
        "azimut": grados, "elevacion": grados,     opcionales; pisan a "desde"
        "margen": número,          1.12 por defecto; mayor aleja la cámara
        "fov": grados,             40 por defecto
        "ancla": nombre de cámara  opcional; usa esa posición fija mirando al objetivo
      },
      "efecto": nombre | { "tipo": nombre, "en": referencia } | lista
                "recuerdo", "destello_verde", "chispas", "confeti", "vibrar", "parpadeo"
    }
  ]
}
```

Reglas:

- Los tiempos del plan mandan. Un plano que esté en el plan y no en la puesta repite la
  puesta del anterior y genera un aviso.
- Si un mismo `id` de utilería necesita otra forma (otro tamaño, con telarañas, partida en
  dos mitades), usa otro `id`.
- Una referencia que no existe nunca detiene la reproducción: se usa un valor de respaldo
  (ancla `centro`, pose `de_pie`, cara `neutra`) y queda en la lista de avisos.

### Ejemplo real: los primeros 8 planos del guion 001

Tomado de `ejemplos/001-puesta.json`. Los tiempos de ese archivo son estimados por número
de palabras; el plan con los tiempos reales del audio los reemplaza.

```json
{
 "video": "001-friendships-have-a-battery", "esquema": 1, "vertical": true, "estilo": "propio",
 "predeterminados": {"clima": "sol"},
 "elenco": {
  "narrador": {"piel": "#F2C9A0", "camisa": "#3B82F6", "pantalon": "#28303F", "pelo": {"tipo": "corto", "color": "#4B2E1A"}},
  "theo": {"piel": "#D9A066", "camisa": "#E5383B", "pantalon": "#1F2937", "pelo": {"tipo": "copete", "color": "#1B1B1F"}},
  "hermana": {"piel": "#F2C9A0", "camisa": "#E94F9B", "pantalon": "#5B4B8A", "pelo": {"tipo": "coletas", "color": "#4B2E1A"}},
  "abuelo": {"piel": "#E8BE96", "camisa": "#8A9A5B", "pantalon": "#6B4A2E", "pelo": {"tipo": "abuelo", "color": "#D9D9DE"}, "mangas": "largas"},
  "amigo_ajedrez": {"piel": "#B9784B", "camisa": "#C89B5E", "pantalon": "#3A3D45", "pelo": {"tipo": "abuelo", "color": "#F4F4F4"}, "mangas": "largas"},
  "extra1": {"piel": "#F2D3B3", "camisa": "#3CD070", "pantalon": "#28303F", "pelo": {"tipo": "corto", "color": "#C98A2B"}},
  "extra2": {"piel": "#8D5A3B", "camisa": "#F2C230", "pantalon": "#1F2937", "pelo": {"tipo": "corto", "color": "#1B1B1F"}},
  "extra3": {"piel": "#F2C9A0", "camisa": "#B07CF2", "pantalon": "#28303F", "pelo": {"tipo": "largo", "color": "#7A3B1E"}},
  "extra4": {"piel": "#D9A066", "camisa": "#F28B30", "pantalon": "#3A3D45", "pelo": {"tipo": "gorra", "color": "#22252E"}},
  "extra5": {"piel": "#F2D3B3", "camisa": "#30B8C9", "pantalon": "#28303F", "pelo": {"tipo": "largo", "color": "#E8C36A"}}
 },
 "planos": [
  {"n": 1, "inicio": 0.0, "fin": 2.73, "texto": "In this world, every friendship has a battery,",
   "escenario": "pueblo",
   "personajes": [
     {"id": "narrador", "ancla": "A", "pose": "de_pie", "cara": "feliz", "mira": "theo"},
     {"id": "theo", "ancla": "B", "pose": "de_pie", "cara": "feliz", "mira": "narrador"}
   ],
   "utileria": [
     {"id": "barra", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 98}}
   ],
   "camara": {"objetivo": ["narrador", "theo", "util:barra"], "tipo": "M", "movimiento": "acercar_lento"}},
  {"n": 2, "inicio": 2.73, "fin": 5.81, "texto": "and everybody can see how much charge is left.",
   "escenario": "pueblo",
   "personajes": [
     {"id": "extra1", "ancla": "pareja_1a", "pose": "de_pie", "cara": "neutra"},
     {"id": "extra2", "ancla": "pareja_1b", "pose": "de_pie", "cara": "neutra"},
     {"id": "extra3", "ancla": "pareja_2a", "pose": "de_pie", "cara": "neutra"},
     {"id": "extra4", "ancla": "pareja_2b", "pose": "de_pie", "cara": "neutra"},
     {"id": "hermana", "ancla": "pareja_3a", "pose": "de_pie", "cara": "neutra"},
     {"id": "extra5", "ancla": "pareja_3b", "pose": "de_pie", "cara": "neutra"},
     {"id": "abuelo", "ancla": "pareja_4a", "pose": "de_pie", "cara": "neutra"},
     {"id": "amigo_ajedrez", "ancla": "pareja_4b", "pose": "de_pie", "cara": "neutra"}
   ],
   "utileria": [
     {"id": "barra_p1", "tipo": "bateria", "ancla": "barra_1", "params": {"porcentaje": 80}},
     {"id": "barra_p2", "tipo": "bateria", "ancla": "barra_2", "params": {"porcentaje": 45}},
     {"id": "barra_p3", "tipo": "bateria", "ancla": "barra_3", "params": {"porcentaje": 15}},
     {"id": "barra_p4", "tipo": "bateria", "ancla": "barra_4", "params": {"porcentaje": 100}}
   ],
   "camara": {"objetivo": ["ancla:barra_2", "ancla:barra_3"], "tipo": "G", "movimiento": "paneo_der", "elevacion": 10}},
  {"n": 3, "inicio": 5.81, "fin": 8.88, "texto": "It floats between you like a little green bar.",
   "escenario": "pueblo",
   "personajes": [
     {"id": "narrador", "ancla": "A", "pose": "de_pie", "cara": "neutra"},
     {"id": "theo", "ancla": "B", "pose": "de_pie", "cara": "neutra"}
   ],
   "utileria": [
     {"id": "barra", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 98}}
   ],
   "camara": {"objetivo": ["util:barra"], "tipo": "C", "movimiento": "acercar_lento"}},
  {"n": 4, "inicio": 8.88, "fin": 10.59, "texto": "Laugh together, it goes up.",
   "escenario": "parque",
   "personajes": [
     {"id": "narrador", "ancla": "A", "pose": "de_pie", "cara": "risa", "mira": "theo"},
     {"id": "theo", "ancla": "B", "pose": "de_pie", "cara": "risa", "mira": "narrador"}
   ],
   "utileria": [
     {"id": "barra", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 70}, "claves": {"porcentaje": [[0, 70], [0.8, 95]]}}
   ],
   "camara": {"objetivo": ["narrador", "theo", "util:barra"], "tipo": "M", "movimiento": "acercar_lento", "inclinacion": 4}},
  {"n": 5, "inicio": 10.59, "fin": 12.3, "texto": "Ignore a text, it drops.",
   "escenario": "cuarto",
   "personajes": [
     {"id": "extra1", "ancla": "centro", "pose": "celular", "cara": "indiferente"}
   ],
   "utileria": [
     {"id": "celular", "tipo": "celular", "pegado": {"personaje": "extra1", "parte": "mano_der", "rel": [0, -0.4, 0.3]}},
     {"id": "barra", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 60}, "claves": {"porcentaje": [[0, 60], [0.8, 35]]}}
   ],
   "camara": {"objetivo": ["extra1", "util:barra"], "tipo": "M", "movimiento": "fijo"}},
  {"n": 6, "inicio": 12.3, "fin": 16.4, "texto": "My grandpa and his chess buddy have been at one hundred percent",
   "escenario": "sala",
   "personajes": [
     {"id": "abuelo", "ancla": "sofa_1", "pose": "sentado", "cara": "neutra", "giro": 25},
     {"id": "amigo_ajedrez", "ancla": "sofa_2", "pose": "sentado", "cara": "neutra", "giro": -25}
   ],
   "utileria": [
     {"id": "ajedrez", "tipo": "ajedrez", "ancla": "mesa"},
     {"id": "barra_vieja", "tipo": "bateria", "ancla": "mesa", "params": {"porcentaje": 100, "telaranas": true}, "desplazar": [0, 6.2, -6.5]}
   ],
   "camara": {"objetivo": ["abuelo", "amigo_ajedrez", "util:barra_vieja"], "tipo": "M", "movimiento": "acercar_lento"}},
  {"n": 7, "inicio": 16.4, "fin": 17.08, "texto": "since 1974.",
   "escenario": "sala",
   "personajes": [
     {"id": "abuelo", "ancla": "sofa_1", "pose": "sentado", "cara": "neutra", "giro": 25},
     {"id": "amigo_ajedrez", "ancla": "sofa_2", "pose": "sentado", "cara": "neutra", "giro": -25}
   ],
   "utileria": [
     {"id": "ajedrez", "tipo": "ajedrez", "ancla": "mesa"},
     {"id": "barra_vieja", "tipo": "bateria", "ancla": "mesa", "params": {"porcentaje": 100, "telaranas": true}, "desplazar": [0, 6.2, -6.5]}
   ],
   "camara": {"objetivo": ["util:barra_vieja"], "tipo": "C", "movimiento": "acercar_brusco"}},
  {"n": 8, "inicio": 17.08, "fin": 20.16, "texto": "My sister lost three friends in one group chat.",
   "escenario": "cuarto",
   "personajes": [
     {"id": "hermana", "ancla": "centro", "pose": "celular", "cara": "susto"}
   ],
   "utileria": [
     {"id": "celular", "tipo": "celular", "pegado": {"personaje": "hermana", "parte": "mano_der", "rel": [0, -0.4, 0.3]}},
     {"id": "roja1", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 3, "ancho": 3, "alto": 1.2}, "desplazar": [-4.2, 0.6, 0]},
     {"id": "roja2", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 2, "ancho": 3, "alto": 1.2}, "desplazar": [0, 1.6, 0]},
     {"id": "roja3", "tipo": "bateria", "ancla": "barra", "params": {"porcentaje": 1, "ancho": 3, "alto": 1.2}, "desplazar": [4.2, 0.6, 0]}
   ],
   "camara": {"objetivo": ["hermana", "util:roja2"], "tipo": "M", "movimiento": "acercar_brusco", "inclinacion": -5}}
 ]
}
```

## Catálogos

- **Poses** (`Elenco.POSES`): de_pie, brazos_arriba, senalar, senalar_arriba, ofrecer,
  saludar, cabeza_abajo, derrotado, mirar_arriba, negar, correr, caminar, sentado,
  acostado, de_espaldas, saltar, abrazo, encogerse, gritar, celular. Una pose también
  puede ser una tabla: `{"bajar": "sentado", "caderaDer": {"x": 90}, "cuello": {"x": 28}}`.
  Articulaciones: raiz, cuello, hombroDer, hombroIzq, caderaDer, caderaIzq. Ángulos en
  grados: `x` flexión (positivo hacia adelante o arriba), `y` giro, `z` apertura lateral.
- **Caras** (`Caras.NOMBRES`): neutra, feliz, risa, triste, llanto, susto, rabia,
  confundido, decidido, enamorado, dormido, picaro, mareado, vacia, sonrisa_enorme,
  angustia, risa_forzada, indiferente, orgulloso, incomodo. Hay alias para las palabras del
  guion (felices, serios, derrotado, emocionado, curioso, etc.).
- **Luz** (`Luz.PREAJUSTES`): atardecer, dia_claro, noche_azul, nevado, lluvia, niebla,
  interior_calido, interior_noche.
- **Utilería** (`Utileria.TIPOS`): bateria, letrero, raton, globos, balon, arco, marcador,
  celular, carta, flor, mesa, silla, cajas, y los prefabricados clavo, bolsa_papas,
  botella_salsa, calabaza, tazon_cereal, ajedrez, gorro_fiesta, boleta, telarana.
- **Batería:** `porcentaje`, `color` (si falta: verde sobre 50, ámbar de 20 a 50, rojo bajo
  20), `ancho`, `alto`, `texto`, `leyenda`, `telaranas`, `apagada`, `mitades` con `izq` y
  `der`.

## Modo vertical: convención de giro

La cámara se gira **+90 grados** alrededor de su eje de visión
(`CFrame.lookAt(pos, objetivo) * CFrame.Angles(0, 0, math.rad(90))`). Con ese giro el
"arriba" de la escena apunta a la **derecha** de la pantalla: la grabación horizontal se ve
girada 90 grados en sentido horario. El montaje la endereza girándola 90 grados en sentido
**antihorario**: `montar.py --rotar antihorario`, que en ffmpeg es `-vf transpose=2`. Una
grabación de 1920 por 1080 queda de 1080 por 1920. `Camara.GIRO_VERTICAL` y
`Camara.ROTAR_MONTAJE` exponen la convención y el Director la imprime al empezar.

En vertical, `Camera.FieldOfView` pasa a ser el campo horizontal del video final, que es
angosto: por eso casi siempre es el ancho del objetivo el que fija la distancia.

## Qué se comprobó y cómo repetirlo

Hace falta el analizador y el intérprete oficiales de Luau
(https://github.com/luau-lang/luau/releases; se usó la versión 0.746) en una carpeta
cualquiera fuera del proyecto.

```
python studio/empaquetar.py
python studio/pruebas/analizar.py --luau-dir CARPETA_DE_LUAU
python studio/pruebas/analizar.py --luau-dir CARPETA_DE_LUAU --estricto
python studio/pruebas/ejecutar.py --luau-dir CARPETA_DE_LUAU
```

- **`luau-analyze`** revisa sintaxis, variables y tipos del código propio. No conoce la API
  de Roblox: los globales van en `.luaurc` y los tipos (`Instance`, `CFrame`...) se
  declaran como `any` en `pruebas/tipos_roblox.luau`. No valida nombres de propiedades.
- **Pruebas con el intérprete** (`pruebas/pruebas.luau`, 38 pruebas): instalan la
  biblioteca con el mismo `cargar.luau` y la ejecutan sobre `pruebas/doble_roblox.luau`.
  El doble rechaza cualquier clase, propiedad, método, evento, servicio o enumeración que
  no exista en `pruebas/api_roblox.luau`, y cualquier valor cuyo tipo no coincida con el
  que declara la propiedad. Esa tabla se genera con `pruebas/generar_api.py` desde el
  volcado oficial de la API (`https://setup.rbxcdn.com/version-63eb6055af4e4688-API-Dump.json`,
  Studio 0.747). Cuando Studio se actualice: `python studio/pruebas/generar_api.py --version version-XXXX`.
- Lo que cubren las pruebas: instalación (también el caso sin permiso y el monolito),
  geometría de las poses en los dos estilos, las 20 caras, los 12 escenarios en ambas
  versiones y los 5 climas, los 8 preajustes de luz y su reversión, toda la utilería, la
  matemática de cámara y del giro vertical, el verificador de tapado, y el Director
  completo sobre los 49 planos del guion 001 con un reloj simulado a 60 cuadros por
  segundo (destello de 2 cuadros, entrada de cada plano con un cuadro de error como máximo,
  sin deriva después de un tirón).

Lo que el doble **no** es: no dibuja, no simula física ni el motor de articulaciones, y sus
tipos de datos (`CFrame`, `Color3`...) están escritos a mano siguiendo la referencia.

## Lo que NO se pudo probar

Lista exacta. Todo esto queda pendiente de la primera sesión con un Studio que abra.

1. **Cualquier resultado visual**: proporciones de los personajes, las 20 caras dibujadas,
   escenarios, utilería, luz, clima. Solo se sabe que las instancias se crean con
   propiedades válidas.
2. **Permisos de `execute_luau`**: si puede asignar `Source`, llamar
   `UpdateSourceAsync`, hacer `require` de un `ModuleScript`, llamar
   `ChangeHistoryService:SetWaypoint` e `InsertService:LoadAsset`.
3. **Límites de `execute_luau`**: si acepta un bloque de unos 170 KB (`cargar.luau`), y
   cuánto tarda construir un escenario sin congelar Studio.
4. **`multi_edit`**: la forma exacta de la llamada y qué clase de script crea.
5. **`SurfaceGui` de la cara**: que se muestre sobre una pieza con `Transparency = 1`, que
   `ClipsDescendants` recorte los medios anillos y que `UIStroke` dibuje por fuera del
   marco. Si no, las caras salen sin arcos o con anillos completos.
6. **Modo rígido de los personajes**: piezas ancladas unidas por `Motor6D`, con el CFrame
   calculado por la biblioteca. Falta ver que Studio no las mueva por su cuenta.
7. **Estilo `r6`**: que el `Humanoid` no muestre nombre ni barra de vida, que `Shirt` y
   `Pants` se pinten, la malla de la cabeza, la calcomanía `face` con `ColorMapContent`.
   Los `C0` y `C1` del R6 estándar están escritos de memoria.
8. **Cámara**: que en edición acepte `CFrame` y `FieldOfView` sin `Scriptable`; que en
   juego el giro de 90 grados se vea como describe la convención; la cámara en modo Run.
9. **Destello**: que `ColorCorrectionEffect.Brightness = 1` deje la pantalla blanca, que
   dure 2 cuadros en la grabación y que se detecte en el montaje.
10. **Ocultar interfaz**: `SetCoreGuiEnabled`, `SetCore("TopbarEnabled", false)` y el cursor.
11. **Partículas**: lluvia y nieve usan la textura por defecto del emisor; falta ver
    densidad, tamaño, `Squash` y `Orientation`.
12. **Cambio de escenario en un cuadro**: mover un `Model` entre `workspace` y la bodega
    puede costar más de un cuadro y producir un tirón visible.
13. **Streaming**: en modo Play con `StreamingEnabled`, los escenarios se marcan como
    `Persistent`, pero no se comprobó que el cliente los reciba completos sin personaje.
14. **`Model:ScaleTo`** sobre la utilería y `Model:GetBoundingBox` real (el doble usa cajas
    alineadas a los ejes).
15. **`screen_capture`** después de `foto`: si respeta la cámara que deja el Director o
    la reemplaza. `foto` devuelve `camara.posicion` y `camara.mira` para pasarlas como
    `camera_position` y `look_at_position`, pero esa captura no conserva el giro vertical.
16. **Tiempos reales del guion 001**: los de `ejemplos/001-puesta.json` son estimados.

## Primera prueba en Studio: 15 pasos

Hazla en un equipo donde Studio abra, con un lugar nuevo guardado como archivo y el
servidor MCP activo. Cada paso dice qué ejecutar, qué debería verse y qué capturar. Si un
paso falla, anota el error textual y sigue con el siguiente cuando no dependa de él.

1. **Conexión.** `execute_luau` (Edit): `return game.Name`. Debe devolver un texto. Captura
   la lista de herramientas (`/mcp`).
2. **Instalar.** Pega `cargar.luau` completo. Debe devolver `Historias 1.0.0 instalada en
   ReplicatedStorage.Historias: Base, Caras, ...`. Si dice que no pudo escribir `Source`,
   instala con `multi_edit` y `cargar_multi_edit.json`. Anota cuál vía funcionó y el tamaño
   que aceptó.
3. **Require.** `return require(game.ReplicatedStorage.Historias.Director).Base.VERSION`.
   Debe devolver `1.0.0`. Si `require` falla, usa `monolito.luau` en los pasos 4 a 11.
4. **Muestrario de caras.** `H.Caras.muestrario(CFrame.new(0, 12, 0))` y `screen_capture`
   desde el frente (+Z). Deben verse 20 cabezas con su nombre debajo. Captura. Revisa
   arcos (sonrisas), lágrimas, espirales y que nada se salga de la cabeza.
5. **Personaje propio.** `H.Elenco.crear({ id = "prueba", pos = {0, 0, 0} })`. Debe verse un
   muñeco de bloques de unos 5,3 studs, cabeza redonda, de pie sobre `y = 0`, con cara
   neutra. Captura de frente y de perfil. Revisa que el panel de la cara no flote.
6. **Muestrario de poses.** `H.Elenco.muestrario("propio", Vector3.new(0, 0, -20))`. Deben
   verse 20 personajes, uno por pose. Captura. Compara con la tabla: brazos arriba, señalar
   al frente, sentado con piernas horizontales, de espaldas, cabeza abajo.
7. **Personaje R6.** `H.Elenco.crear({ id = "prueba_r6", estilo = "r6", pos = {8, 0, 0} })` y
   `H.Elenco.posar(pj, "brazos_arriba")`. Debe verse un R6 clásico sin nombre flotante.
   Captura. Si las piezas quedan fuera de lugar, anótalo: indica un problema del modo rígido.
8. **Un escenario en gris.** `H.Escenarios.construir("pueblo", { version = "gris" })`. Debe
   aparecer cerca del origen, todo gris, con marcas naranjas, azules y moradas en las
   anclas. Captura desde arriba. Anota cuánto tardó la llamada.
9. **El mismo en detalle con luz.** `construir("pueblo", { version = "detalle", luz = true })`
   y luego `H.Luz.aplicar("atardecer")`. Captura. Después `H.Luz.revertir()` y confirma que
   la luz vuelve a la original.
10. **Clima.** `H.Escenarios.clima(H.Escenarios.buscar("pueblo"), "lluvia", { luz = true })`
    y lo mismo con `"nieve"`. Captura cada uno. Revisa dirección y densidad de las
    partículas.
11. **Utilería.** `H.Utileria.crear("bateria", { porcentaje = 98 }):PivotTo(CFrame.new(0, 6, 0))`
    y `H.Utileria.actualizar(modelo, { porcentaje = 2 })`. Debe verse la barra verde con
    `98%` y luego roja con `2%`, legible desde el frente. Captura ambas.
12. **Ensayo del guion 001.** `H.preparar(nil, PUESTA_001, { version = "gris" })` y
    `H.ensayo(ctx)`. Debe devolver 49 planos, 0 inexistentes y el plano 11 como corto.
    Anota la lista de tapados y cuánto tardó `preparar` (puede requerir varias llamadas).
13. **Foto.** `H.foto(ctx, 1)`, `H.foto(ctx, 24)` y `H.foto(ctx, 32)` con `screen_capture`
    después de cada una. Plano 1: dos amigos y la barra entre ellos, imagen girada 90
    grados (cabezas a la derecha). Plano 24: barra en 3%. Plano 32: cuarto de noche,
    narrador acostado. Captura las tres.
14. **Reproducción corta.** Arma una puesta de 3 planos de 2 segundos, `H.guardarDatos`,
    `H.configurarLugar("play")`, inicia la prueba y graba la pantalla. Debe verse: 2
    segundos quietos, un destello blanco, los 3 planos y el final. En la consola debe salir
    `fin de ...: 3 planos, desvío máximo de entrada N ms` con N menor que 20. Revisa en la
    grabación cuántos cuadros dura el destello y que la interfaz no aparezca.
15. **Reproducción completa y montaje.** Repite con los 49 planos del guion 001 en detalle,
    gira la grabación 90 grados en sentido antihorario y comprueba que los personajes
    queden de pie. Mide el desfase contra el audio en tres puntos (inicio, mitad y final).
    Repite el paso 14 con `H.configurarLugar("run")` para saber si el modo Run sirve.

## Marcadores por llenar

- `Caras.CATALOGO`: 20 ids de imagen en 0. Se llenan con `Caras.registrar(nombre, id)`
  después de subir las imágenes propias.
- Estilo `r6`: `camisa_id`, `pantalon_id` (id de la imagen de la plantilla de ropa) y
  `accesorios` (ids del catálogo). Sin ellos el personaje sale con colores lisos.
- `ParticleEmitter.Texture`: se deja la textura por defecto del motor.
