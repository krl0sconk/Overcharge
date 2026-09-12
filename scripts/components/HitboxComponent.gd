class_name HitboxComponent
extends Area3D

signal hit(target:Area3D, damage:int, knockback:Vector3, source:Node3D)
@export var stats: StatsResource
@export var knockback:Vector3 = Vector3.ZERO
@export var source:Node3D

func _ready() -> void:
	if stats == null:
		push_error("StatsResource no asignado en HitboxComponent")
		return

	area_entered.connect(_on_area_entered)

func _on_area_entered(area:Area3D) -> void:
	var damage = stats.damage
	if area.has_method("receive_hit"):
		area.receive_hit(damage, knockback, source)
	
	hit.emit(area, damage, knockback, source)

## Abre la ventana de golpe por su cuenta: la hoja que la pide puede ser
## interrumpida y el hitbox se apaga igual.
func open_window(duration: float) -> void:
	monitoring = true
	await get_tree().create_timer(duration).timeout
	monitoring = false
