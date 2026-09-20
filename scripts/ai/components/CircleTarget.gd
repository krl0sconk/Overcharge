class_name CircleTarget
extends PerceptNode

## Rodea al target en vez de acercarse en línea recta: agarra la tangente en
## un sentido fijo por agente (se sortea una sola vez, ver abajo) y corrige
## radialmente para mantenerse cerca de un radio que respira entre
## orbit_radius - pulse_amplitude y orbit_radius + pulse_amplitude, así no
## rueda siempre a la misma distancia sino que también se acerca y se aleja.
## Encaja con el Virus: no quiere cuerpo a cuerpo, prefiere mantener
## distancia y rodear mientras reparte corrupción.

@export var orbit_radius: float = 4.0
@export var radial_gain: float = 0.6  ## qué tanto pesa cerrar/abrir distancia frente a la tangente
@export var pulse_amplitude: float = 1.5  ## cuánto se acerca/aleja del radio base
@export var pulse_speed: float = 1.0  ## rad/s del ciclo de acercar-alejar

func tick(agent: PerceptComponent) -> Status:
	var target: Node = agent.blackboard.get("target")
	var movement: MovementComponent = agent.movement_component
	if target == null or not is_instance_valid(target) or movement == null \
			or not (agent.actor is Node3D) or not (target is Node3D):
		return Status.FAILURE

	var actor3d: Node3D = agent.actor as Node3D
	var to_target: Vector3 = (target as Node3D).global_position - actor3d.global_position
	to_target.y = 0.0
	var distance: float = to_target.length()
	if distance < 0.0001:
		return Status.RUNNING

	var radial: Vector3 = to_target.normalized()

	## El sentido de giro se sortea una vez y se guarda en memoria del agente
	## -- sin esto cambiaría de sentido cada tick y el Virus temblaría en vez
	## de rodear.
	var direction: float = agent.recall(self, "orbit_direction", 0.0)
	if direction == 0.0:
		direction = 1.0 if randf() < 0.5 else -1.0
		agent.remember(self, "orbit_direction", direction)

	## Fase propia del nodo en vez de usar Time.get_ticks: así el ciclo
	## arranca en cero para cada agente en vez de compartir un reloj global.
	var phase: float = agent.recall(self, "phase", 0.0) + agent.delta * pulse_speed
	agent.remember(self, "phase", phase)
	var target_radius: float = orbit_radius + sin(phase) * pulse_amplitude

	var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x) * direction
	var radial_error: float = distance - target_radius
	movement.set_move_direction(tangent + radial * (radial_error * radial_gain))
	return Status.RUNNING
