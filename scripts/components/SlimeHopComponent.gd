class_name SlimeHopComponent
extends Node

## Rebote tipo gel para enemigos sin animación de caminata propia: mientras el
## MovementComponent tenga dirección de movimiento, hace saltar y aplastar
## (squash & stretch) el modelo visual. Solo anima ese nodo, nunca el
## CharacterBody3D real, para no desalinear hitbox/hurtbox con el salto.

@export var model: Node3D
@export var movement_component: MovementComponent
@export var hop_height: float = 0.3
@export var hops_per_second: float = 2.5
@export var squash_amount: float = 0.25  ## 0..1: cuánto se achata al tocar el suelo y se estira en el aire

var _phase: float = 0.0
var _base_position: Vector3
var _base_scale: Vector3

func _ready() -> void:
	_base_position = model.position
	_base_scale = model.scale

func _process(delta: float) -> void:
	if model == null or movement_component == null:
		return

	var bounce: float = absf(sin(_phase))
	var moving: bool = movement_component.move_direction != Vector3.ZERO
	if moving or bounce > 0.001:
		_phase = fmod(_phase + hops_per_second * PI * delta, TAU)
		bounce = absf(sin(_phase))
	else:
		_phase = 0.0

	model.position = _base_position + Vector3.UP * bounce * hop_height

	## el volumen se conserva a ojo: se estira en el punto más alto, se
	## achata al tocar el suelo.
	var vertical: float = 1.0 + squash_amount * (2.0 * bounce - 1.0)
	var horizontal: float = 1.0 / sqrt(vertical)
	model.scale = Vector3(_base_scale.x * horizontal, _base_scale.y * vertical, _base_scale.z * horizontal)
