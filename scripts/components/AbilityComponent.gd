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

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

func _exit_tree() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)

func try_execute() -> void:
	if state != State.READY and not (state == State.ACTIVE and ability.can_chain):
		return
	if state == State.READY:
		state = State.ACTIVE
		duration_remaining = ability.duration
		movement_component.movement_enabled = false
	ability.execute(owner_body, movement_component.move_direction) # Sujeto a cambios

func _on_enemy_died(killer: Node) -> void:
	if killer == owner_body:
		return

	reset_cooldown()

func reset_cooldown() -> void:
	if state != State.COOLDOWN:
		return

	cooldown_remaining = 0.0
	state = State.READY

## Corta la habilidad ya mismo. Quien llama decide cuándo es seguro (ej.
## después de la ventana comprometida del golpe): acá no se vuelve a chequear
## duration_remaining porque en un combo se congela en 0 después del primer
## golpe y ya no sirve para saber si el golpe actual sigue en curso.
func try_cancel() -> void:
	if state != State.ACTIVE:
		return
	ability.cancel()

func _physics_process(delta: float) -> void:
	if state == State.ACTIVE:
		if duration_remaining > 0.0:
			duration_remaining -= delta
		ability.update(delta)

		## duration_remaining es un mínimo, no un ciclo de polling: una vez
		## cumplido, is_finished() se chequea todos los frames en vez de
		## esperar a que se reagote, para no dejar al jugador congelado de
		## más mientras la habilidad ya terminó.
		if duration_remaining <= 0.0 and ability.is_finished():
			state = State.COOLDOWN
			cooldown_remaining = ability.cooldown
			movement_component.movement_enabled = true # Sujeto a cambios
	elif state == State.COOLDOWN:
		cooldown_remaining -= delta

		if cooldown_remaining <= 0.0:
			cooldown_remaining = 0.0
			state = State.READY
