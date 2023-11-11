@tool
extends Node2D
class_name MapScript

signal map_loaded

@export var autoAssignTreeTops: bool:
	get:
		return false
	set(value):
		_assign_tree_tops(value)

func _ready():
	map_loaded.emit()

func _assign_tree_tops(booleanVal: bool):
	if Engine.is_editor_hint():
		var tilemap: TileMap = get_node("TileMap")
		for tree1Tile in tilemap.get_used_cells_by_id(1, 1, Vector2i(0,1)):
			var tree1TopTile: Vector2i = Vector2i(tree1Tile.x, tree1Tile.y - 1)
			tilemap.set_cell(2, tree1TopTile, 1, Vector2i(0, 0))
		for tree2Tile in tilemap.get_used_cells_by_id(1, 1, Vector2i(1,1)):
			var tree2TopTile: Vector2i = Vector2i(tree2Tile.x, tree2Tile.y - 1)
			tilemap.set_cell(2, tree2TopTile, 1, Vector2i(1, 0))
		for tree3Tile in tilemap.get_used_cells_by_id(1, 1, Vector2i(2,1)):
			var tree3TopTile: Vector2i = Vector2i(tree3Tile.x, tree3Tile.y - 1)
			tilemap.set_cell(2, tree3TopTile, 1, Vector2i(2, 0))
	pass
