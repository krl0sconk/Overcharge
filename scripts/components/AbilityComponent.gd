class_name AbilityComponent
extends Node

enum State {
	READY,
	ACTIVE,
	COOLDOWN
}

@export var ability: Ability
@export var owner_body: CharacterBody3D
@export var movement_component: MovementComponent

var state: State = State.READY
var cooldown_remaining: float = 0.0
var duration_remaining: float = 0.0

func try_execute() -> void:
	if state != State.READY and not (state == State.ACTIVE and ability.can_chain):
		return
	if state == State.READY:
		state = State.ACTIVE
		duration_remaining = ability.duration
		movement_component.movement_enabled = false
	ability.execute(owner_body, movement_component.move_direction) #Sujeto a cambios

func _process(delta: float) -> void:
	if state == State.ACTIVE:
		duration_remaining -= delta
		ability.update(delta)
		
		if duration_remaining <= 0.0:
			if ability.is_finished(): 
				state = State.COOLDOWN
				cooldown_remaining = ability.cooldown
				movement_component.movement_enabled = true #Sujeto a cambios
			else:
				duration_remaining = ability.duration			
	elif state == State.COOLDOWN:
		cooldown_remaining -= delta

		if cooldown_remaining <= 0.0:
			cooldown_remaining = 0.0
			state = State.READY
		
