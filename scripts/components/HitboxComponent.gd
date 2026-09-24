class_name HitboxComponent
extends Area3D

signal hit(target:Area3D, damage:int, knockback:Vector3, source:Node3D)
@export var stats: StatsResource
@export var knockback_strength: float = 0.0  ## 0 = sin empujón
@export var source:Node3D

var _hit_this_window: Array[Area3D] = []

func _ready() -> void:
	if stats == null:
		push_error("StatsResource no asignado en HitboxComponent")
		return

	area_entered.connect(_on_area_entered)

func _on_area_entered(area:Area3D) -> void:
	_apply_hit(area)

func _apply_hit(area: Area3D) -> void:
	if area in _hit_this_window:
		return
	_hit_this_window.append(area)

	var damage = stats.damage
	var impulse: Vector3 = knockback_vector(area.global_position)
	if area.has_method("receive_hit"):
		area.receive_hit(damage, impulse, source)

	hit.emit(area, damage, impulse, source)

## Empuje calculado desde la posición de source hacia el punto golpeado
## (aplanado a XZ), no un vector fijo -- así funciona sin importar hacia
## dónde mire este hitbox. Necesario para Centinela: el cuerpo no gira al
## disparar, solo el brazo, así que un vector local fijo empujaría siempre
## para el mismo lado.
func knockback_vector(target_position: Vector3) -> Vector3:
	if knockback_strength <= 0.0 or source == null:
		return Vector3.ZERO
	var dir: Vector3 = target_position - source.global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized() * knockback_strength

## Abre la ventana de golpe por su cuenta: la hoja que la pide puede ser
## interrumpida y el hitbox se apaga igual.
## Reencender monitoring solo dispara area_entered para solapamientos
## NUEVOS -- si el objetivo ya estaba adentro sin moverse (quieto, a
## distancia de ataque), Godot no vuelve a emitir el enter y ese golpe se
## perdía en silencio (por eso el primer golpe de un enemigo conectaba y
## los siguientes no). Por eso también se consultan las áreas ya
## superpuestas después de esperar un frame de física.
func open_window(duration: float) -> void:
	monitoring = true
	_hit_this_window.clear()
	await get_tree().physics_frame
	for area in get_overlapping_areas():
		_apply_hit(area)
	await get_tree().create_timer(duration).timeout
	monitoring = false
