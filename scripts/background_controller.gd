extends ColorRect

# Sits on a CanvasLayer behind everything else and recolors the
# whole screen based on whose turn it is, so you can tell at a
# glance without reading the status panel.
#
# Deep indigo for Crows, deep maroon for Vulture - a nod to
# traditional Indian textile and temple palettes.

const CROW_BG := Color(0.07, 0.09, 0.19, 1.0)
const VULTURE_BG := Color(0.22, 0.06, 0.05, 1.0)
const NEUTRAL_BG := Color(0.08, 0.06, 0.06, 1.0)

const TRANSITION_DURATION := 0.5

@onready var board: Node2D = %Board

var active_tween: Tween


func _ready() -> void:
	board.board_updated.connect(_on_board_updated)
	color = _target_color(board.game_state)


func _on_board_updated() -> void:
	var target := _target_color(board.game_state)

	if color.is_equal_approx(target):
		return

	if active_tween:
		active_tween.kill()

	active_tween = create_tween()
	active_tween.tween_property(self, "color", target, TRANSITION_DURATION) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


func _target_color(gs: GameState) -> Color:
	if gs.game_over:
		return NEUTRAL_BG

	if gs.turn == GameState.Turn.CROWS:
		return CROW_BG

	return VULTURE_BG
