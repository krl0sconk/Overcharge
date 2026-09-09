class_name ChargeForward
extends PerceptNode

## Rama 2 del Yunque, a propósito con prioridad alta: mientras "charging" esté
## activo no se reconsidera nada más, así el jugador lo puede engañar contra
## una pared. Si no está cargando, no aplica (FAILURE).

# TODO(María): reemplazar los duck-types set_move_direction/stop/hit_wall por MovementComponent.

func tick(agent: PerceptComponent) -> Status:
	if not agent.blackboard.get("charging", false):
		return Status.FAILURE

	var movement: Node = agent.movement_component
	if movement != null and movement.get("hit_wall") == true:
		if movement.has_method("stop"):
			movement.stop()
		agent.blackboard["charging"] = false
		agent.blackboard["stunned"] = true
		return Status.SUCCESS

	var direction: Vector3 = agent.blackboard.get("charge_direction", Vector3.ZERO)
	if movement != null and movement.has_method("set_move_direction"):
		movement.set_move_direction(direction)

	return Status.RUNNING
