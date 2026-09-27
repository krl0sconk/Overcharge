extends CanvasLayer

@onready var hp_bar_p1: TextureProgressBar = $HBarP1
@onready var hp_bar_p2: TextureProgressBar = $HBarP2
@onready var timer_label: Label = $TimerContainer/TimeLabel

@onready var attack_button_p1: TextureButton = $AttackButtonP1
@onready var attack_button_p2: TextureButton = $AttackButtonP2
@onready var attack_button_combo: TextureButton = $AttackButtonCombo

const COLOR_NORMAL: Color = Color(1, 1, 1)
const COLOR_COOLDOWN: Color = Color(0.5, 0.5, 0.5)

var time_left: float = 99.0

# --- Referencias reales a los jugadores y sus componentes ---
var player_p1: Node = null  # Nitzsch
var player_p2: Node = null  # Plato

var ability_p1: AbilityComponent = null  # ComboAbilityComponent de Nitzsch
var ability_p2: AbilityComponent = null  # AbilityComponent (proyectil) de Plato

# --- Cooldown del "ataque combinado" (todavía no hay habilidad real detrás) ---
const COOLDOWN_COMBO: float = 3.0
var cooldown_combo_left: float = 0.0

func _ready() -> void:
	timer_label.text = str(int(time_left))
	call_deferred("_setup_players")

func _setup_players() -> void:
	_find_players()
	print("DEBUG player_p1: ", player_p1)
	print("DEBUG player_p2: ", player_p2)
	_connect_health_signals()
	_connect_ability_references()

func _find_players() -> void:
	for player in get_tree().get_nodes_in_group("players"):
		if player is Nitzsch:
			player_p1 = player
		elif player is Plato:
			player_p2 = player

func _connect_health_signals() -> void:
	if player_p1 != null and player_p1.health_component != null:
		print("DEBUG conectando P1, max_health: ", player_p1.health_component.stats.max_health)
		hp_bar_p1.max_value = player_p1.health_component.stats.max_health
		hp_bar_p1.value = player_p1.health_component.current_health
		player_p1.health_component.damaged.connect(_on_p1_damaged)
		player_p1.health_component.died.connect(_on_p1_died)
	else:
		print("DEBUG P1 no conectado -- player_p1: ", player_p1, " health_component: ", player_p1.health_component if player_p1 != null else "N/A")

	if player_p2 != null and player_p2.health_component != null:
		print("DEBUG conectando P2, max_health: ", player_p2.health_component.stats.max_health)
		hp_bar_p2.max_value = player_p2.health_component.stats.max_health
		hp_bar_p2.value = player_p2.health_component.current_health
		player_p2.health_component.damaged.connect(_on_p2_damaged)
		player_p2.health_component.died.connect(_on_p2_died)
	else:
		print("DEBUG P2 no conectado -- player_p2: ", player_p2, " health_component: ", player_p2.health_component if player_p2 != null else "N/A")

func _connect_ability_references() -> void:
	if player_p1 != null:
		ability_p1 = player_p1.get_node_or_null("ComboAbilityComponent")
	if player_p2 != null:
		ability_p2 = player_p2.ability_component  # AbilityComponent genérico (proyectil)

func _on_p1_damaged(_amount: int) -> void:
	print("DEBUG P1 recibió daño: ", _amount)
	hp_bar_p1.value = player_p1.health_component.current_health

func _on_p1_died() -> void:
	hp_bar_p1.value = 0

func _on_p2_damaged(_amount: int) -> void:
	print("DEBUG P2 recibió daño: ", _amount)
	hp_bar_p2.value = player_p2.health_component.current_health

func _on_p2_died() -> void:
	hp_bar_p2.value = 0

func _process(delta: float) -> void:
	_update_attack_button(attack_button_p1, ability_p1)
	_update_attack_button(attack_button_p2, ability_p2)

	if cooldown_combo_left > 0:
		cooldown_combo_left -= delta
		if cooldown_combo_left <= 0:
			cooldown_combo_left = 0
			attack_button_combo.disabled = false
			attack_button_combo.modulate = COLOR_NORMAL

func _update_attack_button(button: TextureButton, ability: AbilityComponent) -> void:
	if ability == null or button == null:
		return

	var is_ready: bool = ability.state == AbilityComponent.State.READY
	button.disabled = not is_ready
	button.modulate = COLOR_NORMAL if is_ready else COLOR_COOLDOWN

func _on_attack_button_combo_pressed() -> void:
	print("Ataque combinado")
	attack_button_combo.disabled = true
	attack_button_combo.modulate = COLOR_COOLDOWN
	cooldown_combo_left = COOLDOWN_COMBO

func _on_attack_button_p_2_pressed() -> void:
	print("Ataque P2")

func _on_attack_button_p_1_pressed() -> void:
	print("Ataque P1")
