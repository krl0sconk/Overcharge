class_name EmissiveStateComponent
extends Node

## Tiñe la textura emisiva compartida (material_1) según el estado del árbol
## de IA: azul en patrulla (sin objetivo), blanco al trabar un objetivo
## (girando o entre disparos), amarillo mientras telegrafía/dispara
## ("firing") y rojo un instante al recibir daño.
## Tiñe tanto la emisión (brillo, siempre a full color) como el albedo (la
## placa "en frío", atenuado por albedo_tint_strength) -- así el cambio de
## estado se nota aunque la cámara no tenga glow habilitado.
## No usa blackboard["reloading"] -- lo prende el nodo Reload compartido,
## pero solo lo apaga si termina su espera completa sin interrupciones; en
## cuanto aparece un objetivo se queda pegado en true para siempre y tapa
## el azul casi todo el juego. blackboard["target"] en cambio se revalida
## cada tick en AcquireTarget (se borra apenas se pierde de vista), así que
## es la señal confiable para saber si está enganchado a alguien o no.
## Duplica el material una vez por instancia: sin eso todos los Centinelas
## del mapa comparten el mismo Resource y cambian de color juntos.
## Fuerza emission_operator a Multiply: material_1 lo trae en Add (default
## de Godot) y con la textura emisiva ya blanca ahí, "blanco + mi color" da
## siempre blanco -- ningún tinte se nota. En Multiply la textura actúa
## como máscara de intensidad y el color sí se ve.
## current_color lleva el parpadeo de ruido ya aplicado -- LaserSightComponent
## lo usa tal cual para que el hilo de puntería titile en sincro con el cuerpo.

@export var model: Node3D
@export var emissive_material: StandardMaterial3D  ## material_1, el que ya usa su textura como máscara de emisión
@export var percept: PerceptComponent
@export var health_component: HealthComponent

@export var color_active: Color = Color(0.15, 0.55, 1.0)
@export var color_alert: Color = Color(1.0, 0.85, 0.1)
@export var color_reload: Color = Color(1.0, 1.0, 1.0)
@export var color_damaged: Color = Color(1.0, 0.1, 0.1)
@export var damaged_flash_duration: float = 0.35
@export var emission_energy: float = 4.0  ## Multiply pide más energía que Add para brillar igual
@export_range(0.0, 1.0) var albedo_tint_strength: float = 0.6  ## 0 = placa gris intacta, 1 = tiñe la placa entera
@export var noise_speed: float = 4.0  ## qué tan rápido titila
@export_range(0.0, 1.0) var noise_strength: float = 0.2  ## 0 = color plano, 1 = parpadeo fuerte

var current_color: Color = Color(0.15, 0.55, 1.0)  ## leído por otros componentes (ej. LaserSightComponent) para no duplicar la prioridad de estados

var _local_material: StandardMaterial3D
var _damaged_timer: float = 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	if emissive_material == null or model == null:
		return
	_local_material = emissive_material.duplicate()
	_local_material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	_local_material.emission_energy_multiplier = emission_energy
	_apply_to_meshes(model)
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
	_noise.seed = randi()

func _process(delta: float) -> void:
	if _local_material == null:
		return
	var color: Color
	if _damaged_timer > 0.0:
		_damaged_timer -= delta
		color = color_damaged
	else:
		color = _color_for_state()
	color = _flicker(color)
	current_color = color
	_local_material.emission = color
	_local_material.albedo_color = Color.WHITE.lerp(color, albedo_tint_strength)

## Nada de este juego debería tener un color liso y quieto -- un poco de
## ruido temporal (FastNoiseLite muestreado por tiempo, no por posición)
## simula la inestabilidad de una luz digital en vez de un LED perfecto.
func _flicker(color: Color) -> Color:
	var n: float = _noise.get_noise_1d(Time.get_ticks_msec() / 1000.0 * noise_speed)
	var mult: float = 1.0 + n * noise_strength
	return Color(color.r * mult, color.g * mult, color.b * mult, color.a)

func _color_for_state() -> Color:
	if percept == null:
		return color_active
	if percept.blackboard.get("firing", false):
		return color_alert
	if percept.blackboard.get("target") != null:
		return color_reload
	return color_active

func _on_damaged(_amount: int) -> void:
	_damaged_timer = damaged_flash_duration

## Recorre el modelo buscando las superficies que usan el material emisivo
## compartido y les pone el override local -- el material real vive en las
## superficies del ArrayMesh importado, no en los MeshInstance3D.
func _apply_to_meshes(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		for i in node.mesh.get_surface_count():
			if node.mesh.surface_get_material(i) == emissive_material:
				node.set_surface_override_material(i, _local_material)
	for child in node.get_children():
		_apply_to_meshes(child)
