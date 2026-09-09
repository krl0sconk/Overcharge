@tool
extends PanelContainer
class_name PerceptPanel

const RUNTIME_SCRIPTS_ROOT: String = "res://scripts"
const TREE_DIRECTORY: String = "res://resources/ai/trees"

var _debugger: PerceptDebugger
var _palette: PerceptPalette
var _graph_edit: PerceptGraphEdit
var _agent_picker: OptionButton
var _tick_label: Label
var _status_label: Label
var _pause_button: CheckButton
var _file_dialog: FileDialog

var _graph_nodes: Dictionary = {}
var _path_to_graph_node: Dictionary = {}
var _next_node_id: int = 0
var _current_tree_path: String = ""
var _dirty: bool = false
var _live: bool = false
var _paused: bool = false
var _agent_labels: Dictionary = {}

func _ready() -> void:
	if get_child_count() == 0:
		_build_ui()
	_scan_runtime_palette()

func set_debugger(debugger: PerceptDebugger) -> void:
	_debugger = debugger
	_debugger.agent_seen.connect(_on_agent_seen)
	_debugger.tick_received.connect(_on_tick_received)
	_debugger.session_state_changed.connect(_on_session_state_changed)
	_refresh_agent_picker()

func _build_ui() -> void:
	custom_minimum_size = Vector2(0.0, 380.0)

	var main_box := VBoxContainer.new()
	main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_box)

	var toolbar := HBoxContainer.new()
	toolbar.custom_minimum_size = Vector2(0.0, 32.0)
	main_box.add_child(toolbar)

	var new_button := Button.new()
	new_button.text = "Nuevo"
	new_button.pressed.connect(_on_new_pressed)
	toolbar.add_child(new_button)

	var open_button := Button.new()
	open_button.text = "Abrir .tres"
	open_button.pressed.connect(_on_open_pressed)
	toolbar.add_child(open_button)

	var save_button := Button.new()
	save_button.text = "Guardar .tres"
	save_button.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_button)

	var tree_label := Label.new()
	tree_label.text = "Árbol:"
	tree_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(tree_label)

	_status_label = Label.new()
	_status_label.text = "Sin árbol abierto"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.clip_text = true
	toolbar.add_child(_status_label)

	var agent_label := Label.new()
	agent_label.text = "Agente:"
	agent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(agent_label)

	_agent_picker = OptionButton.new()
	_agent_picker.custom_minimum_size = Vector2(180.0, 0.0)
	_agent_picker.item_selected.connect(_on_agent_selected)
	toolbar.add_child(_agent_picker)

	_tick_label = Label.new()
	_tick_label.text = "Ticks: —"
	_tick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toolbar.add_child(_tick_label)

	_pause_button = CheckButton.new()
	_pause_button.text = "Pausar"
	_pause_button.toggled.connect(_on_pause_toggled)
	toolbar.add_child(_pause_button)

	var splitter := HSplitContainer.new()
	splitter.size_flags_vertical = Control.SIZE_EXPAND_FILL
	splitter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_box.add_child(splitter)

	_palette = PerceptPalette.new()
	_palette.name = "Palette"
	_palette.custom_minimum_size = Vector2(190.0, 0.0)
	_palette.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette.tooltip_text = "Arrastrá una clase al canvas"
	_palette.item_activated.connect(_on_palette_activated)
	splitter.add_child(_palette)

	_graph_edit = PerceptGraphEdit.new()
	_graph_edit.name = "GraphEdit"
	_graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph_edit.palette_node_dropped.connect(_on_palette_node_dropped)
	_graph_edit.connection_request.connect(_on_connection_request)
	_graph_edit.disconnection_request.connect(_on_disconnection_request)
	_graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	_graph_edit.end_node_move.connect(_on_end_node_move)
	splitter.add_child(_graph_edit)

	_file_dialog = FileDialog.new()
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.tres ; Percept tree resource"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

func _scan_runtime_palette() -> void:
	if _palette == null:
		return
	var types: Array = []
	_scan_runtime_scripts(RUNTIME_SCRIPTS_ROOT, types)
	types.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["class_name"]) < str(b["class_name"])
	)
	_palette.set_types(types)

