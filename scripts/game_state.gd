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
	VULTURE
}


# Emitted any time the logical state changes (placement, movement,
# capture, or game over). The Board/UI listen to this instead of
# polling every frame.
signal state_changed


var phase: Phase = Phase.PLACEMENT
var turn: Turn = Turn.CROWS

var board := {}

var crows_placed := 0
var captured_crows := 0
var vulture_position := ""

var game_over := false
var winner: Winner = Winner.NONE


func _init() -> void:
	for point_id in BoardTopology.CONNECTIONS.keys():
		board[point_id] = ""


func is_empty(point_id: String) -> bool:
	return board.get(point_id, "") == ""


# Returns an independent copy of this state. Used by the AI to try
# out hypothetical moves without touching the live game and without
# firing state_changed for every dead-end it explores.
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

	return copy


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

	if crows_placed == 1:
		turn = Turn.VULTURE

	elif crows_placed == 7:
		phase = Phase.MOVEMENT
		turn = Turn.VULTURE

		# The seventh crow may trap the vulture immediately.
		# Once placement is complete, check whether the vulture
		# has either a normal move or a legal capture.
		check_crow_victory()

	state_changed.emit()

	return true


func place_vulture(point_id: String) -> bool:
	if game_over:
		return false

	if phase != Phase.PLACEMENT:
		return false

	if turn != Turn.VULTURE:
		return false

	if vulture_position != "":
		return false

	if not is_empty(point_id):
		return false

	board[point_id] = "VULTURE"
	vulture_position = point_id

	turn = Turn.CROWS

	state_changed.emit()

	return true


func move_vulture(destination: String) -> bool:
	if game_over:
		return false

	if phase != Phase.MOVEMENT:
		return false

	if turn != Turn.VULTURE:
		return false

	if vulture_position == "":
		return false

	if not is_empty(destination):
		return false

	if not BoardTopology.are_connected(vulture_position, destination):
		return false

	var old_position := vulture_position

	board[old_position] = ""
	board[destination] = "VULTURE"

	vulture_position = destination
	turn = Turn.CROWS

	state_changed.emit()

	return true


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

	if phase != Phase.MOVEMENT:
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

	if captured_crows >= 4:
		game_over = true
		winner = Winner.VULTURE
		state_changed.emit()
		return true

	turn = Turn.CROWS

	state_changed.emit()

	return true


func move_crow(origin: String, destination: String) -> bool:
	if game_over:
		return false

	if phase != Phase.MOVEMENT:
		return false

	if turn != Turn.CROWS:
		return false

	if board.get(origin, "") != "CROW":
		return false

	if not is_empty(destination):
		return false

	if not BoardTopology.are_connected(origin, destination):
		return false

	board[origin] = ""
	board[destination] = "CROW"

	turn = Turn.VULTURE

	check_crow_victory()

	state_changed.emit()

	return true


func get_vulture_normal_moves() -> Array:
	var legal_moves := []

	if vulture_position == "":
		return legal_moves

	for neighbor in BoardTopology.get_neighbors(vulture_position):
		if is_empty(neighbor):
			legal_moves.append(neighbor)

	return legal_moves


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
	if get_vulture_normal_moves().size() > 0:
		return true

	if get_vulture_captures().size() > 0:
		return true

	return false


func check_crow_victory() -> bool:
	if game_over:
		return false

	if phase != Phase.MOVEMENT:
		return false

	if turn != Turn.VULTURE:
		return false

	if has_any_vulture_action():
		return false

	game_over = true
	winner = Winner.CROWS

	return true
