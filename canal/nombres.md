# Nombres del canal: candidatos y disponibilidad

Comprobado el 2026-11-13. **La disponibilidad es la de ese día.** Un identificador
libre puede dejar de estarlo en cualquier momento (el nicho se está llenando: de
72 nombres en inglés probados, 44 ya tenían canal). Si te decides por uno, crea el canal
y reserva el identificador cuanto antes, y vuelve a comprobarlo justo antes.

## Cómo se comprobó

| Dato | Método | Qué tan confiable es |
|---|---|---|
| YouTube (comprobación 1) | Petición a `https://www.youtube.com/@Nombre` con cookie de consentimiento, leyendo el contenido: 404 es libre; página con `channelId` es ocupado. | Alta. Controles: `@YouTube` y `@studby` salieron ocupados y una cadena al azar salió libre. |
| YouTube (comprobación 2) | `yt-dlp --flat-playlist --playlist-items 1` sobre la misma dirección: error 404 es libre. | Alta. Coincidió con la primera en los 25. |
| TikTok | Punto de acceso público `oembed` con el usuario en minúsculas: 200 con autor es que existe; 400 es que no aparece. | Orientativa. Una cuenta privada o suspendida puede dar 400. Controles: `nasa` existe, cadena al azar no. |
| Instagram | No se pudo comprobar: Instagram respondió 429 (límite de peticiones) o un muro de inicio de sesión. | Sin dato. Revísalo a mano en la app. |
| Dominio `.com` | `Resolve-DnsName nombre.com -Type NS`. Con servidores de nombres es que está registrado; "no existe" sugiere que está libre. | Orientativa. Un dominio registrado sin DNS se vería libre. |
| Marcas y canales grandes | Búsqueda web de los finalistas (Almostville, Rulefolk, OneOddRule, Rulemoor, Bylawville, Oddbylaw). | Orientativa. No se consultó ningún registro oficial de marcas (USPTO, EUIPO, SIC). |

Un 404 en YouTube tampoco es garantía total: YouTube puede tener reservado un
identificador de un canal eliminado. Solo se sabe con certeza al intentar
registrarlo.

Ningún candidato contiene "Roblox", "Rblx", "Blox", "R6" ni el nombre de un
canal líder.

## Los 25 candidatos en inglés

| # | Nombre | YouTube | TikTok | Instagram | .com | Comentario |
|---|---|---|---|---|---|---|
| 1 | Almostville | Libre (404 en las dos comprobaciones) | No aparece | Sin comprobar | Registrado | Un pueblo donde todo es casi normal. Sin marca ni canal conocido en la búsqueda. |
| 2 | Rulefolk | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | "La gente de la regla". Libre en todo lo que se pudo medir. |
| 3 | OneOddRule | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Describe el formato. Se parece a "One Rule Tales" (34,5 mil suscriptores) y a "The Odd Rule" (canal mínimo). |
| 4 | Rulemoor | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Suena a pueblo inglés; "moor" es menos conocido para público joven. |
| 5 | Otherwick | Libre (404 x2) | Existe | Sin comprobar | Parece libre | Bonito, pero no dice "regla" y el usuario de TikTok ya está tomado. |
| 6 | Bylawville | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Gracioso, pero "bylaw" es difícil de escribir. |
| 7 | Oddbylaw | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Mismo problema de ortografía. |
| 8 | Wishlaw | Libre (404 x2) | No aparece | Sin comprobar | Registrado | Corto; suena a bufete de abogados. |
| 9 | Ruleshire | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Suena a condado; correcto, poco memorable. |
| 10 | Ruleford | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Parece apellido. |
| 11 | Rulestead | Libre (404 x2) | Existe | Sin comprobar | Registrado | Tomado en TikTok y dominio. |
| 12 | Rulemere | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Pronunciación dudosa. |
| 13 | Oddmoor | Libre (404 x2) | No aparece | Sin comprobar | Registrado | Doble "d" y doble "o": fácil de escribir mal. |
| 14 | Townlaw | Libre (404 x2) | Existe | Sin comprobar | Registrado | Suena a firma legal. |
| 15 | BylawTown | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Ortografía difícil. |
| 16 | StrangeBylaws | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Largo. |
| 17 | RuleAndTwist | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Explica la fórmula, pero suena a nombre de coctel. |
| 18 | TheTownRule | Libre (404 x2) | Existe (lo usa una cuenta llamada "oddtown") | Sin comprobar | Parece libre | Posible competidor en TikTok. |
| 19 | RulebookTown | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Claro, algo largo. |
| 20 | OddlyTown | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Fácil, pero genérico. |
| 21 | TinyRuleTales | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | "Tiny" y "Tales" tiran a infantil (riesgo de "hecho para niños"). |
| 22 | SquareheadTales | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | "Squarehead" es un insulto antiguo en inglés. Descartado. |
| 23 | EveryTownHasARule | Libre (404 x2) | No aparece | Sin comprobar | Parece libre | Demasiado largo como nombre; sirve como lema. |
| 24 | RuleTown | **Ocupado** (canal "Rule Town", 26 suscriptores) | Existe | Sin comprobar | Registrado | Era la opción obvia. Ya no está. |
| 25 | OneRuleTales | **Ocupado** (canal "One Rule Tales", 34,5 mil suscriptores) | No aparece | Sin comprobar | Parece libre | Canal activo del mismo nicho. Evitar nombres muy parecidos. |

