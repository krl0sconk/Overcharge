class_name TurnToTarget
extends PerceptNode

## Genérica y reusable: gira el actor hacia el objetivo del blackboard.
## En el árbol del Yunque se reutiliza tal cual en dos ramas: "me
## flanquearon" (gateada por IsTargetBehind) y "buscar línea" (rama por
## defecto, sin gate). Al ser un Resource sin estado propio, la misma
## instancia se puede compartir entre ambas ramas.

@export var turn_speed: float = 6.0  ## rad/s
@export var aligned_epsilon: float = 0.02  ## rad

func tick(agent: PerceptComponent) -> Status:
	var target: Node = agent.blackboard.get("target")
	if target == null or not is_instance_valid(target) or not (agent.actor is Node3D) or not (target is Node3D):
		return Status.FAILURE

	var actor3d: Node3D = agent.actor as Node3D
	var to_target: Vector3 = (target as Node3D).global_position - actor3d.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Status.SUCCESS

	var desired_yaw: float = atan2(to_target.x, to_target.z) + PI
	var current_yaw: float = actor3d.rotation.y
	var delta_yaw: float = wrapf(desired_yaw - current_yaw, -PI, PI)

	if abs(delta_yaw) <= aligned_epsilon:
		return Status.SUCCESS

	var step: float = clamp(delta_yaw, -turn_speed * agent.delta, turn_speed * agent.delta)
	actor3d.rotation.y = current_yaw + step
	return Status.RUNNING
