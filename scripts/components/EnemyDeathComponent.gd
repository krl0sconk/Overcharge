class_name EnemyDeathComponent
extends Node

## Despawnea al enemigo cuando muere. No va en Entidad: la muerte del
## jugador no despawnea, se revive.

@export var health_component: HealthComponent
@export var hurtbox: HurtboxComponent
@export var hitbox: HitboxComponent
@export var owner_body: Node3D
@export var despawn_delay: float = 0.3

var _killer: Node

func _ready() -> void:
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)
	health_component.died.connect(_on_health_died)

func _on_hurtbox_hit_received(_damage: int, _knockback: Vector3, source: Node3D) -> void:
	_killer = source

func _on_health_died() -> void:
	## set_deferred: esto corre dentro del propio callback de área de la
	## física (area_entered -> receive_hit -> take_damage -> died), y
	## Godot no deja tocar monitoring/monitorable en caliente ahí.
	if hitbox != null:
		hitbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	EventBus.enemy_died.emit(_killer)
	await get_tree().create_timer(despawn_delay).timeout
	owner_body.queue_free()
