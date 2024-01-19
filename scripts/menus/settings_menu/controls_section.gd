extends Control
class_name ControlsSection

@export var sectionToggleButton: Button

@onready var captureControl: Control = get_node('CaptureControl')
@onready var saveButton: Button = get_node('TabContainer/Keyboard/Buttons/SaveButton')
@onready var tabContainer: TabContainer = get_node('TabContainer')
@onready var keyboardTab: VBoxContainer = get_node("TabContainer/Keyboard")
@onready var controllerTab: VBoxContainer = get_node("TabContainer/Controller")
@onready var primaryUpKeyBtn: Button = get_node('TabContainer/Keyboard/UpKey/ChangeButton1')

var buttonToChange: Button = null
var trapFocus: bool = false
var changedInputsMap: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	saveButton.focus_neighbor_left = saveButton.get_path_to(sectionToggleButton)
	#var keyboardTab: Control = tabContainer.get_tab_control(0)
	#keyboardTab.focus_neighbor_bottom = keyboardTab.get_path_to(primaryUpKeyBtn)
	#var controllerTab: Control = tabContainer.get_tab_control(1)
	#controllerTab.focus_neighbor_bottom = '' # TODO
	get_viewport().gui_focus_changed.connect(_viewport_focus_changed)

func _viewport_focus_changed(control: Control):
	if trapFocus and control != captureControl:
		captureControl.grab_focus()

func toggle_section(enable: bool):
	visible = enable
	if enable:
		for controlMap in get_tree().get_nodes_in_group('KeyboardControlMap'):
			var changeButton1: Button = controlMap.get_node('ChangeButton1')
			changeButton1.focus_neighbor_left = changeButton1.get_path_to(sectionToggleButton)
			if not changeButton1.pressed.is_connected(_on_change_pressed.bind(changeButton1)):
				changeButton1.pressed.connect(_on_change_pressed.bind(changeButton1))
			var changeButton2: Button = controlMap.get_node('ChangeButton2')
			if not changeButton2.pressed.is_connected(_on_change_pressed.bind(changeButton2)):
				changeButton2.pressed.connect(_on_change_pressed.bind(changeButton2))
			var clearSecondaryButton: Button = controlMap.get_node('ClearSecondaryButton')
			if not clearSecondaryButton.pressed.is_connected(_on_clear_secondary_pressed.bind(clearSecondaryButton)):
				clearSecondaryButton.pressed.connect(_on_clear_secondary_pressed.bind(clearSecondaryButton))
		build_map_value_strings()
		
func build_map_value_strings():
	for controlMap in get_tree().get_nodes_in_group('KeyboardControlMap'):
		var keyValue1: RichTextLabel = controlMap.get_node('Value1')
		var changeButton1: Button = controlMap.get_node('ChangeButton1')
		var action = changeButton1.get_meta('action')
		var actionEvents = InputMap.action_get_events(action)
		var actionIndex1: int = changeButton1.get_meta('index')
		var keycode1 = actionEvents[actionIndex1].keycode
		if keycode1 == 0:
			keycode1 = actionEvents[actionIndex1].physical_keycode
		keyValue1.text = '[center]' + OS.get_keycode_string(keycode1) + '[/center]'
		var keyValue2: RichTextLabel = controlMap.get_node('Value2')
		var changeButton2: Button = controlMap.get_node('ChangeButton2')
		var actionIndex2: int = changeButton2.get_meta('index')
		if actionIndex2 < len(actionEvents):
			var keycode2 = actionEvents[actionIndex2].keycode
			if keycode2 == 0:
				keycode2 = actionEvents[actionIndex2].physical_keycode
			keyValue2.text = '[center]' + OS.get_keycode_string(keycode2) + '[/center]'
		else:
			keyValue2.text = ''

func _on_change_pressed(btn: Button):
	if btn.button_pressed:
		for changeBtn in get_tree().get_nodes_in_group('ChangeButton'):
			if changeBtn != btn:
				changeBtn.button_pressed = true
				changeBtn.disabled = true
		buttonToChange = btn
		captureControl.visible = true
		captureControl.focus_mode = Control.FOCUS_ALL
		captureControl.grab_focus()
	else:
		for changeBtn in get_tree().get_nodes_in_group('ChangeButton'):
			changeBtn.button_pressed = false
			changeBtn.disabled = false
	trapFocus = btn.button_pressed
	if PlayerFinder.player != null:
		PlayerFinder.player.pauseDisabled = btn.button_pressed

