# Contexto de la conversación

Todo lo que el chat del primer equipo sabía y que no está en el código.

| Archivo | Qué es | Cuándo leerlo |
|---|---|---|
| `HISTORIAL.md` | Resumen curado: qué se pidió, qué se hizo, qué se decidió y qué nunca se probó | Siempre, al empezar |
| `memoria.md` | La nota de memoria del proyecto y las preferencias permanentes del usuario | Al empezar; guárdala en tu memoria |
| `conversacion.md` | La conversación completa: mensajes del usuario, respuestas del asistente, herramientas usadas e informes de los subagentes | Solo para buscar el detalle de una decisión |
| `transcripcion-cruda/` | Los archivos de sesión originales de Claude Code, sin sanear: la conversación principal (`.jsonl`), una por cada subagente (`subagents/`) y dos resultados largos de herramientas (`tool-results/`). 60 MB | Último recurso; busca dentro, no los abras enteros |
| `exportar_chat.py` | El script que generó `conversacion.md` desde el archivo de sesión de Claude Code | Si quieres exportar otra sesión |

La transcripción cruda se publicó por decisión expresa del dueño del
repositorio el 2026-11-13, sabiendo que contiene su correo, su nombre de
usuario de Windows e identificadores del primer equipo. Se revisó antes que no
tuviera claves ni tokens.

`conversacion.md` está saneada: no trae el correo, el nombre de usuario de
Windows, identificadores del equipo ni el resultado crudo de las
herramientas. Tampoco los avisos internos del sistema. Los mensajes repetidos
de "Stop hook feedback" son avisos automáticos de la función de objetivos de
Claude Code, no texto del usuario.

Para exportar otra sesión:

```powershell
python contexto\exportar_chat.py "$env:USERPROFILE\.claude\projects\CARPETA-DEL-PROYECTO\ID-DE-SESION.jsonl" contexto\conversacion-2.md
```
