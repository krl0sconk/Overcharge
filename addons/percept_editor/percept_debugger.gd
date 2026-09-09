@tool
extends EditorDebuggerPlugin
class_name PerceptDebugger

signal agent_seen(tree_path: String, agent_id: String, agent_label: String, session_id: int)
signal tick_received(tree_path: String, agent_id: String, statuses: Dictionary, tick_count: int, session_id: int)
signal session_state_changed(running: bool, session_id: int)

var _agents_by_tree: Dictionary = {}
var _watched_tree_path: String = ""
var _watched_agent_id: String = ""
var _connected_sessions: Dictionary = {}

func _has_capture(capture: String) -> bool:
	return capture == "percept"

func _capture(message: String, data: Array, session_id: int) -> bool:
	print("DBG_CAPTURE ", message, " active=", get_session(session_id).is_active())
	var normalized_message: String = message.trim_prefix("percept:")
	if normalized_message == "ack":
		print("DBG_ACK ", data)
		return true
	if normalized_message == "agent" and data.size() >= 3:
		var tree_path: String = str(data[0])
		var agent_id: String = str(data[1])
		var agent_label: String = str(data[2])
		if not _agents_by_tree.has(tree_path):
			_agents_by_tree[tree_path] = {}
		_agents_by_tree[tree_path][agent_id] = agent_label
		agent_seen.emit(tree_path, agent_id, agent_label, session_id)
		return true

	if normalized_message == "tick" and data.size() >= 4:
		var tree_path: String = str(data[0])
		var agent_id: String = str(data[1])
		var statuses: Dictionary = data[2] if data[2] is Dictionary else {}
		var tick_count: int = int(data[3])
		tick_received.emit(tree_path, agent_id, statuses, tick_count, session_id)
		return true

	return false

func _setup_session(session_id: int) -> void:
	var session: EditorDebuggerSession = get_session(session_id)
	if session == null:
		return
	if not _connected_sessions.has(session_id):
		session.started.connect(_on_session_started.bind(session_id))
		session.stopped.connect(_on_session_stopped.bind(session_id))
		_connected_sessions[session_id] = true

func _on_session_started(session_id: int) -> void:
	print("DBG_STARTED ", session_id, " active=", get_session(session_id).is_active(), " debuggable=", get_session(session_id).is_debuggable())
	session_state_changed.emit(true, session_id)
	_send_watch_to_session(session_id)

func _on_session_stopped(session_id: int) -> void:
	print("DBG_STOPPED ", session_id)
	_agents_by_tree.clear()
	session_state_changed.emit(false, session_id)

func get_agents_for_tree(tree_path: String) -> Array:
	var result: Array = []
	var agents: Dictionary = _agents_by_tree.get(tree_path, {})
	for agent_id in agents:
		result.append({
			"id": str(agent_id),
			"label": str(agents[agent_id]),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["label"]) < str(b["label"])
	)
	return result

func send_watch(tree_path: String, agent_id: String) -> void:
	print("DBG_SEND_WATCH ", tree_path, " ", agent_id)
	_watched_tree_path = tree_path
	_watched_agent_id = agent_id
	for session_id in _connected_sessions:
		_send_watch_to_session(int(session_id))

func _send_watch_to_session(session_id: int) -> void:
	print("DBG_SEND_WATCH_SESSION ", session_id, " active=", get_session(session_id).is_active(), " debuggable=", get_session(session_id).is_debuggable())
	if _watched_tree_path.is_empty() or _watched_agent_id.is_empty():
		return
	var session: EditorDebuggerSession = get_session(session_id)
	if session != null and session.is_active():
		session.send_message("percept:watch", [_watched_tree_path, _watched_agent_id])
