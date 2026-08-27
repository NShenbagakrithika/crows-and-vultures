extends Node

# Autoloaded as "GameConfig". Holds whatever the player picked on
# the menu screen so the game scene knows what to set up.


enum Mode {
	HUMAN_VS_HUMAN,
	HUMAN_VS_AI
}

enum Difficulty {
	EASY,
	NORMAL,
	HARD
}


var mode: int = Mode.HUMAN_VS_HUMAN

# Only meaningful when mode == HUMAN_VS_AI. Which side the human
# controls; the AI takes whichever side is left.
var human_side: int = GameState.Turn.CROWS

# Only meaningful when mode == HUMAN_VS_AI.
var difficulty: int = Difficulty.NORMAL


func get_ai_side() -> int:
	if human_side == GameState.Turn.CROWS:
		return GameState.Turn.VULTURE

	return GameState.Turn.CROWS


func get_search_depth() -> int:
	match difficulty:
		Difficulty.EASY:
			return 2
		Difficulty.NORMAL:
			return 3
		Difficulty.HARD:
			return 4

	return 3


func difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY:
			return "Easy"
		Difficulty.NORMAL:
			return "Normal"
		Difficulty.HARD:
			return "Hard"

	return "Normal"
