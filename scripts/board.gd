extends Node2D


const POINT_RADIUS := 9.0
const CLICK_RADIUS := 24.0
const PIECE_RADIUS := 20.0

# P0-P9 labels were only for development.
const SHOW_DEBUG_LABELS := false

const BOARD_CENTER := Vector2(400, 350)

const LINE_COLOR := Color(0.85, 0.68, 0.30)
const CROW_COLOR := Color(0.10, 0.58, 0.62)
const VULTURE_COLOR := Color(0.92, 0.62, 0.13)
const MOVE_HIGHLIGHT_COLOR := Color(0.20, 0.83, 0.60)
const CAPTURE_HIGHLIGHT_COLOR := Color(0.97, 0.44, 0.44)
const MOTIF_COLOR := Color(0.85, 0.65, 0.25)

const AI_THINK_MIN_DELAY := 0.45
const AI_THINK_MAX_DELAY := 0.95


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

const EDGES := [
	["P0", "P2"],
	["P2", "P4"],
	["P4", "P1"],
	["P1", "P3"],
	["P3", "P0"],
]

# Bird silhouettes, authored in local space against a reference
# PIECE_RADIUS of 20.0 and scaled at draw time. Both face right,
# perched, with a beak/tail that pokes slightly past the coin edge
# for a bit of character.
var crow_shape := PackedVector2Array([
	Vector2(-16, 4),
	Vector2(-9, -6),
	Vector2(-2, -13),
	Vector2(6, -13),
	Vector2(13, -9),
	Vector2(18, -6),
	Vector2(14, -3),
	Vector2(9, 1),
	Vector2(10, 8),
	Vector2(-2, 12),
	Vector2(-11, 9),
])

var vulture_shape := PackedVector2Array([
	Vector2(-18, 6),
	Vector2(-10, -8),
	Vector2(-3, -15),
	Vector2(7, -14),
	Vector2(14, -8),
	Vector2(20, -3),
	Vector2(16, 2),
	Vector2(10, 3),
	Vector2(12, 10),
	Vector2(-2, 14),
	Vector2(-13, 10),
])


# Emitted whenever anything the UI cares about changes: a move, a
# placement, a capture, a game over, a restart, or the AI starting
# to "think".
signal board_updated


# Logical state of the current match.
var game_state := GameState.new()

# Currently selected piece, if any.
var selected_point := ""

# Point currently under the mouse cursor, for hover feedback.
var hovered_point := ""

# True while the AI's move is queued behind AITimer.
var ai_thinking := false

# Accumulates every frame to drive the pulsing glow animations.
var glow_time := 0.0

@onready var ai_timer: Timer = $AITimer


func _ready() -> void:
	game_state.state_changed.connect(_on_state_changed)

	ai_timer.one_shot = true
	ai_timer.timeout.connect(_on_ai_timer_timeout)

	queue_redraw()
	maybe_trigger_ai()


func _process(delta: float) -> void:
	glow_time += delta
	queue_redraw()


func _on_state_changed() -> void:
	queue_redraw()
	board_updated.emit()
	maybe_trigger_ai()


# --------------------------------------------------
# RESTART
# --------------------------------------------------

func restart_game() -> void:
	ai_timer.stop()
	ai_thinking = false

	game_state = GameState.new()
	game_state.state_changed.connect(_on_state_changed)

	selected_point = ""
	hovered_point = ""

	queue_redraw()
	board_updated.emit()
	maybe_trigger_ai()


# --------------------------------------------------
# AI TURN HANDLING
# --------------------------------------------------

func maybe_trigger_ai() -> void:
	if GameConfig.mode != GameConfig.Mode.HUMAN_VS_AI:
		return

	if game_state.game_over:
		return

	if game_state.turn != GameConfig.get_ai_side():
		return

	if ai_thinking:
		return

	ai_thinking = true
	board_updated.emit()

	ai_timer.start(randf_range(AI_THINK_MIN_DELAY, AI_THINK_MAX_DELAY))


func _on_ai_timer_timeout() -> void:
	perform_ai_move()


func perform_ai_move() -> void:
	ai_thinking = false

	if game_state.game_over:
		board_updated.emit()
		return

	if game_state.turn != GameConfig.get_ai_side():
		board_updated.emit()
		return

	var depth := GameConfig.get_search_depth()
	var add_randomness := GameConfig.difficulty == GameConfig.Difficulty.EASY

	var action := AIPlayer.choose_action(game_state, depth, add_randomness)

	if action.is_empty():
		board_updated.emit()
		return

	match action["kind"]:
		"place_crow":
			game_state.place_crow(action["destination"])
		"place_vulture":
			game_state.place_vulture(action["destination"])
		"move_vulture":
			game_state.move_vulture(action["destination"])
		"capture_vulture":
			game_state.capture_with_vulture(action["destination"])
		"move_crow":
			game_state.move_crow(action["origin"], action["destination"])


