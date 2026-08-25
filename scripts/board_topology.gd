class_name BoardTopology
extends RefCounted


const CONNECTIONS := {
	"P0": ["P5", "P9"],
	"P1": ["P5", "P6"],
	"P2": ["P6", "P7"],
	"P3": ["P7", "P8"],
	"P4": ["P8", "P9"],

	"P5": ["P0", "P6", "P9", "P1"],
	"P6": ["P5", "P2", "P1", "P7"],
	"P7": ["P2", "P8", "P6", "P3"],
	"P8": ["P7", "P4", "P3", "P9"],
	"P9": ["P4", "P8", "P5", "P0"],
}


const CAPTURE_PATHS := [
	["P0", "P5", "P6"],
	["P5", "P6", "P2"],

	["P2", "P7", "P8"],
	["P7", "P8", "P4"],

	["P4", "P9", "P5"],
	["P9", "P5", "P1"],

	["P1", "P6", "P7"],
	["P6", "P7", "P3"],

	["P3", "P8", "P9"],
	["P8", "P9", "P0"],
]


static func get_neighbors(point_id: String) -> Array:
	return CONNECTIONS.get(point_id, [])


static func are_connected(point_a: String, point_b: String) -> bool:
	return point_b in get_neighbors(point_a)
