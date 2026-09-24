class_name Projectile
extends Area3D

@export var speed: float = 10.0
@export var stats: StatsResource
@export var knockback: Vector3 = Vector3.ZERO

var direction: Vector3 = Vector3.ZERO
var source: Node3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(new_direction: Vector3) -> void:
	direction = new_direction.normalized()
	if direction != Vector3.ZERO:
		## looking_at() alinea -Z con el target; el largo de la cápsula
		## (ver transform del MeshInstance3D) queda en +Z, así que se le
		## pasa -direction para que +Z termine apuntando a direction.
		basis = Basis.looking_at(-direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(_body: Node3D) -> void:
	queue_free()

## Mismo patrón que HitboxComponent: el golpe se resuelve contra el Hurtbox
## (Area3D), no contra el cuerpo físico.
func _on_area_entered(area: Area3D) -> void:
	if stats != null and area.has_method("receive_hit"):
		area.receive_hit(stats.damage, knockback, source)
	queue_free()