func is_input_locked() -> bool:
	if game_state.game_over:
		return true

	if ai_thinking:
		return true

	if GameConfig.mode == GameConfig.Mode.HUMAN_VS_AI:
		if game_state.turn == GameConfig.get_ai_side():
			return true

	return false


# --------------------------------------------------
# INPUT
# --------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var point := get_point_at_position(event.position)

		if point != hovered_point:
			hovered_point = point
			queue_redraw()

		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			if is_input_locked():
				return

			var clicked_point := get_point_at_position(event.position)

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
		game_state.place_crow(clicked_point)

	elif game_state.turn == GameState.Turn.VULTURE:
		game_state.place_vulture(clicked_point)


# --------------------------------------------------
# MOVEMENT PHASE
# --------------------------------------------------

func handle_movement_click(clicked_point: String) -> void:
	if game_state.turn == GameState.Turn.VULTURE:
		handle_vulture_movement_click(clicked_point)

	elif game_state.turn == GameState.Turn.CROWS:
		handle_crow_movement_click(clicked_point)


func handle_vulture_movement_click(clicked_point: String) -> void:

	# First click must select the vulture.
	if selected_point == "":
		if clicked_point == game_state.vulture_position:
			selected_point = clicked_point
			queue_redraw()

		return

	# Clicking the selected vulture again cancels selection.
	if clicked_point == selected_point:
		selected_point = ""
		queue_redraw()
		return

	# Try a capture first; if that's not legal at this destination,
	# fall back to a normal move.
	if game_state.can_vulture_capture(clicked_point):
		if game_state.capture_with_vulture(clicked_point):
			selected_point = ""
			queue_redraw()

		return

	if game_state.move_vulture(clicked_point):
		selected_point = ""
		queue_redraw()


func handle_crow_movement_click(clicked_point: String) -> void:

	# First click selects a crow.
	if selected_point == "":
		if game_state.board.get(clicked_point, "") == "CROW":
			selected_point = clicked_point
			queue_redraw()

		return

	# Clicking the selected crow again cancels selection.
	if clicked_point == selected_point:
		selected_point = ""
		queue_redraw()
		return

	if game_state.move_crow(selected_point, clicked_point):
		selected_point = ""
		queue_redraw()


# --------------------------------------------------
# LEGAL MOVE LOOKUP (used for highlighting the selected piece)
# --------------------------------------------------

func get_legal_destinations() -> Array:
	var results := []

	if selected_point == "":
		return results

	if game_state.phase != GameState.Phase.MOVEMENT:
		return results

	if game_state.turn == GameState.Turn.VULTURE and selected_point == game_state.vulture_position:
		for destination in game_state.get_vulture_normal_moves():
			results.append({"point": destination, "capture": false})

		for destination in game_state.get_vulture_captures():
			results.append({"point": destination, "capture": true})

	elif game_state.turn == GameState.Turn.CROWS \
	and game_state.board.get(selected_point, "") == "CROW":
		for neighbor in BoardTopology.get_neighbors(selected_point):
			if game_state.is_empty(neighbor):
				results.append({"point": neighbor, "capture": false})

	return results


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
	draw_ambient_glow()
	draw_mandala_ring()
	draw_board_lines()
	draw_intersections()

	if SHOW_DEBUG_LABELS:
		draw_point_labels()

	draw_legal_highlights()
	draw_pieces()
	draw_selection_ring()


func draw_ambient_glow() -> void:
	draw_circle(BOARD_CENTER, 340.0, Color(0.85, 0.65, 0.25, 0.05))
	draw_circle(BOARD_CENTER, 250.0, Color(0.85, 0.65, 0.25, 0.04))


