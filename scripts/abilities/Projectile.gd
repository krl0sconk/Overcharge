class_name Projectile
extends Area3D

@export var speed: float = 10.0

var direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(new_direction: Vector3) -> void:
	direction = new_direction.normalized()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	queue_free()
	
