class_name HitboxComponent
extends Area3D

signal hit(target:Area3D, damage:int, knockback:Vector3, source:Node3D)
@export var damage:int = 1
@export var knockback:Vector3 = Vector3.ZERO
@export var source:Node3D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area:Area3D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage, knockback, source)
	
	hit.emit(area, damage, knockback, source)
