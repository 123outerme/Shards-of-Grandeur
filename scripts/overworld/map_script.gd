@tool
extends Node2D
class_name MapScript

class TileDef:
	var layer: String = ''
	var atlasId: int = 0
	var atlasPos: Vector2i = Vector2i()
	var altTileId: int = 0
	
	func _init(
		i_layer: String = '',
		i_atlasId: int = 0,
		i_atlasPos: Vector2i = Vector2i(),
		i_altTile: int = 0
	):
		layer = i_layer
		atlasId = i_atlasId
		atlasPos = i_atlasPos
		altTileId = i_altTile

signal map_loaded

@export_tool_button('Auto-Assign Two-Layer Tiles', 'TileMapLayer') var autoAssignTwoLayerTiles: Callable = _assign_two_layer_tiles

func _ready():
	map_loaded.emit()

func _assign_two_layer_tiles():
	if Engine.is_editor_hint():
		print('Matched two-layer terrain tiles')
		var bottomTiles: Array[TileDef] = [
			TileDef.new('Midground', 1, Vector2i(0,1)), # trees.png, 1st tree base
			TileDef.new('Midground', 1, Vector2i(1,1)), # trees.png, 2nd tree base
			TileDef.new('Midground', 1, Vector2i(2,1)), # trees.png, 3rd tree base
			TileDef.new('Midground', 1, Vector2i(4,1)), # trees.png, 5th tree base
			TileDef.new('Midground', 1, Vector2i(5,1)), # trees.png, 6th tree base
			TileDef.new('Midground', 1, Vector2i(6,1)), # trees.png, 7th tree base
			TileDef.new('Midground', 1, Vector2i(0,3)), # trees.png, 1st snowy tree base
			TileDef.new('Midground', 1, Vector2i(1,3)), # trees.png, 2nd snowy tree base
			TileDef.new('Midground', 1, Vector2i(2,3)), # trees.png, 3rd snowy tree base
			TileDef.new('Midground', 1, Vector2i(3,3)), # trees.png, 1st desert tree base
			TileDef.new('Midground', 1, Vector2i(4,3)), # trees.png, 2nd desert tree base
			TileDef.new('Midground', 1, Vector2i(0,5)), # trees.png, 1st burned tree base
			TileDef.new('Midground', 1, Vector2i(1,5)), # trees.png, 2nd burned tree base
			TileDef.new('Midground', 1, Vector2i(2,5)), # trees.png, 3rd burned tree base
			TileDef.new('Midground', 1, Vector2i(0,7)), # trees.png, 1st submerged tree shadow
			TileDef.new('Midground', 1, Vector2i(1,7)), # trees.png, 2nd submerged tree shadow
			TileDef.new('Midground', 1, Vector2i(2,7)), # trees.png, 3rd submerged tree shadow
			TileDef.new('Midground', 1, Vector2i(4,7)), # trees.png, 4th submerged tree shadow
			TileDef.new('Midground', 1, Vector2i(5,7)), # trees.png, 5th submerged tree shadow
			TileDef.new('Midground', 1, Vector2i(6,7)), # trees.png, 6th submerged tree shadow
			TileDef.new('Midground', 2, Vector2i(0,1)), # house.png, 1st left house
			TileDef.new('Midground', 2, Vector2i(1,1)), # house.png, 1st middle house
			TileDef.new('Midground', 2, Vector2i(2,1)), # house.png, 1st right house
			TileDef.new('Midground', 2, Vector2i(3,1)), # house.png, 2nd left house
			TileDef.new('Midground', 2, Vector2i(4,1)), # house.png, 2nd middle house
			TileDef.new('Midground', 2, Vector2i(5,1)), # house.png, 2nd right house
			TileDef.new('Midground', 2, Vector2i(0,3)), # house.png, Standstill burned left house
			TileDef.new('Midground', 2, Vector2i(1,3)), # house.png, Standstill burned middle house
			TileDef.new('Midground', 2, Vector2i(2,3)), # house.png, Standstill burned right house
			TileDef.new('Midground', 2, Vector2i(3,3)), # house.png, snowy left house
			TileDef.new('Midground', 2, Vector2i(4,3)), # house.png, snowy middle house
			TileDef.new('Midground', 2, Vector2i(5,3)), # house.png, snowy right house
			TileDef.new('Midground', 5, Vector2i(0,1)), # well.png, 1st well base
			TileDef.new('Midground', 5, Vector2i(1,1)), # well.png, 2nd well base
			TileDef.new('Midground', 22, Vector2i(2,1)), # ruined_castle.png, 1st house left
			TileDef.new('Midground', 22, Vector2i(3,1)), # ruined_castle.png, 1st house right
			TileDef.new('Midground', 22, Vector2i(4,1)), # ruined_castle.png, 2nd house left
			TileDef.new('Midground', 22, Vector2i(5,1)), # ruined_castle.png, 2nd house right
			TileDef.new('Midground', 29, Vector2i(0,3)), # animated_decals.png, large fire bottom
		]
		var topTiles: Array[TileDef] = [
			TileDef.new('Foreground', 1, Vector2i(0,0)), # trees.png, 1st tree top
			TileDef.new('Foreground', 1, Vector2i(1,0)), # trees.png, 2nd tree top
			TileDef.new('Foreground', 1, Vector2i(2,0)), # trees.png, 3rd tree top
			TileDef.new('Foreground', 1, Vector2i(4,0)), # trees.png, 5th tree top
			TileDef.new('Foreground', 1, Vector2i(5,0)), # trees.png, 6th tree top
			TileDef.new('Foreground', 1, Vector2i(6,0)), # trees.png, 7th tree top
			TileDef.new('Foreground', 1, Vector2i(0,2)), # trees.png, 1st snowy tree top
			TileDef.new('Foreground', 1, Vector2i(1,2)), # trees.png, 2nd snowy tree top
			TileDef.new('Foreground', 1, Vector2i(2,2)), # trees.png, 3rd snowy tree top
			TileDef.new('Foreground', 1, Vector2i(3,2)), # trees.png, 1st desert tree top
			TileDef.new('Foreground', 1, Vector2i(4,2)), # trees.png, 2nd desert tree top
			TileDef.new('Foreground', 1, Vector2i(0,4)), # trees.png, 1st burned tree top
			TileDef.new('Foreground', 1, Vector2i(1,4)), # trees.png, 2nd burned tree top
			TileDef.new('Foreground', 1, Vector2i(2,4)), # trees.png, 3rd burned tree top
			TileDef.new('Foreground', 1, Vector2i(0,6)), # trees.png, 1st submerged tree top
			TileDef.new('Foreground', 1, Vector2i(1,6)), # trees.png, 2nd submerged tree top
			TileDef.new('Foreground', 1, Vector2i(2,6)), # trees.png, 3rd submerged tree top
			TileDef.new('Foreground', 1, Vector2i(4,6)), # trees.png, 4th submerged tree top
			TileDef.new('Foreground', 1, Vector2i(5,6)), # trees.png, 5th submerged tree top
			TileDef.new('Foreground', 1, Vector2i(6,6)), # trees.png, 6th submerged tree top
			TileDef.new('Foreground', 2, Vector2i(0,0)), # house.png, 1st left house roof
			TileDef.new('Foreground', 2, Vector2i(1,0)), # house.png, 1st middle house roof
			TileDef.new('Foreground', 2, Vector2i(2,0)), # house.png, 1st right house roof 
			TileDef.new('Foreground', 2, Vector2i(3,0)), # house.png, 2nd left house roof
			TileDef.new('Foreground', 2, Vector2i(4,0)), # house.png, 2nd middle house roof
			TileDef.new('Foreground', 2, Vector2i(5,0)), # house.png, 2nd right house roof
			TileDef.new('Foreground', 2, Vector2i(0,2)), # house.png, Standstill burned left house roof
			TileDef.new('Foreground', 2, Vector2i(1,2)), # house.png, Standstill burned middle house roof
			TileDef.new('Foreground', 2, Vector2i(2,2)), # house.png, Standstill burned right house roof
			TileDef.new('Foreground', 2, Vector2i(3,2)), # house.png, snowy left house roof
			TileDef.new('Foreground', 2, Vector2i(4,2)), # house.png, snowy middle house roof
			TileDef.new('Foreground', 2, Vector2i(5,2)), # house.png, snowy right house roof
			TileDef.new('Foreground', 5, Vector2i(0,0)), # well.png, 1st well roof
			TileDef.new('Foreground', 5, Vector2i(1,0)), # well.png, 2nd well roof
			TileDef.new('Foreground', 22, Vector2i(2,0)), # ruined_castle.png, 1st house left roof
			TileDef.new('Foreground', 22, Vector2i(3,0)), # ruined_castle.png, 1st house right roof
			TileDef.new('Foreground', 22, Vector2i(4,0)), # ruined_castle.png, 2nd house left roof
			TileDef.new('Foreground', 22, Vector2i(5,0)), # ruined_castle.png, 2nd house right roof
			TileDef.new('Foreground', 29, Vector2i(0,2)), # animated_decals.png, large fire top
		]
		var deltas: Array[Vector2i] = [
			Vector2i(0, -1), # shift trees.png, 1st tree top up 1 from tree bottom position
			Vector2i(0, -1), # shift trees.png, 2nd tree top up 1
			Vector2i(0, -1), # shift trees.png, 3rd tree top up 1
			Vector2i(0, -1), # shift trees.png, 5th tree top up 1
			Vector2i(0, -1), # shfit trees.png, 6th tree top up 1
			Vector2i(0, -1), # shift trees.png, 7th tree top up 1
			Vector2i(0, -1), # shift trees.png, 1st snowy tree top up 1
			Vector2i(0, -1), # shift trees.png, 2nd snowy tree top up 1
			Vector2i(0, -1), # shift trees.png, 3rd snowy tree top up 1
			Vector2i(0, -1), # shift trees.png, 1st desert tree top up 1
			Vector2i(0, -1), # shift trees.png, 2nd desert tree top up 1
			Vector2i(0, -1), # shift trees.png, 1st burned tree top up 1
			Vector2i(0, -1), # shift trees.png, 2nd burned tree top up 1
			Vector2i(0, -1), # shift trees.png, 3rd burned tree top up 1
			Vector2i(0, -1), # shift trees.png, 1st submerged tree top up 1
			Vector2i(0, -1), # shift trees.png, 2nd submerged tree top up 1
			Vector2i(0, -1), # shift trees.png, 3rd submerged tree top up 1
			Vector2i(0, -1), # shift trees.png, 4th submerged tree top up 1
			Vector2i(0, -1), # shift trees.png, 5th submerged tree top up 1
			Vector2i(0, -1), # shift trees.png, 6th submerged tree top up 1
			Vector2i(0, -1), # shift house.png, 1st left house roof up 1
			Vector2i(0, -1), # shift house.png, 1st middle house roof up 1
			Vector2i(0, -1), # shift house.png, 1st right house roof up 1
			Vector2i(0, -1), # shift house.png, 2nd left house roof up 1
			Vector2i(0, -1), # shift house.png, 2nd middle house roof up 1
			Vector2i(0, -1), # shift house.png, 2nd right house roof up 1
			Vector2i(0, -1), # shift house.png, burned left house roof up 1
			Vector2i(0, -1), # shift house.png, burned middle house roof up 1
			Vector2i(0, -1), # shift house.png, burned right house roof up 1
			Vector2i(0, -1), # shift well.png, 1st well roof up 1
			Vector2i(0, -1), # shift well.png, 2nd well roof up 1
			Vector2i(0, -1), # shift ruined_castle.png, 1st house left roof up 1
			Vector2i(0, -1), # shift ruined_castle.png, 1st house right roof up 1
			Vector2i(0, -1), # shift ruined_castle.png, 2nd house left roof up 1
			Vector2i(0, -1), # shift ruined_castle.png, 2nd house right roof up 1
			Vector2i(0, -1), # shift animated_decals.png, large fire top up 1
		]
		
		for idx in len(bottomTiles):
			var bottomTileLayer: TileMapLayer = get_node_or_null('TilemapRoot/' + bottomTiles[idx].layer)
			if bottomTileLayer != null:
				for tilePos in bottomTileLayer.get_used_cells_by_id(bottomTiles[idx].atlasId, bottomTiles[idx].atlasPos, bottomTiles[idx].altTileId):
					var topTilePos: Vector2i = Vector2i(tilePos.x + deltas[idx].x, tilePos.y + deltas[idx].y)
					var topTileLayer: TileMapLayer = get_node_or_null('TilemapRoot/' + topTiles[idx].layer)
					if topTileLayer != null:
						topTileLayer.set_cell(topTilePos, topTiles[idx].atlasId, topTiles[idx].atlasPos, topTiles[idx].altTileId)
					else:
						printerr('Top tile layer ', topTiles[idx].layer, ' was not found (idx ', idx, ')!')
			else:
				printerr('Bottom tile layer ', bottomTiles[idx].layer, ' was not found (idx ', idx, ')!')
