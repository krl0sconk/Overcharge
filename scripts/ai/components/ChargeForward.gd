class_name ChargeForward
extends PerceptNode

## Rama 2 del Yunque, a propósito con prioridad alta: mientras "charging" esté
## activo no se reconsidera nada más, así el jugador lo puede engañar contra
## una pared. Si no está cargando, no aplica (FAILURE).

func tick(agent: PerceptComponent) -> Status:
	if not agent.blackboard.get("charging", false):
		_release(agent)
		return Status.FAILURE

	var movement: MovementComponent = agent.movement_component
	if movement != null and movement.hit_wall:
		movement.stop()
		agent.blackboard["charging"] = false
		agent.blackboard["stunned"] = true
		_release(agent)
		return Status.SUCCESS

	var direction: Vector3 = agent.blackboard.get("charge_direction", Vector3.ZERO)
	if movement != null:
		movement.set_move_direction(direction)

	_carry(agent, movement)

	return Status.RUNNING

func _carry(agent: PerceptComponent, movement: MovementComponent) -> void:
	var carried: MovementComponent = agent.blackboard.get("carried_movement")

	if carried == null:
		carried = _find_target(agent)
		if carried == null:
			return
		agent.blackboard["carried_movement"] = carried
		carried.movement_enabled = false
		if movement != null and movement.owner_body != null and carried.owner_body != null:
			movement.owner_body.add_collision_exception_with(carried.owner_body)
			carried.owner_body.add_collision_exception_with(movement.owner_body)

	if movement != null and carried.owner_body != null:
		carried.owner_body.velocity = movement.owner_body.velocity

func _find_target(agent: PerceptComponent) -> MovementComponent:
	if agent.hitbox == null:
		return null
	for area in agent.hitbox.get_overlapping_areas():
		if area is HurtboxComponent and area.movement_component != null:
			return area.movement_component
	return null

func _release(agent: PerceptComponent) -> void:
	var carried: MovementComponent = agent.blackboard.get("carried_movement")
	if carried == null:
		return

	carried.movement_enabled = true
	var movement: MovementComponent = agent.movement_component
	if movement != null and movement.owner_body != null and carried.owner_body != null:
		movement.owner_body.remove_collision_exception_with(carried.owner_body)
		carried.owner_body.remove_collision_exception_with(movement.owner_body)
	agent.blackboard.erase("carried_movement")
