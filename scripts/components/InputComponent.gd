class_name InputComponent
extends Node

@export var device_id: int = 0

var move_dir: Vector3 = Vector3.ZERO
var wants_attack: bool = false
var wants_dash: bool = false

var _move_left: float = 0.0
var _move_right: float = 0.0
var _move_up: float = 0.0
var _move_down: float = 0.0


func _input(event: InputEvent) -> void:
	if event.device != device_id:
		return
	
	if event.is_action_pressed("move_right"):
		_move_right = 1.0

	if event.is_action_released("move_right"):
		_move_right = 0.0
		
	if event.is_action_pressed("move_left"):
		_move_left = 1.0

	if event.is_action_released("move_left"):
		_move_left = 0.0

	if event.is_action_pressed("move_up"):
		_move_up = 1.0

	if event.is_action_released("move_up"):
		_move_up = 0.0

	if event.is_action_pressed("move_down"):
		_move_down = 1.0

	if event.is_action_released("move_down"):
		_move_down = 0.0
		
	if event.is_action_pressed("attack"):
		wants_attack = true
	
	if event.is_action_pressed("dash"):
		wants_dash = true
		

	var input_vector := Vector2(
		_move_right - _move_left,
		_move_down - _move_up
	).limit_length(1.0)

	move_dir = Vector3(
			input_vector.x,
			0.0,
			input_vector.y
		)
	

func consume_attack() -> bool:
	if not wants_attack: 
		return false

	wants_attack = false
	return true


func consume_dash() -> bool:
	if not wants_dash:
		return false

	wants_dash = false
	return true
