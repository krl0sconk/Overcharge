# Overcharge

Dungeon crawler cooperativo top-down para dos jugadores, hecho en Godot 4.

Dos robots descienden por una red social que se volvió física. El screentime es el puntaje.

**Estructura de Datos II — Universidad del Norte**

## Equipo

| Integrante | Área |
| --- | --- |
| Krlos | IA y behavior trees |
| María S | Controladores de personajes |
| Miguel.E | Generación de niveles y pathfinding |
| Mafe | Red, UI/UX y accesibilidad |

## Antes de escribir código

Leé [`AGENTS.md`](AGENTS.md). Tiene la arquitectura de componentes, las capas de colisión,
la convención de nombres y el flujo de ramas. Las decisiones de ahí están acordadas por el
equipo y no se cambian sin avisar.

## Estructura

Organizada por **tipo de archivo primero, categoría después**. Jugadores y enemigos van dentro
de `entities/` porque heredan de `Entidad`.

```
assets/       arte y audio         → entities/players, entities/enemies, maps, ui, audio, fonts
scenes/       archivos .tscn       → entities/players, entities/enemies, maps/rooms, ui
scripts/      archivos .gd         → entities, components, abilities, ai, maps, ui, autoload
resources/    archivos .tres       → stats, abilities
```

Un mismo elemento se reparte entre carpetas. Usá siempre el mismo nombre base en todas:
`centinela.gd`, `centinela.tscn`, `centinela_stats.tres`.
