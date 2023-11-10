extends Node2D
class_name MapScript

signal map_loaded

func _ready():
	map_loaded.emit()