func _scan_runtime_scripts(directory_path: String, types: Array) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return
	for file_name in directory.get_files():
		if not file_name.ends_with(".gd"):
			continue
		var script_path: String = directory_path.path_join(file_name)
		var script := load(script_path) as Script
		if script == null or script.get_global_name().is_empty() or not _script_extends_percept(script):
			continue
		types.append({
			"class_name": script.get_global_name(),
			"script_path": script_path,
		})
	for subdirectory in directory.get_directories():
		_scan_runtime_scripts(directory_path.path_join(subdirectory), types)

func _script_extends_percept(script: Script) -> bool:
	var current: Script = script
	while current != null:
		if current.get_global_name() == "PerceptNode":
			return true
		current = current.get_base_script()
	return false

func _on_new_pressed() -> void:
	_clear_graph()
	_current_tree_path = ""
	_dirty = false
	_set_status("Árbol nuevo sin guardar")

func _on_open_pressed() -> void:
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.current_dir = TREE_DIRECTORY
	_file_dialog.popup_centered(Vector2(800.0, 560.0))

func _on_save_pressed() -> void:
	var errors: Array[String] = _validate_graph()
	if not errors.is_empty():
		_set_status("No se guardó: " + " | ".join(errors))
		return

	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.current_dir = TREE_DIRECTORY
	_file_dialog.current_file = _default_save_name()
	_file_dialog.popup_centered(Vector2(800.0, 560.0))

func _on_file_selected(path: String) -> void:
	if _file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		_open_tree(path)
	else:
		_save_tree(path)

func _open_tree(path: String) -> void:
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Resource
	if loaded == null or not _resource_extends_percept(loaded):
		_set_status("No es un árbol Percept válido: %s" % path)
		return

	_clear_graph()
	_current_tree_path = path
	_next_node_id = 0
	var positions: Dictionary = loaded.get_meta("percept_editor_positions", {})
	_load_resource_node(loaded, 0, positions, "")
	_refresh_order_labels()
	_rebuild_runtime_paths()
	_dirty = false
	_set_status(path)
	_refresh_agent_picker()

func _load_resource_node(node_resource: Resource, depth: int, positions: Dictionary, runtime_path: String) -> StringName:
	var stable_id: String = "node_%d" % _next_node_id
	var graph_name: StringName = _add_graph_node(
		node_resource,
		_get_resource_class_name(node_resource),
		_get_saved_position(positions, runtime_path, depth, _graph_nodes.size()),
		stable_id
	)
	var children: Array = _resource_children(node_resource)
	for child_index in children.size():
		var child_resource: Resource = children[child_index] as Resource
		if child_resource == null:
			continue
		var child_path: String = str(child_index) if runtime_path.is_empty() else "%s/%d" % [runtime_path, child_index]
		var child_name: StringName = _load_resource_node(child_resource, depth + 1, positions, child_path)
		_graph_edit.connect_node(graph_name, 0, child_name, 0)
	return graph_name

func _get_saved_position(positions: Dictionary, runtime_path: String, depth: int, index: int) -> Vector2:
	var saved: Variant = positions.get(runtime_path, null)
	if saved is Vector2:
		return saved
	return Vector2(depth * 330.0, index * 145.0)

func _on_palette_activated(index: int) -> void:
	if _palette == null or index < 0:
		return
	var center: Vector2 = (_graph_edit.size / 2.0 + _graph_edit.scroll_offset) / _graph_edit.zoom
	_on_palette_node_dropped(str(_palette.get_item_metadata(index)), center)

func _on_palette_node_dropped(script_path: String, graph_position: Vector2) -> void:
	var script := load(script_path) as Script
	if script == null:
		_set_status("No se pudo cargar la clase: %s" % script_path)
		return
	var node_resource := Resource.new()
	node_resource.set_script(script)
	var stable_id: String = "node_%d" % _next_node_id
	_add_graph_node(node_resource, script.get_global_name(), graph_position - Vector2(120.0, 30.0), stable_id)
	_refresh_order_labels()
	_dirty = true

func _add_graph_node(node_resource: Resource, node_title: String, graph_position: Vector2, stable_id: String) -> StringName:
	var graph_node := PerceptGraphNode.new()
	graph_node.name = "GraphNode_%d" % _next_node_id
	_next_node_id += 1
	graph_node.configure(node_resource, node_title, stable_id)
	graph_node.position_offset = graph_position
	graph_node.property_changed.connect(_on_graph_node_property_changed)
	_graph_edit.add_child(graph_node)
	_graph_nodes[graph_node.name] = graph_node
	return graph_node.name

