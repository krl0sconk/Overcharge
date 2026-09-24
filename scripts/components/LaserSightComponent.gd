class_name LaserSightComponent
extends Node3D

## Sigue la posición y dirección lógica de apuntado de percept cada frame en
## vez de ser hijo directo del brazo -- así no depende de habilitar "editable
## children" sobre el modelo importado de Blockbench, y usa la misma
## dirección corregida (aim_forward) que el raycast de RangedAttack, no la
## rotación cruda del mesh.
## Por eso mover el Transform de este nodo en el editor no sirve de nada:
## se pisa todos los frames. Para reubicar la punta del cañón, usá
## muzzle_offset (Inspector, nodo LaserSight) en vez del gizmo 3D.
##
## Tres capas de feedback, de menor a mayor compromiso:
## - aim_line: hilo fino y tenue, visible todo el tiempo que hay un
##   objetivo trabado (blackboard["target"]) -- el enemigo "te tiene en la
##   mira" aunque todavía no vaya a disparar. Toma su color de
##   EmissiveStateComponent.current_color en vez de tener uno fijo propio,
##   así combina con el cuerpo (blanco en "recarga", azul en "activo") en
##   vez de quedar siempre celeste sin importar el estado.
## - beam_mesh durante el telegraph (begin_telegraph): arranca como un
##   brillo chico en la punta del cañón y crece de grosor con un Tween
##   hasta el momento del disparo -- el "se pone grande al lockear". Se
##   queda en ámbar a propósito: solo aparece durante "firing", que ya es
##   el momento en que el cuerpo también está en alerta (amarillo).
## - beam_mesh en fire(): el disparo real, grosor completo estirado hasta
##   el punto de impacto.
##
## beam_mesh también lleva ruido temporal sobre su color base, igual que
## el cuerpo (EmissiveStateComponent) -- nada de esto debería verse como
## un LED sólido y quieto.

@export var percept: PerceptComponent
@export var emissive_state: EmissiveStateComponent  ## opcional: si está, aim_line sigue su color de estado
@export var telegraph_particles: GPUParticles3D
@export var beam_particles: GPUParticles3D
@export var beam_mesh: MeshInstance3D  ## cilindro ya orientado hacia -Z local
@export var aim_line: MeshInstance3D   ## mismo cilindro, versión fina y tenue

@export var beam_duration: float = 0.25
@export var muzzle_offset: Vector3 = Vector3.ZERO  ## relativo a la dirección de apuntado: x=derecha, y=arriba, z=atrás
@export var aim_line_length: float = 6.0
@export var aim_line_alpha: float = 0.35  ## tenue a propósito: es un hilo guía, no el disparo
@export var telegraph_grow_duration: float = 0.5  ## debe rondar el telegraph_duration de RangedAttack
@export var telegraph_charge_length: float = 0.35  ## largo del brillo en la punta del cañón mientras carga
@export var telegraph_charge_thickness: float = 1.6  ## grosor final relativo al del disparo (1.0)
@export var noise_speed: float = 5.0
@export_range(0.0, 1.0) var noise_strength: float = 0.25

var _beam_timer: float = 0.0
var _telegraphing: bool = false
var _grow_tween: Tween
var _aim_line_material: StandardMaterial3D
var _beam_material: StandardMaterial3D
var _beam_base_albedo: Color
var _beam_base_emission: Color
var _noise := FastNoiseLite.new()

