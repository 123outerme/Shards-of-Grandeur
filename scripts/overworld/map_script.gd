@tool
extends Node2D
class_name MapScript

class TileDef:
	var layer: int = 0
	var atlasId: int = 0
	var atlasPos: Vector2i = Vector2i()
	var altTileId: int = 0
	
	func _init(
		i_layer = 0,
		i_atlasId = 0,
		i_atlasPos = Vector2i(),
		i_altTile = 0
	):
		layer = i_layer
		atlasId = i_atlasId
		atlasPos = i_atlasPos
		altTileId = i_altTile

signal map_loaded

@export var autoAssignTwoLayerTiles: bool:
	get:
		return false
	set(value):
		_assign_two_layer_tiles()

func _ready():
	map_loaded.emit()

func _assign_two_layer_tiles():
	if Engine.is_editor_hint():
		print('Matched two-layer terrain tiles')
		var bottomTiles: Array[TileDef] = [
			TileDef.new(1, 1, Vector2i(0,1)),
			TileDef.new(1, 1, Vector2i(1,1)),
			TileDef.new(1, 1, Vector2i(2,1)),
			TileDef.new(1, 2, Vector2i(0,1)),
			TileDef.new(1, 2, Vector2i(1,1)),
			TileDef.new(1, 2, Vector2i(2,1)),
			TileDef.new(1, 5, Vector2i(0,1)),
		]
		var topTiles: Array[TileDef] = [
			TileDef.new(2, 1, Vector2i(0,0)),
			TileDef.new(2, 1, Vector2i(1,0)),
			TileDef.new(2, 1, Vector2i(2,0)),
			TileDef.new(2, 2, Vector2i(0,0)),
			TileDef.new(2, 2, Vector2i(1,0)),
			TileDef.new(2, 2, Vector2i(2,0)),
			TileDef.new(2, 5, Vector2i(0,0)),
		]
		var deltas: Array[Vector2i] = [
			Vector2i(0, -1),
			Vector2i(0, -1),
			Vector2i(0, -1),
			Vector2i(0, -1),
			Vector2i(0, -1),
			Vector2i(0, -1),
			Vector2i(0, -1),
		]
		
		var tilemap: TileMap = get_node("TileMap")
		
		for idx in len(bottomTiles):
			for tilePos in tilemap.get_used_cells_by_id(bottomTiles[idx].layer, bottomTiles[idx].atlasId, bottomTiles[idx].atlasPos, bottomTiles[idx].altTileId):
				var topTilePos: Vector2i = Vector2i(tilePos.x + deltas[idx].x, tilePos.y + deltas[idx].y)
				tilemap.set_cell(topTiles[idx].layer, topTilePos, topTiles[idx].atlasId, topTiles[idx].atlasPos, topTiles[idx].altTileId)
