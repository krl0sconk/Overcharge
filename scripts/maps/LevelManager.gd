extends Node

## Número total de "espacios" de nivel en el mapa.
const TOTAL_LEVELS: int = 3

## Cuántos están desbloqueados. 1 = solo el primero.
var unlocked_count: int = 1

func is_unlocked(level_index: int) -> bool:
	return level_index < unlocked_count

func complete_level(level_index: int) -> void:
	if level_index + 1 >= unlocked_count:
		unlocked_count = min(level_index + 2, TOTAL_LEVELS)

func select_level(level_index: int) -> void:
	if not is_unlocked(level_index):
		return
	print("Nivel seleccionado: ", level_index, " (todavía no hay escena asignada)")
