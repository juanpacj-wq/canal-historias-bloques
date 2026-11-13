# 09. Audio: voz, música y efectos

Corte de la información: 13 de noviembre de 2026. Todos los precios y
condiciones de licencia se consultaron ese día en la página enlazada. Lo marcado
**sin verificar** no se pudo confirmar en una fuente primaria. Las citas en
inglés son fragmentos textuales de la página oficial; antes de usarlas en una
apelación, vuelve a abrir el enlace y copia la frase completa.

Supuestos de cálculo: un video tiene unas 400 palabras, es decir, cerca de
2.500 caracteres con espacios y unos 105 segundos a 230 palabras por minuto.
Treinta videos al mes son 75.000 caracteres.

## Decisión rápida

| Pieza | Opción principal | Respaldo gratuito |
|---|---|---|
| Voz | ElevenLabs, plan Creator (22 USD al mes), modelo `eleven_multilingual_v2`, una sola voz de la biblioteca, con marcas de tiempo | Kokoro-82M en este equipo (0 USD, licencia Apache 2.0) |
| Música | Biblioteca de audio de YouTube (licencia estándar, sin atribución) | Kevin MacLeod en Incompetech (CC BY 4.0, con crédito) |
| Efectos | Mixkit y Pixabay (sin atribución) | Freesound solo con licencia CC0 |
| Mezcla | ffmpeg, cadena de este documento, salida a -14 LUFS | Igual |

Si tu inglés narrado suena natural a 220 o 240 palabras por minuto, **la voz
propia le gana a todo lo anterior en el frente de políticas** y cuesta 0 USD
(ver "Voz propia"). La voz sintética es la opción práctica, no la más segura.

Tres hechos de esta investigación que cambian lo escrito en `docs/03`:

1. **Las voces predeterminadas de ElevenLabs desaparecen el 31 de diciembre de
   2026.** No construyas la identidad del canal sobre una de ellas.
2. **Los modelos de voz de OpenAI (`tts-1`, `tts-1-hd`, `gpt-4o-mini-tts`) se
   apagan el 6 de enero de 2027.** No sirven como base del flujo.
3. **Piper tiene voces populares que no admiten uso comercial** (lessac, ryan).
   Solo vale una lista corta de voces.

## 1. Voz sintética

### ElevenLabs

