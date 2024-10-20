extends Control
class_name MapMarker

@export var location: WorldLocation.MapLocation

@onready var pinSprite: AnimatedSprite2D = get_node('PinSprite')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_marker()

func hide_marker() -> void:
	pinSprite.play('hide')

func mark_player() -> void:
	pinSprite.play('player')

func mark_location() -> void:
	pinSprite.play('location')

func mark_quest() -> void:
	pinSprite.play('quest')

func mark_player_location() -> void:
	pinSprite.play('player_location')

func mark_player_quest() -> void:
	pinSprite.play('player_quest')

func mark_default() -> void:
	mark_location()
