# Carpeta `canal/`: identidad del canal

Preparada el 2026-11-13. Nombre recomendado: **Almostville** (canal hermano en
español: **Casipueblo**). No se creó ninguna cuenta: todo esto es material
listo para cuando abras el canal.

## Qué hay

| Archivo | Contenido |
|---|---|
| `nombres.md` | 25 nombres candidatos en inglés y 10 en español, con la disponibilidad comprobada ese día, cómo se comprobó y los 3 recomendados. |
| `textos-canal.txt` | Textos listos para pegar (descripción corta y larga, palabras clave, texto del enlace, lista de reproducción, comentario fijado) para Almostville, Rulefolk y OneOddRule, y la versión en español para Casipueblo. |
| `identidad.md` | Paleta, tipografía, cómo se dibuja el personaje insignia, qué hacer y qué no. |
| `imagen/generar.py` | Script que produce todas las imágenes. |
| `imagen/perfil-800.png` | Foto de perfil. |
| `imagen/perfil-48-prueba.png` | La foto de perfil a 48 px, solo para revisar que se lea. No se sube. |
| `imagen/banner-2560x1440.png` | Banner del canal. |
| `imagen/marca-de-agua-150.png` | Marca de agua con fondo transparente. |
| `imagen/miniatura-plantilla.png` | Plantilla de miniatura para videos largos. |
| `imagen/miniatura-ejemplo-2.png` | Segundo ejemplo de miniatura (otro texto, color y expresión). |
| `imagen/fuentes/` | Lilita One y Fredoka con sus licencias OFL. |

## Cómo regenerar las imágenes con otro nombre

Necesitas Python 3 y Pillow:

    pip install --user pillow

Desde la carpeta `canal/imagen`:

    python generar.py --nombre "Rulefolk"

Eso vuelve a crear el perfil, el banner, la marca de agua y la miniatura. El
nombre solo aparece en el banner, y el tamaño de letra se ajusta solo al ancho
disponible. Para el canal en español cambia también la frase y el lema:

    python generar.py --nombre "Casipueblo" --frase "En este mundo..." --lema "cada pueblo tiene una regla imposible" --salida ../imagen-es

## Cómo hacer una miniatura nueva

    python generar.py --solo miniatura --mini-texto "FRIENDS RUN OUT" --mini-fondo "#1B2452" --mini-expresion llanto --mini-personaje "#FFC531" --mini-salida mini-001.png

| Parámetro | Para qué sirve |
|---|---|
| `--solo` | `todo`, `perfil`, `banner`, `marca` o `miniatura`. |
| `--mini-texto` | Hasta tres palabras; cada una va en un renglón. |
| `--mini-fondo` | Color de fondo en hex. Usa los de la paleta. |
| `--mini-expresion` | `feliz`, `sorpresa`, `llanto` o `picaro`. |
| `--mini-personaje` | Color de la cabeza del personaje en hex. |
| `--mini-resaltar` | Qué palabra va resaltada: 0, 1 o 2 (por defecto, la última). |
| `--mini-salida` | Nombre del archivo. |
| `--salida` | Carpeta donde se guardan las imágenes. |

## Pendientes antes de abrir el canal

- Volver a comprobar el identificador elegido el mismo día en que lo registres.
- Revisar Instagram a mano (no se pudo comprobar de forma automática).
- Leer las pautas de marca de Roblox vigentes y decidir si se usa el aviso de
  no afiliación que está en `textos-canal.txt`.
- En los ajustes del canal, marcar "No, no es contenido hecho para niños".
