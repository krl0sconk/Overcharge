class_name ReturnNodeAbility
extends Ability

var return_position: Vector3 = Vector3.ZERO
var has_return_position: bool = false

func execute(owner_body: CharacterBody3D, direction: Vector3) -> void:
	if not has_return_position:
		return_position = owner_body.global_position
		has_return_position = true
		print("Nodo de retorno guardado: ", return_position)
	else:
		owner_body.global_position = return_position
		has_return_position = false
		print("Regresando al nodo: ", return_position)
		
