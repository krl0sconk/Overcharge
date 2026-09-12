@tool
extends GraphNode
class_name PerceptGraphNode

signal property_changed(property_name: String, value: Variant)

const PORT_COLOR: Color = Color(0.52, 0.75, 0.98)
const SUCCESS_COLOR: Color = Color(0.45, 0.95, 0.55)
const FAILURE_COLOR: Color = Color(0.70, 0.70, 0.70)
const RUNNING_COLOR: Color = Color(1.0, 0.72, 0.25)
const DIM_COLOR: Color = Color(0.42, 0.42, 0.45)

var resource: Resource
var base_title: String = "PerceptNode"
var editor_id: String = ""
var _property_controls: Dictionary = {}

func configure(node_resource: Resource, node_title: String, stable_id: String) -> void:
	resource = node_resource
	base_title = node_title
	editor_id = stable_id
	_build_contents()
	clear_runtime_status()

func set_order_title(order: int, is_root: bool) -> void:
	if is_root:
		title = "%s  ·  raíz" % base_title
	else:
		title = "%s  ·  hijo %d" % [base_title, order]

func set_runtime_status(status: int, visited: bool) -> void:
	if not visited:
		modulate = DIM_COLOR
		return
	match status:
		0:
			modulate = SUCCESS_COLOR
		1:
			modulate = FAILURE_COLOR
		2:
			modulate = RUNNING_COLOR
		_:
			modulate = Color.WHITE

func clear_runtime_status() -> void:
	modulate = Color.WHITE

func _build_contents() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_property_controls.clear()

	var port_slot := Control.new()
	port_slot.name = "Ports"
	port_slot.custom_minimum_size = Vector2(1.0, 2.0)
	port_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(port_slot)
	set_slot(0, true, 0, PORT_COLOR, true, 0, PORT_COLOR)

	var port_hint := Label.new()
	port_hint.text = "entrada  ←     salida  →"
	port_hint.add_theme_color_override("font_color", Color(0.58, 0.62, 0.7))
	port_hint.add_theme_font_size_override("font_size", 10)
	add_child(port_hint)

	for property_info in resource.get_property_list():
		if not _is_editable_export(property_info):
			continue
		_add_property_control(property_info)

func _is_editable_export(property_info: Dictionary) -> bool:
	var property_name: String = str(property_info.get("name", ""))
	var usage: int = int(property_info.get("usage", 0))
	if property_name.is_empty() or property_name == "script" or property_name == "children":
		return false
	return (usage & PROPERTY_USAGE_EDITOR) != 0

func _add_property_control(property_info: Dictionary) -> void:
	var property_name: String = str(property_info["name"])
	var row := HBoxContainer.new()
	row.name = "Property_%s" % property_name
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = property_name
	label.custom_minimum_size = Vector2(132.0, 0.0)
	label.tooltip_text = property_name
	row.add_child(label)

	var control: Control
	match int(property_info.get("type", TYPE_NIL)):
		TYPE_FLOAT, TYPE_INT:
			control = _make_spin_box(property_info)
		TYPE_BOOL:
			control = CheckBox.new()
			(control as CheckBox).button_pressed = bool(resource.get(property_name))
			(control as CheckBox).toggled.connect(_on_bool_changed.bind(property_name))
		TYPE_STRING:
			control = LineEdit.new()
			(control as LineEdit).text = str(resource.get(property_name))
			(control as LineEdit).text_changed.connect(_on_string_changed.bind(property_name))
		_:
			control = Label.new()
			(control as Label).text = str(resource.get(property_name))
			(control as Label).modulate = Color(0.55, 0.58, 0.65)

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	add_child(row)
	_property_controls[property_name] = control

func _make_spin_box(property_info: Dictionary) -> SpinBox:
	var property_name: String = str(property_info["name"])
	var spin_box := SpinBox.new()
	spin_box.value = float(resource.get(property_name))
	spin_box.allow_greater = true
	spin_box.allow_lesser = true
	spin_box.step = 1.0 if int(property_info.get("type", TYPE_FLOAT)) == TYPE_INT else 0.01
	var hint_string: String = str(property_info.get("hint_string", ""))
	var hint_parts: PackedStringArray = hint_string.split(",")
	if hint_parts.size() >= 2:
		spin_box.min_value = float(hint_parts[0])
		spin_box.max_value = float(hint_parts[1])
		spin_box.allow_greater = false
		spin_box.allow_lesser = false
	if hint_parts.size() >= 3 and not hint_parts[2].is_empty():
		spin_box.step = maxf(absf(float(hint_parts[2])), 0.001)
	spin_box.value_changed.connect(_on_number_changed.bind(property_name))
	return spin_box

func _on_number_changed(value: float, property_name: String) -> void:
	_set_resource_property(property_name, value)

func _on_bool_changed(value: bool, property_name: String) -> void:
	_set_resource_property(property_name, value)

func _on_string_changed(value: String, property_name: String) -> void:
	_set_resource_property(property_name, value)

func _set_resource_property(property_name: String, value: Variant) -> void:
	if resource == null:
		return
	resource.set(property_name, value)
	resource.emit_changed()
	property_changed.emit(property_name, value)
