class_name HurtboxComponent
extends Area3D

signal hit_received(damage:int, knockback:Vector3, source:Node3D)
@export var health_component: HealthComponent
@export var movement_component: MovementComponent

func receive_hit(damage:int, knockback:Vector3, source:Node3D) -> void:
	if health_component == null:
		return

	if movement_component != null:
		movement_component.apply_knockback(knockback)
	# Antes de take_damage: si el golpe mata, EnemyDeathComponent necesita
	# haber guardado el killer que llega en este mismo hit_received.
	hit_received.emit(damage, knockback, source)
	health_component.take_damage(damage)
