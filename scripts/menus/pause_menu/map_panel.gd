extends Control
class_name MapPanel

enum MapLocationsFilter {
	ALL = 0,
	LOCATIONS = 1,
	QUESTS = 2,
}

signal back_pressed

const sfxButtonScene = preload('res://prefabs/ui/sfx_button.tscn')

@export var filter: MapLocationsFilter = MapLocationsFilter.ALL

@onready var allButton: Button = get_node('LocationsControl/HBoxContainer/AllButton')
@onready var locationsButton: Button = get_node('LocationsControl/HBoxContainer/LocationsButton')
@onready var questsButton: Button = get_node('LocationsControl/HBoxContainer/QuestsButton')

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed('game_decline'):
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

func load_map_panel() -> void:
	visible = true
	build_map_locations()
	pass # TODO

func build_map_locations() -> void:
	pass # TODO

func _on_back_button_pressed() -> void:
	visible = false
	back_pressed.emit()
