extends Node2D


const POINT_RADIUS := 10.0
const CLICK_RADIUS := 22.0
const PIECE_RADIUS := 18.0


# Visual positions of the 10 playable intersections.
const POINTS := {
	# Five outer points
	"P0": Vector2(400, 80),
	"P1": Vector2(680, 285),
	"P2": Vector2(575, 615),
	"P3": Vector2(225, 615),
	"P4": Vector2(120, 285),

	# Five inner intersections
	"P5": Vector2(467.06, 285.00),
	"P6": Vector2(507.89, 409.83),
	"P7": Vector2(400.00, 488.08),
	"P8": Vector2(292.11, 409.83),
	"P9": Vector2(332.94, 285.00),
}


# Logical state of the current match.
var game_state := GameState.new()

# Stores the currently selected piece position.
var selected_point := ""


func _ready() -> void:
	queue_redraw()


# --------------------------------------------------
# INPUT
# --------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			# Once somebody has won, the board becomes locked.
			if game_state.game_over:
				print("Game is over. No more moves allowed.")
				return

			var clicked_point := get_point_at_position(event.position)

			# Temporary input debugging.
			print("Mouse clicked at: ", event.position)
			print("Detected board point: ", clicked_point)

			# Ignore clicks outside the 10 playable intersections.
			if clicked_point == "":
				return

			if game_state.phase == GameState.Phase.PLACEMENT:
				handle_placement_click(clicked_point)

			elif game_state.phase == GameState.Phase.MOVEMENT:
				handle_movement_click(clicked_point)


# --------------------------------------------------
# PLACEMENT PHASE
# --------------------------------------------------

func handle_placement_click(clicked_point: String) -> void:
	if game_state.turn == GameState.Turn.CROWS:

		if game_state.place_crow(clicked_point):
			print(
				"Crow placed at: ",
				clicked_point,
				" | Total crows: ",
				game_state.crows_placed
			)

			if game_state.phase == GameState.Phase.MOVEMENT:
				print("PLACEMENT PHASE COMPLETE")
				print("MOVEMENT PHASE STARTED")
				print("FIRST MOVEMENT TURN: VULTURE")

			queue_redraw()

		else:
			print(
				"Crow placement rejected at: ",
				clicked_point
			)

	elif game_state.turn == GameState.Turn.VULTURE:

		if game_state.place_vulture(clicked_point):
			print(
				"Vulture placed at: ",
				clicked_point
			)

			queue_redraw()

		else:
			print(
				"Vulture placement rejected at: ",
				clicked_point
			)


# --------------------------------------------------
# MOVEMENT PHASE
# --------------------------------------------------

func handle_movement_click(clicked_point: String) -> void:
	if game_state.turn == GameState.Turn.VULTURE:
		handle_vulture_movement_click(clicked_point)

	elif game_state.turn == GameState.Turn.CROWS:
		handle_crow_movement_click(clicked_point)


# --------------------------------------------------
# VULTURE MOVEMENT AND CAPTURE
# --------------------------------------------------

func handle_vulture_movement_click(clicked_point: String) -> void:

	# First click must select the vulture.
	if selected_point == "":
		if clicked_point == game_state.vulture_position:
			selected_point = clicked_point

			print(
				"Vulture selected at: ",
				clicked_point
			)

			queue_redraw()

		else:
			print("Select the vulture first.")

		return


	# Clicking the selected vulture again cancels selection.
	if clicked_point == selected_point:
		selected_point = ""

		print("Vulture selection cancelled.")

		queue_redraw()
		return


	# --------------------------------------------------
	# CAPTURE
	# --------------------------------------------------

	# Always check whether the requested destination
	# represents a legal capture before trying a
	# normal movement.
	if game_state.can_vulture_capture(clicked_point):

		var old_position := selected_point

		var captured_position := game_state.get_capture_middle(
			old_position,
			clicked_point
		)

		if game_state.capture_with_vulture(clicked_point):

			print(
				"Vulture captured crow at ",
				captured_position,
				" and landed at ",
				clicked_point
			)

			print(
				"CAPTURED CROWS: ",
				game_state.captured_crows
			)

			selected_point = ""

			queue_redraw()


			# ------------------------------------------
			# VULTURE WIN
			# ------------------------------------------

			if game_state.game_over:
				print("VULTURE WINS!")
				print("4 CROWS CAPTURED")
				return


			# A successful capture always ends the
			# vulture's turn.
			print("TURN: CROWS")

		return


	# --------------------------------------------------
	# NORMAL VULTURE MOVEMENT
	# --------------------------------------------------

	if game_state.move_vulture(clicked_point):

		print(
			"Vulture moved from ",
			selected_point,
			" to ",
			clicked_point
		)

		selected_point = ""

		print("TURN: CROWS")

		queue_redraw()

	else:
		print(
			"Illegal vulture action from ",
			selected_point,
			" to ",
			clicked_point
		)


