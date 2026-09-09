class_name HurtboxComponent
extends Area3D

signal hit_received(damage:int, knockback:Vector3, source:Node3D)
@export var health_component: HealthComponent

func receive_hit(damage:int, knockback:Vector3, source:Node3D) -> void:
	if health_component == null:
		return
	
	health_component.take_damage(damage)
	hit_received.emit(damage, knockback, source)
