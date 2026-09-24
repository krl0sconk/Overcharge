class_name DeathDissolveComponent
extends Node

## Desaparición "digital" al morir: el modelo titila (glitch) unas pocas
## veces, se encoge, y suelta una ráfaga de cubos de píxeles propios del
## enemigo. Lo dispara EnemyDeathComponent llamando a play() -- este nodo
## no escucha HealthComponent directamente para no adelantarse a
## EnemyDeathComponent, que es quien decide cuándo el enemigo ya murió de
## verdad.
## despawn_delay en EnemyDeathComponent debe ser al menos tan largo como
## esta animación (glitch + shrink_duration) o el queue_free corta la
## desaparición a la mitad.

@export var model: Node3D
@export var particles: GPUParticles3D
@export var glitch_flickers: int = 4
@export var glitch_interval: float = 0.05
@export var shrink_duration: float = 0.3

func play() -> void:
	if particles != null:
		particles.restart()
		particles.emitting = true
	_glitch_and_shrink()

func _glitch_and_shrink() -> void:
	if model == null:
		return
	for i in glitch_flickers:
		model.visible = false
		await get_tree().create_timer(glitch_interval * 0.4, true, false, true).timeout
		model.visible = true
		await get_tree().create_timer(glitch_interval * 0.6, true, false, true).timeout

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "scale", Vector3.ZERO, shrink_duration)
