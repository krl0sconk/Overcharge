class_name PlayerStub
extends CharacterBody3D

## Stub mínimo para probar el árbol del Yunque. Sin habilidades ni vida:
## solo se mueve con WASD y sirve de objetivo para AcquireTarget. No usa
## InputComponent a propósito: es descartable, no forma parte del jugador real.

@export var speed: float = 4.0

func _physics_process(_delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1.0

	velocity = input_dir.normalized() * speed if input_dir != Vector3.ZERO else Vector3.ZERO
	move_and_slide()
