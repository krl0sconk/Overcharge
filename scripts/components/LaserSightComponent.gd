class_name LaserSightComponent
extends Node3D

## Sigue la posición y dirección lógica de apuntado de percept cada frame en
## vez de ser hijo directo del brazo -- así no depende de habilitar "editable
## children" sobre el modelo importado de Blockbench, y usa la misma
## dirección corregida (aim_forward) que el raycast de RangedAttack, no la
## rotación cruda del mesh.

@export var percept: PerceptComponent
@export var telegraph_particles: GPUParticles3D
@export var beam_particles: GPUParticles3D
@export var beam_mesh: MeshInstance3D  ## cilindro ya orientado hacia -Z local
@export var beam_duration: float = 0.25

var _beam_timer: float = 0.0

func _ready() -> void:
	if beam_mesh != null:
		beam_mesh.visible = false

func _process(delta: float) -> void:
	if percept != null:
		global_position = percept.aim_position()
		look_at(global_position + percept.aim_forward(), Vector3.UP)

	if _beam_timer <= 0.0:
		return
	_beam_timer -= delta
	if _beam_timer <= 0.0 and beam_mesh != null:
		beam_mesh.visible = false

func begin_telegraph() -> void:
	if telegraph_particles != null:
		telegraph_particles.emitting = true

func end_telegraph() -> void:
	if telegraph_particles != null:
		telegraph_particles.emitting = false

func fire(distance: float) -> void:
	end_telegraph()
	if beam_particles != null:
		beam_particles.restart()
		beam_particles.emitting = true
	if beam_mesh != null:
		beam_mesh.visible = true
		beam_mesh.scale.y = distance
		beam_mesh.position = Vector3(0.0, 0.0, -distance * 0.5)
	_beam_timer = beam_duration
