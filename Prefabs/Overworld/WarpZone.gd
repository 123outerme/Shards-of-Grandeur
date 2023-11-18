extends Area2D

@export var mapName: String
@export var mapPos: Vector2
@export var isUnderground: bool
@export var storyRequirements: StoryRequirements = null
@export var warpEnabled: bool = true

@onready var mapLoader: MapLoader = get_node("/root/Overworld/MapLoader")

func _on_area_entered(area):
	if area.name == "PlayerEventCollider" and warpEnabled and (storyRequirements == null or storyRequirements.is_valid()):
		mapLoader.entered_warp(mapName, mapPos, isUnderground)
		warpEnabled = false
