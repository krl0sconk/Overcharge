class_name ProjectileAbility
extends Ability

@export var projectile_speed: float = 10.0
@export var projectile_scene: PackedScene

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	print("Proyectil ejecutado")	
	#Se agregará el bloque de código una vez se tenga Projectile.tscn
