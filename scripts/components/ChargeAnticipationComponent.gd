class_name ChargeAnticipationComponent
extends Node

## Puesta en escena del embiste del Yunque, leída directo del blackboard del
## PerceptComponent (telegraphing/charging/stunned): se agacha y se comprime
## al telegrafiar, se lanza hacia adelante con un golpe al arrancar la carga,
## se inclina y tiembla mientras carga, y da un culatazo si choca contra la
## pared. Solo anima el modelo visual, nunca el CharacterBody3D real.

@export var model: Node3D
@export var percept: PerceptComponent
@export var coil_tilt_deg: float = 12.0     ## se echa hacia atrás al telegrafiar
@export var coil_squash: float = 0.18       ## cuánto se achata al telegrafiar
@export var charge_lean_deg: float = 10.0   ## inclinación hacia adelante mientras carga
@export var charge_stretch: float = 0.12    ## estiramiento hacia adelante mientras carga
@export var rumble_deg: float = 2.5         ## temblor aleatorio mientras carga
@export var kick_tilt_deg: float = 18.0     ## golpe extra al lanzar la carga o al chocar
@export var kick_squash: float = 0.25       ## golpe extra de escala al lanzar o chocar
@export var pose_lerp_speed: float = 10.0
@export var kick_decay: float = 6.0

var _base_scale: Vector3
var _tilt: float = 0.0
var _squash: float = 1.0
var _kick: float = 0.0
var _was_charging: bool = false

func _ready() -> void:
	if model != null:
		_base_scale = model.scale

func _process(delta: float) -> void:
	if model == null or percept == null:
		return

	var telegraphing: bool = percept.blackboard.get("telegraphing", false)
	var charging: bool = percept.blackboard.get("charging", false)
	var stunned: bool = percept.blackboard.get("stunned", false)

	if charging and not _was_charging:
		_kick = -1.0  ## arranca la carga: lanzón hacia adelante
	elif _was_charging and not charging and stunned:
		_kick = 1.0  ## se estrelló: culatazo hacia atrás
	_was_charging = charging

	var target_tilt: float = 0.0
	var target_squash: float = 1.0
	if telegraphing:
		target_tilt = deg_to_rad(coil_tilt_deg)
		target_squash = 1.0 - coil_squash
	elif charging:
		target_tilt = -deg_to_rad(charge_lean_deg) + deg_to_rad(rumble_deg) * randf_range(-1.0, 1.0)
		target_squash = 1.0 + charge_stretch

	var pose_t: float = clampf(pose_lerp_speed * delta, 0.0, 1.0)
	_tilt = lerp(_tilt, target_tilt, pose_t)
	_squash = lerp(_squash, target_squash, pose_t)
	_kick = move_toward(_kick, 0.0, kick_decay * delta)

	model.rotation.x = _tilt + _kick * deg_to_rad(kick_tilt_deg)
	var final_squash: float = clampf(_squash - _kick * kick_squash, 0.4, 1.8)
	var stretch_inv: float = 1.0 / sqrt(final_squash)
	model.scale = Vector3(_base_scale.x * stretch_inv, _base_scale.y * final_squash, _base_scale.z * stretch_inv)
