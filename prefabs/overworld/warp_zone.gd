extends Area2D

@export var mapName: String
@export var mapPos: Vector2
@export var isUnderground: bool
@export var storyRequirements: StoryRequirements = null
@export var warpEnabled: bool = true
@export var useVerticalOffset: bool = false
@export var useHorizontalOffset: bool = false

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and warpEnabled and (storyRequirements == null or storyRequirements.is_valid()):
		PlayerFinder.player.play_animation('stand')
		var mapLoader: MapLoader = null
		if SceneLoader.mapLoader != null:
			mapLoader = SceneLoader.mapLoader
		else:
			mapLoader = get_node_or_null("/root/Overworld/MapLoader")
		if mapLoader != null:
			mapLoader.entered_warp(mapName, mapPos, position, isUnderground, useVerticalOffset, useHorizontalOffset)
		else:
			printerr('MAP LOADER WAS NOT FOUND, error on warp zone: ', name)
		warpEnabled = false
