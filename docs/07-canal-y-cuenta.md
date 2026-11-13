# 07. Canal y cuenta: guía paso a paso

Corte de la información: 13 de noviembre de 2026. Todo sale de la ayuda oficial
de YouTube, AdSense y Google, del blog de YouTube y de las páginas oficiales de
Roblox, leídas ese día. Lo marcado **sin verificar** no se pudo confirmar en
una fuente oficial.

Avisos antes de empezar:

- Los nombres de menú son los de la ayuda en español de Latinoamérica. YouTube
  cambia rótulos con frecuencia: si un menú no aparece con ese nombre, busca el
  equivalente más cercano y revisa el enlace de la fuente.
- Los tiempos por paso son estimaciones propias, no datos oficiales.
- Este documento no es asesoría legal ni tributaria.
- Complementa a `04-monetizacion-y-politicas.md` y `06-plan-de-accion.md`. Los
  puntos donde los corrige están en la sección 7.

## 1. Cuenta de Google y canal

### 1.1 Cuenta dedicada y tipo de canal

Recomendación: **una cuenta de Google nueva solo para el canal, con un canal
personal dentro de ella, y tu cuenta de siempre invitada con permisos del
canal**. No uses cuenta de marca salvo que la necesites.

| Opción | A favor | En contra |
|---|---|---|
| Canal personal en cuenta dedicada, con permisos del canal | Es lo que YouTube recomienda. Roles finos (administrador, editor, lector). El nombre del canal es libre y no tiene que ser tu nombre. | El propietario no puede transferir la propiedad. Si se borra la cuenta propietaria, se borra el canal. Los invitados no pueden usar la API de YouTube. |
| Cuenta de marca | Permite pasar la propiedad principal a otra cuenta (útil si algún día cedes o vendes el canal). | YouTube pide usarla solo si es necesario. Roles más gruesos. Más errores al vincular AdSense (hay que usar el correo original del canal). |

