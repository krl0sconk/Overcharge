class_name TurnToTarget
extends PerceptNode

## Genérica y reusable: pide girar el actor hacia el objetivo del blackboard.
## No gira directamente -- publica el yaw deseado y no hace más. Quien
## interpola la rotación real, cada frame de física, es PerceptComponent:
## si el paso se diera acá se vería a saltos, porque tick() corre solo cada
## tick_rate (10 Hz por defecto) y no cada physics frame (~60 Hz).
## Siempre SUCCESS (salvo sin objetivo) para no frenar una Sequence que la
## encadena con movimiento -- antes devolvía RUNNING mientras giraba y eso le
## cortaba el turno a MoveToTarget en la misma Sequence.
##
## En el árbol del Yunque se reutiliza tal cual en dos ramas: "me
## flanquearon" (gateada por IsTargetBehind) y "buscar línea" (rama por
## defecto, sin gate). Al ser un Resource sin estado propio, la misma
## instancia se puede compartir entre ambas ramas.

@export var turn_speed: float = 6.0  ## rad/s

func tick(agent: PerceptComponent) -> Status:
	var target: Node = agent.blackboard.get("target")
	if target == null or not is_instance_valid(target) or not (agent.actor is Node3D) or not (target is Node3D):
		return Status.FAILURE

	var actor3d: Node3D = agent.actor as Node3D
	var to_target: Vector3 = (target as Node3D).global_position - actor3d.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return Status.SUCCESS

	agent.blackboard["turning"] = true
	agent.blackboard["turn_target_yaw"] = atan2(to_target.x, to_target.z) + PI
	agent.blackboard["turn_speed"] = turn_speed
	return Status.SUCCESS
