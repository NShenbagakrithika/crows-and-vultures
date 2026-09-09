class_name GameState
extends RefCounted


enum Phase {
	PLACEMENT,
	MOVEMENT
}


enum Turn {
	CROWS,
	VULTURE
}


enum Winner {
	NONE,
	CROWS,
	VULTURE,
	DRAW
}


signal state_changed


var phase: Phase = Phase.PLACEMENT
var turn: Turn = Turn.CROWS

var board := {}

var crows_placed := 0
var captured_crows := 0
var vulture_position := ""

var game_over := false
var winner: Winner = Winner.NONE

# Used for threefold-repetition detection.
# Only movement-phase positions are counted.
var position_history := {}


func _init() -> void:
	for point_id in BoardTopology.CONNECTIONS.keys():
		board[point_id] = ""


# --------------------------------------------------
# BASIC HELPERS
# --------------------------------------------------

func is_empty(point_id: String) -> bool:
	return board.get(point_id, "") == ""


func clone() -> GameState:
	var copy := GameState.new()

	copy.phase = phase
	copy.turn = turn
	copy.board = board.duplicate()
	copy.crows_placed = crows_placed
	copy.captured_crows = captured_crows
	copy.vulture_position = vulture_position
	copy.game_over = game_over
	copy.winner = winner
	copy.position_history = position_history.duplicate()

	return copy


# --------------------------------------------------
# CROW PLACEMENT
# --------------------------------------------------

func place_crow(point_id: String) -> bool:
	if game_over:
		return false

	if phase != Phase.PLACEMENT:
		return false

	if turn != Turn.CROWS:
		return false

	if crows_placed >= 7:
		return false

	if not is_empty(point_id):
		return false

	board[point_id] = "CROW"
	crows_placed += 1

	# After every crow placement, the vulture gets its turn.
	turn = Turn.VULTURE

	# Once the seventh crow is placed, crow placement ends.
	if crows_placed >= 7:
		phase = Phase.MOVEMENT

	# If the vulture already exists, the newly placed crow might
	# have trapped it.
	if vulture_position != "":
		check_crow_victory()

	if not game_over:
		register_position()

	state_changed.emit()
	return true


# --------------------------------------------------
# VULTURE PLACEMENT
# --------------------------------------------------

func place_vulture(point_id: String) -> bool:
	if game_over:
		return false

	if phase != Phase.PLACEMENT:
		return false

	if turn != Turn.VULTURE:
		return false

	# The vulture may only be placed once.
	if vulture_position != "":
		return false

	# The first crow must already have been placed.
	if crows_placed < 1:
		return false

	if not is_empty(point_id):
		return false

	board[point_id] = "VULTURE"
	vulture_position = point_id

	turn = Turn.CROWS

	state_changed.emit()
	return true


# --------------------------------------------------
# VULTURE NORMAL MOVEMENT
# --------------------------------------------------

func move_vulture(destination: String) -> bool:
	if game_over:
		return false

	if turn != Turn.VULTURE:
		return false

	if vulture_position == "":
		return false

	if not is_empty(destination):
		return false

	# Capture is compulsory.
	# If even one capture exists, normal movement is illegal.
	if get_vulture_captures().size() > 0:
		return false

	if not BoardTopology.are_connected(
		vulture_position,
		destination
	):
		return false

	var old_position := vulture_position

	board[old_position] = ""
	board[destination] = "VULTURE"

	vulture_position = destination
	turn = Turn.CROWS

	register_position()

	state_changed.emit()
	return true


# --------------------------------------------------
# VULTURE CAPTURE LOGIC
# --------------------------------------------------

func get_capture_middle(
	origin: String,
	destination: String
) -> String:

	for path in BoardTopology.CAPTURE_PATHS:
		var point_a: String = path[0]
		var middle: String = path[1]
		var point_c: String = path[2]

		if origin == point_a and destination == point_c:
			return middle

		if origin == point_c and destination == point_a:
			return middle

	return ""


func can_vulture_capture(destination: String) -> bool:
	if game_over:
		return false

	if turn != Turn.VULTURE:
		return false

	if vulture_position == "":
		return false

	if not is_empty(destination):
		return false

	var middle := get_capture_middle(
		vulture_position,
		destination
	)

	if middle == "":
		return false

	if board.get(middle, "") != "CROW":
		return false

	return true