Fuentes: YouTube dice "Deberías usar los permisos del canal para administrar
el acceso de los usuarios a tu canal" y "Solo usa los roles de las Cuentas de
marca si es necesario"
([cuentas de marca](https://support.google.com/youtube/answer/4628007?hl=es-419));
recomienda migrar a permisos del canal "para evitar riesgos de seguridad, como
el uso compartido de contraseñas"
([ayuda](https://support.google.com/youtube/answer/9367690?hl=es-419)); el
propietario "no puede transferir la propiedad" con permisos del canal
([roles](https://support.google.com/youtube/answer/9481328?hl=es-419)).

Por qué una cuenta dedicada: separa el canal de tu correo personal, y la
revisión de funciones avanzadas mira datos de la cuenta de Google (fecha y
método de creación, frecuencia de uso). Una cuenta recién creada arranca sin
historial, así que conviene crearla cuanto antes y usarla con normalidad
([ayuda](https://support.google.com/youtube/answer/9891124?hl=es-419)).

Consecuencia práctica para la automatización: si más adelante subes videos por
la API de YouTube, la autorización debe hacerse con la cuenta propietaria, no
con la invitada (los invitados "no" pueden usar las API,
[ayuda](https://support.google.com/youtube/answer/9367690?hl=es-419)).

### 1.2 Crear la cuenta de Google

1. En una ventana de incógnito abre `accounts.google.com/signup`.
2. Usa tu nombre real y tu fecha de nacimiento real. Si después verificas tu
   identidad con documento, la fecha de nacimiento debe coincidir con la de la
   cuenta de Google
   ([ayuda](https://support.google.com/youtube/answer/9891124?hl=es-419)).
3. Agrega teléfono y correo de recuperación (tu correo personal).
4. Guarda la contraseña en un gestor de contraseñas.

### 1.3 Verificación en dos pasos (obligatoria para monetizar)

Es requisito del Programa de Socios: "Turn on 2-Step Verification for your
Google Account"
([requisitos](https://support.google.com/youtube/answer/72851?hl=en)).

1. Abre `myaccount.google.com`.
2. Entra a **Seguridad y acceso**.
3. En **Cómo acceder a Google**, elige **Activar la Verificación en 2 pasos**.
4. Configura como mínimo dos métodos: una llave de acceso (passkey) o los
   mensajes de Google en el celular, más una app de autenticación.
5. Descarga los códigos de respaldo y guárdalos fuera del computador.

Google advierte que el SMS es el método menos seguro y que las llaves de acceso
protegen mejor contra el phishing
([ayuda](https://support.google.com/accounts/answer/185839?hl=es-419)). El
robo de canales por phishing es común: no dejes el SMS como único método.

### 1.4 Crear el canal

1. Entra a YouTube con la cuenta nueva, desde un computador.
2. Foto de perfil, luego **Configuración**.
3. En **Cuenta**, elige **Agregar o administrar tus canales**.
4. Haz clic en **Crear un canal**.
5. Pon foto de perfil, nombre e identificador, y haz clic en **Crear canal**.

Fuente: [crear un canal](https://support.google.com/youtube/answer/1646861?hl=es-419).
Si en vez de esto usas **Crear un canal nuevo** desde la lista de canales, se
crea una cuenta de marca (misma fuente). No es lo que buscas.

Nombre del canal: sin "Roblox" ni "Blox" (ver sección 5.4). Se puede cambiar
dos veces cada 14 días
([perfil del canal](https://support.google.com/youtube/answer/2657964?hl=es-419)).

### 1.5 Identificador (handle)

Reglas oficiales
([ayuda](https://support.google.com/youtube/answer/11585688?hl=es-419)):

- Entre 3 y 30 caracteres.
- Letras y números; también guion bajo (_), guion (-), punto (.) y punto
  medio, "pero no al principio ni al final".
- No distingue mayúsculas de minúsculas.
- No puede parecer una URL ni un número de teléfono, ni estar en uso.
- Un solo identificador por canal. No se pueden vender ni transferir.
- "YouTube se reserva el derecho de cambiar, reclamar o quitar identificadores
  en cualquier momento."
- Queda como dirección del canal: `youtube.com/@tuidentificador`.

Cómo cambiarlo: YouTube Studio, **Personalización**, **Perfil**, campo
**Identificador**, **PUBLICAR**. Límite: dos cambios en 14 días
([ayuda](https://support.google.com/youtube/answer/2657964?hl=es-419)).

Consejos (criterio propio): que sea igual o casi igual al nombre del canal,
corto, fácil de dictar en inglés, sin números al final y sin "roblox" ni
"blox". Antes de decidir, revisa que el mismo nombre esté libre en TikTok e
Instagram, porque el plan publica en las tres.

### 1.6 Verificación por teléfono (funciones intermedias)

1. YouTube Studio, **Configuración**, **Canal**, **Elegibilidad de funciones**,
   **Funciones intermedias**, **VERIFICAR NÚMERO DE TELÉFONO**. También sirve
   `youtube.com/verify`.
2. Escribe el número y recibe el código por SMS o llamada.

Datos oficiales:

- "Un número de teléfono solo se puede asociar con 2 canales por año"
  ([ayuda](https://support.google.com/youtube/answer/171664?hl=es-419)). No
  gastes ese cupo en canales de prueba.
- No todos los operadores reciben los mensajes de Google; si el SMS no llega,
  prueba la llamada de voz (misma fuente).

### 1.7 Funciones avanzadas

Los tres niveles
([acceso a funciones](https://support.google.com/youtube/answer/9890437?hl=es-419)):

| Nivel | Cómo se obtiene | Qué da |
|---|---|---|
| Estándar | Al crear el canal, sin faltas activas | Subir videos y Shorts, listas, publicaciones (con límite diario) |
| Intermedio | Verificar el teléfono | Videos de más de 15 minutos, miniaturas personalizadas, transmitir en vivo desde computador, podcasts |
| Avanzado | Teléfono verificado y, además, historial del canal suficiente o verificación de identidad con documento o con video | **Solicitar la monetización**, **video relacionado en un Short**, enlaces en descripciones de videos largos y publicaciones, fijar comentarios, apelar reclamos de Content ID, pruebas A/B, capítulos, límites diarios más altos |

Por qué importa desde el día uno: sin acceso avanzado no puedes solicitar el
Programa de Socios, ni poner el video relacionado en los Shorts (el puente
hacia los videos largos del plan), ni fijar comentarios.

Cómo obtenerlo
([ayuda](https://support.google.com/youtube/answer/9891124?hl=es-419)):

1. YouTube Studio, **Configuración**, **Canal**, **Elegibilidad de funciones**,
   **Funciones avanzadas**, **ACCEDER A FUNCIONES**.
2. Elige una de las opciones que te ofrezca:
   - **Documento de identidad**: te llega un correo o un código QR, lo abres en
     el celular, aceptas las condiciones y fotografías el documento. La
     revisión "suele tardar 24 horas".
   - **Verificación por video**: sigues las indicaciones en pantalla (seguir un
     punto, girar la cabeza). También suele tardar 24 horas.
   - **Historial del canal**: no se pide; se acumula con la actividad del
     canal y de la cuenta. No hay plazo oficial para un canal nuevo. La única
     cifra publicada es para canales que perdieron el acceso: "suelen volver a
     desarrollar suficiente historial del canal en un período de 2 meses".

Notas:

- La verificación con documento o con video "no está disponible para todos los
  creadores". **Sin verificar** si se ofrece a un canal recién creado en
  Colombia: solo se sabe al abrir el menú.
- Solo el propietario principal puede verificarse.
- Los datos del documento o del video se borran en un máximo de 2 años. Si los
  borras antes de consolidar historial, pierdes el acceso avanzado.
- El acceso se puede perder por faltas, spam o faltas de derechos de autor.

### 1.8 Segundo administrador (permisos del canal)

1. YouTube Studio, **Configuración**, **Permisos**, **INVITAR**.
2. Escribe el correo de tu cuenta personal.
3. En **Acceso** elige **Administrador** y haz clic en **LISTO**.
4. Acepta la invitación desde ese correo. Vence a los 30 días.

Roles ([ayuda](https://support.google.com/youtube/answer/9481328?hl=es-419)):

| Rol | Puede | No puede |
|---|---|---|
| Propietario | Casi todo, incluso borrar el canal | Transferir la propiedad |
| Administrador | Ver todo, editar, administrar permisos | Borrar el canal |
| Editor | Editar, subir y publicar | Administrar permisos |
| Editor (limitado) | Lo del editor | Ver ingresos |
| Lector | Ver todo, incluidos ingresos | Editar |
| Lector (limitado) | Ver | Ver ingresos |

A un colaborador futuro (editor de video, por ejemplo) dale **Editor
(limitado)**, nunca la contraseña.

## 2. Configuración inicial en YouTube Studio

### 2.1 Configuración > Canal > Información básica

Fuente: [configuración del canal](https://support.google.com/youtube/answer/2976814?hl=es-419).

| Campo | Qué poner | Por qué |
|---|---|---|
| **País de residencia** | Colombia | La ayuda dice que los criterios de elegibilidad del Programa de Socios dependen de este ajuste. Debe ser el país real: es donde se verifica identidad, dirección y pagos. Poner Estados Unidos no sube el alcance y sí crea un problema con AdSense. |
| **Palabras clave** | 8 a 12 términos en inglés: el género y el formato (por ejemplo `animated stories`, `short stories`, `story animation`, `in this world`, `roblox story`) | La ayuda solo dice que sirven para "agregar palabras clave relacionadas con tu canal". Su peso real en el descubrimiento está **sin verificar**. Evita `kids`, `for kids`, `children`. |

### 2.2 Configuración > Canal > Configuración avanzada

| Campo | Qué poner | Nota |
|---|---|---|
| **Público** | "No, deseo configurar este canal como no creado para niños. Casi nunca subo contenido orientado a un público infantil" | Ver 2.3. |
| **Subtítulos automáticos** | Marcar "No mostrar palabras potencialmente inapropiadas" | Opcional. |
| **Clips** | Dejar marcado "Permitir que los usuarios creen clips con mi contenido" | Ayuda a la difusión. |
| **Entrenamiento de terceros** | Dejar sin marcar | Permite que empresas externas entrenen modelos de IA con tu contenido. Viene desactivado. |
| **Anuncios** (desactivar anuncios por intereses) | No activar | La ayuda advierte que puede reducir los ingresos. |
| **Uso compartido de estadísticas** | Como viene (desactivado) | Solo aplica dentro del Programa de Socios. |

### 2.3 Audiencia: "no es contenido creado para niños"

Dónde: **Configuración**, **Canal**, **Configuración avanzada**, **Público**
(solo en la versión web de Studio), y además en cada subida, en **Público**
([ayuda](https://support.google.com/youtube/answer/9527654?hl=es-419)).

Qué mira la clasificación
([factores](https://support.google.com/youtube/answer/9528076?hl=es-419)):

- El tema del video.
- Si los niños son el público previsto "(es decir, como lo indicas en los
  metadatos del video) o real".
- "Si el video incluye personajes, celebridades o juguetes que puedan ser de
  interés para los niños".
- Si el lenguaje está pensado para niños.
- Canciones, historias o poemas para niños.
- En Estados Unidos, niño es el menor de 13 años.

Dos frases de esa página que pesan en este proyecto:

- El contenido apto para toda la familia o con actividades asociadas a niños
  no es, por eso solo, contenido para niños.
- El contenido de "público mixto" **sí** se trata como creado para niños:
  "incluye a los menores entre su público, aunque no sean el público
  principal".

Es decir: muñecos de Roblox con historias para adolescentes y adultos jóvenes
es defendible como audiencia general, pero la línea es fina y la marcas tú con
los temas, el lenguaje y los metadatos.

Qué se pierde si un video queda como creado para niños
([ayuda](https://support.google.com/youtube/answer/9527654?hl=es-419)):
comentarios, publicidad personalizada, campana de notificaciones, membresías,
Súper chat, marca de agua, tarjetas y pantallas finales, reproducción
automática y guardar en listas. Además, el video relacionado automático de un
Short no se agrega si el Short es creado para niños
([ayuda](https://support.google.com/youtube/answer/14075157?hl=en)).

Qué pasa si YouTube lo reclasifica:

- YouTube usa aprendizaje automático para detectar videos claramente dirigidos
  a niños.
- Si ya habías definido el público y el sistema detecta "un error o abuso", el
  video queda con la marca "Se configuró como creado para niños" y **no puedes
  cambiarla**.
- Apelación: Studio, **Contenido**, pasa el cursor sobre "Se configuró como
  creado para niños", **Apelar**, escribe el motivo, **Enviar**. Solo una
  apelación por video; la respuesta llega por correo.
- Clasificar mal a propósito puede traer problemas con la FTC y medidas sobre
  la cuenta.

Cómo reducir el riesgo: ver 5.2.

### 2.4 Perfil: descripción, enlaces y contacto

Dónde: **Personalización**, **Perfil**, y al final **PUBLICAR**
([ayuda](https://support.google.com/youtube/answer/2657964?hl=es-419)).

| Campo | Qué poner |
|---|---|
| **Descripción** | En inglés, 3 a 5 frases: qué es el canal, que cada historia es original y cómo se hace (guion propio, escenas construidas y animadas por ti, edición propia). Los revisores de monetización leen la sección "Acerca de" ([política](https://support.google.com/youtube/answer/1311392?hl=en)). Agrega una línea de no afiliación, por ejemplo: "This channel is not affiliated with, sponsored or endorsed by Roblox Corporation." (ver 5.4). La ayuda no publica un límite de caracteres. |
| **Enlaces** | Hasta 14. El primero queda destacado junto al botón de suscripción: pon el más importante (TikTok o Instagram al inicio; después, la lista de videos largos). |
| **Información de contacto** | Un correo para asuntos comerciales. Usa uno distinto del correo de acceso a la cuenta. |
| **Foto de perfil** | JPG, PNG, BMP o GIF sin animación, máximo 15 MB; se muestra a 98 × 98 px. Sin el logo de Roblox. |
| **Banner** | Mínimo 2.048 × 1.152 px (16:9), máximo 6 MB. Zona segura para texto y logo: 1.235 × 338 px. Recomendado 2.560 × 1.440 px. |
| **Marca de agua** | Imagen cuadrada, mínimo 150 × 150 px, máximo 1 MB. Elige "Todo el video". |

Medidas de imagen: [ayuda de marca](https://support.google.com/youtube/answer/10456525?hl=es-419).

Sobre la marca de agua: no aparece en videos creados para niños, y en celular
solo se muestra en vista horizontal (misma fuente). **Sin verificar** si se
muestra en el reproductor de Shorts: la ayuda no lo menciona. Sirve para los
videos largos; no esperes efecto en los Shorts.

### 2.5 Configuración predeterminada de carga

Dónde: **Configuración**, **Configuración predeterminada de carga**, pestañas
**Información básica** y **Configuración avanzada**, **Guardar**
([ayuda](https://support.google.com/youtube/answer/2660027?hl=es-419)).

Límite importante: solo aplica a lo que subes desde el navegador. "Si subes
videos desde dispositivos móviles o el editor de video, no se respetará tu
configuración predeterminada."

La ayuda confirma que se pueden predeterminar privacidad, categoría, título,
etiquetas, comentarios e idioma, "entre otros". El detalle de qué campo está en
cada pestaña no se pudo leer en la ayuda (**sin verificar**; revísalo en
pantalla). Valores recomendados:

| Campo | Valor | Motivo |
|---|---|---|
| Título | Vacío | Cada video lleva el suyo. |
| Descripción | Plantilla corta en inglés: una línea de crédito ("Original story written and animated by ..."), la línea de no afiliación con Roblox y 2 o 3 etiquetas (`#shorts #robloxstory #animation`) | Deja constancia de autoría en cada video. |
| Visibilidad | **Privado** | Evita publicar por error; publicas o programas a mano. |
| Etiquetas | 3 a 5 genéricas del formato | Según la ayuda, sirven sobre todo para corregir errores de búsqueda. |
| Idioma del video | Inglés | Activa subtítulos automáticos y traducciones correctas. |
| Categoría | **Cine y animación** o **Entretenimiento** | Criterio propio: evita presentar el canal como juego infantil. No hay dato oficial de que la categoría cambie el alcance (**sin verificar**). |
| Licencia | **Licencia estándar de YouTube** | Creative Commons permite que otros reutilicen tu video. |
| Comentarios | **Activados**, moderación **Estricto** | Ver 2.6. |
| Remixes de Shorts | Permitir | Criterio propio: el remix enlaza al original. Revísalo si aparecen copias. |

### 2.6 Comentarios para un público adolescente

Opciones oficiales
([ayuda](https://support.google.com/youtube/answer/9483359?hl=es-419)):

- Por video: **Activar**, **Pausar** o **Desactivar**.
- **Moderación de comentarios**: **Ninguno**, **Básico**, **Estricto** o
  **Retenerlos todos**. Los retenidos quedan en Studio hasta 60 días.
- **Quién puede comentar**: se puede limitar a **Suscriptores y miembros**, con
  tiempo mínimo de suscripción.
- A nivel de canal: **palabras bloqueadas**, **bloquear comentarios con
  enlaces**, **usuarios ocultos** y **usuarios aprobados**.

Configuración recomendada (criterio propio; YouTube no publica un perfil
específico para adolescentes):

1. Moderación en **Estricto** desde el día uno.
2. **Bloquear comentarios con enlaces**: activado.
3. Lista de **palabras bloqueadas**: insultos comunes en inglés y español,
   términos sexuales, y palabras de contacto (`whatsapp`, `telegram`,
   `discord`, `snap`, `dm me`, `add me`, `robux gratis`, `free robux`).
4. Revisa la cola de retenidos en **Comunidad** una vez al día.
5. Nunca pidas datos personales ni edad en los comentarios.
6. No desactives los comentarios: su ausencia total es justo lo que pasa en el
   contenido para niños, y el formato vive de que la gente proponga reglas.

La ruta exacta para estos ajustes de canal (hoy bajo **Configuración**,
**Comunidad**) está **sin verificar** en la ayuda; puede haber cambiado.

### 2.7 Tráiler, secciones y listas de reproducción

Dónde: **Personalización**, **Pestaña Principal**, bloque "Diseño", **AGREGAR
sección**, y al final **Publicar**
([ayuda](https://support.google.com/youtube/answer/3219384?hl=es-419)).

- **Avance del canal** (tráiler, para quien no está suscrito): no lo llenes el
  primer día. Cuando tengas 5 videos, pon el mejor. Cuando exista el primer
  video largo, cámbialo por ese.
- **Destacado** (para suscriptores): el video largo más reciente.
- **Secciones**: hasta 12. Orden sugerido: 1) Videos cortos, 2) lista de
  videos largos (cuando existan), 3) listas por tema.
- **Listas de reproducción**: una por tema, en inglés (amor y amistad,
  colegio, familia, terror suave, comedia), más una de videos largos. Agrega
  cada video a su lista al subirlo.

## 3. Al subir cada Short

### 3.1 Qué cuenta como Short

Un video subido desde el 15 de octubre de 2024, cuadrado o vertical, de hasta
tres minutos, se clasifica como Short
([ayuda](https://support.google.com/youtube/answer/15424877?hl=en)). Para que
un video quede como video largo debe ir en 16:9.

### 3.2 Campos, en el orden de la pantalla de subida

Flujo en computador: **CREAR**, **Subir videos**
([ayuda](https://support.google.com/youtube/answer/57407?hl=es-419&co=GENIE.Platform%3DDesktop)).

| Campo | Qué hacer |
|---|---|
| **Título** (máx. 100 caracteres) | El campo que más pesa. Según `05-guiones-y-fuentes.md`. Sin "kids". |
| **Descripción** (máx. 5.000) | La plantilla de 2.5 más una frase propia del video. Los enlaces en descripciones y comentarios de Shorts no son clicables ([ayuda](https://support.google.com/youtube/answer/13748639?hl=en)). |
| **Miniatura** | En un Short no se sube imagen; ver 3.4. |
| **Playlist** | La lista del tema. |
| **Público** | "No, no es contenido creado para niños". Confírmalo en cada subida. |
| **Restricción de edad** | No. |
| **Video relacionado** | El video largo que quieras empujar; ver 3.5. |
| **MOSTRAR MÁS**: Contenido de marca | Solo si hay patrocinio. |
| Uso de IA / Contenido alterado | Ver 3.3. |
| Etiquetas | Las predeterminadas más 2 o 3 del tema. |
| Idioma | Inglés. |
| Licencia, distribución | Estándar; permitir incorporación. |
| Remixes de Shorts | Permitir. |
| Categoría | La predeterminada. |
| Comentarios y calificaciones | Activados, moderación Estricto. |
| **Elementos del video**: subtítulos | Opcional. Los subtítulos ya van quemados en la imagen. |
| **Verificaciones** | Espera a que termine la revisión de derechos de autor antes de publicar. Si aparece un reclamo, no publiques (ver 5.3). |
| **Visibilidad** | Ver 3.6. |

### 3.3 Uso de IA (contenido alterado o sintético)

Dónde: en la subida, sección **Atributos**, campo **Uso de IA**, **Sí** o
**No** ([ayuda](https://support.google.com/youtube/answer/14328491?hl=es-419)).
La página de subida todavía lo llama "Contenido alterado"; el rótulo depende de
la versión que te muestre Studio.

Regla: "We require creators to disclose AI-generated or altered content that
seems realistic"
([ayuda en inglés](https://support.google.com/youtube/answer/14328491?hl=en)).

No requiere declaración, según los ejemplos de esa página:

- Contenido claramente irreal, y en concreto animación generada o alterada con
  IA "en un video completamente animado".
- Ayuda de producción: esquema, guion, miniatura, título.
- Subtítulos, mejora o reparación de audio.
- Clonar tu propia voz para voces en off o doblajes.

Sí requiere declaración:

- Hacer que una persona real parezca decir o hacer algo que no hizo.
- Alterar imágenes de un hecho o lugar real, o generar una escena realista que
  no ocurrió.
- **Música generada con IA** cuando es el foco del video.

Aplicación a este canal:

| Caso | Respuesta | Base |
|---|---|---|
| Animación con muñecos, guion asistido por IA | **No** | Ejemplos literales de la ayuda. |
| Voz sintética genérica (ElevenLabs) narrando ficción animada | **No** (interpretación) | La ayuda no menciona voces sintéticas ni texto a voz. El criterio general es que parezca real y pueda confundir; un narrador de ficción animada no lo hace. **Sin verificar** con texto literal. |
| Voz clonada de una persona real distinta de ti | Prohibido en este canal | Cae en "hacer que una persona real parezca decir algo". |
| Pista musical generada con IA | No la uses | Evita la zona de declaración obligatoria. |

Otros datos de la misma página:

- Declarar no limita el público ni la monetización: "Divulgar el contenido
  generado por IA no limitará el público del video ni afectará su elegibilidad
  para obtener ingresos."
- YouTube puede poner la etiqueta por su cuenta si detecta IA o metadatos
  C2PA; llega un aviso en Studio y normalmente se puede corregir.
- No declarar de forma repetida cuando sí toca puede llevar a retirar
  contenido o a la suspensión del Programa de Socios.

### 3.4 Cuadro de portada de un Short

- Se elige un fotograma del propio video; no se sube una imagen aparte.
- "Solo puedes editar la miniatura desde la app de YouTube, no desde Studio."
- Se puede elegir "antes o después de subirlo".

Fuente: [crear Shorts](https://support.google.com/youtube/answer/10343433?hl=es-419).

Cómo hacerlo si subes desde el computador:

1. Sube el Short desde Studio en **Privado**.
2. Abre la app de YouTube en el celular con la cuenta del canal.
3. Ve a tu canal, **Tus videos**, **Más** (tres puntos) en el Short,
   **Editar**.
4. Elige el fotograma y guarda.
5. Vuelve a Studio y programa o publica.

Para que exista un buen fotograma: deja en el montaje un plano de al menos
medio segundo con la regla visible y la cara del personaje, sin subtítulo
encima. Una página antigua de la ayuda decía que la portada personalizada se
podía agregar desde Studio en computador; las vigentes dicen que no. Trátalo
como no disponible.

### 3.5 Video relacionado (del Short a un video largo)

1. Studio, **Contenido**, clic en el Short.
2. En **Video relacionado**, elige un video de tu canal.
3. **GUARDAR**.

Fuente: [ayuda](https://support.google.com/youtube/answer/14075157?hl=es-419).

- Requiere acceso a funciones avanzadas (ver 1.7).
- El video enlazado debe ser público o no listado. Puede ser un video largo,
  otro Short o un directo.
- El espectador ve un enlace clicable debajo del identificador del canal. Es
  el único enlace clicable de un Short.
- Mientras no exista un video largo, enlaza el mejor Short de la misma
  familia. Cuando publiques el primer video largo, actualiza los Shorts con
  más vistas.

### 3.6 Programación

En **Visibilidad**, elige **Programar**, fecha y hora. El video queda privado
hasta ese momento
([ayuda](https://support.google.com/youtube/answer/57407?hl=es-419&co=GENIE.Platform%3DDesktop)).

- Se pueden subir hasta 15 videos a la vez.
- Puedes dejar varios días programados de una sola sentada.
- La mejor hora para la audiencia de Estados Unidos no tiene dato oficial
  (**sin verificar**). Empieza con una hora fija (por ejemplo, 3:00 p. m. hora
  de Colombia, que es la tarde en la costa este) y ajusta con la pestaña
  **Público** de las estadísticas cuando haya datos.

### 3.7 Límite de subidas diarias

- Existe un límite de subidas por canal cada 24 horas, sumando computador,
  celular y API. YouTube **no publica la cifra**: "puede variar según país,
  región o historial del canal"
  ([ayuda](https://support.google.com/youtube/answer/57407?hl=es-419&co=GENIE.Platform%3DDesktop)).
- Si aparece "Alcanzaste el límite diario de cargas", se reintenta a las 24
  horas.
- El acceso avanzado suele tener límites más altos
  ([ayuda](https://support.google.com/youtube/answer/9890437?hl=es-419)).
- Las faltas de derechos de autor y de la comunidad reducen el límite.
- Las cifras que circulan en blogs (10, 15 o 100 videos al día) están **sin
  verificar**. Para este plan (1 video diario como techo) el límite no estorba.

## 4. Monetización paso a paso

### 4.1 Requisitos

| Nivel | Hasta el 31 de enero de 2027 | Desde el 1 de febrero de 2027 (canales nuevos) | Fuente |
|---|---|---|---|
| Financiación de fans (membresías, Super Thanks, Súper chat, Shopping) | 500 suscriptores, **3 subidas públicas válidas en los últimos 90 días**, y 3.000 horas en 12 meses **o** 3 millones de vistas de Shorts en 90 días | Sin cambio, según el blog | [programa ampliado](https://support.google.com/youtube/answer/13429240?hl=es-419), [blog](https://blog.youtube/news-and-events/youtube-partner-program-updates-2027-new-opportunities-earn/) |
| Ingresos por anuncios | 1.000 suscriptores y 4.000 horas en 12 meses **o** 10 millones de vistas de Shorts en 90 días | 1.000 suscriptores y **8.000 horas** en 365 días **o** **20 millones** de vistas de Shorts en 90 días | [requisitos](https://support.google.com/youtube/answer/72851?hl=en), [blog](https://blog.youtube/news-and-events/youtube-partner-program-updates-2027-new-opportunities-earn/) |
| Seguir cobrando por Shorts | Sin piso | **10 millones de vistas de Shorts en los últimos 90 días** | [política de Shorts](https://support.google.com/youtube/answer/12504220?hl=en) |

Confirmación de las cifras de `04`:

- El blog dice: "New creators applying for YPP will need 8,000 qualified watch
  hours in the last 365 days" o 20 millones de vistas de Shorts en 90 días, y
  "This update won't impact creators already in YPP".
- La política de Shorts dice que desde el 1 de febrero de 2027 "you will need
  to have at least 10 million qualified Shorts views in the last 90 days".
- Por debajo del piso, el canal sigue en el programa y cobra por videos largos;
  el reparto de Shorts vuelve solo al superar el piso (blog).
- La página de requisitos (72851) todavía muestra solo las cifras actuales y
  agrega que quienes ya están dentro deben aceptar las condiciones nuevas en
  Studio antes del 31 de enero de 2027.
- Las horas vistas en el feed de Shorts no cuentan para la ruta de horas.
- **Sin verificar**: si para quedar con las cifras actuales basta haber
  solicitado antes del 1 de febrero o hay que estar admitido. El blog no lo
  aclara.

Requisitos que no son de cifras
([lista](https://support.google.com/youtube/answer/72851?hl=en)):

1. Cumplir las políticas de monetización del canal.
2. Vivir en un país donde el programa está disponible. Colombia aparece en la
   lista del programa ampliado
   ([lista](https://support.google.com/youtube/answer/13429240?hl=es-419)).
3. Sin faltas activas de los Lineamientos de la Comunidad.
4. Verificación en dos pasos activada.
5. Acceso a funciones avanzadas.
6. Una cuenta activa de AdSense para YouTube vinculada, o crearla en Studio.

### 4.2 Solicitar el ingreso

1. Mientras no cumplas: Studio, **Ingresos**, **Recibir notificación**.
2. Al cumplir: Studio, **Ingresos**, **Postularse ahora**.
3. **Comenzar** y **Aceptar** las Condiciones Básicas.
4. **Comenzar** para crear o vincular AdSense para YouTube (ver 4.4).
5. El paso de revisión queda "En curso".

Fuente: [ayuda](https://support.google.com/youtube/answer/72851?hl=es-419).

Qué esperar:

- La decisión suele tardar "alrededor de 1 mes". Revisan sistemas automáticos
  y personas, sobre el canal completo.
- Si te rechazan la primera vez: 21 días para apelar, o volver a postularte a
  los 30 días. En rechazos posteriores, 90 días.
- Un canal que pasa 6 meses sin subir ni publicar puede perder la
  monetización.
- Solicita primero el nivel de financiación de fans cuando lo alcances: el
  procedimiento es el mismo y deja lista la cuenta de AdSense.

### 4.3 Aceptar los módulos

Al ser admitido, en **Ingresos** aparecen contratos por separado:

| Módulo | Qué activa | Fuente |
|---|---|---|
| Módulo de monetización de Shorts | Reparto de anuncios y de Premium en el feed de Shorts | [ayuda](https://support.google.com/youtube/answer/12504220?hl=en) |
| Módulo de productos comerciales | Financiación de fans y Shopping | [ayuda](https://support.google.com/youtube/answer/13429240?hl=es-419) |
| Módulo de monetización de páginas de reproducción | Anuncios en videos largos | Nombre **sin verificar** en la ayuda leída |

Acéptalos el mismo día: "Shorts ad revenue sharing will apply to your
channel's eligible Shorts views starting on the date you accept". Las vistas
anteriores a la aceptación no pagan.

Cómo se paga un Short (misma fuente): se junta el dinero de los anuncios del
feed, se reparte según tu proporción de vistas y te quedas con el 45 %. No
pagan las vistas de Shorts no originales, las artificiales ni las de Shorts
que no cumplen las pautas para anunciantes.

### 4.4 AdSense para YouTube desde Colombia

Reglas que conviene saber antes de tocar nada
([ayuda](https://support.google.com/youtube/answer/72866?hl=es-419)):

- La cuenta se crea **solo desde YouTube Studio**. Crearla en
  `google.com/adsense` o `adsense.com` "provoca el rechazo".
- "Solo puedes tener una cuenta de AdSense o AdSense para YouTube con el mismo
  nombre de beneficiario". Si ya tuviste AdSense alguna vez (un blog, otro
  canal), no crees otra: vincula la existente. La duplicada se rechaza.
- La cuenta vinculada solo se puede cambiar "una vez cada 32 días".
- La propiedad de la cuenta no se transfiere.

Pasos:

1. Studio, **Ingresos**, tarjeta **Regístrate en AdSense para YouTube**,
   **COMENZAR**.
2. Vuelve a autenticarte y elige la cuenta de Google. Usa la misma del canal
   (o la que ya tenga tu AdSense).
3. Tipo de cuenta: individual. Nombre: **idéntico al de tu cédula**. Dirección:
   una donde de verdad llegue correo postal en Colombia.
4. Envía. La aprobación "puede tardar varios días".

Verificaciones posteriores:

| Paso | Cuándo | Detalle | Fuente |
|---|---|---|---|
| Identidad | Al llegar a 10 USD de saldo | En AdSense, **Pagos**, **Verificación**. Documento colombiano con foto: cédula de ciudadanía, pasaporte, licencia de conducción o cédula de extranjería. El nombre debe coincidir con el del perfil de pagos. Plazo de 45 días; la revisión tarda hasta 2 días. Mientras tanto hay retención temporal de pagos. | [identidad, Colombia](https://support.google.com/youtube/answer/7568896?hl=es-419&co=GENIE.CountryCode%3DCO) |
| Dirección (PIN) | Después de la identidad, al llegar a 10 USD | Llega por correo postal una carta con un PIN de 6 dígitos; "tarda de 3 a 4 semanas", sin número de seguimiento. Se ingresa en **Pagos**, **Verificación**. Hay 4 meses desde que se genera; si no, se anula la monetización. Tres intentos fallidos también la anulan. A las 3 semanas se puede pedir un PIN de reemplazo. | [PIN](https://support.google.com/youtube/answer/14727844?hl=es-419) |
| Forma de pago | Al llegar a 10 USD | **Pagos**, **Información de pagos**, **Agregar forma de pago**. | [formas de pago](https://support.google.com/youtube/answer/14728152?hl=es-419) |
| Información fiscal | Apenas exista la cuenta | Ver 4.5. | [impuestos](https://support.google.com/youtube/answer/10391362?hl=en) |

Umbrales en dólares
([límites de pago](https://support.google.com/adsense/answer/1709871?hl=es-419)):
verificación de dirección 10 USD, selección de forma de pago 10 USD, **pago
100 USD**, cancelación 10 USD. Esto confirma la cifra que en `04` estaba sin
verificar.

Formas de pago en Colombia, según la tabla oficial
([ayuda](https://support.google.com/youtube/answer/14728152?hl=es-419)):

| Forma | Disponible en Colombia | Tiempo |
|---|---|---|
| Transferencia bancaria internacional | Sí | Hasta 15 días hábiles |
| Hyperwallet | Sí | 1 a 2 días |
| Cheque | Sí | 2 a 4 semanas por correo |
| Transferencia electrónica de fondos (local) | No | No aplica |
| Western Union | Ya no se puede elegir | No aplica |

Tiempos: [procesamiento de pagos](https://support.google.com/youtube/answer/14728151?hl=es-419).

- Para la transferencia, el banco debe estar en el mismo país de la dirección
  del perfil de pagos; si no, no acepta el código SWIFT.
- No se puede cambiar la moneda de pago.
- Calendario: los ingresos del mes se publican entre el 7 y el 12 del mes
  siguiente; el saldo al día 20 debe alcanzar los 100 USD; el pago sale entre
  el 21 y el 26. Si no alcanza, se acumula.
- **Comisiones: sin verificar.** Google no publica comisiones propias. El
  costo real lo ponen el banco receptor (comisión por giro recibido, posible
  banco intermediario, tasa de cambio al monetizar) o Hyperwallet (retiro y
  cambio). Pide a tu banco por escrito el costo de recibir un giro del
  exterior en dólares y los datos que exige (código SWIFT, número de cuenta,
  formulario de cambios). Compara con Hyperwallet con el primer pago.

### 4.5 Formulario fiscal de Estados Unidos (W-8BEN)

Quién: "All monetizing creators on YouTube, regardless of their location in the
world, are required to provide tax info"
([ayuda](https://support.google.com/youtube/answer/10391362?hl=en)).

Qué se retiene:

| Situación | Retención | Sobre qué |
|---|---|---|
| Sin información fiscal enviada | Hasta 24 % | **Todos** los ingresos, de todo el mundo |
| Con W-8BEN, país sin tratado (Colombia) | 30 % | Solo los ingresos generados por **espectadores de Estados Unidos** (anuncios, Premium, Súper chat, Super Thanks, membresías) |
| Con W-8BEN, país con tratado | 0 a 30 % | La misma porción |

Colombia no está en la
[lista de tratados de renta del IRS](https://www.irs.gov/businesses/international-businesses/united-states-income-tax-treaties-a-to-z)
(revisada el 3 de enero de 2026), así que aplica el 30 % sobre la porción de
Estados Unidos. Con un canal en inglés esa porción será alta: tenlo en cuenta
en las cuentas de `04`.

Dónde
([ayuda](https://support.google.com/youtube/answer/10390801?hl=es-419)):

1. Entra a tu cuenta de AdSense para YouTube.
2. **Pagos**, **Información de pago**.
3. **Administrar configuración**.
4. En "Perfil de pagos", editar junto a "Información fiscal de Estados
   Unidos".
5. **Administrar la información fiscal**. Una guía te lleva al formulario
   correcto y genera el PDF.

Cómo responder siendo persona natural residente en Colombia. La ayuda no
publica la lista de preguntas; lo que sigue es el contenido estándar del
formulario W-8BEN, y los rótulos exactos de cada pantalla están **sin
verificar**:

| Pregunta | Respuesta |
|---|---|
| Tipo de cuenta | Persona física (individual) |
| ¿Ciudadano o residente de Estados Unidos? | No |
| Formulario | W-8BEN |
| Nombre | El legal, igual al del perfil de pagos |
| País de ciudadanía | Colombia |
| Número de identificación fiscal extranjero | El NIT de tu RUT. La ayuda de Google no dice cuál número colombiano acepta ("reference your local tax authority"); confírmalo con tu contador. |
| Número fiscal de Estados Unidos (SSN o ITIN) | No tienes; se deja vacío |
| Dirección de residencia permanente | La de Colombia. No uses apartado postal ni una dirección "a cargo de" otra persona. |
| ¿Reclamas beneficio de un tratado? | No. Colombia no tiene tratado. |
| Actividades y servicios en Estados Unidos | No: produces todo desde Colombia y no tienes empleados ni equipos allá |
| Certificación y firma | Tu nombre legal completo |

Datos de la ayuda:

- Revisión: hasta 7 días hábiles. Estados: en revisión, aprobado, rechazado.
- Si marcan tu envío, pueden pedir un documento de identidad (PNG, JPEG, PDF).
- Vigencia: el año del envío más tres años calendario. Se reenvía al vencer o
  si cambian tus circunstancias.
- La retención se ve en el informe de pagos de AdSense, no en YouTube
  Analytics.
- Cada año, a más tardar el 14 de abril, Google emite el formulario 1042-S
  con lo retenido el año anterior. Guárdalo.
- No pongas una dirección de Estados Unidos ni uses VPN al llenarlo: una
  dirección de ese país dispara revisión
  ([preguntas frecuentes](https://support.google.com/adsense/answer/10735961?hl=en)).

Cuándo: el mismo día en que AdSense quede aprobada. `06` lo deja para después
de entrar al programa; si se demora, el riesgo es la retención de hasta 24 %
sobre todo.

### 4.6 Impuestos en Colombia (orientación, no asesoría)

Nada de esta sección se confirmó en una fuente oficial de la DIAN para el caso
concreto de un creador de YouTube. Todo está **sin verificar** y sirve solo
como lista de preguntas para un contador:

1. **RUT**: si ya lo tienes, qué actividad económica y qué responsabilidades
   hay que agregar para recibir ingresos de Google.
2. **Renta**: un residente fiscal colombiano tributa por sus ingresos de
   fuente mundial; los pagos de Google entran en la declaración de renta.
   Pregunta en qué cédula y desde qué monto quedas obligado a declarar.
3. **Retención de Estados Unidos**: pregunta si el 30 % retenido allá (soporte:
   formulario 1042-S) se puede descontar del impuesto en Colombia.
4. **IVA**: el Estatuto Tributario trata como exentos los servicios prestados
   en Colombia y usados exclusivamente en el exterior (artículo 481, literal
   c). Pregunta si aplica a estos ingresos, si te vuelve responsable de IVA y
   si exige inscribirte como exportador de servicios en el RUT y facturar
   electrónicamente a Google.
5. **Cambios**: cómo se registra el ingreso de divisas al recibir el giro.
6. **Soportes**: guarda cada mes el informe de pagos de AdSense, el
   comprobante del banco con la tasa de cambio y el 1042-S anual.

Haz esta consulta antes del primer pago, no después.

## 5. Riesgos que tumban la monetización

### 5.1 Contenido no auténtico, reutilizado o producido en masa

Texto vigente de las
[políticas de monetización del canal](https://support.google.com/youtube/answer/1311392?hl=en)
(última entrada fechada del historial: 15 de julio de 2025, que renombra
"contenido repetitivo" a "contenido no auténtico" para aclarar que "this
includes content that is repetitive or mass-produced"):

- Definición: "Generic or repetitive content includes content that looks like
  it's made with a template".
- No se monetiza: "Videos where characters are put in the same situation over
  and over again with the same outcome".
- No se monetiza: "Image slideshows, templated storylines, or scrolling text
  with minimal or no narrative, commentary, or educational value".
- No se monetiza: "AI-generated content made with generic or unoriginal
  templates".
- Sí se permite: "Same intro and outro for your videos, but the bulk of your
  content is different".
- Sí se permite: "Similar content, like a series following a set of characters
  across episodes".
- Sobre herramientas automáticas y plantillas: se pueden usar si el resultado
  demuestra "your creative vision".
- Contenido reutilizado: "channels that repurpose content that's already on
  YouTube or another online source". Ejemplo no permitido: "Content uploaded
  many times by other creators".

Qué revisan: tema principal, videos más vistos, videos más recientes, la mayor
proporción del tiempo de reproducción, metadatos (títulos, miniaturas,
descripciones) y la sección "Acerca de".

La aclaración de julio de 2026 que cita `04` a partir de prensa no aparece
como entrada fechada en la página oficial (**sin verificar** en fuente
oficial).

Evidencia de originalidad que conviene guardar, por video, desde el primero:

| Evidencia | Dónde |
|---|---|
| Origen de la premisa y las versiones del guion con tus ediciones | Repositorio, con fecha de commit |
| Lista de planos | Repositorio |
| Archivo de proyecto de Roblox Studio (`.rbxl`) o el código de la ruta B | Carpeta del video |
| Grabación cruda antes del montaje | Disco externo o nube |
| Proyecto de montaje y comandos de ffmpeg | Repositorio |
| Licencia o enlace de la pista de música | Bitácora |
| Recibo o registro de la voz (o la grabación de tu voz) | Bitácora |
| Un video corto de pantalla, una vez al mes, mostrando el proceso | Sirve para una apelación en video |

Y en el canal: la descripción cuenta el proceso (2.4), los tipos de final
varían, y no se abre un segundo canal con el mismo material sin adaptarlo.

Si te rechazan por este motivo: apelación dentro de los 21 días con esa
evidencia, o nueva solicitud a los 30 días
([ayuda](https://support.google.com/youtube/answer/72851?hl=es-419)).

### 5.2 Contenido creado para niños

Reglas y consecuencias: ver 2.3. Medidas desde el día uno:

1. Canal y cada video marcados como no creados para niños.
2. Temas de adolescentes y adultos jóvenes: relaciones, amistad, familia,
   colegio, misterio. Nada preescolar.
3. Título, descripción, etiquetas y palabras clave sin `kids`, `for kids`,
   `children`, `toddlers`. Los metadatos son un factor literal de la lista.
4. Sin canciones infantiles ni música de cuna.
5. Vocabulario y conflictos de adolescente, no de niño pequeño.
6. Nada dirigido a niños en la descripción del canal.
7. Si un video queda marcado por YouTube, apela una vez con argumentos
   concretos (tema, público real en estadísticas, lenguaje) y revisa qué tenía
   de distinto antes de subir otro igual.

Además, si el canal tuviera contenido para niños, la monetización de ese
contenido se evalúa con los principios de calidad para contenido infantil y
familiar
([política](https://support.google.com/youtube/answer/1311392?hl=en)).

### 5.3 Reclamos de Content ID en Shorts de más de un minuto

Todos los videos del canal duran más de un minuto, así que esto aplica a
todos.

- "Los Shorts de más de un minuto con reclamos de Content ID activos de
  cualquier tipo, incluidos los manuales," se bloquean a nivel global: no se
  reproducen, no se recomiendan y no son aptos para monetización. No genera
  sanción al canal y se levanta al resolver el reclamo
  ([Shorts de tres minutos](https://support.google.com/youtube/answer/15424877?hl=es-419)).
- La política de monetización dice lo mismo: "Shorts over one minute in length
  that contain claimed content are blocked and not eligible for monetization"
  ([ayuda](https://support.google.com/youtube/answer/12504220?hl=en)).
- Otra página oficial dice lo contrario sobre el bloqueo: "Los Shorts de más
  de un minuto con un reclamo por derechos de autor activo ya no se bloquearán
  automáticamente y es posible que sigan disponibles en YouTube"
  ([crear Shorts](https://support.google.com/youtube/answer/10343433?hl=es-419)).
  Las páginas oficiales se contradicen; cuál está al día queda **sin
  verificar**. En los dos casos el Short reclamado no cobra.

Cómo evitarlo:

1. Solo música de la Biblioteca de audio de YouTube (en Studio) o con licencia
   que cubra uso comercial en YouTube. Guarda el comprobante.
2. La música del selector de sonidos de Shorts tiene tope: lo usual es hasta
   90 segundos en un Short de tres minutos, y algunas pistas solo 60 o 30
   ([ayuda](https://support.google.com/youtube/answer/15424877?hl=en)). No la
   uses en videos de más de un minuto.
3. Sin efectos de sonido ni audios de moda sacados de otros videos.
4. Sube en privado y espera el paso **Verificaciones** antes de programar.
5. Si llega un reclamo equivocado, impúgnalo desde Studio con la licencia. La
   apelación de Content ID exige acceso avanzado (1.7).

### 5.4 Nombre, logo y avatares de Roblox

Textos oficiales leídos el 13 de noviembre de 2026:

| Tema | Qué dice | Fuente |
|---|---|---|
| Logo | "The Roblox Logo and Roblox Tilt are not permitted for general use on any creative materials or copy (unless it's part of the Official Badge)". Su uso se limita a socios elegidos y al programa de influenciadores. | [Pautas de nombre y logo](https://en.help.roblox.com/hc/en-us/articles/115001708126-Roblox-Name-and-Logo-Community-Usage-Guidelines) (editadas el 1 de noviembre de 2026) |
| Nombre | "Roblox", "Blox" y parecidos están prohibidos en títulos de juegos, nombres de usuario, nombres visibles y grupos **dentro de Roblox**. El texto no menciona nombres de canales de YouTube. | Mismas pautas |
| Respaldo | No se puede "Imply official Roblox partnership or endorsement". | Mismas pautas |
| Uso comercial | El nombre, el logo y los "Classic Roblox Avatars" (R6 y R15) no se permiten "on physical products or commercial content" ni atados a productos o servicios ("physical products, packaging, retail displays, services, NFTs, film, TV, books, stage shows or amusement parks") sin licencia. | Mismas pautas |
| Avatares clásicos | Roblox los pone a disposición de los creadores "solely for on-platform use". | Mismas pautas, nota final |
| Contenido de Roblox fuera de la plataforma | "Roblox-Owned Content may not be used outside of the Services unless such use is both (a) expressly authorized by Roblox; and (b) consistent with Roblox's Name and Logo Guidelines." Ese contenido incluye los modelos de avatar. | [Términos de uso](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use), sección 3.4.1, vigentes desde el 1 de noviembre de 2026 |
| Videos monetizados | "You are free to continue using all avatar types in your social media content and you may continue monetizing that content" (por ejemplo con ingresos de anuncios de YouTube). Para una serie de TV o una película con avatares clásicos sí hay que contactar a Roblox. | [FAQ del personal de Roblox, DevForum, 23 de junio de 2022](https://devforum.roblox.com/t/update-to-roblox-licensing-program-brand-guidelines/1843674) |
| Canales con "Roblox" en el nombre | Si una página o canal de fans usa "Roblox" o "Blox", debe decir que no está afiliado a Roblox. | Misma FAQ |

Lectura para este proyecto:

- El permiso expreso para monetizar videos con avatares existe, pero está en
  una FAQ de 2022. Los textos vigentes de 2026 son más restrictivos en su
  letra ("solely for on-platform use", "commercial content") y no repiten ese
  permiso. Las pautas no nombran los videos de YouTube entre los usos
  comerciales prohibidos, y miles de canales monetizan así. **Sin verificar**
  si Roblox mantiene hoy la posición de la FAQ.
- El formato del canal usa justamente muñecos R6, que son "Classic Roblox
  Avatars".

Qué hacer:

1. Nunca el logo de Roblox ni el "Tilt": ni en foto de perfil, ni en banner,
   ni en miniaturas, ni dentro del video.
2. Sin "Roblox" ni "Blox" en el nombre del canal ni en el identificador. Como
   etiqueta y en descripciones (`#roblox`, "Roblox story") es el uso
   descriptivo habitual.
3. Línea de no afiliación en la descripción del canal y en la plantilla de
   descripción de cada video.
4. Guarda una copia en PDF de la FAQ de 2022 y de las pautas vigentes, con
   fecha.
5. Nada de mercancía, libros ni productos con los muñecos sin licencia.
6. Ropa, caras y accesorios de los personajes hechos por ti; no uses artículos
   del catálogo de Roblox ni de otros creadores como rasgo de identidad.
7. Mantén viva la ruta B de `03` (todo en código, con personajes propios): es
   la salida si Roblox cambia de posición.
8. Vuelve a leer las dos páginas cada mes, en la revisión mensual de `06`.

Dato adicional: el programa Roblox Video Stars pide, para contenido corto,
100.000 seguidores y 50.000 vistas promedio en los últimos 6 meses (25.000 en
videos largos), y acepta canales en inglés y en español
([página oficial](https://en.help.roblox.com/hc/en-us/articles/360026092011-Roblox-Video-Stars-Program),
actualizada en diciembre de 2025).

### 5.5 Varios canales con una misma cuenta de AdSense

- Está permitido: "puedes monetizar más de un canal de YouTube con la misma
  cuenta de AdSense para YouTube"
  ([ayuda](https://support.google.com/youtube/answer/72866?hl=es-419)). Y es
  obligatorio en la práctica, porque solo puedes tener una cuenta de AdSense a
  tu nombre.
- El riesgo es que los canales quedan atados entre sí. Si un canal pierde la
  monetización o es cancelado, no puedes crear ni usar otros canales para
  saltarte la restricción, y la medida "may apply to all of your existing
  channels, any new channels you create"
  ([política](https://support.google.com/youtube/answer/1311392?hl=en)). Las
  infracciones pueden suspender la monetización "on all or any of your
  accounts" (misma política).
- Abrir canales adicionales en la misma cuenta de Google exige acceso
  avanzado
  ([ayuda](https://support.google.com/youtube/answer/9890437?hl=es-419)).

Reglas para el canal en español de la fase 3:

1. No lo abras hasta que el primero esté sano y, si es posible, admitido.
2. Que sea una adaptación real: guion localizado, títulos propios, voz en
   español. Un clon traducido de forma automática es justo el patrón de
   "producido en masa".
3. Misma cuenta de AdSense (no hay otra opción legítima), con su propia
   solicitud al programa.
4. Nunca uses la cuenta de AdSense de otra persona ni prestes la tuya: va
   contra las condiciones
   ([ayuda](https://support.google.com/youtube/answer/72866?hl=es-419)).
5. Cualquier falta en un canal pone en riesgo al otro: la lista de calidad de
   `06` aplica igual a los dos.

## 6. Lista de comprobación: día de creación del canal

Tiempos estimados (propios). Total: unas 3 horas, más las esperas.

Antes de sentarte (30 min):

Ya preparado en `canal/` (2026-11-13); solo confirma que te gusta:

- [x] Nombre del canal y dos alternativas, sin "Roblox" ni "Blox":
      Almostville, Rulefolk y OneOddRule (`canal/nombres.md`).
- [ ] Mismo nombre libre como identificador. En YouTube y TikTok estaba
      libre el 2026-11-13; **vuelve a comprobarlo el día que lo crees** y
      revisa Instagram, que no se pudo consultar. (5 min)
- [x] Foto de perfil, banner de 2.560 × 1.440 px y marca de agua de
      150 × 150 px: `canal/imagen/`.
- [x] Descripción del canal, palabras clave, texto del enlace y comentario
      fijado, listos para pegar: `canal/textos-canal.txt`.
- [x] Listas de reproducción con título y descripción: `videos/LISTAS.md`.

Cuenta (25 min):

- [ ] Crear la cuenta de Google dedicada con nombre y fecha de nacimiento
      reales, teléfono y correo de recuperación. (10 min)
- [ ] Activar la verificación en dos pasos con dos métodos y guardar los
      códigos de respaldo. (10 min)
- [ ] Guardar la contraseña en el gestor. (5 min)

Canal (35 min):

- [ ] Crear el canal personal: foto, nombre, identificador. (5 min)
- [ ] Verificar el teléfono (funciones intermedias). (5 min)
- [ ] Abrir **Elegibilidad de funciones**, **Funciones avanzadas** y completar
      la verificación con documento o con video, si se ofrece. Si no, anotar
      la fecha para revisar cada semana. (15 min, más 24 horas de revisión)
- [ ] Invitar tu cuenta personal como **Administrador** y aceptar la
      invitación. (10 min)

Configuración (60 min):

- [ ] **Configuración**, **Canal**, **Información básica**: país Colombia y
      palabras clave. (5 min)
- [ ] **Configuración avanzada**: público "no creado para niños"; subtítulos,
      clips y entrenamiento de terceros según 2.2. (5 min)
- [ ] **Personalización**, **Perfil**: descripción, enlaces, correo de
      contacto, foto, banner y marca de agua; **PUBLICAR**. (20 min)
- [ ] **Configuración predeterminada de carga**: plantilla de descripción,
      visibilidad privada, idioma inglés, categoría, licencia estándar,
      comentarios con moderación estricta. (10 min)
- [ ] Comentarios del canal: bloquear enlaces y cargar la lista de palabras
      bloqueadas. (15 min)
- [ ] Crear las listas de reproducción por tema, vacías. (5 min)

Preparar la monetización (20 min):

- [ ] Studio, **Ingresos**, **Recibir notificación**. (2 min)
- [ ] Revisar si ya existe una cuenta de AdSense a tu nombre. Si existe,
      anotar con qué correo. No crear ninguna por fuera de Studio. (5 min)
- [ ] Confirmar que tu nombre y dirección postal están escritos igual que en
      la cédula y que a esa dirección llega correo. (3 min)
- [ ] Pedir al banco el costo y los requisitos de un giro recibido del
      exterior en dólares. (10 min, respuesta en días)

Cierre (20 min):

- [ ] Instalar la app de YouTube en el celular con la cuenta del canal (se
      necesita para la portada de los Shorts). (5 min)
- [ ] Guardar en PDF las pautas de Roblox y la FAQ de 2022. (5 min)
- [ ] Crear en el repositorio la carpeta de bitácora por video (5.1). (5 min)
- [ ] Anotar en `06` la fecha de creación del canal. (5 min)

Pendientes con fecha:

- [ ] A las 24 horas: confirmar que el acceso avanzado quedó "Habilitada".
- [ ] Con el quinto video: poner el avance del canal y ordenar las secciones.
- [ ] Al llegar a 500 suscriptores, 3 subidas en 90 días y 3 millones de
      vistas de Shorts: postularse, crear AdSense desde Studio y enviar el
      W-8BEN el mismo día.
- [ ] Al llegar a 10 USD de saldo: verificar identidad, esperar el PIN y
      agregar la forma de pago.
- [ ] Antes del primer pago: consulta con el contador (4.6).
- [ ] Antes del 31 de enero de 2027, si ya estás dentro: aceptar las
      condiciones nuevas en Studio.

## 7. Qué cambia frente a `04` y `06`

| Tema | Lo que decían | Lo que dice la fuente oficial |
|---|---|---|
| Nivel de financiación de fans | 500 suscriptores y 3 millones de vistas, o 3.000 horas | Además exige 3 subidas públicas válidas en los últimos 90 días ([ayuda](https://support.google.com/youtube/answer/13429240?hl=es-419)) |
| Derechos de Roblox | Permitido según la FAQ de 2022 | Los términos del 1 de noviembre de 2026 y las pautas vigentes restringen los avatares R6 y R15 a uso dentro de la plataforma y prohíben el "commercial content" sin licencia; el permiso de 2022 no se repite (5.4) |
| Roblox Video Stars | 100 mil seguidores y 50 mil vistas, "según terceros" | Confirmado en la página oficial; acepta español (5.4) |
| Mínimo de pago | 100 USD, sin verificar | Confirmado: 100 USD; verificación y forma de pago desde 10 USD (4.4) |
| W-8BEN | Enviarlo en la fase 4, después de entrar | Enviarlo al crear AdSense; sin él, hasta 24 % sobre todos los ingresos (4.5) |
| Etiqueta de IA | "No hay una exención literal" para animación | Sí hay ejemplo literal: animación con IA en un video completamente animado no se declara. La voz sintética sigue sin mención (3.3) |
| Content ID en Shorts largos | Quedan bloqueados | Dos páginas oficiales lo confirman y una tercera dice que ya no se bloquean automáticamente; en todos los casos no cobran (5.3) |
| Política de contenido no auténtico | Aclarada en julio de 2026 | La página oficial no tiene entrada fechada en 2026; la última es del 15 de julio de 2025 (5.1) |
| Video relacionado en cada Short | Se da por disponible | Requiere acceso a funciones avanzadas, que un canal nuevo no tiene por defecto (1.7) |
| Solicitar antes del 1 de febrero | "Solicitar de inmediato para quedar con las reglas actuales" | El blog no aclara si cuenta la fecha de solicitud o la de admisión; la revisión tarda cerca de un mes (4.1, 4.2) |
| Hecho para niños | "Zona gris" | El contenido de público mixto se trata como creado para niños, y si YouTube marca un video no se puede cambiar; una sola apelación (2.3) |

## 8. Lo que quedó sin verificar

- Si la verificación con documento o video para funciones avanzadas se ofrece
  a un canal nuevo en Colombia, y cuánto tarda el historial en un canal nuevo.
- Si la fecha que cuenta para las reglas de 2027 es la de solicitud o la de
  admisión.
- Tratamiento de la voz sintética en la política de uso de IA (no hay texto
  literal).
- Cuál de las páginas oficiales sobre el bloqueo de Shorts reclamados está al
  día.
- La aclaración de julio de 2026 de la política de contenido no auténtico, en
  fuente oficial.
- Si Roblox mantiene el permiso de 2022 para monetizar videos con avatares
  clásicos frente a sus términos de noviembre de 2026.
- Cifra del límite diario de subidas.
- Peso real de las palabras clave del canal y de la categoría.
- Si la marca de agua se muestra en Shorts.
- Campos exactos de cada pestaña de la configuración predeterminada de carga y
  ruta exacta de los ajustes de comentarios del canal.
- Nombre exacto del módulo de anuncios en videos largos.
- Rótulos exactos de las pantallas del formulario W-8BEN y qué número fiscal
  colombiano acepta Google.
- Comisiones bancarias y de Hyperwallet en Colombia.
- Toda la sección de impuestos en Colombia (4.6).
- Mejor hora de publicación.
