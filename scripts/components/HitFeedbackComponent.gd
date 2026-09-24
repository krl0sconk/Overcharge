class_name HitFeedbackComponent
extends Node

## Feedback de golpe: flash blanco del modelo, freeze-frame breve, sacudida
## de cámara y una ráfaga de partículas opcional. Se activa solo con la
## señal `damaged` del HealthComponent, así que funciona igual para
## jugador y enemigos -- hit_particles es lo único que cambia por enemigo.

@export var health_component: HealthComponent
@export var model: Node3D  ## raíz del modelo visual; se buscan sus MeshInstance3D
@export var flash_duration: float = 0.08
@export var flash_color: Color = Color(1.0, 1.0, 1.0)
@export var hit_pause_duration: float = 0.05
@export var hit_pause_scale: float = 0.05
@export var shake_strength: float = 0.15
@export var shake_duration: float = 0.15
@export var hit_particles: GPUParticles3D  ## opcional: ráfaga de partículas propia de cada enemigo

var _mesh_instances: Array[MeshInstance3D] = []
var _original_overrides: Array = []  ## por mesh, materiales originales por superficie

## Compartido entre todas las instancias: si dos golpes se solapan, el
## freeze-frame no vuelve a tiempo normal hasta que el último termine.
static var _pause_requests: int = 0

func _ready() -> void:
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
	if model != null:
		_collect_meshes(model)

func _collect_meshes(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			var overrides: Array = []
			for i in child.mesh.get_surface_count():
				overrides.append(child.get_surface_override_material(i))
			_mesh_instances.append(child)
			_original_overrides.append(overrides)
		_collect_meshes(child)

func _on_damaged(_amount: int) -> void:
	_flash()
	_hit_pause()
	_shake_camera()
	if hit_particles != null:
		hit_particles.restart()
		hit_particles.emitting = true

func _flash() -> void:
	if _mesh_instances.is_empty() or flash_duration <= 0.0:
		return

	var flash_material := StandardMaterial3D.new()
	flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash_material.albedo_color = flash_color

	for mesh_instance in _mesh_instances:
		for i in mesh_instance.mesh.get_surface_count():
			mesh_instance.set_surface_override_material(i, flash_material)

	await get_tree().create_timer(flash_duration, true, false, true).timeout

	for idx in _mesh_instances.size():
		var mesh_instance: MeshInstance3D = _mesh_instances[idx]
		if not is_instance_valid(mesh_instance):
			continue
		var overrides: Array = _original_overrides[idx]
		for i in overrides.size():
			mesh_instance.set_surface_override_material(i, overrides[i])

func _hit_pause() -> void:
	if hit_pause_duration <= 0.0:
		return

	_pause_requests += 1
	Engine.time_scale = hit_pause_scale
	## ignore_time_scale=true: si no, el freeze-frame se alargaría solo por
	## haber bajado el time_scale que él mismo puso.
	await get_tree().create_timer(hit_pause_duration, true, false, true).timeout
	_pause_requests = max(_pause_requests - 1, 0)
	if _pause_requests == 0:
		Engine.time_scale = 1.0

## No hay guardas contra sacudidas solapadas de la misma cámara -- para el
## juego (nunca son tantos golpes seguidos sobre la misma cámara) el drift
## que dejaría no se nota, y evita cablear coordinación entre instancias.
func _shake_camera() -> void:
	if shake_duration <= 0.0:
		return

	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var original_position: Vector3 = camera.position
	var start_usec: int = Time.get_ticks_usec()

	while is_instance_valid(camera):
		var elapsed: float = (Time.get_ticks_usec() - start_usec) / 1_000_000.0
		if elapsed >= shake_duration:
			break
		var falloff: float = 1.0 - elapsed / shake_duration
		camera.position = original_position + Vector3(
			randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0
		) * shake_strength * falloff
		await get_tree().process_frame

	if is_instance_valid(camera):
		camera.position = original_position
