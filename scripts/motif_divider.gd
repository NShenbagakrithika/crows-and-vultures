extends Control

# A slim gold hairline with a small diamond at its center and a dot
# on either side - a simple nod to Indian textile/temple border
# patterns, used in place of a plain separator line.

@export var motif_color := Color(0.85, 0.65, 0.25, 0.55)


func _draw() -> void:
	var mid_y := size.y / 2.0
	var center_x := size.x / 2.0

	draw_line(Vector2(0, mid_y), Vector2(center_x - 14, mid_y), motif_color, 1.5)
	draw_line(Vector2(center_x + 14, mid_y), Vector2(size.x, mid_y), motif_color, 1.5)

	var diamond := PackedVector2Array([
		Vector2(center_x, mid_y - 6),
		Vector2(center_x + 6, mid_y),
		Vector2(center_x, mid_y + 6),
		Vector2(center_x - 6, mid_y),
	])
	draw_colored_polygon(diamond, motif_color)

	draw_circle(Vector2(center_x - 20, mid_y), 2.0, motif_color)
	draw_circle(Vector2(center_x + 20, mid_y), 2.0, motif_color)
