class_name ComboAbility
extends Ability

var current_hit: int = 0
var chain_remaining: float = 0.0
var combo_finished: bool = false

@export var max_hits: int = 3
@export var chain_window: float = 0.5

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	combo_finished = false
	
	print("Combo golpe: ", current_hit + 1)

	chain_remaining = chain_window

	if current_hit < max_hits - 1:
		current_hit += 1
	else:
		current_hit = 0
		combo_finished = true

func update(delta: float) -> void:
	if chain_remaining > 0.0:
		chain_remaining -= delta

		if chain_remaining <= 0.0:
			chain_remaining = 0.0
			current_hit = 0
			combo_finished = false

func is_finished() -> bool:
	return combo_finished
