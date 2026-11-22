# DoesItDiePlus (con dos correcciones)

Esta carpeta es una **copia modificada** de [UsefulPlatesAndTooltips](https://www.curseforge.com/wow/addons/doesitdieplus), de Ironship (versión 0.9.140). No es la versión oficial: la oficial está en ese enlace.

Licencia: GPL-3.0-or-later (archivo LICENSE); el módulo SpellDamageInfo, además, MIT (Modules/SpellDamageInfo/LICENSE-SpellDamageInfo.txt). Esta copia se distribuye bajo la misma licencia.

## Qué se ha cambiado (hugofpinho)

- 2026-11-21 — `Modules/SpellDamageInfo/Estimate.lua` y `Core.lua`: en WoW Forever (1.60 o más) ya no suma el poder con hechizos al daño del tooltip. La descripción de los hechizos de Forever ya lo lleva sumado, y el addon lo contaba dos veces (una Descarga de las Sombras de 272-286 salía como 419-433).
- 2026-11-21 — `Modules/StatsInfo/BagMarkers.lua`: la flecha verde de mejora «de reserva» (cuando el addon no sabe puntuar el cambio) solo sale si el objeto no pierde ninguna estadística. Antes marcaba como mejora objetos que el propio tooltip daba por peores.

Los cambios están marcados en el código con «Cambio local». Todo lo demás es el addon original.

Si lo instalas con CurseForge, al actualizarse se sustituye por la versión oficial, sin estas correcciones.
