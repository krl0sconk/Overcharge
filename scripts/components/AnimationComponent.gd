class_name AnimationComponent
extends Node

## Traduce el movimiento y las habilidades de Ni-TZSch a viajes del
## AnimationTree. Nadie fuera de este componente llama a travel(): los
## golpes de una sola pasada (combos, dash) se piden desde afuera con
## play_combo_hit()/play_dash(), el resto (idle/walk) lo decide este
## componente solo mirando la velocidad.

## Combos: el propio AnimationTree los saca de acá (AUTO + at_end) apenas
## termina el clip. Dash no entra en esta lista: se maneja aparte, contra
## dash_component, porque tiene que quedarse en el último frame en vez de
## volver a Idle solo.
const ONE_SHOT_STATES: Array[String] = ["Combo1", "Combo2", "Combo3"]

@export var animation_tree: AnimationTree
@export var owner_body: CharacterBody3D
@export var dash_component: AbilityComponent  ## solo para saber cuándo el dash devuelve el control, no para arrancarlo
@export var idle_speed_threshold: float = 0.15
@export var walk_speed_scale: float = 1.5  ## multiplica el playback del clip Walk (ver AnimationNodeTimeScale del estado Walk)

var _playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	if animation_tree == null:
		push_error("AnimationComponent sin animation_tree asignado")
		set_process(false)
		return
	if owner_body == null:
		push_error("AnimationComponent sin owner_body asignado")
		set_process(false)
		return

	animation_tree.active = true
	_playback = animation_tree.get("parameters/playback")
	animation_tree.set("parameters/Walk/TimeScale/scale", walk_speed_scale)

func play_combo_hit(hit_index: int) -> void:
	_playback.travel("Combo%d" % (hit_index + 1))

func play_dash() -> void:
	_playback.travel("Dash")

## El clip de Dash es más corto que lo que dura la habilidad (NitzschDash.tres
## iguala duration al largo del clip), así que al terminar de reproducirse se
## queda congelado en el último frame -- no hay transición automática hacia
## Idle en el AnimationTree para Dash. Recién se suelta cuando dash_component
## deja ACTIVE, o sea cuando el jugador recupera el control del movimiento.
func _process(_delta: float) -> void:
	var current_node: String = _playback.get_current_node()
	if current_node in ONE_SHOT_STATES:
		return
	if current_node == "Dash" and dash_component != null \
			and dash_component.state == AbilityComponent.State.ACTIVE:
		return

	var planar_speed: float = Vector2(owner_body.velocity.x, owner_body.velocity.z).length()
	if planar_speed > idle_speed_threshold:
		_playback.travel("Walk")
	else:
		_playback.travel("Idle")
