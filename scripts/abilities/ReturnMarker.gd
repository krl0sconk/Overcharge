class_name ReturnMarker
extends Node3D

@export var spin_speed: float = 2.0

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