Otros 42 nombres que se probaron y ya tenían canal en YouTube (descartados):
OneRuleTown, OddRuleTown, InThisTown, Rulewick, Ruleburg, Rulebrook, Oddhollow,
TheOddRule, TownOfRules, StrangeRuleTown, WhatIfTown, NoSuchTown, Quirkville,
Fablewick, PocketFables, CubeFables, BlockyFables, OddlawTown, Nowhereville,
OddTownTales, ImpossibleTown, OddRuleTales, OnlyOneRule, Rulehaven, Rulewood,
Oddbury, Rulebury, Fablemoor, Whimtown, Elsewick, TwistTown, Oddvale, Unrule,
OddOrdinance, Twistwick, Oddwick, Rulenook, HollowRule, Mapleverse,
PlotTwistTown, Wishbrook, OneRuleWorld.

## Recomendación: los 3 mejores

1. **Almostville.** Es el más memorable y el único que suena a lugar con
   personalidad: un pueblo "casi" normal, que es exactamente la premisa. Se
   pronuncia y se escribe sin dudas, no contiene palabras de terceros, sirve
   para frases de marca ("Welcome to Almostville", "Only in Almostville") y da
   un universo común a los videos largos y a las recopilaciones. No tira a
   infantil. Tiene traducción natural para el canal hermano (Casipueblo).
   En contra: `almostville.com` ya está registrado (servidores de IONOS), así
   que el dominio tendría que ser otro (por ejemplo `.tv` o `.video`), y la
   palabra no dice "regla" por sí sola: la frase "In this world..." tiene que
   acompañarla siempre.
2. **Rulefolk.** Corto (8 letras), libre en YouTube, TikTok y aparentemente en
   `.com`, sin resultados de marca en la búsqueda. Pone el foco en la gente que
   vive bajo la regla, que es donde está la emoción del formato. En contra: es
   más frío y menos visual que Almostville, y "folk" puede sonar a música.
3. **OneOddRule.** Es el que mejor explica el formato y el más fácil de
   encontrar por búsqueda. Libre en YouTube, TikTok y aparentemente en `.com`.
   En contra: comparte dos palabras con "One Rule Tales" (34,5 mil
   suscriptores, mismo nicho) y con "The Odd Rule"; hay riesgo real de
   confusión y de parecer un imitador. Por eso va de tercero.

Las imágenes de `imagen/` están generadas con **Almostville**.

## Canal hermano en español: 10 candidatos

Para estos solo se hizo la primera comprobación de YouTube (petición directa).

| # | Nombre | YouTube | Comentario |
|---|---|---|---|
| 1 | Casipueblo | Libre (404) | Traducción directa de Almostville. Recomendado. |
| 2 | VillaCasi | Libre (404) | Variante con sabor de nombre de pueblo. |
| 3 | CasiVilla | Libre (404) | Igual, en otro orden. |
| 4 | PuebloCasi | Libre (404) | Menos natural. |
| 5 | Reglopolis | Libre (404) | Va bien con Rulefolk u OneOddRule. |
| 6 | Raropolis | Libre (404) | Divertido; no dice "regla". |
| 7 | UnaReglaRara | Libre (404) | Equivalente de OneOddRule. |
| 8 | LaReglaRara | Libre (404) | Igual, con artículo. |
| 9 | PuebloConRegla | Libre (404) | Claro, algo largo. |
| 10 | CuentosConRegla | Libre (404) | Describe el contenido; "cuentos" tira un poco a infantil. |

Probados y ocupados: Casilandia, VillaRegla, Reglandia.

## Antes de registrar

- Vuelve a abrir `https://www.youtube.com/@Nombre` desde un navegador.
- Revisa Instagram a mano.
- Busca el nombre en el registro de marcas de Estados Unidos (USPTO) y en la
  SIC de Colombia, en las clases de entretenimiento (41) y ropa (25).
- Lee las pautas de nombre y logo de Roblox vigentes (cambiaron el 2026-11-01:
  prohíben "Roblox", "Blox" y parecidos en el nombre).