func _on_capture_control_gui_input(event: InputEvent):
	if keyboardTab.visible and not (event is InputEventKey) or \
			controllerTab.visible and not (event is InputEventJoypadMotion or event is InputEventJoypadButton):
		unlock_focus_trap()
		return
	
	var actionToChange: String = buttonToChange.get_meta('action')
	var actionEvents = InputMap.action_get_events(actionToChange)
	var actionIndex: int = buttonToChange.get_meta('index')
	for action in SettingsHandler.gameSettings.stored_actions:
		for existingEvent in InputMap.action_get_events(action):
			if event.is_match(existingEvent):
				unlock_focus_trap()
				return # don't let existing events overwrite
	
	var newEvents: Array[InputEvent] = actionEvents.duplicate()
	if actionIndex < len(newEvents):
		newEvents[actionIndex] = event
	else:
		newEvents.append(event)
	InputMap.action_erase_events(actionToChange)
	for i in range(len(newEvents)):
		InputMap.action_add_event(actionToChange, newEvents[i])
		
	changedInputsMap[actionToChange] = newEvents.duplicate()
	
	# change UI navigation as well as player movement
	if actionToChange.begins_with('move_'):
		var uiAction = 'ui_' + actionToChange.substr(5)
		var uiActions = InputMap.action_get_events(uiAction)
		var newUiEvents: Array[InputEvent] = uiActions.duplicate()
		if actionIndex < len(newUiEvents):
			newUiEvents[actionIndex] = event
		else:
			newUiEvents.append(event)
		InputMap.action_erase_events(uiAction)
		for i in range(len(newUiEvents)):
			InputMap.action_add_event(uiAction, newUiEvents[i])
		changedInputsMap[uiAction] = newUiEvents.duplicate()
	
	# change UI accept to use the same as game_interact
	if actionToChange == 'game_interact':
		for uiAction in ['ui_accept', 'ui_select']:
			var uiActions = InputMap.action_get_events(uiAction)
			var newUiEvents: Array[InputEvent] = uiActions.duplicate()
			if actionIndex < len(newUiEvents):
				newUiEvents[actionIndex] = event
			else:
				newUiEvents.append(event)
			InputMap.action_erase_events(uiAction)
			for i in range(len(newUiEvents)):
				InputMap.action_add_event(uiAction, newUiEvents[i])
			changedInputsMap[uiAction] = newUiEvents.duplicate()
	unlock_focus_trap()

func unlock_focus_trap():
	trapFocus = false
	for changeBtn in get_tree().get_nodes_in_group('ChangeButton'):
		changeBtn.button_pressed = false
		changeBtn.disabled = false
	call_deferred('reenable_pause')
	buttonToChange.grab_focus()
	captureControl.focus_mode = Control.FOCUS_NONE
	captureControl.visible = false
	build_map_value_strings()

func _on_clear_secondary_pressed(btn: Button):
	var action = btn.get_meta('action')
	var index = 2
	var actionEvents = InputMap.action_get_events(action)
	var newEvents: Array[InputEvent] = []
	for i in range(len(actionEvents)):
		if i != index:
			newEvents.append(actionEvents[i])
	InputMap.action_erase_events(action)
	for i in range(len(newEvents)):
		InputMap.action_add_event(action, newEvents[i])
	
	changedInputsMap[action] = newEvents.duplicate()
	
	if action.begins_with('move_'):
		var uiAction = 'ui_' + action.substr(5)
		var uiActions = InputMap.action_get_events(uiAction)
		var newUiEvents: Array[InputEvent] = []
		for i in range(len(uiActions)):
			if i != index:
				newEvents.append(uiActions[i])
		InputMap.action_erase_events(uiAction)
		for i in range(len(newUiEvents)):
			InputMap.action_add_event(uiAction, newUiEvents[i])
		changedInputsMap[uiAction] = newUiEvents.duplicate()
			
	
	# change UI accept to use the same as game_interact
	if action == 'game_interact':
		for uiAction in ['ui_accept', 'ui_select']:
			var uiActions = InputMap.action_get_events(uiAction)
			var newUiEvents: Array[InputEvent] = []
			for i in range(len(uiActions)):
				if i != index:
					newEvents.append(uiActions[i])
			InputMap.action_erase_events(uiAction)
			for i in range(len(newUiEvents)):
				InputMap.action_add_event(uiAction, newUiEvents[i])
			changedInputsMap[uiAction] = newUiEvents.duplicate()
			
	build_map_value_strings()

func reenable_pause():
	if PlayerFinder.player != null:
		PlayerFinder.player.pauseDisabled = false

func _on_save_button_pressed():
	SettingsHandler.gameSettings.save_controls_from_diffs(changedInputsMap)
	changedInputsMap = {}

func _on_cancel_button_pressed():
	changedInputsMap = {}
	SettingsHandler.gameSettings.apply_from_stored_inputs() # apply stored inputs, discarding changes
	build_map_value_strings()
	
func _on_default_button_pressed():
	SettingsHandler.gameSettings.restore_default_controls()
	build_map_value_strings()
