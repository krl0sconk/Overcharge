class_name Nitzsch
extends Entidad

## Controlador de Ni-TZSch: traduce las intenciones del InputComponent a los
## demás componentes. Ataque por ComboAbilityComponent, dash por
## DashAbilityComponent; ambos disparan su clip en AnimationComponent.

@export var attack_window: float = 0.2
@export var turn_speed: float = 10.0  ## rad/s

@onready var dash_component: AbilityComponent = get_node_or_null("DashAbilityComponent")
@onready var combo_component: AbilityComponent = get_node_or_null("ComboAbilityComponent")
@onready var animation_component: AnimationComponent = get_node_or_null("AnimationComponent")

var _attack_buffered: bool = false  ## guarda como mucho un golpe pendiente; spamear la tecla no apila más
var _combo_hit_lock: float = 0.0  ## tiempo mínimo entre golpes ejecutados, igual al duration del combo

func _physics_process(delta: float) -> void:
	if input_component == null or movement_component == null:
		return

	movement_component.set_move_direction(input_component.move_dir)

	## Congelado mirando para donde dasheó: si gira con el input mientras el
	## dash sigue activo, se ve como si el dash se cortara aunque la
	## animación y el estado sigan corriendo normal.
	var dashing: bool = dash_component != null and dash_component.state == AbilityComponent.State.ACTIVE
	if not dashing:
		_face_move_direction(delta)

	if input_component.consume_attack():
		_attack_buffered = true

	if _combo_hit_lock > 0.0:
		_combo_hit_lock -= delta

	## Pasado el candado (la ventana comprometida del golpe), un golpe en
	## cola tiene prioridad; si no hay ninguno y el jugador está moviéndose,
	## cancela el combo en vez de dejarlo congelado esperando un encadenado
	## que ya no va a llegar.
	if _combo_hit_lock <= 0.0:
		if _attack_buffered and combo_component != null:
			_attack_buffered = false
			_try_attack()
		elif input_component.move_dir != Vector3.ZERO and combo_component != null:
			combo_component.try_cancel()

	if input_component.consume_dash() and dash_component != null \
			and dash_component.state == AbilityComponent.State.READY:
		dash_component.try_execute()
		if animation_component != null:
			animation_component.play_dash()

## Lee current_hit antes de ejecutar: execute() ya lo incrementa para dejar
## listo el próximo golpe, así que después ya no identifica cuál acaba de
## conectar. Repite el criterio de AbilityComponent.try_execute() (READY, o
## ACTIVE con can_chain) porque éste se sale en silencio cuando no está
## listo: sin la comprobación acá, la animación se dispara en golpes que
## nunca ocurrieron.
func _try_attack() -> void:
	var combo: ComboAbility = combo_component.ability as ComboAbility
	var can_execute: bool = combo_component.state == AbilityComponent.State.READY \
			or (combo_component.state == AbilityComponent.State.ACTIVE and combo.can_chain)
	if not can_execute:
		return

	var hit_index: int = combo.current_hit
	movement_component.stop()
	combo_component.try_execute()
	_combo_hit_lock = combo.duration

	if animation_component != null:
		animation_component.play_combo_hit(hit_index)
	if hitbox_component != null:
		hitbox_component.open_window(attack_window)

## Mismo criterio que TurnToTarget.gd: +PI porque el modelo mira +Z, no -Z.
func _face_move_direction(delta: float) -> void:
	var direction: Vector3 = input_component.move_dir
	if direction == Vector3.ZERO:
		return
	var target_yaw: float = atan2(direction.x, direction.z) + PI
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)
