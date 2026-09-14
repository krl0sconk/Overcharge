class_name Plato
extends Entidad

## Controlador de Pl4-to: mueve y ataca con lo que ya tiene cableado.
## TODO(quien le ponga la habilidad): todavía no tiene AbilityComponent en
## la escena, así que no hay dash ni combo que enlazar acá.

@export var attack_window: float = 0.2

func _physics_process(_delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	movement_component.set_move_direction(input_component.move_dir)

	if input_component.consume_attack() and hitbox_component != null:
		hitbox_component.open_window(attack_window)
