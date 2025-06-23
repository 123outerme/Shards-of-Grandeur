extends Control
class_name MapPanel

enum MapLocationsFilter {
	ALL = 0,
	LOCATIONS = 1,
	QUESTS = 2,
}

enum MapLocationType {
	NONE,
	LOCATION,
	QUEST
}

class MapPanelLocation:
	var locations: Array[WorldLocation.MapLocation] = []
	var buttonText: String = ''
	var type: MapLocationType = MapLocationType.LOCATION
	var quest: Quest = null
	
	func _init(
		i_locations: Array[WorldLocation.MapLocation] = [],
		i_buttonText: String = '',
		i_type: MapLocationType = MapLocationType.LOCATION,
		i_quest: Quest = null
	):
		locations = i_locations
		buttonText = i_buttonText
		type = i_type
		quest = i_quest

signal back_pressed

const sfxButtonScene = preload('res://prefabs/ui/sfx_button.tscn')

@export var filter: MapLocationsFilter = MapLocationsFilter.ALL

var locationOptions: Array[MapPanelLocation]
var selectedLocation: MapPanelLocation = null
var noneLocationOption: MapPanelLocation = MapPanelLocation.new([], 'None', MapLocationType.NONE)
var locationButtons: Dictionary[MapPanelLocation, Button] = {}
var fromQuestsPanelQuest: Quest = null

@onready var mapPanelLabel: RichTextLabel = get_node('MapPanelLabel')

@onready var markersControl: Control = get_node('MapSpritesControl/MarkersControl')
@onready var cloudsControl: Control = get_node('MapSpritesControl/CloudsControl')
@onready var unknownOverlay: TextureRect = get_node('MapSpritesControl/UnknownOverlay')

@onready var allButton: Button = get_node('LocationsControl/HBoxContainer/AllButton')
@onready var locationsButton: Button = get_node('LocationsControl/HBoxContainer/LocationsButton')
@onready var questsButton: Button = get_node('LocationsControl/HBoxContainer/QuestsButton')

@onready var buttonsHboxContainer: HBoxContainer = get_node('LocationsControl/ScrollContainer/HBoxContainer')

@onready var backButton: Button = get_node('BackButton')

func _init() -> void:
	SignalBus.show_map_for_location.connect(_show_map_for_location)

func _unhandled_input(event):
	if visible:
		if event.is_action_pressed('game_decline'):
			_on_back_button_pressed()
			get_viewport().set_input_as_handled()

func load_map_panel(initial: bool = true) -> void:
	update_cloud_layers()
	build_map_locations()
	if initial:
		fromQuestsPanelQuest = null
		selectedLocation = null
		initial_focus()
		filter = MapLocationsFilter.ALL
		update_filter(filter)
	update_selected_location(selectedLocation)
	visible = true

func initial_focus() -> void:
	allButton.grab_focus()

func restore_filter_button_focus(filterSelected: MapLocationsFilter) -> void:
	match filterSelected:
		MapLocationsFilter.ALL:
			allButton.grab_focus()
		MapLocationsFilter.LOCATIONS:
			locationsButton.grab_focus()
		MapLocationsFilter.QUESTS:
			questsButton.grab_focus()
		_: # default
			initial_focus()

func update_cloud_layers() -> void:
	var children: Array[Node] = cloudsControl.get_children()
	for child: Node in children:
		if child is MapCloudLayerTextureRect:
			var cloudLayer: MapCloudLayerTextureRect = child as MapCloudLayerTextureRect
			cloudLayer.visible = not PlayerResources.playerInfo.has_visited_map_location(cloudLayer.location)

func build_map_locations() -> void:
	locationOptions = [noneLocationOption]
	if filter == MapLocationsFilter.ALL or filter == MapLocationsFilter.LOCATIONS:
		locationOptions.append_array(build_locations_options())
	if filter == MapLocationsFilter.ALL or filter == MapLocationsFilter.QUESTS:
		locationOptions.append_array(build_quests_options())
	
	for child: Node in buttonsHboxContainer.get_children():
		child.queue_free()
	
	locationButtons = {}
	var lastButton: Button = null
	for option: MapPanelLocation in locationOptions:
		var instantiatedButton: Button = sfxButtonScene.instantiate()
		instantiatedButton.text = option.buttonText
		instantiatedButton.pressed.connect(update_selected_location.bind(option))
		instantiatedButton.custom_minimum_size = Vector2(0, 40)
		buttonsHboxContainer.add_child(instantiatedButton)
		locationButtons[option] = instantiatedButton
		_connect_location_button_focus.call_deferred(instantiatedButton, lastButton)
		lastButton = instantiatedButton

func build_locations_options() -> Array[MapPanelLocation]:
	var options: Array[MapPanelLocation] = []
	var markers: Array[Node] = markersControl.get_children()
	for marker: Node in markers:
		var mapMarker: MapMarker = marker as MapMarker
		if PlayerResources.playerInfo.has_visited_map_location(mapMarker.location):
			options.append(MapPanelLocation.new([mapMarker.location], WorldLocation.map_location_to_specific_string(mapMarker.location)))
	return options

