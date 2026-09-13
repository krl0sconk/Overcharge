class_name CorruptionBlotComponent
extends Area3D

## Mancha de corrupción que suelta el Virus al moverse. Daño periódico (no
## area_entered) a lo que tenga encima mientras dure, para no premiar
## quedarse parado sobre el borde un instante; se autodestruye sola.

@export var damage: int = 1
@export var damage_interval: float = 1.0
@export var lifetime: float = 5.0

func _ready() -> void:
	var damage_timer := Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.timeout.connect(_on_damage_timeout)
	add_child(damage_timer)
	damage_timer.start()

	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _on_damage_timeout() -> void:
	for area in get_overlapping_areas():
		if area.has_method("receive_hit"):
			area.receive_hit(damage, Vector3.ZERO, null)
