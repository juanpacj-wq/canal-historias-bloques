# studio: biblioteca Historias y director de planos

Biblioteca Luau para producir los cortos del canal dentro de Roblox Studio. Un
chat de Claude Code la instala por el servidor MCP de Studio y la usa video tras
video. Todo el contenido visual se arma con piezas propias (`Part`): no usa el
logo ni marcas de Roblox, ni recursos del catálogo.

**Estado: validada en Roblox Studio 0.747 el 2026-11-13 con el video 001
completo.** Cómo se usa para producir está en la skill `producir-video` y en
`docs/11-metodo-probado.md`. Este archivo es la referencia de la biblioteca.

## Arquitectura

| Archivo | Qué hace |
|---|---|
| `lib/Base.luau` | Utilidades: colores y vectores desde JSON, piezas (bloque, bola, ovalo, cilindro, cuña), carpetas, curvas, interpolación por claves. |
| `lib/Caras.luau` | 20 expresiones dibujadas con `SurfaceGui`. Catálogo de ids de imagen en 0 (sin usar). |
| `lib/Elenco.luau` | Personajes de bloques con cabeza redonda y pelo de bolas; 20 poses sobre `Motor6D`; ubicar, posar, mirar. Estilo `"propio"` (el que se usa) y `"r6"` (sin revisar). |
| `lib/Luz.luau` | 8 preajustes de `Lighting` con Atmosphere, Bloom, ColorCorrection, DepthOfField y SunRays. Tintes para efectos. |
| `lib/Utileria.luau` | Batería, letrero, ratón, globos, balón, arco, marcador, celular, carta, flor, mesa, silla, objeto de cajas y 9 prefabricados. |
| `lib/Escenarios.luau` | 12 escenarios por piezas con anclas y cámaras con nombre, y 5 climas. |
| `lib/Camara.luau` | Encuadres, 8 movimientos, inclinación y modo vertical. |
| `Director.luau` | Une plan y puesta, monta cada plano y lo anima cuadro por cuadro. |
| `empaque/RodajeCuadros.client.luau` | Lanzador del rodaje cuadro a cuadro (el que se usa para grabar). |
| `empaque/Rodar*.luau` | Lanzadores de reproducción en tiempo real. Quedaron sin uso. |
| `empaquetar.py` | Genera `cargar.luau`, `cargar_multi_edit.json` y `monolito.luau` desde los fuentes. |
| `cargar.luau` | GENERADO. Un bloque para `execute_luau` que instala todo en `ReplicatedStorage.Historias`. |
| `plantilla/lugar-vacio.rbxl` | Lugar vacío del que nace el lugar de cada video. |
| `ejemplos/001-puesta.json` | Puesta vieja de 49 planos. Solo la usan las pruebas de `pruebas/`; el ejemplo real es `videos/001-.../escenas/hacer_puesta.py`. |
| `pruebas/` | Doble de la API de Roblox y pruebas fuera de Studio. No se han vuelto a correr desde los cambios del 2026-11-13. |

En el lugar de Studio todo queda así:

- `ReplicatedStorage.Historias`: los 8 `ModuleScript` y la carpeta `Datos`.
- `workspace.Historias.Escenarios`, `.Elenco`, `.Utileria`: lo que está en escena.
- `ReplicatedStorage.HistoriasBodega`: lo que no participa en el plano actual.
- En `Lighting`, todo lo que crea la biblioteca se llama `Historias_...`.

## Instalar y actualizar

```powershell
herramientas\.venv\Scripts\python.exe herramientas\studio\puente.py --video NNN instalar
```

Empaqueta los fuentes y ejecuta `cargar.luau` (unos 178 KB) en una sola llamada
de `execute_luau`, que sí puede asignar `Source` y hacer `require`. Después de
cambiar cualquier fuente se repite, y se corre `puente.py --video NNN
reconstruir` para rehacer escenarios, elenco y utilería: `preparar` reutiliza
lo que ya existe y no nota el cambio.

## Convenciones

- **Todo cerca del origen.** Cada escenario vive en una celda de una cuadrícula
  de 4 por 3 con 160 studs de separación. Un `Model` por escenario.
- **El frente es +Z.** La cámara mira hacia -Z. Los interiores son dioramas sin
  techo ni pared frontal.
- **Giro de personajes:** `giro = 0` mira hacia la cámara; positivo gira hacia
  +X. La cara es un panel plano: a más de unos 40 grados deja de verse.
- **Solo el escenario activo está en `workspace`**; lo demás va a la bodega.
- **Cada plano es autosuficiente:** declara todo lo que se ve.
- **Utilería:** el frente del objeto es su +Z local y su origen es el centro de
  la base. Un mismo `id` es el mismo objeto en todos los planos.

## Esquema de `puesta.json`

Se genera con `herramientas/studio/puesta.py`; no se escribe a mano.

