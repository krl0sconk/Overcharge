extends Node

@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	print("Vida inicial: ", health.current_health)

	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)

	health.take_damage(30)
	print("Después del daño: ", health.current_health)

	health.heal(20)
	print("Después de curar: ", health.current_health)

	health.take_damage(100)
	print("Después del daño mortal: ", health.current_health)

	health.heal(20)
	print("Después de curar estando muerto: ", health.current_health)


func _on_damaged(amount: int) -> void:
	print("Señal damaged recibida. Daño: ", amount)


func _on_died() -> void:
	print("Señal died recibida")