func _on_graph_node_property_changed(_property_name: String, _value: Variant) -> void:
	_dirty = true

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_port != 0 or to_port != 0 or from_node == to_node:
		return
	if not _graph_nodes.has(from_node) or not _graph_nodes.has(to_node):
		return
	if not _resource_has_property(_graph_nodes[from_node].resource, "children"):
		_set_status("Solo un compuesto puede tener hijos")
		return
	for connection in _graph_edit.get_connection_list():
		if connection["to_node"] == to_node:
			_set_status("Un nodo no puede tener dos padres")
			return
	if _would_create_cycle(from_node, to_node):
		_set_status("La conexión crearía un ciclo")
		return
	_graph_edit.connect_node(from_node, from_port, to_node, to_port)
	_dirty = true
	_refresh_order_labels()

func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
	_dirty = true
	_refresh_order_labels()

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	for node_name in nodes:
		if not _graph_nodes.has(node_name):
			continue
		for connection in _graph_edit.get_connection_list():
			if connection["from_node"] == node_name or connection["to_node"] == node_name:
				_graph_edit.disconnect_node(
					connection["from_node"], connection["from_port"],
					connection["to_node"], connection["to_port"]
				)
		var graph_node: PerceptGraphNode = _graph_nodes[node_name]
		_graph_nodes.erase(node_name)
		_graph_edit.remove_child(graph_node)
		graph_node.queue_free()
	_dirty = true
	_refresh_order_labels()

func _on_end_node_move() -> void:
	_refresh_order_labels()
	_dirty = true

func _refresh_order_labels() -> void:
	for node_name in _graph_nodes:
		var graph_node: PerceptGraphNode = _graph_nodes[node_name]
		var parent_count: int = 0
		for connection in _graph_edit.get_connection_list():
			if connection["to_node"] == node_name:
				parent_count += 1
		if parent_count == 0:
			graph_node.set_order_title(0, true)

	for parent_name in _graph_nodes:
		var children: Array = _children_of(parent_name)
		for child_index in children.size():
			var child_node: PerceptGraphNode = _graph_nodes[children[child_index]]
			child_node.set_order_title(child_index + 1, false)

func _children_of(parent_name: StringName) -> Array:
	var children: Array = []
	for connection in _graph_edit.get_connection_list():
		if connection["from_node"] == parent_name:
			children.append(connection["to_node"])
	children.sort_custom(Callable(self, "_sort_graph_nodes_by_y"))
	return children

func _sort_graph_nodes_by_y(a: StringName, b: StringName) -> bool:
	return _graph_nodes[a].position_offset.y < _graph_nodes[b].position_offset.y

func _would_create_cycle(from_node: StringName, to_node: StringName) -> bool:
	var pending: Array[StringName] = [to_node]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current: StringName = pending.pop_back()
		if current == from_node:
			return true
		if visited.has(current):
			continue
		visited[current] = true
		for child in _children_of(current):
			pending.append(child)
	return false

func _validate_graph() -> Array[String]:
	var errors: Array[String] = []
	if _graph_nodes.is_empty():
		return ["el árbol no tiene nodos"]

	var parent_by_child: Dictionary = {}
	for connection in _graph_edit.get_connection_list():
		var child_name: StringName = connection["to_node"]
		if parent_by_child.has(child_name):
			errors.append("un nodo tiene dos padres: %s" % child_name)
		else:
			parent_by_child[child_name] = connection["from_node"]

	var roots: Array = []
	for node_name in _graph_nodes:
		if not parent_by_child.has(node_name):
			roots.append(node_name)
	if roots.size() != 1:
		errors.append("debe existir exactamente una raíz (hay %d)" % roots.size())
		return errors

	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	_validate_node_recursive(roots[0], visiting, visited, errors)
	if visited.size() != _graph_nodes.size():
		errors.append("hay nodos desconectados de la raíz")
	return errors

func _validate_node_recursive(node_name: StringName, visiting: Dictionary, visited: Dictionary, errors: Array[String]) -> void:
	if visiting.has(node_name):
		errors.append("hay un ciclo en el árbol")
		return
	if visited.has(node_name):
		return
	visiting[node_name] = true
	var graph_node: PerceptGraphNode = _graph_nodes[node_name]
	var children: Array = _children_of(node_name)
	var is_composite: bool = _resource_has_property(graph_node.resource, "children")
	if is_composite and children.is_empty():
		errors.append("el compuesto %s necesita al menos un hijo" % graph_node.base_title)
	if not is_composite and not children.is_empty():
		errors.append("el nodo %s no acepta hijos" % graph_node.base_title)
	if _is_decorator(graph_node.resource) and children.size() != 1:
		errors.append("el decorador %s necesita exactamente un hijo" % graph_node.base_title)
	for child_name in children:
		_validate_node_recursive(child_name, visiting, visited, errors)
	visiting.erase(node_name)
	visited[node_name] = true

