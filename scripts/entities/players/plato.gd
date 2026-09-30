class_name Plato
extends Entidad

## Controlador de Pl4-to: se mueve y ataca a distancia con el proyectil.

@export var turn_speed: float = 10.0  ## rad/s
@onready var return_ability_component: AbilityComponent = get_node_or_null("ReturnAbilityComponent")

@onready var animation_tree: AnimationTree = get_node_or_null("AnimationTree")
@onready var animation_playback: AnimationNodeStateMachinePlayback = (
	animation_tree.get("parameters/playback") if animation_tree else null
)
## Ajusta esta ruta según dónde quedó el AnimationPlayer (Copy Node Path).
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

const MOVE_THRESHOLD: float = 0.1

## Secuencia del combo de disparo: cada ataque avanza a la siguiente.
const SHOOT_COMBO: Array[String] = ["shoot1", "shoot2", "doubleshoot"]
var _combo_index: int = 0

## Multiplicador de velocidad por animación. 1.0 = velocidad normal.
const ANIMATION_SPEED: Dictionary = {
	"shoot1": 4,
	"shoot2": 4,
	"doubleshoot": 4,
}

var _was_moving: bool = false

func _physics_process(delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	if input_component.aim_lock:
		movement_component.set_move_direction(Vector3.ZERO)
	else:
		movement_component.set_move_direction(input_component.move_dir)
	_face_move_direction(delta)
	_update_move_animation()

	if input_component.consume_attack():
		if ability_component != null:
			ability_component.try_execute()
		_play_next_combo_shot()
	
	if input_component.consume_return():
		if return_ability_component != null:
			return_ability_component.try_execute()

	if input_component.consume_emote():
		_play_emote()

func _update_move_animation() -> void:
	if animation_playback == null:
		return

	var is_moving: bool = input_component.move_dir.length() > MOVE_THRESHOLD

	if is_moving and not _was_moving:
		_travel_to("walkstart")
	elif not is_moving and _was_moving:
		_travel_to("idle")

	_was_moving = is_moving

func _play_next_combo_shot() -> void:
	if animation_playback == null:
		return

	var shot_name: String = SHOOT_COMBO[_combo_index]
	_travel_to(shot_name)
	_combo_index = (_combo_index + 1) % SHOOT_COMBO.size()

func _play_emote() -> void:
	if animation_playback == null:
		return
	_travel_to("emote")

## Centraliza el travel() para que siempre se aplique la velocidad correcta
## (o 1.0 si la animación no tiene un multiplicador definido).
func _travel_to(state_name: String) -> void:
	if animation_player != null:
		animation_player.speed_scale = ANIMATION_SPEED.get(state_name, 1.0)
	animation_playback.travel(state_name)

## Mismo criterio que TurnToTarget.gd: +PI porque el modelo mira +Z, no -Z.
func _face_move_direction(delta: float) -> void:
	var direction: Vector3 = input_component.move_dir
	if direction == Vector3.ZERO:
		return
	var target_yaw: float = atan2(direction.x, direction.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
