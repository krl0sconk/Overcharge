extends CanvasLayer

@onready var hp_bar_p1: TextureProgressBar = $HBarP1
@onready var hp_bar_p2: TextureProgressBar = $HBarP2
@onready var timer_label: Label = $TimerContainer/TimeLabel

@onready var attack_button_p1: TextureButton = $AttackButtonP1
@onready var attack_button_p2: TextureButton = $AttackButtonP2
@onready var attack_button_combo: TextureButton = $AttackButtonCombo

var hp_p1: float = 100.0
var hp_p2: float = 100.0
var time_left: float = 99.0

# --- Cooldowns (en segundos) ---
const COOLDOWN_P1: float = 1.5
const COOLDOWN_P2: float = 1.5
const COOLDOWN_COMBO: float = 3.0

const COLOR_NORMAL: Color = Color(1, 1, 1)
const COLOR_COOLDOWN: Color = Color(0.5, 0.5, 0.5)

var cooldown_p1_left: float = 0.0
var cooldown_p2_left: float = 0.0
var cooldown_combo_left: float = 0.0

func _ready() -> void:
	hp_bar_p1.max_value = 100
	hp_bar_p2.max_value = 100

	hp_bar_p1.value = hp_p1
	hp_bar_p2.value = hp_p2

	timer_label.text = str(int(time_left))

func _process(delta: float) -> void:
	if cooldown_p1_left > 0:
		cooldown_p1_left -= delta
		if cooldown_p1_left <= 0:
			cooldown_p1_left = 0
			attack_button_p1.disabled = false
			attack_button_p1.modulate = COLOR_NORMAL

	if cooldown_p2_left > 0:
		cooldown_p2_left -= delta
		if cooldown_p2_left <= 0:
			cooldown_p2_left = 0
			attack_button_p2.disabled = false
			attack_button_p2.modulate = COLOR_NORMAL

	if cooldown_combo_left > 0:
		cooldown_combo_left -= delta
		if cooldown_combo_left <= 0:
			cooldown_combo_left = 0
			attack_button_combo.disabled = false
			attack_button_combo.modulate = COLOR_NORMAL

func _on_attack_button_combo_pressed() -> void:
	print("Ataque combinado")
	attack_button_combo.disabled = true
	attack_button_combo.modulate = COLOR_COOLDOWN
	cooldown_combo_left = COOLDOWN_COMBO

func _on_attack_button_p_2_pressed() -> void:
	print("Ataque P2")
	attack_button_p2.disabled = true
	attack_button_p2.modulate = COLOR_COOLDOWN
	cooldown_p2_left = COOLDOWN_P2

func _on_attack_button_p_1_pressed() -> void:
	print("Ataque P1")
	attack_button_p1.disabled = true
	attack_button_p1.modulate = COLOR_COOLDOWN
	cooldown_p1_left = COOLDOWN_P1