func build_quests_options() -> Array[MapPanelLocation]:
	var options: Array[MapPanelLocation] = []
	for questTracker: QuestTracker in PlayerResources.questInventory.get_sorted_trackers():
		var status: QuestTracker.Status = questTracker.get_current_status()
		if status != QuestTracker.Status.COMPLETED and status != QuestTracker.Status.FAILED:
			var step: QuestStep = questTracker.get_current_step()
			if step != null:
				# use the regular locations if the step isn't ready to turn in; otherwise use the turn in locations
				var locations: Array[WorldLocation.MapLocation] = step.locations \
						if questTracker.get_current_status() != QuestTracker.Status.READY_TO_TURN_IN_STEP \
						else step.turnInLocations
				options.append(MapPanelLocation.new(locations, questTracker.quest.questName, MapLocationType.QUEST, questTracker.quest))
	return options

func get_current_location() -> MapPanelLocation:
	var worldLocation: WorldLocation = MapLoader.get_world_location_for_name(PlayerResources.playerInfo.map)
	if worldLocation != null:
		return MapPanelLocation.new([worldLocation.mapLocation], TextUtils.substitute_playername('@'))
	printerr('get_current_location Error: Current WorldLocation is null!')
	return MapPanelLocation.new([], TextUtils.substitute_playername('@')) # this is a problem if this returns!

func update_filter(newFilter: MapLocationsFilter) -> void:
	filter = newFilter
	load_map_panel(false)
	restore_filter_button_focus(newFilter)
	if allButton.button_pressed and newFilter != MapLocationsFilter.ALL:
		allButton.button_pressed = false
	if locationsButton.button_pressed and newFilter != MapLocationsFilter.LOCATIONS:
		locationsButton.button_pressed = false
	if questsButton.button_pressed and newFilter != MapLocationsFilter.QUESTS:
		questsButton.button_pressed = false

func deselect_filter(deselectedFilter: MapLocationsFilter) -> void:
	if not allButton.button_pressed and not locationsButton.button_pressed and not questsButton.button_pressed:
		update_filter(MapLocationsFilter.ALL)
		allButton.button_pressed = true

func _on_back_button_pressed() -> void:
	visible = false
	if fromQuestsPanelQuest != null:
		SignalBus.return_from_quest_map_location.emit(fromQuestsPanelQuest)
		# explicitly NOT null'ing fromQuestsPanelQuest:
		# this is state information used by the Pause panel to make sure it doesn't make itself visible
		# and/or take away focus from the Stats panel as it comes back up
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

func update_selected_location(location: MapPanelLocation) -> void:
	unknownOverlay.visible = false
	selectedLocation = location
	if location == noneLocationOption:
		selectedLocation = null
	if selectedLocation == null:
		mapPanelLabel.text = '[center]Map[/center]'
	else:
		mapPanelLabel.text = '[center]Map - ' + location.buttonText + '[/center]'
	var playerLocation: MapPanelLocation = get_current_location()
	var markers: Array[Node] = markersControl.get_children()
	for marker: Node in markers:
		var mapMarker: MapMarker = marker as MapMarker
		var markPlayer: bool = false
		if mapMarker.location == playerLocation.locations[0]:
			markPlayer = true
		if selectedLocation != null and mapMarker.location in selectedLocation.locations:
			if location.type == MapLocationType.LOCATION:
				if markPlayer:
					mapMarker.mark_player_location()
				else:
					mapMarker.mark_location()
			elif location.type == MapLocationType.QUEST:
				if markPlayer:
					mapMarker.mark_player_quest()
				else:
					mapMarker.mark_quest()
			else:
				mapMarker.mark_default()
		elif markPlayer:
			mapMarker.mark_player()
		else:
			mapMarker.hide_marker()
	if location != null and ((len(location.locations) == 0) or (len(location.locations) == 1 and location.locations[0] == WorldLocation.MapLocation.UNKNOWN)):
		unknownOverlay.visible = true

func _on_all_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		update_filter(MapLocationsFilter.ALL)
	else:
		deselect_filter(MapLocationsFilter.ALL)

func _on_locations_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		update_filter(MapLocationsFilter.LOCATIONS)
	else:
		deselect_filter(MapLocationsFilter.LOCATIONS)

func _on_quests_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		update_filter(MapLocationsFilter.QUESTS)
	else:
		deselect_filter(MapLocationsFilter.QUESTS)

func _show_map_for_location(locations: Array[WorldLocation.MapLocation], quest: Quest):
	initial_focus.call_deferred()
	if quest != null:
		load_map_panel(true)
		fromQuestsPanelQuest = quest
		for option: MapPanelLocation in locationOptions:
			if option.type == MapLocationType.QUEST and option.quest == quest:
				if locationButtons.has(option):
					locationButtons[option].button_pressed = true
				update_selected_location(option)
				break
		filter = MapLocationsFilter.QUESTS
	else:
		load_map_panel(true)
		if len(locations) < 1:
			return

		for option: MapPanelLocation in locationOptions:
			if option.type == MapLocationType.LOCATION and locations[0] in option.locations:
				if locationButtons.has(option):
					locationButtons[option].button_pressed = true
				update_selected_location(option)
				break
		filter = MapLocationsFilter.LOCATIONS
