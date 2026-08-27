extends Control


@onready var board: Node2D = %Board

@onready var turn_label: Label = %TurnLabel
@onready var ai_thinking_label: Label = %AIThinkingLabel
@onready var phase_label: Label = %PhaseLabel
@onready var crows_label: Label = %CrowsLabel
@onready var captured_label: Label = %CapturedLabel
@onready var capture_pips: Control = %CapturePips
@onready var mode_label: Label = %ModeLabel

@onready var game_over_panel: PanelContainer = %GameOverPanel
@onready var winner_label: Label = %WinnerLabel
@onready var rematch_button: Button = %RematchButton
@onready var main_menu_button: Button = %MainMenuButton

@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	board.board_updated.connect(_on_board_updated)

	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_main_menu_pressed)
	rematch_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	_update_mode_label()
	_on_board_updated()


func _update_mode_label() -> void:
	if GameConfig.mode == GameConfig.Mode.HUMAN_VS_HUMAN:
		mode_label.text = "Human vs Human"
	else:
		var side_name := "Crows" if GameConfig.human_side == GameState.Turn.CROWS else "Vulture"
		mode_label.text = "You: %s  •  %s AI" % [side_name, GameConfig.difficulty_name()]


func _on_board_updated() -> void:
	var gs: GameState = board.game_state

	_update_turn_label(gs)
	_update_phase_label(gs)

	crows_label.text = "Crows placed: %d / 7" % gs.crows_placed
	captured_label.text = "Crows captured: %d / 4" % gs.captured_crows
	capture_pips.set_captured(gs.captured_crows)

	ai_thinking_label.visible = board.ai_thinking

	if gs.game_over:
		_show_game_over(gs)
	else:
		game_over_panel.visible = false


func _update_turn_label(gs: GameState) -> void:
	var suffix := ""

	if GameConfig.mode == GameConfig.Mode.HUMAN_VS_AI:
		if gs.turn == GameConfig.human_side:
			suffix = " (You)"
		else:
			suffix = " (AI)"

	if gs.turn == GameState.Turn.CROWS:
		turn_label.text = "Turn: Crows" + suffix
		turn_label.modulate = Color(0.20, 0.72, 0.76)
	else:
		turn_label.text = "Turn: Vulture" + suffix
		turn_label.modulate = Color(0.92, 0.62, 0.13)


func _update_phase_label(gs: GameState) -> void:
	if gs.phase == GameState.Phase.PLACEMENT:
		phase_label.text = "Phase: Placement"
	else:
		phase_label.text = "Phase: Movement"


func _show_game_over(gs: GameState) -> void:
	if gs.winner == GameState.Winner.CROWS:
		winner_label.text = "Crows Win!\nThe vulture has no legal moves left."
		winner_label.modulate = Color(0.20, 0.72, 0.76)

	elif gs.winner == GameState.Winner.VULTURE:
		winner_label.text = "Vulture Wins!\n4 crows have been captured."
		winner_label.modulate = Color(0.92, 0.62, 0.13)

	else:
		winner_label.text = "Game Over"
		winner_label.modulate = Color.WHITE

	game_over_panel.visible = true


func _on_restart_pressed() -> void:
	board.restart_game()


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