func _ready() -> void:
	_noise.seed = randi()
	if aim_line != null:
		aim_line.visible = false
		## Sin duplicar, todos los Centinelas compartirían este material y
		## teñirían su hilo de puntería juntos -- mismo motivo que
		## EmissiveStateComponent con material_1.
		var base_material: Material = aim_line.mesh.surface_get_material(0)
		if base_material is StandardMaterial3D:
			_aim_line_material = base_material.duplicate()
			_aim_line_material.emission_enabled = true  ## defensivo: un resave del editor puede pisar este flag en el .tres
			aim_line.set_surface_override_material(0, _aim_line_material)
	if beam_mesh != null:
		beam_mesh.visible = false
		## Mismo motivo: material_override hoy es el StandardMaterial3D_beam
		## compartido en la escena -- sin duplicar, todos los Centinelas
		## titilarían en fase y cambiarían de color juntos.
		var beam_base: Material = beam_mesh.material_override
		if beam_base is StandardMaterial3D:
			_beam_material = beam_base.duplicate()
			_beam_material.emission_enabled = true
			_beam_base_albedo = _beam_material.albedo_color
			_beam_base_emission = _beam_material.emission
			beam_mesh.material_override = _beam_material

func _process(delta: float) -> void:
	if percept != null:
		global_position = percept.aim_position()
		look_at(global_position + percept.aim_forward(), Vector3.UP)
		if muzzle_offset != Vector3.ZERO:
			global_position += global_transform.basis * muzzle_offset

	_update_aim_line()
	_update_beam_flicker()

	if _beam_timer <= 0.0:
		return
	_beam_timer -= delta
	if _beam_timer <= 0.0 and beam_mesh != null:
		beam_mesh.visible = false

func _update_beam_flicker() -> void:
	if _beam_material == null or beam_mesh == null or not beam_mesh.visible:
		return
	var n: float = _noise.get_noise_1d(Time.get_ticks_msec() / 1000.0 * noise_speed)
	var mult: float = 1.0 + n * noise_strength
	_beam_material.albedo_color = Color(_beam_base_albedo.r * mult, _beam_base_albedo.g * mult, _beam_base_albedo.b * mult, _beam_base_albedo.a)
	_beam_material.emission = Color(_beam_base_emission.r * mult, _beam_base_emission.g * mult, _beam_base_emission.b * mult, _beam_base_emission.a)

func _update_aim_line() -> void:
	if aim_line == null:
		return
	var has_target: bool = percept != null and percept.blackboard.get("target") != null
	aim_line.visible = has_target and not _telegraphing and _beam_timer <= 0.0
	if not aim_line.visible:
		return

	aim_line.scale.y = aim_line_length
	aim_line.position = Vector3(0.0, 0.0, -aim_line_length * 0.5)

	if _aim_line_material != null and emissive_state != null:
		var color: Color = emissive_state.current_color
		color.a = aim_line_alpha
		_aim_line_material.albedo_color = color
		_aim_line_material.emission = emissive_state.current_color

func begin_telegraph() -> void:
	_telegraphing = true
	if telegraph_particles != null:
		telegraph_particles.emitting = true
	if beam_mesh == null:
		return

	beam_mesh.visible = true
	beam_mesh.scale = Vector3(1.0, telegraph_charge_length, 1.0)
	beam_mesh.position = Vector3(0.0, 0.0, -telegraph_charge_length * 0.5)

	if _grow_tween != null:
		_grow_tween.kill()
	_grow_tween = create_tween()
	_grow_tween.set_parallel(true)
	_grow_tween.tween_property(beam_mesh, "scale:x", telegraph_charge_thickness, telegraph_grow_duration)
	_grow_tween.tween_property(beam_mesh, "scale:z", telegraph_charge_thickness, telegraph_grow_duration)

func end_telegraph() -> void:
	_telegraphing = false
	if telegraph_particles != null:
		telegraph_particles.emitting = false

func fire(distance: float) -> void:
	end_telegraph()
	if _grow_tween != null:
		_grow_tween.kill()
		_grow_tween = null

	if beam_particles != null:
		beam_particles.restart()
		beam_particles.emitting = true
	if beam_mesh != null:
		beam_mesh.visible = true
		beam_mesh.scale = Vector3(1.0, distance, 1.0)
		beam_mesh.position = Vector3(0.0, 0.0, -distance * 0.5)
	_beam_timer = beam_duration
