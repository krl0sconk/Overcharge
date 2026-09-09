extends Node3D

@onready var attacker: Node3D = $Atacante
@onready var hitbox: HitboxComponent = $Atacante/HitboxComponent
@onready var health: HealthComponent = $Objetivo/HealthComponent


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	hitbox.hit.connect(_on_hit)

	print("Vida inicial: ", health.current_health)

	await get_tree().create_timer(1.0).timeout
	attacker.position.x = 0.0


func _on_hit(
	target: Area3D,
	damage: int,
	knockback: Vector3,
	source: Node3D
) -> void:
	print("Hitbox detectó: ", target.name)
	print("Daño enviado: ", damage)


func _on_damaged(amount: int) -> void:
	print("Target recibió daño: ", amount)
	print("Vida actual: ", health.current_health)


func _on_died() -> void:
	print("Target murió")