func _save_tree(path: String) -> void:
	var roots: Array = []
	var parent_nodes: Dictionary = {}
	for connection in _graph_edit.get_connection_list():
		parent_nodes[connection["to_node"]] = true
	for node_name in _graph_nodes:
		if not parent_nodes.has(node_name):
			roots.append(node_name)
	if roots.size() != 1:
		_set_status("No se guardó: la validación cambió mientras se elegía el archivo")
		return

	var positions: Dictionary = {}
	_collect_positions(roots[0], "", positions)
	var root_resource: Resource = _build_resource(roots[0])
	root_resource.set_meta("percept_editor_positions", positions)
	var error: Error = ResourceSaver.save(root_resource, path)
	if error != OK:
		_set_status("No se pudo guardar (%s): %s" % [error, path])
		return
	_current_tree_path = path
	_dirty = false
	_set_status(path)

func _build_resource(node_name: StringName) -> Resource:
	var graph_node: PerceptGraphNode = _graph_nodes[node_name]
	var node_resource: Resource = graph_node.resource
	if _resource_has_property(node_resource, "children"):
		var child_resources: Array[PerceptNode] = []
		for child_name in _children_of(node_name):
			child_resources.append(_build_resource(child_name) as PerceptNode)
		node_resource.set("children", child_resources)
	return node_resource

func _collect_positions(node_name: StringName, runtime_path: String, positions: Dictionary) -> void:
	var graph_node: PerceptGraphNode = _graph_nodes[node_name]
	positions[runtime_path] = graph_node.position_offset
	var children: Array = _children_of(node_name)
	for child_index in children.size():
		var child_path: String = str(child_index) if runtime_path.is_empty() else "%s/%d" % [runtime_path, child_index]
		_collect_positions(children[child_index], child_path, positions)

func _resource_children(node_resource: Resource) -> Array:
	if not _resource_has_property(node_resource, "children"):
		return []
	var value: Variant = node_resource.get("children")
	return value if value is Array else []

func _resource_has_property(node_resource: Resource, property_name: String) -> bool:
	for property_info in node_resource.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false

func _resource_extends_percept(node_resource: Resource) -> bool:
	var script: Script = node_resource.get_script() as Script
	return script != null and _script_extends_percept(script)

func _get_resource_class_name(node_resource: Resource) -> String:
	var script: Script = node_resource.get_script() as Script
	if script != null and not script.get_global_name().is_empty():
		return script.get_global_name()
	return "PerceptNode"

func _is_decorator(node_resource: Resource) -> bool:
	var script: Script = node_resource.get_script() as Script
	while script != null:
		if script.get_global_name() == "PerceptDecorator":
			return true
		script = script.get_base_script()
	return _get_resource_class_name(node_resource).ends_with("Decorator")

func _clear_graph() -> void:
	for node_name in _graph_nodes.keys():
		var graph_node: PerceptGraphNode = _graph_nodes[node_name]
		_graph_edit.remove_child(graph_node)
		graph_node.queue_free()
	_graph_nodes.clear()
	_graph_edit.clear_connections()
	_path_to_graph_node.clear()
	_clear_live_visuals()

func _rebuild_runtime_paths() -> void:
	_path_to_graph_node.clear()
	var roots: Array = []
	for node_name in _graph_nodes:
		var has_parent := false
		for connection in _graph_edit.get_connection_list():
			if connection["to_node"] == node_name:
				has_parent = true
				break
		if not has_parent:
			roots.append(node_name)
	if roots.size() == 1:
		_map_runtime_paths(roots[0], "")

func _map_runtime_paths(node_name: StringName, path: String) -> void:
	_path_to_graph_node[path] = _graph_nodes[node_name]
	var children: Array = _children_of(node_name)
	for child_index in children.size():
		var child_path: String = str(child_index) if path.is_empty() else "%s/%d" % [path, child_index]
		_map_runtime_paths(children[child_index], child_path)

func _on_agent_seen(tree_path: String, agent_id: String, agent_label: String, _session_id: int) -> void:
	if tree_path != _current_tree_path:
		return
	_agent_labels[agent_id] = agent_label
	_refresh_agent_picker(agent_id)

