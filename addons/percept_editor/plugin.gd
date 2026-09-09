@tool
extends EditorPlugin

var _panel: PerceptPanel
var _debugger: PerceptDebugger

func _enter_tree() -> void:
	_panel = PerceptPanel.new()
	_panel.name = "Percept"
	add_control_to_bottom_panel(_panel, "Percept")

	_debugger = PerceptDebugger.new()
	add_debugger_plugin(_debugger)
	_panel.set_debugger(_debugger)
	_panel._open_tree("res://resources/ai/trees/yunque.tres")

func _exit_tree() -> void:
	if _debugger != null:
		remove_debugger_plugin(_debugger)
		_debugger = null
	if _panel != null:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
