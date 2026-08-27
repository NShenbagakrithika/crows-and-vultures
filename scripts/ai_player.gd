class_name AIPlayer
extends RefCounted

# A stateless AI. Every function takes a GameState and hands back
# either an evaluation score or a chosen action - it never mutates
# the real game. Board.gd applies whatever action comes back using
# the exact same GameState methods a human click would use.
#
# Scoring convention: positive scores favor the Vulture, negative
# scores favor the Crows. Whoever is currently "on move" in the
# state being searched picks the branch that's best for their own
# side (Vulture maximizes, Crows minimizes) - this falls naturally
# out of GameState.turn at every ply, including the placement
# phase's non-alternating turns (crows 2-6 are placed back-to-back).


const EASY_RANDOM_CHANCE := 0.35


# Picks an action for whichever side is currently on move in `state`.
# If add_randomness is true (used for Easy difficulty), sometimes
# ignores the search and plays a random legal action instead, so the
# AI is beatable.
static func choose_action(
	state: GameState,
	depth: int,
	add_randomness: bool = false
) -> Dictionary:

	var actions := generate_actions(state)

	if actions.is_empty():
		return {}

	if add_randomness and randf() < EASY_RANDOM_CHANCE:
		return actions[randi() % actions.size()]

	var maximizing := state.turn == GameState.Turn.VULTURE

	var best_action: Dictionary = actions[0]
	var best_value: float = -INF if maximizing else INF

	var alpha := -INF
	var beta := INF

	for action in actions:
		var next_state := apply_action(state, action)
		var value := minimax(next_state, depth - 1, alpha, beta)

		if maximizing:
			if value > best_value:
				best_value = value
				best_action = action
			alpha = max(alpha, value)
		else:
			if value < best_value:
				best_value = value
				best_action = action
			beta = min(beta, value)

	return best_action


static func minimax(
	state: GameState,
	depth: int,
	alpha: float,
	beta: float
) -> float:

	if depth <= 0 or state.game_over:
		return evaluate(state)

	var actions := generate_actions(state)

	if actions.is_empty():
		return evaluate(state)

	var maximizing := state.turn == GameState.Turn.VULTURE

	if maximizing:
		var best: float = -INF

		for action in actions:
			var next_state := apply_action(state, action)
			var value := minimax(next_state, depth - 1, alpha, beta)

			best = max(best, value)
			alpha = max(alpha, value)

			if alpha >= beta:
				break

		return best

	else:
		var best: float = INF

		for action in actions:
			var next_state := apply_action(state, action)
			var value := minimax(next_state, depth - 1, alpha, beta)

			best = min(best, value)
			beta = min(beta, value)

			if alpha >= beta:
				break

		return best


# Positive favors Vulture, negative favors Crows.
static func evaluate(state: GameState) -> float:
	if state.game_over:
		if state.winner == GameState.Winner.VULTURE:
			return 100000.0
		elif state.winner == GameState.Winner.CROWS:
			return -100000.0

		return 0.0

	var score := 0.0

	# Captures are most of the way to winning - weight them heavily.
	score += state.captured_crows * 300.0

	# The Vulture wants freedom of movement; the Crows want to take
	# that freedom away, which is how they actually win.
	var normal_moves := state.get_vulture_normal_moves().size()
	var captures_available := state.get_vulture_captures().size()

	score += normal_moves * 6.0
	score += captures_available * 40.0

	return score


# All legal actions for whichever side is currently on move.
static func generate_actions(state: GameState) -> Array:
	var actions := []

	if state.game_over:
		return actions

	if state.phase == GameState.Phase.PLACEMENT:
		if state.turn == GameState.Turn.CROWS:
			for point_id in state.board.keys():
				if state.is_empty(point_id):
					actions.append({
						"kind": "place_crow",
						"destination": point_id
					})
		else:
			for point_id in state.board.keys():
				if state.is_empty(point_id):
					actions.append({
						"kind": "place_vulture",
						"destination": point_id
					})

	else:
		if state.turn == GameState.Turn.VULTURE:
			for destination in state.get_vulture_normal_moves():
				actions.append({
					"kind": "move_vulture",
					"destination": destination
				})

			for destination in state.get_vulture_captures():
				actions.append({
					"kind": "capture_vulture",
					"destination": destination
				})

		else:
			for origin in state.board.keys():
				if state.board[origin] == "CROW":
					for neighbor in BoardTopology.get_neighbors(origin):
						if state.is_empty(neighbor):
							actions.append({
								"kind": "move_crow",
								"origin": origin,
								"destination": neighbor
							})

	return actions


static func apply_action(state: GameState, action: Dictionary) -> GameState:
	var next_state := state.clone()

	match action["kind"]:
		"place_crow":
			next_state.place_crow(action["destination"])
		"place_vulture":
			next_state.place_vulture(action["destination"])
		"move_vulture":
			next_state.move_vulture(action["destination"])
		"capture_vulture":
			next_state.capture_with_vulture(action["destination"])
		"move_crow":
			next_state.move_crow(action["origin"], action["destination"])

	return next_state
