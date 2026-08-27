extends Control

# Draws a row of small dots representing captured crows out of 4.
# Filled = captured, hollow = still safe.

const TOTAL := 4
const RADIUS := 7.0
const SPACING := 22.0

var captured := 0


func set_captured(value: int) -> void:
	if value == captured:
		return

	captured = value
	queue_redraw()


func _draw() -> void:
	var start_x := RADIUS + 2.0
	var center_y := size.y / 2.0

	for i in TOTAL:
		var center := Vector2(start_x + i * SPACING, center_y)

		if i < captured:
			draw_circle(center, RADIUS, Color(0.92, 0.62, 0.13))
		else:
			draw_circle(center, RADIUS, Color(1, 1, 1, 0.10))
			draw_arc(center, RADIUS, 0.0, TAU, 20, Color(1, 1, 1, 0.35), 1.5)
