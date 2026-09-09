class_name AIPlayer
extends RefCounted


const EASY_RANDOM_CHANCE := 0.35


# --------------------------------------------------
# CHOOSE ACTION
# --------------------------------------------------

static func choose_action(
	state: GameState,
	depth: int,
	add_randomness: bool = false
) -> Dictionary:

	var actions := generate_actions(state)

	if actions.is_empty():
		return {}

	if (
		add_randomness
		and randf() < EASY_RANDOM_CHANCE
	):
		return actions[
			randi() % actions.size()
		]

	var maximizing := (
		state.turn
		== GameState.Turn.VULTURE
	)

	var best_action: Dictionary = actions[0]

	var best_value: float = (
		-INF
		if maximizing
		else INF
	)

	var alpha := -INF
	var beta := INF

	for action in actions:

		var next_state := apply_action(
			state,
			action
		)

		var value := minimax(
			next_state,
			depth - 1,
			alpha,
			beta
		)

		if maximizing:

			if value > best_value:
				best_value = value
				best_action = action

			alpha = max(
				alpha,
				value
			)

		else:

			if value < best_value:
				best_value = value
				best_action = action

			beta = min(
				beta,
				value
			)

	return best_action


# --------------------------------------------------
# MINIMAX
# --------------------------------------------------

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

	var maximizing := (
		state.turn
		== GameState.Turn.VULTURE
	)

	if maximizing:

		var best: float = -INF

		for action in actions:

			var next_state := apply_action(
				state,
				action
			)

			var value := minimax(
				next_state,
				depth - 1,
				alpha,
				beta
			)

			best = max(
				best,
				value
			)

			alpha = max(
				alpha,
				value
			)

			if alpha >= beta:
				break

		return best

	else:

		var best: float = INF

		for action in actions:

			var next_state := apply_action(
				state,
				action
			)

			var value := minimax(
				next_state,
				depth - 1,
				alpha,
				beta
			)

			best = min(
				best,
				value
			)

			beta = min(
				beta,
				value
			)

			if alpha >= beta:
				break

		return best


# --------------------------------------------------
# EVALUATION
# --------------------------------------------------

static func evaluate(
	state: GameState
) -> float:

	if state.game_over:

		if (
			state.winner
			== GameState.Winner.VULTURE
		):
			return 100000.0

		if (
			state.winner
			== GameState.Winner.CROWS
		):
			return -100000.0

		# Draw.
		return 0.0

	var score := 0.0

	# Capturing crows is the vulture's main objective.
	score += (
		state.captured_crows
		* 300.0
	)

	# Use raw movement mobility for evaluation.
	# Mandatory capture should not hide positional freedom
	# from the heuristic.
	var normal_moves := (
		state
		.get_vulture_raw_normal_moves()
		.size()
	)

	var captures_available := (
		state
		.get_vulture_captures()
		.size()
	)

	score += normal_moves * 6.0
	score += captures_available * 40.0

	# Being close to immobilisation should strongly favour crows.
	if normal_moves == 0 and captures_available == 0:
		score -= 5000.0

	return score


# --------------------------------------------------
# ACTION GENERATION
# --------------------------------------------------

static func generate_actions(
	state: GameState
) -> Array:

	var actions := []

	if state.game_over:
		return actions

	# ----------------------------------------------
	# CROWS
	# ----------------------------------------------

	if state.turn == GameState.Turn.CROWS:

		# During placement, crows can only drop a new crow.
		if state.phase == GameState.Phase.PLACEMENT:

			for point_id in state.board.keys():

				if state.is_empty(point_id):

					actions.append({
						"kind": "place_crow",
						"destination": point_id
					})

			return actions

		# After all seven have been placed,
		# existing crows may move.
		for origin in state.board.keys():

			if state.board[origin] != "CROW":
				continue

			for neighbor in BoardTopology.get_neighbors(
				origin
			):

				if state.is_empty(neighbor):

					actions.append({
						"kind": "move_crow",
						"origin": origin,
						"destination": neighbor
					})

		return actions

	# ----------------------------------------------
	# VULTURE
	# ----------------------------------------------

	# The vulture's very first action is placement.
	if state.vulture_position == "":

		for point_id in state.board.keys():

			if state.is_empty(point_id):

				actions.append({
					"kind": "place_vulture",
					"destination": point_id
				})

		return actions

	# Once placed, the vulture can move/capture
	# during BOTH the crow-placement phase
	# and normal movement phase.

	var captures := state.get_vulture_captures()

	# Capture is compulsory.
	if captures.size() > 0:

		for destination in captures:

			actions.append({
				"kind": "capture_vulture",
				"destination": destination
			})

		return actions

	for destination in state.get_vulture_normal_moves():

		actions.append({
			"kind": "move_vulture",
			"destination": destination
		})

	return actions


# --------------------------------------------------
# SIMULATE ACTION
# --------------------------------------------------

static func apply_action(
	state: GameState,
	action: Dictionary
) -> GameState:

	var next_state := state.clone()

	match action["kind"]:

		"place_crow":
			next_state.place_crow(
				action["destination"]
			)

		"place_vulture":
			next_state.place_vulture(
				action["destination"]
			)

		"move_vulture":
			next_state.move_vulture(
				action["destination"]
			)

		"capture_vulture":
			next_state.capture_with_vulture(
				action["destination"]
			)

		"move_crow":
			next_state.move_crow(
				action["origin"],
				action["destination"]
			)

	return next_state
