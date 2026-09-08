extends Control


@onready var mode_panel: Control = %ModePanel
@onready var ai_panel: Control = %AIPanel

@onready var hvh_button: Button = %HumanVsHumanButton
@onready var hva_button: Button = %HumanVsAIButton

@onready var side_crows_button: Button = %SideCrowsButton
@onready var side_vulture_button: Button = %SideVultureButton

@onready var difficulty_easy_button: Button = %DifficultyEasyButton
@onready var difficulty_normal_button: Button = %DifficultyNormalButton
@onready var difficulty_hard_button: Button = %DifficultyHardButton

@onready var start_button: Button = %StartButton
@onready var back_button: Button = %BackButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	hvh_button.pressed.connect(_on_human_vs_human_pressed)
	hva_button.pressed.connect(_on_human_vs_ai_pressed)
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	side_crows_button.button_pressed = true
	difficulty_normal_button.button_pressed = true

	ai_panel.visible = false
	mode_panel.visible = true


func _on_human_vs_human_pressed() -> void:
	GameConfig.mode = GameConfig.Mode.HUMAN_VS_HUMAN
	_start_game()


func _on_human_vs_ai_pressed() -> void:
	ai_panel.visible = true
	mode_panel.visible = false


func _on_back_pressed() -> void:
	ai_panel.visible = false
	mode_panel.visible = true


func _on_start_pressed() -> void:
	GameConfig.mode = GameConfig.Mode.HUMAN_VS_AI

	if side_crows_button.button_pressed:
		GameConfig.human_side = GameState.Turn.CROWS
	else:
		GameConfig.human_side = GameState.Turn.VULTURE

	if difficulty_easy_button.button_pressed:
		GameConfig.difficulty = GameConfig.Difficulty.EASY
	elif difficulty_hard_button.button_pressed:
		GameConfig.difficulty = GameConfig.Difficulty.HARD
	else:
		GameConfig.difficulty = GameConfig.Difficulty.NORMAL

	_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
