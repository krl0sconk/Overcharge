class_name PerceptComponent
extends Node

@export var actor: Node
@export var tree: PerceptNode          ## el .tres compartido
@export var tick_rate: float = 0.1
@export var movement_component: MovementComponent
@export var hitbox: HitboxComponent
@export var laser: LaserSightComponent
@export var health_component: HealthComponent  ## opcional: prende hit_recently para ramas de huida
@export var aim_node: Node3D            ## qué gira para apuntar. Vacío = gira el actor entero.
@export var aim_yaw_offset_deg: float = 0.0

var blackboard: Dictionary = {}        ## datos del enemigo: target, etc.
var memory: Dictionary = {}            ## lo que un nodo necesita recordar
var delta: float = 0.0

var _accum: float = 0.0
var _debug_statuses: Dictionary = {}
var _debug_path_stack: Array[String] = []
var _debug_tick_count: int = 0
var _debug_watch_tree_path: String = ""
var _debug_watch_agent_id: String = ""
var _debug_capture_owner: bool = false
var _debug_agent_announce_accum: float = 0.0

func _ready() -> void:
	if health_component != null:
		health_component.damaged.connect(_on_damaged)

	if OS.has_feature("debug") and EngineDebugger.is_active():
		_debug_capture_owner = get_tree().get_nodes_in_group("percept_debug_components").is_empty()
		add_to_group("percept_debug_components")
		if _debug_capture_owner:
			EngineDebugger.register_message_capture("percept", Callable(self, "_on_debug_message"))
		_send_debug_agent()

func _exit_tree() -> void:
	if OS.has_feature("debug") and EngineDebugger.is_active() and _debug_capture_owner:
		EngineDebugger.unregister_message_capture("percept")

	var carried: MovementComponent = blackboard.get("carried_movement")
	if carried != null:
		carried.movement_enabled = true
		if movement_component != null and movement_component.owner_body != null and carried.owner_body != null:
			movement_component.owner_body.remove_collision_exception_with(carried.owner_body)
			carried.owner_body.remove_collision_exception_with(movement_component.owner_body)

func _physics_process(d: float) -> void:
	_step_turn(d)

	_accum += d
	if _accum < tick_rate:
		return
	delta = _accum
	_accum = 0.0
	if tree == null:
		return

	## Se apaga acá y la vuelve a prender TurnToTarget si le toca tickear
	## este ciclo -- así deja de girar apenas otra rama de más prioridad
	## (cargar, atacar) toma el control del Selector.
	blackboard["turning"] = false

	if OS.has_feature("debug") and EngineDebugger.is_active():
		_debug_agent_announce_accum += delta
		if _debug_agent_announce_accum >= 1.0:
			_debug_agent_announce_accum = 0.0
			_send_debug_agent()
		_debug_statuses.clear()
		_debug_path_stack.clear()
		tree.tick_traced(self, "")
		_debug_tick_count += 1
		if _is_debug_watched():
			EngineDebugger.send_message(
				"percept:tick",
				[_debug_tree_path(), _debug_agent_id(), _debug_statuses, _debug_tick_count]
			)
	else:
		tree.tick(self)

## Interpola la rotación hacia turn_target_yaw cada physics frame en vez de
## cada tick de decisión -- ver comentario en TurnToTarget.gd.
## Usa rotación global porque aim_node puede colgar de padres ya rotados.
func _step_turn(d: float) -> void:
	if not blackboard.get("turning", false):
		return
	var node: Node3D = aim_node if aim_node != null else (actor as Node3D)
	if node == null:
		return

	var offset: float = deg_to_rad(aim_yaw_offset_deg)
	var target_yaw: float = blackboard.get("turn_target_yaw", node.global_rotation.y - offset) + offset
	var speed: float = blackboard.get("turn_speed", 6.0)
	var current_yaw: float = node.global_rotation.y
	var delta_yaw: float = wrapf(target_yaw - current_yaw, -PI, PI)

	var step: float = clamp(delta_yaw, -speed * d, speed * d)
	node.global_rotation.y = current_yaw + step

## Posición y dirección "lógicas" de apuntado: descuentan aim_yaw_offset_deg,
## que gira aim_node para que el mesh se vea bien apuntando, no para que su
## eje -Z real señale al objetivo. Todo lo que dispare o chequee línea de
## visión debe usar esto en vez de leer aim_node directamente.
func aim_position() -> Vector3:
	var node: Node3D = aim_node if aim_node != null else (actor as Node3D)
	return node.global_position if node != null else Vector3.ZERO

func aim_forward() -> Vector3:
	var node: Node3D = aim_node if aim_node != null else (actor as Node3D)
	if node == null:
		return Vector3.FORWARD
	var yaw: float = node.global_rotation.y - deg_to_rad(aim_yaw_offset_deg)
	return Vector3(-sin(yaw), 0.0, -cos(yaw))

## Los nodos son compartidos, así que su memoria vive acá, en cada enemigo.
func remember(node: PerceptNode, key: String, value: Variant) -> void:
	if not memory.has(node):
		memory[node] = {}
	memory[node][key] = value

func recall(node: PerceptNode, key: String, default: Variant = null) -> Variant:
	return memory.get(node, {}).get(key, default)

func _on_damaged(_amount: int) -> void:
	blackboard["hit_recently"] = true

func _debug_enter(path: String) -> void:
	_debug_path_stack.append(path)

func _debug_exit() -> void:
	if not _debug_path_stack.is_empty():
		_debug_path_stack.pop_back()

func _debug_child_path(index: int) -> String:
	var parent_path: String = _debug_path_stack.back() if not _debug_path_stack.is_empty() else ""
	return str(index) if parent_path.is_empty() else "%s/%d" % [parent_path, index]

func _debug_record(path: String, status: PerceptNode.Status) -> void:
	_debug_statuses[path] = int(status)

func _debug_tree_path() -> String:
	return tree.resource_path if tree != null else ""

func _debug_agent_id() -> String:
	return str(actor.get_path()) if actor != null and is_instance_valid(actor) else str(get_path())

func _debug_agent_label() -> String:
	if actor != null and is_instance_valid(actor):
		return "%s (%s)" % [actor.name, actor.get_path()]
	return name

func _is_debug_watched() -> bool:
	return _debug_watch_tree_path == _debug_tree_path() and _debug_watch_agent_id == _debug_agent_id()

func _send_debug_agent() -> void:
	var path: String = _debug_tree_path()
	if path.is_empty():
		return
	EngineDebugger.send_message(
		"percept:agent",
		[path, _debug_agent_id(), _debug_agent_label()]
	)

func _on_debug_message(message: String, data: Array) -> bool:
	var normalized_message: String = message.trim_prefix("percept:")
	print("DBG_RUNTIME_MESSAGE ", message)
	if normalized_message != "watch" or data.size() < 2:
		return false

	var watched_tree_path: String = str(data[0])
	var watched_agent_id: String = str(data[1])
	EngineDebugger.send_message("percept:ack", [watched_tree_path, watched_agent_id])
	for component_variant in get_tree().get_nodes_in_group("percept_debug_components"):
		if component_variant is PerceptComponent:
			component_variant._debug_watch_tree_path = watched_tree_path
			component_variant._debug_watch_agent_id = watched_agent_id
	return true
