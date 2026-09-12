class_name PerceptComponent
extends Node

@export var actor: Node
@export var tree: PerceptNode          ## el .tres compartido
@export var tick_rate: float = 0.1
@export var movement_component: MovementComponent   # TODO(María): tipar a MovementComponent cuando exista.

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
	if OS.has_feature("debug") and EngineDebugger.is_active():
		_debug_capture_owner = get_tree().get_nodes_in_group("percept_debug_components").is_empty()
		add_to_group("percept_debug_components")
		if _debug_capture_owner:
			EngineDebugger.register_message_capture("percept", Callable(self, "_on_debug_message"))
		_send_debug_agent()

func _exit_tree() -> void:
	if OS.has_feature("debug") and EngineDebugger.is_active() and _debug_capture_owner:
		EngineDebugger.unregister_message_capture("percept")

func _physics_process(d: float) -> void:
	_accum += d
	if _accum < tick_rate:
		return
	delta = _accum
	_accum = 0.0
	if tree == null:
		return

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

## Los nodos son compartidos, así que su memoria vive acá, en cada enemigo.
func remember(node: PerceptNode, key: String, value: Variant) -> void:
	if not memory.has(node):
		memory[node] = {}
	memory[node][key] = value

func recall(node: PerceptNode, key: String, default: Variant = null) -> Variant:
	return memory.get(node, {}).get(key, default)

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