# --------------------------------------------------
# CROW MOVEMENT
# --------------------------------------------------

func handle_crow_movement_click(clicked_point: String) -> void:

	# First click selects a crow.
	if selected_point == "":

		if game_state.board.get(clicked_point, "") == "CROW":
			selected_point = clicked_point

			print(
				"Crow selected at: ",
				clicked_point
			)

			queue_redraw()

		else:
			print("Select a crow first.")

		return


	# Clicking the selected crow again cancels selection.
	if clicked_point == selected_point:
		selected_point = ""

		print("Crow selection cancelled.")

		queue_redraw()
		return


	# Attempt to move the selected crow.
	if game_state.move_crow(
		selected_point,
		clicked_point
	):

		print(
			"Crow moved from ",
			selected_point,
			" to ",
			clicked_point
		)

		selected_point = ""

		if game_state.game_over:
			print("CROWS WIN!")
			print("VULTURE HAS NO LEGAL ACTIONS")
		else:
			print("TURN: VULTURE")

		queue_redraw()

	else:
		print(
			"Illegal crow move from ",
			selected_point,
			" to ",
			clicked_point
		)


# --------------------------------------------------
# POINT DETECTION
# --------------------------------------------------

func get_point_at_position(mouse_position: Vector2) -> String:

	for point_id in POINTS:
		var point_position: Vector2 = POINTS[point_id]

		if mouse_position.distance_to(point_position) <= CLICK_RADIUS:
			return point_id

	return ""


# --------------------------------------------------
# DRAWING
# --------------------------------------------------

func _draw() -> void:
	draw_board()
	draw_intersections()
	draw_point_labels()
	draw_pieces()
	draw_selection()


# --------------------------------------------------
# DRAW BOARD
# --------------------------------------------------

func draw_board() -> void:

	# Five strokes forming the pentagram.

	draw_line(
		POINTS["P0"],
		POINTS["P2"],
		Color.WHITE,
		3.0
	)

	draw_line(
		POINTS["P2"],
		POINTS["P4"],
		Color.WHITE,
		3.0
	)

	draw_line(
		POINTS["P4"],
		POINTS["P1"],
		Color.WHITE,
		3.0
	)

	draw_line(
		POINTS["P1"],
		POINTS["P3"],
		Color.WHITE,
		3.0
	)

	draw_line(
		POINTS["P3"],
		POINTS["P0"],
		Color.WHITE,
		3.0
	)


# --------------------------------------------------
# DRAW INTERSECTIONS
# --------------------------------------------------

func draw_intersections() -> void:

	for point_position in POINTS.values():

		draw_circle(
			point_position,
			POINT_RADIUS,
			Color.WHITE
		)


# --------------------------------------------------
# DRAW DEBUG POINT LABELS
# --------------------------------------------------

func draw_point_labels() -> void:

	# P0-P9 are temporary development labels.
	# We'll remove them when we start visual polish.

	for point_id in POINTS:

		var point_position: Vector2 = POINTS[point_id]

		draw_string(
			ThemeDB.fallback_font,
			point_position + Vector2(14, -14),
			point_id,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			18,
			Color.WHITE
		)


# --------------------------------------------------
# DRAW PIECES
# --------------------------------------------------

func draw_pieces() -> void:

	for point_id in game_state.board:

		var piece = game_state.board[point_id]

		# Crow placeholder.
		if piece == "CROW":

			draw_circle(
				POINTS[point_id],
				PIECE_RADIUS,
				Color.SKY_BLUE
			)

		# Vulture placeholder.
		elif piece == "VULTURE":

			draw_circle(
				POINTS[point_id],
				PIECE_RADIUS,
				Color.GOLD
			)


# --------------------------------------------------
# DRAW SELECTED PIECE
# --------------------------------------------------

func draw_selection() -> void:

	if selected_point == "":
		return

	draw_arc(
		POINTS[selected_point],
		PIECE_RADIUS + 7.0,
		0.0,
		TAU,
		32,
		Color.WHITE,
		3.0
	)
