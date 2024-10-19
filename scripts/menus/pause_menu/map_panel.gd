extends Control
class_name MapPanel

enum MapLocationsFilter {
	ALL = 0,
	LOCATIONS = 1,
	QUESTS = 2,
}

class MapPanelLocation:
	var locations: Array[WorldLocation.MapLocation] = []
	var buttonText: String = ''
	
	func _init(
		i_locations: Array[WorldLocation.MapLocation] = [],
		i_buttonText: String = '',
	):
		locations = i_locations
		buttonText = i_buttonText

signal back_pressed

const sfxButtonScene = preload('res://prefabs/ui/sfx_button.tscn')

@export var filter: MapLocationsFilter = MapLocationsFilter.ALL

var selectedLocation: MapPanelLocation = null

@onready var allButton: Button = get_node('LocationsControl/HBoxContainer/AllButton')
@onready var locationsButton: Button = get_node('LocationsControl/HBoxContainer/LocationsButton')
@onready var questsButton: Button = get_node('LocationsControl/HBoxContainer/QuestsButton')

@onready var buttonsHboxContainer: HBoxContainer = get_node('LocationsControl/ScrollContainer/HBoxContainer')

@onready var backButton: Button = get_node('BackButton')

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
	var locationOptions: Array[MapPanelLocation] = []
	if filter == MapLocationsFilter.ALL or filter == MapLocationsFilter.LOCATIONS:
		locationOptions.append_array(build_locations_options())
	if filter == MapLocationsFilter.ALL or filter == MapLocationsFilter.QUESTS:
		locationOptions.append_array(build_quests_options())
	
	var lastButton: Button = null
	for option: MapPanelLocation in locationOptions:
		var instantiatedButton: Button = sfxButtonScene.instantiate()
		instantiatedButton.text = option.buttonText
		instantiatedButton.pressed.connect(_location_button_pressed.bind(option))
		buttonsHboxContainer.add_child(instantiatedButton)
		_connect_location_button_focus.call_deferred(instantiatedButton, lastButton)
		lastButton = instantiatedButton

func build_locations_options() -> Array[MapPanelLocation]:
	var options: Array[MapPanelLocation] = []
	for location: WorldLocation.MapLocation in range(WorldLocation.MapLocation.MAX_LOCATIONS):
		if PlayerResources.playerInfo.has_visited_map_location(location):
			options.append(MapPanelLocation.new([location], WorldLocation.map_location_to_string(location)))
	return options

func build_quests_options() -> Array[MapPanelLocation]:
	var options: Array[MapPanelLocation] = []
	for questTracker: QuestTracker in PlayerResources.questInventory.get_sorted_trackers():
		var status: QuestTracker.Status = questTracker.get_current_status()
		if status != QuestTracker.Status.COMPLETED and status != QuestTracker.Status.FAILED:
			var step: QuestStep = questTracker.get_current_step()
			if step != null:
				options.append(MapPanelLocation.new(step.locations, questTracker.quest.questName))
	return options

func get_current_location() -> MapPanelLocation:
	var worldLocation: WorldLocation = MapLoader.get_world_location_for_name(PlayerResources.playerInfo.map)
	if worldLocation != null:
		return MapPanelLocation.new([worldLocation.mapLocation], TextUtils.substitute_playername('@'))
	return MapPanelLocation.new([], TextUtils.substitute_playername('@')) # this is a problem if this returns!

func _on_back_button_pressed() -> void:
	visible = false
	back_pressed.emit()

func _connect_location_button_focus(button: Button, lastButton: Button) -> void:
	if lastButton != null:
		button.focus_neighbor_left = button.get_path_to(lastButton)
		lastButton.focus_neighbor_right = lastButton.get_path_to(button)
	else:
		button.focus_neighbor_left = '.'
	
	button.focus_neighbor_right = '.'
	button.focus_neighbor_top = button.get_path_to(locationsButton)
	
	button.focus_neighbor_bottom = button.get_path_to(backButton)

func _location_button_pressed(location: MapPanelLocation) -> void:
	selectedLocation = location
	pass # TODO drop pin(s) on all selected locations