func draw_mandala_ring() -> void:
	const PETAL_COUNT := 16
	const RING_RADIUS := 300.0

	var petal := PackedVector2Array([
		Vector2(RING_RADIUS - 9, -5),
		Vector2(RING_RADIUS + 15, 0),
		Vector2(RING_RADIUS - 9, 5),
		Vector2(RING_RADIUS - 2, 0),
	])

	var petal_color := Color(MOTIF_COLOR.r, MOTIF_COLOR.g, MOTIF_COLOR.b, 0.10)

	for i in PETAL_COUNT:
		var angle := i * TAU / PETAL_COUNT

		draw_set_transform(BOARD_CENTER, angle, Vector2.ONE)
		draw_colored_polygon(petal, petal_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var ring_line_color := Color(MOTIF_COLOR.r, MOTIF_COLOR.g, MOTIF_COLOR.b, 0.08)
	draw_arc(BOARD_CENTER, RING_RADIUS, 0.0, TAU, 64, ring_line_color, 1.0)


func draw_board_lines() -> void:
	for edge in EDGES:
		var point_a: Vector2 = POINTS[edge[0]]
		var point_b: Vector2 = POINTS[edge[1]]

		draw_line(point_a, point_b, Color(0.85, 0.68, 0.30, 0.20), 7.0)
		draw_line(point_a, point_b, LINE_COLOR, 2.5)


func draw_intersections() -> void:
	for point_position in POINTS.values():
		draw_arc(point_position, POINT_RADIUS + 3.0, 0.0, TAU, 20, Color(1, 0.95, 0.85, 0.15), 1.5)
		draw_circle(point_position, POINT_RADIUS, Color(0.98, 0.94, 0.86, 0.88))


func draw_point_labels() -> void:
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


func draw_legal_highlights() -> void:
	if selected_point == "":
		return

	var pulse := (sin(glow_time * 3.0) + 1.0) / 2.0

	for entry in get_legal_destinations():
		var point_id: String = entry["point"]
		var is_capture: bool = entry["capture"]

		var point_position: Vector2 = POINTS[point_id]
		var base_color: Color = CAPTURE_HIGHLIGHT_COLOR if is_capture else MOVE_HIGHLIGHT_COLOR

		var is_hovered := point_id == hovered_point

		var radius := PIECE_RADIUS + 6.0 + pulse * 3.0
		var ring_alpha := 0.45 + pulse * 0.25
		var fill_alpha := 0.16

		if is_hovered:
			radius += 4.0
			ring_alpha = 0.85
			fill_alpha = 0.30

		draw_circle(point_position, radius, Color(base_color.r, base_color.g, base_color.b, fill_alpha))
		var ring_color := Color(base_color.r, base_color.g, base_color.b, ring_alpha)
		draw_arc(point_position, radius, 0.0, TAU, 28, ring_color, 2.5)


func draw_pieces() -> void:
	for point_id in game_state.board:
		var piece = game_state.board[point_id]
		var point_position: Vector2 = POINTS[point_id]

		if piece == "CROW":
			_draw_piece(point_position, CROW_COLOR, false)
		elif piece == "VULTURE":
			_draw_piece(point_position, VULTURE_COLOR, true)


func _draw_piece(center: Vector2, coin_color: Color, is_vulture: bool) -> void:
	# Soft drop shadow.
	draw_circle(center + Vector2(0, 3), PIECE_RADIUS, Color(0, 0, 0, 0.35))

	# Coin base and fill.
	draw_circle(center, PIECE_RADIUS, coin_color.darkened(0.5))
	draw_circle(center, PIECE_RADIUS - 3.0, coin_color)

	# Bird silhouette, drawn in its own local coordinate space so the
	# art can be authored once at a fixed reference size and simply
	# scale with PIECE_RADIUS.
	var art_scale := PIECE_RADIUS / 20.0
	draw_set_transform(center, 0.0, Vector2(art_scale, art_scale))

	if is_vulture:
		_draw_vulture_silhouette()
	else:
		_draw_crow_silhouette()

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Rim, back in world space.
	draw_arc(center, PIECE_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 1.5)


func _draw_crow_silhouette() -> void:
	draw_colored_polygon(crow_shape, Color(0.05, 0.08, 0.14, 0.92))

	# Folded-wing crease.
	var wing_points := PackedVector2Array([
		Vector2(-6, -2),
		Vector2(0, -4),
		Vector2(6, 1),
	])
	draw_polyline(wing_points, Color(1, 1, 1, 0.18), 1.5, true)

	# Eye.
	draw_circle(Vector2(6, -9), 1.4, Color(0.9, 0.95, 1.0, 0.9))


func _draw_vulture_silhouette() -> void:
	draw_colored_polygon(vulture_shape, Color(0.12, 0.08, 0.05, 0.92))

	# Bald head, the classic vulture tell.
	draw_circle(Vector2(9, -8), 5.5, Color(0.80, 0.68, 0.60, 0.95))

	# Hooked beak.
	var beak_points := PackedVector2Array([
		Vector2(15, -8),
		Vector2(22, -4),
		Vector2(16, -1),
	])
	draw_colored_polygon(beak_points, Color(0.85, 0.7, 0.35, 0.95))

	# Eye.
	draw_circle(Vector2(9, -9), 1.3, Color(0.1, 0.05, 0.02, 0.9))


func draw_selection_ring() -> void:
	if selected_point == "":
		return

	var pulse := (sin(glow_time * 4.0) + 1.0) / 2.0
	var radius := PIECE_RADIUS + 8.0 + pulse * 4.0

	draw_arc(POINTS[selected_point], radius, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 3.0)
	draw_arc(POINTS[selected_point], radius + 5.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 1.5)