```text
{
  "video": texto, "esquema": 1, "vertical": true, "estilo": "propio",
  "predeterminados": { "clima": ..., "luz": ..., "escenario": ... },
  "elenco": {
    "<id>": { "piel": "#RRGGBB", "camisa": "#RRGGBB", "pantalon": "#RRGGBB",
              "mangas": "cortas" | "largas",
              "pelo": { "tipo": "corto" | "largo" | "coletas" | "copete" | "rizado" |
                                "mono" | "abuelo" | "gorra" | "ninguno", "color": "#RRGGBB" } }
  },
  "planos": [
    {
      "n": número, "inicio": s, "fin": s, "texto": texto,      los pisa el plan
      "escenario": pueblo | parque | cuarto | sala | cocina | salon | pasillo |
                   cafeteria | cancha | patio | bosque | calle_noche,
      "clima": "sol" | "noche" | "lluvia" | "nieve" | "niebla",
      "luz": atardecer | dia_claro | noche_azul | nevado | lluvia | niebla |
             interior_calido | interior_noche,
      "personajes": [
        { "id": id del elenco,
          "pos": [x, y, z] relativo al origen del escenario   o   "ancla": nombre,
          "giro": grados, "desplazar": [dx, dy, dz],
          "pose": nombre   o   tabla de ángulos por articulación,
          "cara": nombre de expresión,
          "anim": "respirar" (por defecto) | "quieto" | "saltar" | "reir" | "temblar" |
                  "caminar" | "negar" | "asentir" | "llorar",
          "amplitud": número (1 por defecto),
          "mover": [dx, dy, dz]            recorrido durante el plano,
          "cambios": [[fracción, { "cara": ..., "pose": ..., "anim": ... }], ...],
          "mira": id | "camara" | "ancla:NOMBRE" | "util:ID"   (gira el cuerpo: evitar) }
      ],
      "utileria": [
        { "id": texto único, "tipo": tipo de utilería,
          "params": { ... },
          "pos": [x, y, z]   o   "ancla": nombre,   "giro": grados, "desplazar": [dx, dy, dz],
          "pegado": { "personaje": id, "parte": "mano_der" | "mano_izq" | "cabeza_arriba" | "pecho", "rel": [x, y, z] },
          "claves": { "porcentaje": [[fracción, valor], ...] },
          "anim": "flotar" (por defecto en baterías) | "quieto" | "girar" | "rodar" |
                  "rebotar" | "latir" | "temblar",
          "mover": [dx, dy, dz], "arco": altura extra a mitad del recorrido }
      ],
      "camara": {
        "objetivo": [ [x, y, z] | id | "util:ID" | "ancla:NOMBRE" | "escena:NOMBRE", ... ],
        "ancho": studs que caben a lo ancho del cuadro final, "alto": ídem a lo alto,
        "desplazar": [dx, dy, dz], "margen": número,
        "tipo": "G" | "M" | "C"      solo cuenta si no se da "ancho",
        "movimiento": "fijo" | "acercar_lento" | "alejar_lento" | "acercar_brusco" |
                      "paneo_der" | "paneo_izq" | "subir" | "temblor",
        "inclinacion": grados, "azimut": grados, "elevacion": grados,
        "desde": "frente" | "izq" | "der" | "alta" | "picado" | "contrapicado" | ...,
        "fov": grados (40 por defecto)
      },
      "efecto": "recuerdo" | { "tipo": "destello_verde" | "chispas" | "confeti" |
                               "vibrar" | "parpadeo", "en": "util:ID" } | lista
    }
  ]
}
```

Reglas:

- Los tiempos del plan (`tiempos/planos.json`) mandan sobre los de la puesta.
- Una referencia que no existe nunca detiene nada: se usa un valor de respaldo
  y queda en la lista de avisos (`inexistentes` del ensayo).
- Con clima `lluvia` en un exterior el Director agrega una nube densa sobre el
  encuadre; no hay que pedirla.

## Batería

`porcentaje`, `color` (si falta: verde sobre 50, ámbar de 20 a 50, rojo bajo
20), `ancho`, `alto`, `leyenda`, `telaranas`, `apagada`, `mitades` con `izq` y
`der`. Lleva un `PointLight` suave con el color de la carga. `ancho`, `alto`,
`telaranas` y `mitades` solo cuentan al crear el objeto: para otra forma, otro
`id`.

## Modo vertical

La cámara se gira 90 grados sobre su eje de visión. En modo juego el "arriba"
de la escena queda a la derecha de la pantalla y el montaje lo endereza con
`montar.py --rotar antihorario`. `Camera.FieldOfView` (40) pasa a ser el campo
horizontal del video final. **En modo edición Studio no respeta siempre ese
giro**: para revisar planos se usa `herramientas/studio/ver.py`, que lo quita.

## Rodaje cuadro a cuadro

`herramientas/studio/rodar.py` pone en el lugar el atributo `Modo = "cuadros"`
y el `LocalScript` `RodajeCuadroACuadro`. En modo juego, ese script prepara la
secuencia y espera: cada vez que alguien escribe el atributo `T` (segundos) en
`ReplicatedStorage.Historias`, monta ese instante, deja pasar dos cuadros de
dibujo y responde con el atributo `Hecho`. El programa de afuera captura la
pantalla entre uno y otro. Las partículas se frenan con `TimeScale` para que
avancen un cuadro de película por captura.

## Pendiente

- Estilo `r6`, clima de nieve y niebla, y los escenarios `salon`, `bosque` y
  `calle_noche`: sin revisar a ojo.
- Los faroles del pueblo se ven inclinados.
- Volver a correr `pruebas/` (hacen falta los binarios de Luau) y ponerlas al
  día con los campos nuevos.
- `Caras.CATALOGO`: 20 ids de imagen en 0; hoy las caras se dibujan con marcos
  y no hacen falta.