Planes, según la [página oficial de precios](https://elevenlabs.io/pricing):

| Plan | Precio al mes | Créditos al mes | Videos de 2.500 caracteres | Licencia comercial |
|---|---|---|---|---|
| Free | 0 USD | 10 mil | 4 | No. Exige atribución y prohíbe uso comercial |
| Starter | 6 USD (1 USD el primer mes) | 30 mil | 12 | Sí |
| Creator | 22 USD (11 USD el primer mes) | 121 mil | 48 | Sí |
| Pro | 99 USD | 600 mil | 240 | Sí |
| Scale | 299 USD | 1,8 millones | 720 | Sí |

- La facturación anual da "two months free". Al cancelar, los créditos pagos sin
  usar se pierden. Se acumulan hasta dos meses de créditos sin usar
  ([facturación](https://elevenlabs.io/docs/overview/administration/billing)).
- **Créditos por carácter**: 1 crédito por carácter en la web para Eleven v4,
  v3, Multilingual v2 y Flash
  ([ayuda](https://elevenlabs.io/docs/help-center/account/general/have-characters-changed.md):
  "each text 'character' you generate into speech will consume 1 credit").
  Algunas voces de la biblioteca aplican un multiplicador ("a custom rate that
  applies a multiplier to your credit consumption"): revisa la ficha de la voz
  antes de adoptarla.
- La [página de precios de la API](https://elevenlabs.io/pricing/api) dice que
  la API se cobra en dólares: 0,08 USD por mil caracteres para v4, v3 y
  Multilingual v2, y 0,04 USD para Flash. Cómo se combina eso con los créditos
  de la suscripción quedó **sin verificar**; presupuesta 1 crédito por carácter.

Licencia comercial
([artículo oficial](https://elevenlabs.io/docs/help-center/legal/can-i-publish-the-content-i-generate-on-the-platform.md),
[términos](https://elevenlabs.io/terms-of-use)):

- "All paid plans include a commercial license, provided you're not using Beta
  Services."
- "The free plan does not include a commercial license and cannot be used for
  any commercial purpose." Además exige poner "elevenlabs.io" o "11.ai" en el
  título.
- "Content created outside of a paid subscription (before or after) cannot be
  used commercially". Consecuencia práctica: **no generes nada con el plan
  gratis para luego publicarlo**, ni siquiera pruebas que termines usando.
- El audio generado mientras pagabas conserva la licencia al cancelar ("will
  still have a commercial license",
  [artículo](https://elevenlabs.io/docs/help-center/account/general/what-happens-to-my-content-after-my-subscription-ends)).
  La palabra exacta "forever" quedó **sin verificar**.
- No existe un artículo oficial de ElevenLabs que nombre la monetización en
  YouTube; el permiso se deduce de la licencia comercial. Lo único específico
  es que su marca de agua "is not connected to other platforms' monetization or
  content policies".

Modelos ([lista oficial](https://elevenlabs.io/docs/models)):

| Modelo | Estado | Límite por petición | Nota |
|---|---|---|---|
| `eleven_v4` | Actual | 10.000 caracteres | El más expresivo. En desarrollo continuo: "its behavior may shift over time". No tiene control de velocidad ni de estilo |
| `eleven_v3` | Generación anterior | 5.000 | Sin velocidad, sin unión de peticiones |
| `eleven_multilingual_v2` | Generación anterior | 10.000 | "Most stable on long-form generations". **El recomendado aquí** |
| `eleven_flash_v2_5` | Actual | 40.000 | Más rápido y a mitad de precio en la API; menos matiz |
| `eleven_turbo_v2_5`, `eleven_turbo_v2` | Obsoletos | | No usar |

Por qué Multilingual v2 y no v4: el canal necesita que la voz del video 30
suene igual a la del video 1, y que acepte el parámetro de velocidad. V4 suena
mejor pero ElevenLabs avisa que su comportamiento cambia con el tiempo.

Marcas de tiempo
([referencia de la API](https://elevenlabs.io/docs/api-reference/text-to-speech/convert-with-timestamps)):

- `POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/with-timestamps`
- Devuelve `audio_base64`, `alignment` y `normalized_alignment`. Cada alineación
  trae `characters`, `character_start_times_seconds` y
  `character_end_times_seconds`.
- **Es por carácter, no por palabra.** El tiempo de cada palabra se arma
  juntando los caracteres entre espacios. Esto reemplaza a WhisperX cuando la
  voz es sintética.
- Qué modelos lo admiten: **sin verificar** (la página no lo restringe).

Ejemplo mínimo (no ejecutado en esta investigación: requiere clave):

```python
import base64, json, os, requests

VOZ = "ID_DE_LA_VOZ"          # siempre el mismo
r = requests.post(
    f"https://api.elevenlabs.io/v1/text-to-speech/{VOZ}/with-timestamps",
    headers={"xi-api-key": os.environ["ELEVENLABS_API_KEY"]},
    json={
        "text": open("guion.txt", encoding="utf-8").read(),
        "model_id": "eleven_multilingual_v2",
        "seed": 20261113,
        "voice_settings": {
            "stability": 0.5, "similarity_boost": 0.75,
            "style": 0, "use_speaker_boost": True, "speed": 1.1,
        },
    },
    timeout=300,
)
r.raise_for_status()
d = r.json()
open("voz_cruda.mp3", "wb").write(base64.b64decode(d["audio_base64"]))
json.dump(d["alignment"], open("tiempos.json", "w"))
```

Parámetros
([guía del producto](https://elevenlabs.io/docs/eleven-creative/playground/text-to-speech)):

| Parámetro | Valor por defecto | Recomendado para el canal | Nota |
|---|---|---|---|
| `stability` | 0,5 | 0,5 | Más alto, más plano; más bajo, más variable |
| `similarity_boost` | 0,75 | 0,75 | |
| `style` | 0 | 0 | "we recommend keeping this setting at 0 at all times" |
| `use_speaker_boost` | true | true | |
| `speed` | 1,0 | 1,1 | Rango 0,7 a 1,2 ("to a minimum of 0.7", "to a maximum of 1.2") |
| `seed` | Sin definir | Un número fijo | 0 a 4294967295. Determinismo aproximado, no garantizado |

- El rango 0 a 1 de `stability`, `similarity_boost` y `style` en la API quedó
  **sin verificar** (la referencia no lo imprime).
- Para llegar a 220 o 240 palabras por minuto: `speed` en 1,1 y el resto con
  `atempo` de ffmpeg (ver cadena de mezcla). Si aceleras con `atempo`, **divide
  todas las marcas de tiempo por el mismo factor**. No apliques `silenceremove`
  a una voz con marcas de tiempo: las desincroniza.
- Guiones largos partidos en varias peticiones: usa `previous_request_ids`
  (máximo 3, de menos de dos horas) para que la entonación continúe
  ([guía](https://elevenlabs.io/docs/eleven-api/guides/cookbooks/text-to-speech/request-stitching)).
  Un guion de 2.500 caracteres cabe en una sola petición, así que casi nunca
  hará falta.

Cómo mantener la misma voz entre videos:

1. Anota en `audio/voz/voz.json` el `voice_id`, el `model_id`, los cuatro
   ajustes, el `seed` y la fecha. Ese archivo es la identidad sonora del canal.
2. Nunca cambies de modelo a mitad de serie. Si cambias, que sea entre
   temporadas y con aviso.
3. ElevenLabs advierte: "setting the sliders to specific values won't guarantee
   the same results every time". Espera variaciones pequeñas; si una toma sale
   rara, se regenera.
4. **No uses una voz predeterminada**: "All our Default voices will expire on
   December 31, 2026, and they will no longer be accessible after this date"
   ([artículo](https://elevenlabs.io/docs/help-center/product/voices/my-voices/what-are-default-voices.md)).
   Los reemplazos "not a strict 1-to-1 replacement".
5. Con una voz de la biblioteca, revisa su periodo de aviso
   ([biblioteca de voces](https://elevenlabs.io/docs/eleven-creative/voices/voice-library)):
   "The minimum notice period is 30 days, and the maximum is 2 years". Si la voz
   no tiene periodo de aviso y el dueño la retira, "you'll lose access to the
   voice immediately". Elige una con aviso largo (la biblioteca permite filtrar
   por ese dato) y guárdala en "My Voices". No la borres: durante el aviso "it
   cannot be saved again".
6. La opción más robusta: una voz creada con Voice Design (es tuya y no depende
   de un tercero) o un clon instantáneo de tu propia voz (desde Starter). Clonar
   la voz propia además está entre lo que YouTube no obliga a declarar.

Voces de la biblioteca y uso comercial: la página
[Voice Library commercial](https://elevenlabs.io/voice-library/commercial) dice
"Yes, you can use the commercial voices in your commercial project". Es una
página de mercadeo; una cláusula equivalente en los términos quedó **sin
verificar**. Con plan gratis las voces de la biblioteca no están disponibles
por API.

### Alternativas en la nube

| Servicio | Modelo vigente | Precio | Costo por video | Costo por 30 videos | Marcas de tiempo | Uso comercial |
|---|---|---|---|---|---|---|
| Google Gemini TTS | `gemini-3.8-flash-tts` | Nivel gratis; pago 9 USD por millón de tokens de audio hasta el 31 dic 2026, 18 USD desde el 1 ene 2027 | 0 USD gratis; unos 0,03 USD pago (estimación) | 0 USD; cerca de 1 USD | No | Sin cláusula que lo prohíba (ver nota) |
| OpenAI | `tts-1` | 15 USD por millón de caracteres | 0,04 USD | 1,13 USD | No | Exige avisar que la voz es de IA. **Se apaga el 6 ene 2027** |
| Azure AI Speech | Voces neuronales | Nivel F0: 500 mil caracteres gratis al mes | 0 USD | 0 USD | Sí, por palabra (`WordBoundary`) | Cláusula **sin verificar** |
| Amazon Polly | Neural / Generative | 16 / 30 USD por millón de caracteres | 0,04 / 0,08 USD | 1,20 / 2,25 USD | Sí, por palabra (Speech Marks) | "your Polly output belongs to you" |

Notas por servicio:

- **Google Gemini TTS** ([precios](https://aistudio.google.com/docs/pricing),
  [términos](https://aistudio.google.com/docs/terms),
  [documentación de voz](https://aistudio.google.com/docs/speech-generation)).
  Los términos dicen "Google won't claim ownership over that content" y "You're
  responsible for your use of generated content". No se encontró ninguna
  cláusula que prohíba el uso comercial del nivel gratis; tampoco una que lo
  conceda de forma expresa. En el nivel gratis el contenido se usa para mejorar
  productos y "human reviewers may read, annotate, and process your API input
  and output": los guiones inéditos pasan por ahí. No hay parámetro numérico de
  velocidad (se pide en lenguaje natural) ni marcas de tiempo, así que toca
  alinear con WhisperX. Salida WAV de 24 kHz mono. El costo por video es una
  estimación propia (32 tokens por segundo es el dato de entrada de audio; el
  de salida quedó **sin verificar**). Los límites del nivel gratis quedaron
  **sin verificar** (la página pide iniciar sesión).
- **OpenAI** ([precios](https://developers.openai.com/api/docs/pricing),
  [obsolescencias](https://developers.openai.com/api/docs/deprecations)). Aviso
  del 1 de octubre de 2026, apagado el 6 de enero de 2027, reemplazo sugerido
  `gpt-realtime-2.1-mini`. Su política obliga a "provide a clear disclosure to
  end users that the TTS voice they are hearing is AI-generated"
  ([guía](https://developers.openai.com/api/docs/guides/text-to-speech)).
  Propiedad de la salida: **sin verificar** (los términos devolvieron error
  403). Descartado.
- **Azure**
  ([precios](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/speech-services/)):
  "0.5 million characters free per month" para voces neuronales, suficiente
  para los 75.000 caracteres del mes. El precio por encima de la cuota (unos 15
  USD por millón de caracteres) quedó **sin verificar** en la página oficial;
  la variante Neural HD cuesta 22 USD por millón según la API oficial de
  precios. Exige cuenta de Azure con tarjeta.
- **Amazon Polly** ([precios](https://aws.amazon.com/polly/pricing/),
  [preguntas frecuentes](https://aws.amazon.com/polly/faqs/)). Nivel gratis
  durante 12 meses: 1 millón de caracteres neuronales o 100 mil generativos al
  mes. "You can cache and replay Amazon Polly's generated speech at no
  additional cost". La redacción literal de "uso comercial" en los términos de
  servicio de AWS quedó **sin verificar**.

### Opciones locales gratuitas (CPU, sin GPU)

Ninguno de estos comandos se ejecutó en este equipo: la tarea prohibía instalar
software. Salen de la documentación oficial de cada proyecto.

| Opción | Calidad | Licencia del modelo | Licencia de las voces | Velocidad | Marcas de tiempo |
|---|---|---|---|---|---|
| **Kokoro-82M** | Alta para su tamaño; la mejor de este grupo | Apache 2.0 | Las mismas del modelo (entrenado con "permissive/non-copyrighted audio data") | `speed=` | Sí en inglés (en el código, no documentado) |
| Piper | Media; robótica frente a Kokoro | Código GPL 3.0 | **Cada voz tiene la suya**; varias no comerciales | `--length-scale` | No |
| MeloTTS | Media | MIT | MIT | `--speed` | No |
| Chatterbox | Alta | MIT | MIT | Sin parámetro directo | No |
| Coqui XTTS-v2 | Alta | **No comercial** | **No comercial** | | |
| edge-tts | Alta | Cliente no oficial | Términos de Microsoft sin aclarar | `--rate` | Sí (`.srt`) |

**Kokoro** ([modelo](https://huggingface.co/hexgrad/Kokoro-82M),
[código](https://github.com/hexgrad/kokoro)). Voces en inglés estadounidense
mejor calificadas por el autor: `af_heart` (A), `af_bella` (A-); las masculinas
(`am_fenrir`, `am_michael`, `am_puck`) tienen C+.

```powershell
pip install "kokoro>=0.9.4" soundfile
# En Windows instala además espeak-ng con el .msi de su página de GitHub
```

```python
from kokoro import KPipeline
import soundfile as sf

pipeline = KPipeline(lang_code="a")          # "a" = inglés estadounidense
texto = open("guion.txt", encoding="utf-8").read()
for i, (gs, ps, audio) in enumerate(pipeline(texto, voice="af_heart", speed=1.1)):
    sf.write(f"voz_{i:02d}.wav", audio, 24000)
```

Variante sin PyTorch, más liviana
([kokoro-onnx](https://github.com/thewh1teagle/kokoro-onnx), licencia MIT):

```powershell
pip install -U kokoro-onnx soundfile
```

Requiere descargar `kokoro-v1.0.onnx` y `voices-v1.0.bin` de sus publicaciones
en GitHub. Marcas de tiempo en esta variante: **sin verificar**. Velocidad real
de Kokoro en la CPU de este equipo: **sin verificar** (no hay prueba oficial).

**Piper** ([repositorio actual](https://github.com/OHF-Voice/piper1-gpl); el
original `rhasspy/piper` se archivó el 6 de octubre de 2025).

```powershell
pip install piper-tts
python -m piper.download_voices en_US-kristin-medium
python -m piper -m en_US-kristin-medium --length-scale 0.9 -f voz.wav -- "This is a test."
```

El propio proyecto advierte: "The Piper project grants no license over voice
models". Su
[guía de uso comercial](https://raw.githubusercontent.com/OHF-Voice/piper1-gpl/main/docs/COMMERCIAL_USE.md)
lista las únicas voces en inglés cuyo origen completo lo permite:

| Voz | Licencia del conjunto de datos |
|---|---|
| `en_US-kristin-medium`, `en_US-john-medium`, `en_US-norman-medium`, `en_US-ljspeech-medium`, `en_US-ljspeech-high`, `en_GB-cori-high` | Dominio público |
| `en_US-joe-medium`, `en_US-mike-medium`, `en_US-kathleen-medium` | CC0 |
| `en_US-libritts-high`, `en_US-hifi_tts_92-medium`, `en_GB-alba-medium`, `en_GB-cori-medium` | CC BY 4.0 (exige atribución) |

**No usar** `en_US-lessac-*` (datos "exclusively for Research Purposes only")
ni `en_US-ryan-*` (CC BY-NC-SA 4.0). Varias voces se reentrenaron a finales de
2026: "A copy downloaded before the retrain is the old version and does not
qualify, even though it has the same file name". Descarga siempre de nuevo.

Las demás, en una línea:

- **MeloTTS** ([repositorio](https://github.com/myshell-ai/MeloTTS)): MIT,
  "free for both commercial and non-commercial use", pero en Windows sus autores
  sugieren Docker.
- **Chatterbox** ([repositorio](https://github.com/resemble-ai/chatterbox)):
  MIT, `pip install chatterbox-tts`; el proyecto se declara retirado desde
  agosto de 2026 y marca cada salida con una marca de agua.
- **Coqui XTTS-v2**
  ([licencia](https://huggingface.co/coqui/XTTS-v2/raw/main/LICENSE.txt)):
  "allows only non-commercial use of a machine learning model and its outputs".
  Prohibido para este canal.
- **edge-tts** ([repositorio](https://github.com/rany2/edge-tts)): usa el
  servicio de Microsoft Edge sin ser un cliente oficial. Los derechos sobre el
  audio no están aclarados (**sin verificar**). No usar en videos monetizados.

### Recomendación y costos

| Opción | Costo por video (2.500 caracteres) | Costo por 30 videos al mes | Qué incluye |
|---|---|---|---|
| **Principal: ElevenLabs Creator** | 0,73 USD (22 USD entre 30) | **22 USD** | 121 mil créditos: los 30 videos y 46 mil créditos para repetir tomas (18 guiones completos) |
| ElevenLabs Starter | 0,50 USD | 6 USD | Solo alcanza para 12 videos al mes |
| ElevenLabs por API en dólares | 0,20 USD | 6,00 USD | A 0,08 USD por mil caracteres. Si exige además una suscripción: **sin verificar** |
| **Respaldo gratuito: Kokoro-82M** | **0 USD** | **0 USD** | Sin límites; más tiempo de máquina |
| Voz propia | 0 USD | 0 USD | Un micrófono de unos 20 a 50 USD, una vez |

Razones:

- ElevenLabs es la única opción que junta calidad, licencia comercial explícita,
  control de velocidad, semilla y marcas de tiempo en una sola llamada.
- Kokoro es el único respaldo gratuito con licencia limpia de punta a punta
  (modelo y voces Apache 2.0), parámetro de velocidad y tiempos por palabra.
- Empieza con Starter el mes del piloto (4 a 12 videos) y sube a Creator cuando
  publiques a diario.
- Gemini TTS queda como tercera opción: es gratis y suena bien, pero no tiene
  marcas de tiempo ni velocidad numérica, sus precios se duplican en enero de
  2027 y en el nivel gratis tus guiones pueden ser revisados por personas.

## 2. Qué exige YouTube sobre la voz sintética

### Casilla de contenido alterado o sintético

Fuente: [ayuda oficial](https://support.google.com/youtube/answer/14328491?hl=en).

Obliga a declarar el contenido realista que:

- "Makes a real person appear to say or do something they didn't do."
- "Alters footage of a real event or place."
- "Generates a realistic scene that didn't actually occur."

No obliga a declarar:

- Contenido claramente irreal o animado.
- Ayudas de producción: guion, ideas, títulos, miniaturas, subtítulos.
- "Cloning one's own voice to create voice overs or dubs".

Sobre una voz sintética genérica narrando ficción animada, la página **no dice
nada expreso**. La lectura razonable es que no encaja en los casos
obligatorios, pero es una interpretación. Dos datos ayudan a decidir:

- Declarar no cuesta: "won't limit a video's audience or impact its eligibility
  to earn money".
- No declarar cuando sí tocaba sí cuesta: "Creators who consistently choose not
  to disclose this information may be subject to manual application of a label"
  y a "removal of content or suspension from the YouTube Partner Program".

Regla del canal: animación con voz sintética genérica, casilla en "No". Si
algún video imita la voz de una persona real o muestra una escena realista,
casilla en "Sí". Nunca clonar voces de terceros.

### Política de contenido no auténtico

Fuente: [políticas de monetización](https://support.google.com/youtube/answer/1311392?hl=en).

No se monetiza:

- "Similar or repetitive content with low educational value, commentary,
  narratives, or minimal variation across videos"
- "Image slideshows, templated storylines, or scrolling text with minimal or no
  narrative, commentary, or educational value"
- "AI-generated content made with generic or unoriginal templates giving the
  impression of mass production"
- "Content that exclusively features readings of other materials you did not
  originally create, like text from websites or news feeds"

Sí se permite:

- Series donde "each video has a distinct storyline, focus, or concept."
- "Content that expresses your unique creative voice, like using AI to
  visualize a unique character and narrative you invented"
- "Content that utilizes creative tools to assist in delivering a unique,
  well-researched, or creative narrative"

Consecuencia: "If we cannot clearly tell that you made the content,
monetization may be removed from your entire channel."

Las palabras "text-to-speech", "synthetic voice" y "narration" no aparecen en
esas secciones. **No existe una frase oficial que diga que la voz sintética
está permitida ni que está prohibida.** La respuesta de TeamYouTube de julio de
2025 que suele citarse no se pudo leer (**sin verificar**).

### Qué reduce el riesgo, de más a menos efectivo

1. **Voz propia.** Es la prueba más directa de que hay una persona detrás.
2. **Clon de tu propia voz** en ElevenLabs: YouTube lo nombra entre lo que no
   hay que declarar y la voz no existe en ningún otro canal.
3. **Una sola voz sintética con identidad**, siempre la misma, con nombre de
   narrador y personalidad en el guion. Una voz de catálogo que usan mil
   canales es justo la "impression of mass production".
4. **Guion original** en cada video, con edición humana visible (gancho y
   remate). Nada de historias de Reddit ni textos ajenos leídos tal cual.
5. Variar premisa, conflicto y tipo de final. La plantilla visual y sonora
   puede repetirse; la trama no.
6. Guardar evidencia: guiones con sus versiones, archivos de Studio, el
   `voz.json` y el registro de licencias de este documento.

## 3. Voz propia

### Grabación mínima

| Punto | Con celular | Con micrófono barato |
|---|---|---|
| Equipo | El celular y su aplicación de grabadora en la máxima calidad (WAV o M4A a 48 kHz) | Micrófono USB o de solapa, de 20 a 50 USD |
| Distancia | 15 a 20 cm de la boca, micrófono apuntando a la barbilla, no al frente | 10 a 15 cm, un poco de lado para evitar soplidos en "p" y "b" |
| Cuarto | El más pequeño y con más tela: un clóset abierto con ropa, o debajo de una cobija | Igual |
| Ruido | Ventilador, nevera y aire apagados; celular en modo avión | Igual |
| Nivel | Que los picos queden entre -12 y -6 dB; nunca en rojo | Igual |

Rutina:

1. Graba 5 segundos de silencio al inicio (sirve para medir el ruido).
2. Lee de pie, con el guion en pantalla, sonriendo en las partes ligeras.
3. Graba por bloques. Si te equivocas, da una palmada y repite la frase: la
   palmada se ve en la forma de onda y el corte es rápido.
4. Lee a ritmo normal y claro. La velocidad del género se consigue en el
   montaje, no atropellando la lectura.
5. Guarda el original sin tocar en `audio/voz/crudo/`.

### Limpieza con ffmpeg

Un solo comando (probado en este equipo; ver "Comprobación"):

```powershell
ffmpeg -y -i voz_cruda.wav -af "highpass=f=80,afftdn=nr=12:nf=-50,silenceremove=start_periods=1:start_threshold=-45dB:stop_periods=-1:stop_duration=0.25:stop_silence=0.12:stop_threshold=-45dB,atempo=1.08" -ar 48000 -ac 1 voz_limpia.wav
```

| Filtro | Qué hace | Cómo ajustarlo |
|---|---|---|
| `highpass=f=80` | Quita retumbe y golpes por debajo de 80 Hz | Voz muy grave: 70. Voz aguda: 100 |
| `afftdn=nr=12:nf=-50` | Reduce ruido de fondo constante. `nr` es cuánto reduce (dB) y `nf` el piso de ruido | Si suena metálico, baja `nr` a 8. Si queda siseo, sube a 16 |
| `silenceremove=...` | Quita el silencio inicial y acorta toda pausa de más de 0,25 s, dejando 0,12 s | Menos agresivo: `stop_duration=0.4`. Si corta finales de palabra, usa `-50dB` |
| `atempo=1.08` | Acelera 8 % sin cambiar el tono | Rango útil 1,03 a 1,15. Más de 1,2 suena artificial |

Cálculo del `atempo`: divide las palabras por minuto que quieres entre las que
tiene la grabación después de quitar silencios. Si quedó en 205 y quieres 225,
el factor es 225 / 205 = 1,10.

Después va la normalización en dos pasadas (pasos 2 y 3 de la cadena de
mezcla).

### Objetivo de sonoridad

- **Meta del video final: -14 LUFS integrados, pico real de -1 dBTP.**
- **Meta de la voz sola antes de mezclar: -16 LUFS, pico real de -1,5 dBTP.**

Fuente y límites del dato:

- **YouTube no publica una cifra oficial en LUFS.** Sus páginas de ayuda solo
  describen el "volumen estable" ("Stable volume balances the range between
  quiet and loud",
  [ayuda](https://support.google.com/youtube/answer/14106294?hl=en)) y un
  ajuste de Studio que permite "Automatic adjustments to volume levels and
  sound mixing"
  ([ayuda](https://support.google.com/youtube/answer/16619284?hl=en)).
- El valor de -14 LUFS es la referencia que mide la comunidad de audio con el
  dato "content loudness" de "Estadísticas para nerds". No se confirmó en
  ninguna fuente primaria: **sin verificar**.
- Lo que sí explica una fuente especializada
  ([Production Advice](https://productionadvice.co.uk/stats-for-nerds/),
  artículo de 2017, no oficial): "YouTube doesn't turn up quieter videos". Si
  subes un video más fuerte que la referencia, YouTube lo baja; si lo subes más
  bajo, se queda bajo. Por eso conviene llegar justo a la referencia.
- Si la normalización se aplica igual a los Shorts: **sin verificar**. En el
  feed de Shorts un video bajo se oye bajo al lado del siguiente, así que la
  meta de -14 LUFS es prudente en cualquier caso.

## 4. Música

### La regla que manda

Fuente: [ayuda oficial sobre Shorts de hasta tres minutos](https://support.google.com/youtube/answer/15424877?hl=en).

- "Shorts longer than one minute that have an active Content ID claim,
  regardless of the policy, will be blocked on YouTube."
- "The video will not be playable or recommended on YouTube, and will not be
  eligible for monetization."
- "There are no penalties to your channel."
- "Once the claim is resolved, your Short will be viewable and eligible for
  monetization."

Todos los videos de este canal duran más de un minuto. Un reclamo, aunque sea
injusto y se gane la disputa, saca el video del aire en sus primeras horas, que
son las que deciden su alcance. **El criterio de selección no es "se puede
usar" sino "no genera reclamos".**

Además, según el
[reparto de ingresos de Shorts](https://support.google.com/youtube/answer/12504220?hl=en),
una pista del catálogo comercial se lleva la mitad del aporte del video. La
música de biblioteca libre no descuenta nada.

### Fuentes

| Fuente | Costo | Atribución | Riesgo de reclamo | Veredicto |
|---|---|---|---|---|
| Biblioteca de audio de YouTube | Gratis | No con licencia estándar; sí con Creative Commons | El más bajo | **Primera opción** |
| Incompetech (Kevin MacLeod) | Gratis | Obligatoria | Medio | Respaldo, con crédito puesto antes de publicar |
| Pixabay Music | Gratis | No | Alto en pistas registradas en Content ID | Solo pistas sin la etiqueta |
| Uppbeat | Gratis limitado o pago | En el plan gratis, sí | **Sin verificar** | Sin evaluar |
| Epidemic Sound | 9,99 USD al mes en plan anual o 17,99 mes a mes | No | Bajo con el canal vinculado | Opcional cuando haya ingresos |
| Artlist | Unos 9,99 a 14,99 USD al mes (**sin verificar**) | No | Bajo con el canal en la lista | Opcional |
| Free Music Archive | Gratis | Casi siempre | Medio a alto | Evitar salvo CC BY o CC0 revisada |

**Biblioteca de audio de YouTube**
([ayuda oficial](https://support.google.com/youtube/answer/3376882?hl=en)). Tiene
dos tipos de licencia:

- Licencia estándar de la Biblioteca: "a standard YouTube Audio Library license
  that doesn't require attribution".
- Creative Commons: "If you're using a track with a Creative Commons license,
  you must credit the artist in your video's description." La página no precisa
  la versión de la licencia (que sea CC BY 4.0 quedó **sin verificar**); el
  texto exacto del crédito lo entrega la propia Biblioteca al elegir la pista.

Garantías: "Copyright-safe music and sound effects downloaded from the Audio
Library won't be claimed by a rights holder" y "you can monetize videos with
music and sound effects from the Audio Library". Y la advertencia: "Only music
and sound effects from the Audio Library are known to YouTube to be
copyright-safe."

La Biblioteca vive dentro de YouTube Studio y pide iniciar sesión, así que
**no se pudo abrir ninguna de sus pistas** en esta investigación. Fíltrala por
"Atribución no necesaria" y por estado de ánimo, y registra lo que descargues.

**Pixabay Music** ([resumen de licencia](https://pixabay.com/service/license-summary/),
[términos](https://pixabay.com/service/terms/),
[preguntas frecuentes](https://pixabay.com/service/faq/)).

- Gratis, uso comercial, sin atribución: "You do not need to credit Pixabay or
  the contributor of Content when you use it".
- Prohibido: "You cannot sell or distribute Content (either in digital or
  physical form) on a Standalone basis".
- El problema: "Some contributors or their distributors may choose to register
  their tracks with Content ID" y "Tracks displaying a shield icon are
  registered with Content ID and may trigger claims". En las fichas revisadas
  la marca aparece como el texto "Content ID Registered".
- Cómo se levanta un reclamo
  ([guía de Pixabay](https://pixabay.com/blog/posts/how-to-clear-a-youtube-content-id-claim-with-a-pix-190/)):
  se descarga el certificado de licencia desde el menú de descarga de la pista
  (con sesión iniciada), se disputa eligiendo "License" y se pega el
  certificado. "The processing time is up to thirty (30) days once you submit a
  dispute."
- Para este canal: hasta 30 días con el Short bloqueado es inaceptable. **Solo
  pistas sin la etiqueta de Content ID**, y aun así con captura de la ficha.

**Incompetech, Kevin MacLeod**
([preguntas frecuentes](https://incompetech.com/music/royalty-free/faq.html),
[licencias](https://incompetech.com/music/royalty-free/licenses/),
[Content ID](https://incompetech.com/music/royalty-free/youtube-contentid.html)).

- CC BY 4.0: "No charge. Requires that you credit the music." Sobre monetizar:
  "Yes. Please use my music to make money on YouTube."
- Formato del crédito, tal como lo pide el autor (va en la descripción):

```text
"Carefree" Kevin MacLeod (incompetech.com)
Licensed under Creative Commons: By Attribution 4.0 License
https://creativecommons.org/licenses/by/4.0/
```

- Sí puede haber reclamos. El autor explica que suelen venir de la falta del
  crédito y que, con el crédito puesto, la disputa "be released within 72 hours
  and likely much faster". En su portada, el 2 de abril de 2026: "We are still
  working to allow-list all my music by default, but that is not currently the
  case."
- Existe una licencia paga sin atribución; su precio quedó **sin verificar**.
- Para este canal: 72 horas de bloqueo siguen siendo un costo. Pon el crédito
  antes de publicar y sube el video como "No listado" o "Privado" unas horas
  antes para ver si aparece un reclamo.

**Uppbeat**: sus páginas oficiales devolvieron error 429 en todos los intentos.
Todo **sin verificar**: límite de descargas del plan gratis, crédito
obligatorio, precios.

**Epidemic Sound**: precios tomados del
[blog de la propia empresa](https://www.epidemicsound.com/blog/artlist-vs-epidemic-sound/)
(1 de abril de 2026) porque la
[página de precios](https://www.epidemicsound.com/pricing/) no mostró las
cifras. Creator: "$9.99 per month billed yearly, or $17.99 billed monthly". Que
los videos publicados durante la suscripción sigan autorizados después de
cancelar quedó **sin verificar** (el artículo de ayuda devolvió error 403).

**Artlist**: la página de precios devolvió error 403; la cifra de la tabla sale
del blog de un competidor (**sin verificar**). Su
[licencia](https://help-center.artlist.io/privacy-terms/artlist-license/) sí se
leyó: los proyectos publicados durante la suscripción pueden seguir publicados
al vencer, y "If you don't add your channel or YouTube Projects URL to the
clearlist, you may receive claims from Artlist Ltd".

**Free Music Archive** ([guía de licencias](https://freemusicarchive.org/License_Guide),
[preguntas frecuentes](https://freemusicarchive.org/faq)). Cada pista tiene su
licencia. Sirven CC BY, CC BY-SA y CC0. No sirven las NC ("You cannot use it
for commercial purposes") ni las ND ("Syncing a track to video/moving images
constitutes a derivative work, which is prohibited by this licence"). Ante un
reclamo hay que escribirle al artista. Demasiado trabajo por pista.

**Nunca**: audio del catálogo de Roblox, música comercial, ni pistas "sin
copyright" de canales de YouTube sin página de licencia.

### Pistas recomendadas

Cómo se verificó cada una:

- Las 14 de Kevin MacLeod figuran en el catálogo oficial
  [`pieces.json`](https://incompetech.com/music/royalty-free/pieces.json) de
  Incompetech, de donde salen el código ISRC, el tempo y la duración. **La
  página individual de cada pista no se pudo abrir** (se arma con JavaScript):
  el enlace con `?isrc=` sigue el patrón del sitio pero no fue comprobado. Si
  no carga, busca el título en el
  [buscador de Incompetech](https://incompetech.com/music/royalty-free/music.html).
- La licencia CC BY 4.0 sale de las preguntas frecuentes del sitio, no de un
  campo por pista.
- La de Pixabay sí se abrió y no mostraba la etiqueta de Content ID ese día.
  Vuelve a mirar antes de descargar: el autor puede registrarla después.

| Tono | Pista | Autor | Tempo y duración | Fuente y licencia | Enlace |
|---|---|---|---|---|---|
| Tierno | Carefree | Kevin MacLeod | 96 ppm, 3:25 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400037) |
| Tierno | Easy Lemon | Kevin MacLeod | 82 ppm, 2:06 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1200076) |
| Tierno | Windswept | Kevin MacLeod | 79 ppm, 3:28 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100757) |
| Tierno | Almost New | Kevin MacLeod | 80 ppm, 3:23 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1800008) |
| Cómico | Sneaky Snitch | Kevin MacLeod | 87 ppm, 2:17 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100772) |
| Cómico | Monkeys Spinning Monkeys | Kevin MacLeod | 144 ppm, 2:05 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1400011) |
| Cómico | Hidden Agenda | Kevin MacLeod | 132 ppm, 2:15 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1200102) |
| Cómico | Investigations | Kevin MacLeod | 94 ppm, 1:34 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100646) |
| Tenso | Lightless Dawn | Kevin MacLeod | 90 ppm, 6:20 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100655) |
| Tenso | Long Note Two | Kevin MacLeod | Sin tempo, 7:42 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100420) |
| Tenso | The Complex | Kevin MacLeod | 104 ppm, 4:28 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1300025) |
| Triste con cierre esperanzador | Rains Will Fall | Kevin MacLeod | 85 ppm, 3:42 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100723) |
| Triste con cierre esperanzador | At Rest | Kevin MacLeod | 57 ppm, 3:27 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1100748) |
| Triste con cierre esperanzador | Bittersweet | Kevin MacLeod | 73 ppm, 3:22 | Incompetech, CC BY 4.0 | [ficha](https://incompetech.com/music/royalty-free/index.html?isrc=USUAN1700004) |
| Triste con cierre esperanzador | Emotional Romantic Piano Story | RomanSenykMusic | 2:43 | Pixabay, Content License, sin etiqueta de Content ID | [ficha abierta](https://pixabay.com/music/modern-classical-emotional-romantic-piano-story-123587/) |

Notas de uso:

- "Monkeys Spinning Monkeys" y "Sneaky Snitch" están muy oídas en videos
  cortos. Sirven para el piloto; para la identidad del canal conviene buscar
  equivalentes menos gastados en la Biblioteca de YouTube.
- "Rains Will Fall" es un vals de piano melancólico que se aclara hacia el
  final: calza con el bloque de cierre de las historias tristes.
- "Investigations" dura 1:34: hay que repetirla en bucle (la cadena de mezcla
  ya lo hace).
- Pistas de Pixabay **descartadas** por mostrar "Content ID Registered":
  "Pizzicato" de Music_For_Videos y "Emotional Piano Music" de DELOSound.
- De reserva, también confirmadas en `pieces.json`: Wholesome, Fluffing a Duck,
  Life of Riley, Heartwarming (1:12), Touching Moments Two - Higher,
  Ossuary 6 - Air, Heart of Nowhere, Frost Waltz.

## 5. Efectos de sonido

### Fuentes

| Fuente | Costo | Atribución | Uso monetizado | Cuenta | Nota |
|---|---|---|---|---|---|
| Biblioteca de audio de YouTube | Gratis | No (licencia estándar) | Sí | Sí (Studio) | La única que YouTube declara segura |
| Mixkit | Gratis | No | Sí | No | La más cómoda |
| Pixabay | Gratis | No | Sí | **Sin verificar** | No redistribuir el archivo suelto |
| Freesound | Gratis | Depende de la licencia | Solo CC0 y CC BY | Sí | Revisar sonido por sonido |
| Sonniss (paquetes GDC) | Gratis | No | Sí | **Sin verificar** | Descargas de varios GB |
| Zapsplat | **Sin verificar** | **Sin verificar** | **Sin verificar** | **Sin verificar** | El sitio devolvió error 403 |

- **Mixkit** ([efectos](https://mixkit.co/free-sound-effects/)): "All sound
  clips are royalty-free and can be used without attribution, plus no sign up
  is required" y "it's fine to use our sound effects in video projects that you
  upload to YouTube". El texto completo de su licencia de efectos no se pudo
  leer (**sin verificar**).
- **Pixabay** ([resumen de licencia](https://pixabay.com/service/license-summary/)):
  misma licencia que la música; los términos incluyen expresamente "sound
  effects". La advertencia de Content ID de sus preguntas frecuentes habla de
  pistas musicales.
- **Freesound** ([preguntas frecuentes](https://freesound.org/help/faq/)). Tres
  licencias vigentes y una antigua:

| Licencia | Sirve para el canal | Condición |
|---|---|---|
| CC0 | Sí | Ninguna: "you can do pretty much what you want with the sound" |
| CC BY 4.0 | Sí | Crédito: "you should always mention the original creators" |
| CC BY-NC 4.0 | **No** | "you can't earn any money with the piece of work you create!" |
| Sampling+ (antigua) | **No** | Equivale a una no comercial |

  Formato de crédito que sugiere Freesound: `"nombre del sonido" by usuario
  (https://freesound.org/s/ID/) licensed under CC BY 4.0`. Los sonidos antiguos
  con CC BY 3.0 no se mencionan en la página (**sin verificar**). Para ahorrar
  trabajo, filtra por CC0 y listo.
- **Sonniss** ([licencia](https://sonniss.com/gdc-bundle-license/)): "All of the
  sounds are royalty free and commercially usable" y "Attribution is always
  appreciated, but never required". Prohíbe redistribuir los efectos como
  efectos y usarlos para entrenar IA.
- **Zapsplat**: todo **sin verificar**. Según resultados de búsqueda no
  confirmados, el plan gratis exige el crédito "Sound from Zapsplat.com" y solo
  da MP3. No lo uses sin leer su licencia.
- **BBC Sound Effects**: su licencia RemArc no se pudo abrir; fuentes
  secundarias dicen que es solo para uso personal, educativo o de
  investigación. **No usar** (**sin verificar**).
- **Sonidos de Roblox** (el "oof" clásico, audio de la Creator Store): la
  [documentación oficial](https://create.roblox.com/docs/audio/assets) los
  describe como recursos "for creators to use within their games" y para
  "any project on the platform". No se encontró permiso para usarlos fuera de
  Roblox; los términos de uso no se pudieron abrir (**sin verificar**). **No
  los extraigas**: usa un sonido parecido de las fuentes de arriba.

### Los 25 efectos más útiles para el formato

| N.º | Archivo | Efecto | Para qué se usa |
|---|---|---|---|
| 1 | `puf.wav` | Puf o "pop" suave | Aparición o desaparición de un personaje u objeto |
| 2 | `silbido_paso.wav` | Barrido de aire ("whoosh") | Cambio de plano o de escena |
| 3 | `pitido_censura.wav` | Pitido de 1 kHz | Tapar una palabra, chiste |
| 4 | `golpe_seco.wav` | Golpe o puño | Caídas, choques, portazos cómicos |
| 5 | `golpe_grave.wav` | Impacto grave ("boom") | Revelación, giro de la trama |
| 6 | `ding.wav` | Campanita o acierto | Idea, respuesta correcta, final feliz |
| 7 | `error.wav` | Zumbido de error | Fracaso, respuesta incorrecta |
| 8 | `rayado_disco.wav` | Disco rayado | Corte brusco de la música, "un momento" |
| 9 | `risas.wav` | Risas de grupo | Burlas en el colegio, remate cómico |
| 10 | `asombro.wav` | "Oh" de grupo | Sorpresa colectiva |
| 11 | `latido.wav` | Latido de corazón | Tensión, miedo, enamoramiento |
| 12 | `campana_colegio.wav` | Timbre o campana de colegio | Inicio y fin de escena escolar |
| 13 | `lluvia.wav` | Lluvia (bucle) | Escenas tristes o de noche |
| 14 | `viento.wav` | Viento (bucle) | Soledad, exteriores, suspenso |
| 15 | `trueno.wav` | Trueno | Giro dramático |
| 16 | `pasos.wav` | Pasos | Llegadas, persecuciones |
| 17 | `puerta.wav` | Puerta que se abre o se cierra | Entradas y salidas |
| 18 | `notificacion.wav` | Notificación de celular | Mensajes, giros por chat |
| 19 | `tecleo.wav` | Tecleo | Escenas de chat o computador |
| 20 | `caja_registradora.wav` | Caja registradora | Dinero, compras, premios |
| 21 | `reloj.wav` | Tic tac | Espera, cuenta regresiva |
| 22 | `grillos.wav` | Grillos | Silencio incómodo |
| 23 | `trombon_triste.wav` | Trombón triste | Fracaso cómico |
| 24 | `brillo.wav` | Destello o campanillas | Momento mágico, transformación |
| 25 | `subida_tension.wav` | Subida de tensión ("riser") | Antes de la revelación o del corte final |

Evita el "vine boom" y otros sonidos de memes sacados de videos: no tienen
licencia. Busca un "boom" equivalente en Mixkit o Pixabay.

### Organización de `audio/`

```text
audio/
  voz/
    voz.json            identidad de la voz (voice_id, modelo, ajustes, semilla)
    crudo/              originales sin tocar
  musica/
    tierno/  comico/  tenso/  triste-esperanza/
    CREDITOS.md
  sfx/
    impactos/           golpe_seco.wav, golpe_grave.wav, puf.wav
    transiciones/       silbido_paso.wav, subida_tension.wav, rayado_disco.wav
    interfaz/           ding.wav, error.wav, notificacion.wav, pitido_censura.wav
    ambiente/           lluvia.wav, viento.wav, grillos.wav, trueno.wav
    humanos/            risas.wav, asombro.wav, latido.wav, pasos.wav
    objetos/            puerta.wav, campana_colegio.wav, reloj.wav, tecleo.wav
    CREDITOS.md
  licencias/            capturas y certificados, un archivo por pista o efecto
```

Reglas:

- Todo en WAV de 48 kHz. Convierte al descargar:
  `ffmpeg -i descarga.mp3 -ar 48000 -ac 2 efecto.wav`.
- Nombres en minúscula, sin espacios ni tildes, que digan qué suena.
- Normaliza cada efecto una vez al guardarlo (pico a -3 dB) para que en la
  mezcla solo haya que bajar, nunca subir:
  `ffmpeg -i efecto.wav -af "loudnorm=I=-18:TP=-3" -ar 48000 efecto_norm.wav`.
- Ningún archivo entra a la carpeta sin su fila en `CREDITOS.md`.

Formato de `audio/sfx/CREDITOS.md` (y de `audio/musica/CREDITOS.md`):

```markdown
# Créditos de efectos de sonido

| Archivo | Título original | Autor | Fuente | Enlace | Licencia | Atribución obligatoria | Fecha de descarga | Evidencia |
|---|---|---|---|---|---|---|---|---|
| impactos/puf.wav | Cartoon pop | (autor) | Mixkit | https://... | Mixkit Sound Effects Free License | No | 2026-11-20 | licencias/puf.png |
| ambiente/lluvia.wav | Rain loop | (usuario) | Freesound | https://freesound.org/s/000000/ | CC0 1.0 | No | 2026-11-20 | licencias/lluvia.png |
```

## 6. Cadena de mezcla con ffmpeg

Niveles de trabajo:

| Elemento | Nivel | Motivo |
|---|---|---|
| Voz | -16 LUFS, pico -1,5 dBTP | Deja margen para música y efectos |
| Música con atenuación automática | -20 LUFS en las pausas, cerca de -28 LUFS bajo la voz | 12 dB por debajo de la voz mientras se habla |
| Música a nivel fijo | -28 LUFS todo el tiempo | Lo mismo, sin compresor |
| Efectos | Entre -6 y -12 dB sobre el archivo ya normalizado | A oído: que se noten sin tapar una palabra |
| Salida | -14 LUFS, pico -1 dBTP, AAC 192 kbps, 48 kHz estéreo | Meta de la sección 3 |

Cuál variante usar: en este formato la voz casi no hace pausas, así que **el
nivel fijo (5B) es el valor por defecto**: es predecible y no "bombea". La
atenuación automática (5A) vale la pena cuando el video tiene entrada o cierre
musical sin voz, o silencios dramáticos.

Los comandos están escritos para PowerShell (la consola de este equipo). La
cadena entre comillas de `-filter_complex` puede ocupar varias líneas.

### Paso 1. Limpiar la voz

Voz propia:

```powershell
ffmpeg -y -i voz_cruda.wav -af "highpass=f=80,afftdn=nr=12:nf=-50,silenceremove=start_periods=1:start_threshold=-45dB:stop_periods=-1:stop_duration=0.25:stop_silence=0.12:stop_threshold=-45dB,atempo=1.08" -ar 48000 -ac 1 voz_limpia.wav
```

Voz sintética con marcas de tiempo (sin reducción de ruido ni recorte de
silencios, para no desincronizar los subtítulos):

```powershell
ffmpeg -y -i voz_cruda.mp3 -af "highpass=f=80,atempo=1.08" -ar 48000 -ac 1 voz_limpia.wav
```

Recuerda dividir las marcas de tiempo por 1,08 (o por el factor que uses).

### Paso 2. Medir la voz

```powershell
ffmpeg -hide_banner -nostats -i voz_limpia.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json" -f null -
```

Anota `input_i`, `input_tp`, `input_lra`, `input_thresh` y `target_offset`.

### Paso 3. Normalizar la voz con esos valores

```powershell
ffmpeg -y -i voz_limpia.wav -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-38.37:measured_TP=-28.51:measured_LRA=0.70:measured_thresh=-48.37:offset=0.08:linear=true" -ar 48000 -ac 1 voz.wav
```

Reemplaza los cinco números por los de tu medición. Las dos pasadas con
`linear=true` suben el volumen sin alterar la dinámica; una sola pasada la
comprime.

### Paso 4. Llevar la música a -20 LUFS

```powershell
ffmpeg -hide_banner -nostats -i musica.wav -af ebur128 -f null -
```

Lee la línea `I:` del resumen final. La ganancia es -20 menos ese valor. Si
midió -23,1 LUFS, son +3,1 dB:

```powershell
ffmpeg -y -i musica.wav -af "volume=3.1dB" -ar 48000 -ac 2 musica_20.wav
```

Hazlo una sola vez por pista y guarda el resultado en `audio/musica/`.

### Paso 5A. Mezcla con atenuación automática (`sidechaincompress`)

```powershell
$dur = [double](ffprobe -v error -show_entries format=duration -of csv=p=0 voz.wav)
$fin = [math]::Round($dur - 1.5, 2).ToString([cultureinfo]::InvariantCulture)

ffmpeg -y -i voz.wav -stream_loop -1 -i musica_20.wav -i golpe.wav -i pitido.wav -filter_complex "
[0:a]aformat=sample_rates=48000:channel_layouts=stereo,asplit=2[voz][llave];
[1:a]aformat=sample_rates=48000:channel_layouts=stereo,afade=t=in:d=0.3,afade=t=out:st=${fin}:d=1.5[mus];
[mus][llave]sidechaincompress=threshold=0.03:ratio=2:attack=15:release=350[musduck];
[2:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=-6dB,adelay=3200:all=1[fx1];
[3:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=-10dB,adelay=9500:all=1[fx2];
[voz][musduck][fx1][fx2]amix=inputs=4:duration=first:normalize=0,alimiter=limit=0.891:attack=5:release=50:level=false[out]
" -map "[out]" -ar 48000 -c:a pcm_s16le mezcla.wav
```

Qué hace cada línea:

| Línea | Función |
|---|---|
| `asplit=2[voz][llave]` | Duplica la voz: una copia se oye y la otra gobierna el compresor |
| `-stream_loop -1` y `duration=first` | La música se repite y la mezcla termina cuando termina la voz |
| `afade` | Entrada de 0,3 s y salida de 1,5 s para la música |
| `sidechaincompress` | Baja la música cuando hay voz. `threshold=0.03` es el nivel de voz que lo activa, `ratio=2` cuánto baja, `attack` y `release` en milisegundos |
| `adelay=3200:all=1` | Coloca el efecto a los 3,2 s (milisegundos desde el inicio) |
| `amix ... normalize=0` | Suma sin que ffmpeg baje el volumen de cada entrada |
| `alimiter=limit=0.891` | Limitador final a -1 dB (0,891 en escala lineal) |

Atenuación medida en este equipo con `threshold=0.03`, música a -20 LUFS y voz
a -16 LUFS:

| `ratio` | Música mientras hay voz | Música en pausa | Atenuación |
|---|---|---|---|
| 2 | -30,6 dB | -23,1 dB | 7,5 dB |
| 3 | -33,4 dB | -23,3 dB | 10,1 dB |
| 4 | -34,8 dB | -23,4 dB | 11,4 dB |

### Paso 5B. Mezcla con música a nivel fijo

```powershell
ffmpeg -y -i voz.wav -stream_loop -1 -i musica_20.wav -i golpe.wav -i pitido.wav -filter_complex "
[0:a]aformat=sample_rates=48000:channel_layouts=stereo[voz];
[1:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=-8dB,afade=t=in:d=0.3,afade=t=out:st=${fin}:d=1.5[mus];
[2:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=-6dB,adelay=3200:all=1[fx1];
[3:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=-10dB,adelay=9500:all=1[fx2];
[voz][mus][fx1][fx2]amix=inputs=4:duration=first:normalize=0,alimiter=limit=0.891:attack=5:release=50:level=false[out]
" -map "[out]" -ar 48000 -c:a pcm_s16le mezcla.wav
```

`volume=-8dB` sobre la pista de -20 LUFS la deja en -28 LUFS: 12 dB por debajo
de la voz. Usa la misma variable `$fin` del paso 5A.

Para más efectos, agrega una entrada `-i`, una línea con su `adelay` y súmala
en `amix` aumentando `inputs`.

### Paso 6. Normalización final y codificación

```powershell
ffmpeg -y -i mezcla.wav -af "loudnorm=I=-14:TP=-1.0:LRA=11:print_format=summary" -ar 48000 -c:a aac -b:a 192k audio_final.m4a
```

### Paso 7. Unir el audio al video sin recodificar la imagen

```powershell
ffmpeg -y -i video_mudo.mp4 -i audio_final.m4a -map 0:v:0 -map 1:a:0 -c:v copy -c:a copy -shortest -movflags +faststart short_final.mp4
```

### Paso 8. Comprobar antes de subir

```powershell
ffmpeg -hide_banner -nostats -i short_final.mp4 -af ebur128=peak=true -f null -
```

Debe dar `I:` entre -15 y -13 LUFS y `Peak:` por debajo de -1 dBFS.

### Comprobación en este equipo

Ejecutado el 13 de noviembre de 2026 con `ffmpeg version
9.0-full_build-www.gyan.dev`, en PowerShell, con audio de prueba generado por
ffmpeg (no es voz real):

```powershell
# "Voz": tono de 180 Hz con trémolo, 1,5 s de sonido y 1 s de silencio, más ruido rosa
ffmpeg -y -f lavfi -i "sine=frequency=180:sample_rate=48000:duration=20" -f lavfi -i "anoisesrc=color=pink:sample_rate=48000:duration=20:amplitude=0.02" -filter_complex "[0:a]volume='if(lt(mod(t,2.5),1.5),0.25,0)':eval=frame,tremolo=f=6:d=0.7[v];[v][1:a]amix=inputs=2:normalize=0[o]" -map "[o]" -ac 1 voz_cruda.wav
# "Música": acorde de tres tonos, 30 s
ffmpeg -y -f lavfi -i "sine=f=220:r=48000:d=30" -f lavfi -i "sine=f=277:r=48000:d=30" -f lavfi -i "sine=f=330:r=48000:d=30" -filter_complex "[0][1][2]amix=inputs=3:normalize=0,volume=0.5,aformat=channel_layouts=stereo[o]" -map "[o]" musica.wav
# Efectos y video de prueba
ffmpeg -y -f lavfi -i "sine=f=80:r=48000:d=0.4" -af "afade=t=out:st=0.05:d=0.35,volume=0.9" golpe.wav
ffmpeg -y -f lavfi -i "sine=f=1000:r=48000:d=0.3" -af "volume=0.6" pitido.wav
ffmpeg -y -f lavfi -i "testsrc2=size=1080x1920:rate=30:duration=14" -c:v libx264 -pix_fmt yuv420p -preset ultrafast video_mudo.mp4
```

Salida real de los pasos 1 a 8 (se omite la línea de progreso de ffmpeg):

```text
=== 1. limpieza de voz ===
exit=0
=== 2. medir voz ===
	"input_i" : "-38.37",
	"input_tp" : "-28.51",
	"input_lra" : "0.70",
	"input_thresh" : "-48.37",
	"output_i" : "-16.08",
	"output_tp" : "-6.44",
	"output_lra" : "0.70",
	"output_thresh" : "-26.08",
	"normalization_type" : "dynamic",
	"target_offset" : "0.08"
}
=== 3. normalizar voz (segunda pasada) ===
exit=0
=== 4. musica a -20 LUFS ===
    I:         -23.1 LUFS
exit=0
=== 5A. mezcla con atenuacion automatica ===
duracion=13.992938  inicio del fundido=12.49
exit=0
=== 5B. mezcla con musica a nivel fijo ===
exit=0
=== 6. master a -14 LUFS, AAC ===
Input Integrated:    -15.7 LUFS
Input True Peak:      -8.0 dBTP
Output Integrated:   -14.1 LUFS
Output True Peak:     -6.6 dBTP
Normalization Type:   Dynamic
exit=0
=== 7. pegar al video ===
exit=0
=== 8. comprobacion final ===
voz.wav          I: -15.9 LUFS  Peak: -6.1 dBFS  dur=13.992938
musica_20.wav    I: -20.0 LUFS  Peak: -14.7 dBFS  dur=30.000000
mezcla.wav       I: -15.6 LUFS  Peak: -8.0 dBFS  dur=13.992938
mezcla_fija.wav  I: -15.7 LUFS  Peak: -7.8 dBFS  dur=13.992938
short_final.mp4  I: -14.1 LUFS  Peak: -6.6 dBFS  dur=14.000000
codec_name=h264|width=1080|height=1920
codec_name=aac|sample_rate=48000|channels=2
```

Lectura de la prueba:

- Todos los comandos terminaron con código 0: la sintaxis es válida en esta
  versión de ffmpeg y en PowerShell, incluida la cadena de varias líneas.
- La limpieza pasó de 20,0 s a 13,99 s: los silencios de 1 s quedaron en unos
  0,24 s y el conjunto se aceleró 8 %.
- La voz quedó en -15,9 LUFS (meta -16) y el archivo final en -14,1 LUFS (meta
  -14) con pico de -6,6 dBFS.
- Lo que la prueba **no** demuestra: cómo suena con voz y música reales. Los
  valores de `afftdn`, el umbral de `silenceremove` y el `threshold` del
  compresor se ajustan a oído con la primera grabación de verdad. Los números
  `measured_*` del paso 3 son de este audio de prueba y hay que reemplazarlos.

## 7. Registro de licencias por video

Un archivo por video, guardado junto al proyecto (por ejemplo
`videos/2026-11-20-titulo/LICENCIAS.md`). Se llena **el día que se descarga**,
no el día del reclamo.

```markdown
# Registro de licencias: (título del video)

- Fecha de publicación:
- Enlace del video:
- Duración:
- Responsable:

## Voz

| Campo | Valor |
|---|---|
| Tipo | Propia / sintética |
| Servicio y plan | ElevenLabs Creator |
| Suscripción activa al generar | Sí (factura del mes: licencias/factura-2026-11.pdf) |
| voice_id y nombre de la voz | |
| Modelo y ajustes | eleven_multilingual_v2, stability 0.5, similarity 0.75, style 0, speed 1.1, seed |
| Fecha de generación | |
| Guion original | guion.md (con historial de versiones) |

## Música

| Pista | Autor | Fuente | Enlace de la ficha | Licencia | Atribución obligatoria | Fecha de descarga | Archivo local | Evidencia |
|---|---|---|---|---|---|---|---|---|
| | | | | | Sí / No | | audio/musica/... | licencias/... |

## Efectos de sonido

| Efecto | Autor | Fuente | Enlace | Licencia | Atribución obligatoria | Fecha de descarga | Archivo local | Evidencia |
|---|---|---|---|---|---|---|---|---|
| | | | | | | | audio/sfx/... | licencias/... |

## Texto de créditos puesto en la descripción

(pegar aquí exactamente lo que quedó publicado)

## Reclamos

| Fecha | Quién reclama | Qué reclama | Acción tomada | Resultado | Fecha de cierre |
|---|---|---|---|---|---|
| | | | | | |
```

Qué cuenta como evidencia, por fuente:

| Fuente | Qué guardar en `audio/licencias/` |
|---|---|
| Biblioteca de audio de YouTube | Captura de la fila de la pista en Studio con el tipo de licencia visible y la fecha |
| Pixabay | El certificado de licencia de la pista si lo ofrece; si no, captura de la ficha sin la etiqueta de Content ID, el enlace y el nombre del archivo |
| Incompetech | Captura de la ficha y de las preguntas frecuentes con la licencia, más el crédito publicado |
| Freesound | Captura de la ficha del sonido con la licencia visible (los autores pueden cambiarla después) |
| Mixkit, Sonniss | Captura de la ficha y copia de la página de licencia de ese día |
| ElevenLabs | Factura del mes y captura de la ficha de la voz |

Antes de publicar cada video:

1. Todas las filas de música y efectos tienen enlace, licencia y fecha.
2. Si alguna licencia exige crédito, el texto está en la descripción.
3. Ninguna pista de Pixabay muestra la etiqueta de Content ID.
4. El video se subió como privado o no listado y, pasadas unas horas, la
   pestaña de derechos de autor de Studio no muestra reclamos.
5. La comprobación del paso 8 da entre -15 y -13 LUFS.

## Lo que quedó sin verificar

| Tema | Qué falta confirmar |
|---|---|
| ElevenLabs | Qué modelos admiten el endpoint con marcas de tiempo; rango numérico de `stability`, `similarity_boost` y `style` en la API; cómo se descuentan los créditos de la suscripción al usar la API; la frase exacta sobre conservar la licencia al cancelar; cláusula de los términos sobre uso comercial de voces de la biblioteca |
| Gemini TTS | Tokens de audio de salida por segundo (el costo por video es una estimación); límites del nivel gratis; marca de agua en el audio |
| OpenAI | Propiedad de la salida (términos con error 403) |
| Azure | Precio neuronal por encima de la cuota gratis; cláusula de uso comercial |
| Amazon Polly | Redacción literal sobre uso comercial en los términos de AWS |
| Locales | Ningún comando de instalación se ejecutó; velocidad de Kokoro en esta CPU; marcas de tiempo en kokoro-onnx; términos de edge-tts |
| YouTube | Cifra oficial de sonoridad (los -14 LUFS son de terceros); si la normalización aplica a Shorts; texto de la respuesta de TeamYouTube de julio de 2025; versión de Creative Commons en la Biblioteca de audio |
| Música | Uppbeat completo (error 429); precio de Artlist (error 403); precios de Epidemic Sound en su página oficial y qué pasa al cancelar; precio de la licencia sin atribución de Incompetech; páginas individuales de las 14 pistas de Kevin MacLeod; cualquier pista concreta de la Biblioteca de audio de YouTube |
| Efectos | Zapsplat completo (error 403); licencia RemArc de la BBC; texto completo de la licencia de efectos de Mixkit; términos de Roblox sobre audio fuera de la plataforma; licencias CC BY 3.0 antiguas en Freesound |