func capture_with_vulture(destination: String) -> bool:
	if not can_vulture_capture(destination):
		return false

	var old_position := vulture_position

	var captured_position := get_capture_middle(
		old_position,
		destination
	)

	board[old_position] = ""
	board[captured_position] = ""
	board[destination] = "VULTURE"

	vulture_position = destination
	captured_crows += 1

	# Only one crow is captured.
	# The turn ends immediately after this capture.

	if captured_crows >= 4:
		game_over = true
		winner = Winner.VULTURE

		state_changed.emit()
		return true

	turn = Turn.CROWS

	register_position()

	state_changed.emit()
	return true


# --------------------------------------------------
# CROW MOVEMENT
# --------------------------------------------------

func move_crow(
	origin: String,
	destination: String
) -> bool:

	if game_over:
		return false

	# Crows cannot move until all seven have been placed.
	if phase != Phase.MOVEMENT:
		return false

	if turn != Turn.CROWS:
		return false

	if board.get(origin, "") != "CROW":
		return false

	if not is_empty(destination):
		return false

	if not BoardTopology.are_connected(
		origin,
		destination
	):
		return false

	board[origin] = ""
	board[destination] = "CROW"

	turn = Turn.VULTURE

	# A crow move may completely trap the vulture.
	check_crow_victory()

	if not game_over:
		register_position()

	state_changed.emit()
	return true


# --------------------------------------------------
# VULTURE LEGAL MOVES
# --------------------------------------------------

func get_vulture_raw_normal_moves() -> Array:
	var legal_moves := []

	if vulture_position == "":
		return legal_moves

	for neighbor in BoardTopology.get_neighbors(
		vulture_position
	):
		if is_empty(neighbor):
			legal_moves.append(neighbor)

	return legal_moves


func get_vulture_normal_moves() -> Array:
	# Mandatory capture rule:
	# normal movement disappears whenever a capture exists.
	if get_vulture_captures().size() > 0:
		return []

	return get_vulture_raw_normal_moves()


func get_vulture_captures() -> Array:
	var legal_captures := []

	if vulture_position == "":
		return legal_captures

	for destination in board.keys():

		if destination == vulture_position:
			continue

		if not is_empty(destination):
			continue

		var middle := get_capture_middle(
			vulture_position,
			destination
		)

		if middle == "":
			continue

		if board.get(middle, "") == "CROW":
			legal_captures.append(destination)

	return legal_captures


func has_any_vulture_action() -> bool:
	if get_vulture_captures().size() > 0:
		return true

	if get_vulture_raw_normal_moves().size() > 0:
		return true

	return false


# --------------------------------------------------
# CROW VICTORY
# --------------------------------------------------

func check_crow_victory() -> bool:
	if game_over:
		return false

	if turn != Turn.VULTURE:
		return false

	if vulture_position == "":
		return false

	if has_any_vulture_action():
		return false

	game_over = true
	winner = Winner.CROWS

	return true


# --------------------------------------------------
# THREEFOLD REPETITION / DRAW
# --------------------------------------------------

func get_position_key() -> String:
	var crow_positions := []

	for point_id in board.keys():
		if board[point_id] == "CROW":
			crow_positions.append(point_id)

	crow_positions.sort()

	var turn_name := "CROWS"

	if turn == Turn.VULTURE:
		turn_name = "VULTURE"

	var phase_name := "PLACEMENT"

	if phase == Phase.MOVEMENT:
		phase_name = "MOVEMENT"

	return "%s|%s|%s|%s|%d|%d" % [
		phase_name,
		turn_name,
		vulture_position,
		",".join(crow_positions),
		crows_placed,
		captured_crows
	]


func register_position() -> void:
	if game_over:
		return

	# Repetition is only relevant once normal movement begins.
	if phase != Phase.MOVEMENT:
		return

	var key := get_position_key()

	var occurrences: int = position_history.get(
		key,
		0
	)

	occurrences += 1
	position_history[key] = occurrences

	if occurrences >= 3:
		game_over = true
		winner = Winner.DRAW