func _on_tick_received(tree_path: String, agent_id: String, statuses: Dictionary, tick_count: int, _session_id: int) -> void:
	print("PERCEPT_PANEL_TICK ", tick_count)
	if tree_path != _current_tree_path:
		return
	_live = true
	if _paused:
		return
	_tick_label.text = "Ticks: %d" % tick_count
	_rebuild_runtime_paths()
	for graph_node in _graph_nodes.values():
		(graph_node as PerceptGraphNode).set_runtime_status(-1, false)
	for path in statuses:
		if _path_to_graph_node.has(str(path)):
			var status: int = int(statuses[path])
			(_path_to_graph_node[str(path)] as PerceptGraphNode).set_runtime_status(status, true)
	_update_connection_activity(statuses)

func _update_connection_activity(statuses: Dictionary) -> void:
	var any_active: bool = false
	for connection in _graph_edit.get_connection_list():
		var from_node: PerceptGraphNode = _graph_nodes[connection["from_node"]]
		var to_node: PerceptGraphNode = _graph_nodes[connection["to_node"]]
		var from_active: bool = _node_status_is_active(_path_for_graph_node(from_node), statuses)
		var to_active: bool = _node_status_is_active(_path_for_graph_node(to_node), statuses)
		var active: bool = from_active and to_active
		any_active = any_active or active
		_graph_edit.set_connection_activity(
			connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"],
			1.0 if active else 0.0
		)
	_graph_edit.connection_lines_thickness = 6.0 if any_active else 4.0

func _node_status_is_active(path: String, statuses: Dictionary) -> bool:
	if not statuses.has(path):
		return false
	var status: int = int(statuses[path])
	return status == 0 or status == 2

func _path_for_graph_node(graph_node: PerceptGraphNode) -> String:
	for path in _path_to_graph_node:
		if _path_to_graph_node[path] == graph_node:
			return str(path)
	return ""

func _on_agent_selected(index: int) -> void:
	if _debugger == null or index < 0 or _agent_picker == null:
		return
	var agent_id: String = str(_agent_picker.get_item_metadata(index))
	_debugger.send_watch(_current_tree_path, agent_id)

func _refresh_agent_picker(preferred_id: String = "") -> void:
	if _agent_picker == null:
		return
	var old_id: String = ""
	if _agent_picker.selected >= 0:
		old_id = str(_agent_picker.get_item_metadata(_agent_picker.selected))
	_agent_picker.clear()
	var agents: Array = _debugger.get_agents_for_tree(_current_tree_path) if _debugger != null else []
	for agent in agents:
		_agent_picker.add_item(str(agent["label"]))
		_agent_picker.set_item_metadata(_agent_picker.item_count - 1, str(agent["id"]))
	if _agent_picker.item_count == 0:
		return
	var desired_id: String = old_id
	if desired_id.is_empty():
		desired_id = preferred_id
	var desired_index: int = 0
	var found_desired: bool = false
	for index in _agent_picker.item_count:
		if str(_agent_picker.get_item_metadata(index)) == desired_id:
			desired_index = index
			found_desired = true
	if not found_desired and not preferred_id.is_empty():
		for index in _agent_picker.item_count:
			if str(_agent_picker.get_item_metadata(index)) == preferred_id:
				desired_index = index
				break
	_agent_picker.select(desired_index)
	_debugger.send_watch(_current_tree_path, str(_agent_picker.get_item_metadata(desired_index)))

func _on_pause_toggled(value: bool) -> void:
	_paused = value

func _on_session_state_changed(running: bool, _session_id: int) -> void:
	if running:
		return
	_live = false
	_paused = false
	if _pause_button != null:
		_pause_button.button_pressed = false
	_tick_label.text = "Ticks: —"
	_agent_labels.clear()
	_refresh_agent_picker()
	_clear_live_visuals()

func _clear_live_visuals() -> void:
	for graph_node in _graph_nodes.values():
		(graph_node as PerceptGraphNode).clear_runtime_status()
	if _graph_edit == null:
		return
	_graph_edit.connection_lines_thickness = 4.0
	for connection in _graph_edit.get_connection_list():
		_graph_edit.set_connection_activity(
			connection["from_node"], connection["from_port"],
			connection["to_node"], connection["to_port"], 0.0
		)

func _default_save_name() -> String:
	if not _current_tree_path.is_empty():
		return _current_tree_path.get_file()
	return "percept_tree.tres"

func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
