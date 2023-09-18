extends Area2D

@export var mapName: String
@export var mapPos: Vector2
@export var isUnderground: bool

@onready var MapLoader: Node2D = get_node("/root/Overworld/MapLoader")

# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_entered(area):
	if area.name == "PlayerEventCollider":
		MapLoader.entered_warp(mapName, mapPos, isUnderground)
	pass # Replace with function body.
