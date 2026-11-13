# Identidad visual del canal

Versión del 2026-11-13, generada para el nombre **Almostville**. Todo sale de
`imagen/generar.py`; si cambias algo aquí, cámbialo también en el script.

## Idea

Un pueblo de noche, casi normal, donde vive gente de bloques con caras enormes.
Colores planos, contornos gruesos, nada de degradados ni texturas. La emoción
la lleva la cara.

## Paleta

| Nombre | Hex | Uso |
|---|---|---|
| Amarillo regla | `#FFC531` | Fondo de la foto de perfil, nombre del canal, palabra resaltada en miniaturas. |
| Menta | `#3DDBB4` | Color del personaje insignia, frase "In this world...". |
| Coral | `#FF5A4E` | Acento: ropa, sombra del título, fondo de miniaturas, batería baja. |
| Azul noche | `#1B2452` | Contornos, fondo del banner, texto sobre claro. Reemplaza al negro. |
| Crema | `#FFF6E3` | Texto sobre oscuro, franjas de la ropa. Reemplaza al blanco. |

Tonos de apoyo que usa el script (no son colores de marca): `#27326B` y
`#34418A` para el pueblo del fondo, `#FF9AA2` para la lengua, `#6FD3FF` para
las lágrimas y blanco puro solo en los ojos.

Combinaciones que funcionan: amarillo o crema sobre azul noche; azul noche
sobre amarillo, menta o crema; crema con contorno azul noche sobre coral.
Evita menta sobre amarillo para texto (poco contraste) y coral sobre azul noche
para letra pequeña.

## Tipografía

| Fuente | Uso | Licencia | Origen |
|---|---|---|---|
| Lilita One | Nombre del canal y texto de miniaturas. Siempre en tamaños grandes. | SIL Open Font License 1.1 | `github.com/google/fonts`, carpeta `ofl/lilitaone` |
| Fredoka (variable, peso 500 a 600) | Frases, lemas y texto secundario. | SIL Open Font License 1.1 | `github.com/google/fonts`, carpeta `ofl/fredoka` |

Los archivos y sus licencias están en `imagen/fuentes/`. La licencia OFL
permite uso comercial e incrustar la fuente en imágenes y video; no permite
vender la fuente sola.

Los subtítulos de los videos pueden ir en Fredoka peso 700, blanco con borde
azul noche, para que todo el canal hable con la misma letra.

## El personaje insignia

Es un diseño propio. No es el avatar clásico de Roblox ni usa sus caras.

Cómo se dibuja (las medidas van en proporción al ancho de la cabeza, `s`):

1. **Cabeza**: rectángulo redondeado de `1,00 s` de ancho por `0,86 s` de alto,
   esquinas con radio `0,20 s`. Es más ancha que alta y mucho más grande que el
   cuerpo (la cabeza es casi dos tercios de la figura).
2. **Contorno**: azul noche, grosor `0,05 s`, en todo.
3. **Bloque flotante**: un cuadrado redondeado de `0,25 s`, inclinado 18
   grados, que flota sobre la esquina superior derecha de la cabeza sin
   tocarla. Es la firma del personaje y el "objeto imposible" permanente. Va en
   un color distinto al de la cabeza.
4. **Ojos**: dos óvalos blancos verticales con contorno, **desiguales a
   propósito** (el izquierdo más grande: `0,15 x 0,19 s` contra `0,125 x 0,16 s`).
   Pupila azul noche grande con un brillo blanco arriba a la izquierda.
5. **Cejas**: dos trazos gruesos de punta redonda, cada uno con su inclinación.
6. **Boca**: según la expresión. Feliz: media luna abierta con lengua rosada.
   Sorpresa: óvalo vertical. Llanto: zigzag con dos chorros azules desde los
   ojos cerrados. Pícaro: sonrisa de lado y un párpado a medio cerrar.
7. **Mejillas**: dos óvalos pequeños, un tono más oscuro que la cabeza.
8. **Cuerpo**: torso en forma de campana (más ancho abajo), de `0,50 s` de alto,
   con una franja crema. Brazos de tubo que terminan en manos redondas del
   color de la cabeza. Dos piernas cortas.
9. **Postura**: siempre un poco inclinado (3 a 5 grados). Nunca recto.

El insignia es **menta con ropa coral y bloque amarillo** (bloque coral cuando
el fondo es amarillo). Los demás habitantes cambian de color de cabeza, ropa y
bloque, pero conservan las proporciones, los ojos desiguales y el bloque.

Expresiones disponibles en el script: `feliz`, `sorpresa`, `llanto`, `picaro`.

## Piezas

| Archivo | Medida | Notas |
|---|---|---|
| `imagen/perfil-800.png` | 800 x 800 | Fondo amarillo plano. Todo lo importante cabe en el círculo en que YouTube recorta. |
| `imagen/perfil-48-prueba.png` | 48 x 48 | Solo para revisar legibilidad. No se sube. |
| `imagen/banner-2560x1440.png` | 2560 x 1440 | Nombre, frase y personajes dentro de la zona segura central de 1546 x 423. El pueblo de fondo solo se ve en televisores y pantallas anchas. |
| `imagen/marca-de-agua-150.png` | 150 x 150 | Fondo transparente, cabeza con halo crema para que se lea sobre cualquier video. |
| `imagen/miniatura-plantilla.png` | 1280 x 720 | Plantilla para videos largos: cara grande a la derecha, tres palabras a la izquierda. |
| `imagen/miniatura-ejemplo-2.png` | 1280 x 720 | La misma plantilla con otro texto, color y expresión. |

## Qué hacer

- Usa solo los cinco colores de la paleta y sus tonos de apoyo.
- Mantén el contorno azul noche grueso en personajes y objetos.
- En miniaturas: máximo tres palabras, una por renglón, la última resaltada.
- Deja que la cara ocupe al menos un tercio de la miniatura.
- Muestra la regla del cuento como objeto flotante (batería, reloj, número).
- Revisa siempre la versión pequeña: si a 48 px no se entiende, simplifica.

## Qué no hacer

- No uses el logo de Roblox, su tipografía de marca, sus caras oficiales ni el
  avatar clásico R6. No escribas "Roblox" ni "Blox" en el nombre, el banner, la
  foto de perfil ni las miniaturas.
- No combines cabeza amarilla, torso azul y piernas verdes: se parece al
  personaje genérico de esa plataforma.
- No uses degradados, sombras difusas, brillos 3D ni fotos.
- No uses negro puro ni blanco puro fuera de los ojos.
- No pongas texto importante fuera de la zona segura del banner.
- No uses flechas rojas, círculos ni emojis en las miniaturas.
- No uses tipos de letra distintos a Lilita One y Fredoka.
- No dibujes al personaje recto, con ojos iguales o sin su bloque.
- No uses estética preescolar (colores pastel, letras infantiles): el canal es
  de audiencia general, para adolescentes y jóvenes adultos.

## Limitaciones conocidas

- Sobre fondo azul noche el contorno de los personajes desaparece, porque es
  del mismo color. En el banner se compensó con piernas crema.
- En la miniatura, las palabras cortas dejan aire a la izquierda porque el
  tamaño de letra tiene tope.
- Las ilustraciones están hechas con formas geométricas en Pillow. Sirven para
  lanzar; si el canal crece, vale la pena redibujar al personaje en vectores.
