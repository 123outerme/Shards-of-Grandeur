extends Control
class_name ControlsSection

@export var unsavedKeybindsSprite: Texture2D
@export var sectionToggleButton: Button

@onready var captureControl: Control = get_node('CaptureControl')
@onready var keyboardSaveButton: Button = get_node('TabContainer/Keyboard/Buttons/HBoxContainer/SaveButton')
@onready var controllerSaveButton: Button = get_node('TabContainer/Controller/Buttons/HBoxContainer/SaveButton')
@onready var tabContainer: TabContainer = get_node('TabContainer')
@onready var keyboardTab: VBoxContainer = get_node("TabContainer/Keyboard")
@onready var controllerTab: VBoxContainer = get_node("TabContainer/Controller")

@onready var movementActionControl: Control = get_node('TabContainer/Controller/MovementAction')

var secondaryControllerMovement: String = 'dpad'
var buttonToChange: Button = null
var trapFocus: bool = false
var changedInputsMap: Dictionary[String, Array] = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	keyboardSaveButton.focus_neighbor_left = keyboardSaveButton.get_path_to(sectionToggleButton)
	controllerSaveButton.focus_neighbor_left = controllerSaveButton.get_path_to(sectionToggleButton)
	#var keyboardTab: Control = tabContainer.get_tab_control(0)
	#keyboardTab.focus_neighbor_bottom = keyboardTab.get_path_to(primaryUpKeyBtn)
	#var controllerTab: Control = tabContainer.get_tab_control(1)
	#controllerTab.focus_neighbor_bottom = '' # TODO
	if SettingsHandler.isMobile:
		keyboardTab.queue_free()
	get_viewport().gui_focus_changed.connect(_viewport_focus_changed)

func _viewport_focus_changed(control: Control):
	if trapFocus and control != captureControl:
		captureControl.grab_focus()

func toggle_section(enable: bool):
	visible = enable
	buttonToChange = null
	trapFocus = false
	changedInputsMap = {}
	if enable:
		for controlMap in get_tree().get_nodes_in_group('KeyboardControlMap'):
			var changeButton1: Button = controlMap.get_node('ChangeButton1')
			changeButton1.focus_neighbor_left = changeButton1.get_path_to(sectionToggleButton)
			if not changeButton1.pressed.is_connected(_on_change_pressed.bind(changeButton1)):
				changeButton1.pressed.connect(_on_change_pressed.bind(changeButton1))
			var changeButton2: Button = controlMap.get_node_or_null('ChangeButton2')
			if changeButton2 != null:
				if not changeButton2.pressed.is_connected(_on_change_pressed.bind(changeButton2)):
					changeButton2.pressed.connect(_on_change_pressed.bind(changeButton2))
			var clearSecondaryButton: Button = controlMap.get_node_or_null('ClearSecondaryButton')
			if clearSecondaryButton != null:
				if not clearSecondaryButton.pressed.is_connected(_on_clear_secondary_pressed.bind(clearSecondaryButton)):
					clearSecondaryButton.pressed.connect(_on_clear_secondary_pressed.bind(clearSecondaryButton))
		
		for controlMap in get_tree().get_nodes_in_group('ControllerControlMap'):
			var changeButton1: Button = controlMap.get_node('ChangeButton1')
			changeButton1.focus_neighbor_left = changeButton1.get_path_to(sectionToggleButton)
			if not changeButton1.pressed.is_connected(_on_change_pressed.bind(changeButton1)):
				changeButton1.pressed.connect(_on_change_pressed.bind(changeButton1))
		
		build_map_value_strings()
		
func build_map_value_strings():
	if len(changedInputsMap.values()) > 0:
		if keyboardSaveButton != null:
			keyboardSaveButton.icon = unsavedKeybindsSprite
		controllerSaveButton.icon = unsavedKeybindsSprite
	else:
		if keyboardSaveButton != null:
			keyboardSaveButton.icon = null
		controllerSaveButton.icon = null
	
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
		var keyValue2: RichTextLabel = controlMap.get_node_or_null('Value2')
		var changeButton2: Button = controlMap.get_node_or_null('ChangeButton2')
		if changeButton2 != null and keyValue2 != null:
			var actionIndex2: int = changeButton2.get_meta('index')
			if actionIndex2 < len(actionEvents) and not (actionEvents[actionIndex2] is InputEventKey):
					actionIndex2 += 1
			if actionIndex2 < len(actionEvents) and (actionEvents[actionIndex2] is InputEventKey):
				var keycode2 = actionEvents[actionIndex2].keycode
				if keycode2 == 0:
					keycode2 = actionEvents[actionIndex2].physical_keycode
				keyValue2.text = '[center]' + OS.get_keycode_string(keycode2) + '[/center]'
			else:
				keyValue2.text = ''
			
	var change1Group: HBoxContainer = movementActionControl.get_node('Change1Group')
	var change2Group: HBoxContainer = movementActionControl.get_node('Change2Group')
	for group in [change1Group, change2Group]:
		var leftStickButton: Button = group.get_node('LeftStickButton')
		var rightStickButton: Button = group.get_node('RightStickButton')
		var dPadButton: Button = group.get_node('DPadButton')
		var moveAction = 'move_up'
		var moveActionEvents = InputMap.action_get_events(moveAction)
		var moveActionIndex = 1
		if group == change2Group:
			moveActionIndex = 2
			if moveActionIndex < len(moveActionEvents) and not (moveActionEvents[moveActionIndex] is InputEventJoypadButton or moveActionEvents[moveActionIndex] is InputEventJoypadMotion):
				moveActionIndex += 1
		if moveActionIndex < len(moveActionEvents) and (moveActionEvents[moveActionIndex] is InputEventJoypadButton or moveActionEvents[moveActionIndex] is InputEventJoypadMotion):
			var moveEvent = moveActionEvents[moveActionIndex]
			if moveEvent is InputEventJoypadMotion:
				if moveEvent.axis == JOY_AXIS_LEFT_Y:
					secondaryControllerMovement = 'leftstick'
					if not leftStickButton.button_pressed: # pre-emptive code: prevent recursion
						leftStickButton.button_pressed = true
					rightStickButton.button_pressed = false
					dPadButton.button_pressed = false
				else:
					secondaryControllerMovement = 'rightstick'
					if not rightStickButton.button_pressed: # pre-emptive code: prevent recursion
						rightStickButton.button_pressed = true
					leftStickButton.button_pressed = false
					dPadButton.button_pressed = false
			elif moveEvent is InputEventJoypadButton:
				secondaryControllerMovement = 'dpad'
				if not dPadButton.button_pressed: # pre-emptive code: prevent recursion
					dPadButton.button_pressed = true
				leftStickButton.button_pressed = false
				rightStickButton.button_pressed = false
		else:
			secondaryControllerMovement = ''
			dPadButton.button_pressed = false
			leftStickButton.button_pressed = false
			rightStickButton.button_pressed = false
	
	for controlMap in get_tree().get_nodes_in_group('ControllerControlMap'):
		var keyValue1: RichTextLabel = controlMap.get_node('Value1')
		var changeButton1: Button = controlMap.get_node('ChangeButton1')
		var action = changeButton1.get_meta('action')
		var actionEvents = InputMap.action_get_events(action)
		var actionIndex1: int = changeButton1.get_meta('index')
		var actionText: String = actionEvents[actionIndex1].as_text()
		if actionText.contains('('):
			if actionText.contains(','):  # get the text inside (...,
				actionText = actionText.split('(')[1].split(',')[0]
			elif actionText.contains(')'): # get the text inside (...)
				actionText = actionText.split('(')[1].split(')')[0]
		if actionEvents[actionIndex1] is InputEventJoypadMotion:
			# workaround: action text for joypad motion events is wrong it seems
			if actionEvents[actionIndex1].axis == 4:
				actionText = 'Left Trigger'
			if actionEvents[actionIndex1].axis == 5:
				actionText = 'Right Trigger'
		keyValue1.text = '[center]' + actionText + '[/center]'

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
	if (keyboardTab != null and keyboardTab.visible) and not (event is InputEventKey) or \
			controllerTab.visible and not (event is InputEventJoypadButton or \
			(event is InputEventJoypadMotion and (event.axis == 4 or event.axis == 5))):
		call_deferred('unlock_focus_trap')
		return
	
	var actionToChange: String = buttonToChange.get_meta('action')
	var actionEvents = InputMap.action_get_events(actionToChange)
	var actionIndex: int = buttonToChange.get_meta('index')
	
	if actionIndex < len(actionEvents):
		if ((keyboardTab != null and keyboardTab.visible) and not (actionEvents[actionIndex] is InputEventKey)) \
				or (controllerTab.visible and not (actionEvents[actionIndex] is InputEventJoypadButton or actionEvents[actionIndex] is InputEventJoypadMotion)):
			actionIndex += 1
	
	for action in GameSettings.STORED_ACTIONS:
		for existingEvent in InputMap.action_get_events(action):
			if event.is_match(existingEvent):
				call_deferred('unlock_focus_trap')
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
	call_deferred('unlock_focus_trap')

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
	var actionEvents = InputMap.action_get_events(action)
	var index = 2
	if len(actionEvents) <= index:
		return
	if not (actionEvents[index] is InputEventKey):
		index += 1
		if len(actionEvents) <= index or not (actionEvents[index] is InputEventKey):
			return
	
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
				newUiEvents.append(uiActions[i])
		InputMap.action_erase_events(uiAction)
		for i in range(len(newUiEvents)):
			InputMap.action_add_event(uiAction, newUiEvents[i])
		changedInputsMap[uiAction] = newUiEvents.duplicate()
			
	# remove ui_accept and ui_select
	if action == 'game_interact':
		for uiAction in ['ui_accept', 'ui_select']:
			var uiActions = InputMap.action_get_events(uiAction)
			var newUiEvents: Array[InputEvent] = []
			for i in range(len(uiActions)):
				if i != index:
					newUiEvents.append(uiActions[i])
			InputMap.action_erase_events(uiAction)
			for i in range(len(newUiEvents)):
				InputMap.action_add_event(uiAction, newUiEvents[i])
			changedInputsMap[uiAction] = newUiEvents.duplicate()
	
	build_map_value_strings()

func reenable_pause():
	if PlayerFinder.player != null:
		PlayerFinder.player.pauseDisabled = false

func replace_controller_movement(actions: Dictionary[String, InputEvent], secondary: bool):
	for action in ['move_up', 'move_down', 'move_left', 'move_right']:
		var actionEvents = InputMap.action_get_events(action)
		var index = 1
		if secondary:
			index = 2
			if len(actionEvents) > index and not (actionEvents[index] is InputEventJoypadMotion or actionEvents[index] is InputEventJoypadButton):
				index += 1
		for existingAction in GameSettings.STORED_ACTIONS:
			for existingEvent in InputMap.action_get_events(existingAction):
				if actions[action].is_match(existingEvent):
					build_map_value_strings()
					return # don't let existing events overwrite
		
		var newEvents: Array[InputEvent] = actionEvents.duplicate()
		if index < len(newEvents):
			newEvents[index] = actions[action]
		else:
			newEvents.append(actions[action])
		InputMap.action_erase_events(action)
		for i in range(len(newEvents)):
			InputMap.action_add_event(action, newEvents[i])
			
		changedInputsMap[action] = newEvents.duplicate()
		
		# change (repeating) UI navigation as well as player movement
		var uiAction = 'ui_repeat_' + action.substr(5)
		var uiActions = InputMap.action_get_events(uiAction)
		var newUiEvents: Array[InputEvent] = uiActions.duplicate()
		# index 0 is the primary controller map index, 1 is the secondary
		var uiIndex: int = 0 if not secondary else 1
		if uiIndex < len(newUiEvents):
			newUiEvents[uiIndex] = actions[action]
		else:
			newUiEvents.append(actions[action])
		InputMap.action_erase_events(uiAction)
		for i in range(len(newUiEvents)):
			InputMap.action_add_event(uiAction, newUiEvents[i])
		changedInputsMap[uiAction] = newUiEvents.duplicate()
	build_map_value_strings()

func clear_secondary_controller_movement():
	for action in ['move_up', 'move_down', 'move_left', 'move_right']:
		var actionEvents = InputMap.action_get_events(action)
		var index = 2
		if len(actionEvents) <= index:
			return
		if not (actionEvents[index] is InputEventJoypadMotion or actionEvents[index] is InputEventJoypadButton):
			index += 1
			if len(actionEvents) <= index or not (actionEvents[index] is InputEventJoypadMotion or actionEvents[index] is InputEventJoypadButton):
				return
		var newEvents: Array[InputEvent] = []
		for i in range(len(actionEvents)):
			if i != index:
				newEvents.append(actionEvents[i])
		InputMap.action_erase_events(action)
		for i in range(len(newEvents)):
			InputMap.action_add_event(action, newEvents[i])
		
		changedInputsMap[action] = newEvents.duplicate()
		
		var uiAction = 'ui_repeat_' + action.substr(5)
		var uiActions = InputMap.action_get_events(uiAction)
		var newUiEvents: Array[InputEvent] = []
		for i in range(len(uiActions)):
			if i != index:
				newUiEvents.append(uiActions[i])
		InputMap.action_erase_events(uiAction)
		for i in range(len(newUiEvents)):
			InputMap.action_add_event(uiAction, newUiEvents[i])
		changedInputsMap[uiAction] = newUiEvents.duplicate()
	secondaryControllerMovement = ''
	build_map_value_strings()

func _on_save_button_pressed():
	SettingsHandler.gameSettings.save_controls_from_diffs(changedInputsMap)
	changedInputsMap = {}
	build_map_value_strings()

func _on_cancel_button_pressed():
	changedInputsMap = {}
	SettingsHandler.gameSettings.apply_from_stored_inputs() # apply stored inputs, discarding changes
	build_map_value_strings()
	
func _on_default_button_pressed():
	changedInputsMap = SettingsHandler.gameSettings.get_default_controls()
	SettingsHandler.gameSettings.apply_from_diffs(changedInputsMap)
	build_map_value_strings()

func _on_left_stick_button_pressed(secondary: bool = false):
	var leftStickUp: InputEventJoypadMotion = InputEventJoypadMotion.new()
	leftStickUp.axis = JOY_AXIS_LEFT_Y
	leftStickUp.axis_value = -1
	
	var leftStickDown: InputEventJoypadMotion = InputEventJoypadMotion.new()
	leftStickDown.axis = JOY_AXIS_LEFT_Y
	leftStickDown.axis_value = 1
	
	var leftStickLeft: InputEventJoypadMotion = InputEventJoypadMotion.new()
	leftStickLeft.axis = JOY_AXIS_LEFT_X
	leftStickLeft.axis_value = -1
	
	var leftStickRight: InputEventJoypadMotion = InputEventJoypadMotion.new()
	leftStickRight.axis = JOY_AXIS_LEFT_X
	leftStickRight.axis_value = 1
	
	var leftStickActions: Dictionary[String, InputEvent] = {
		'move_up': leftStickUp,
		'move_down': leftStickDown,
		'move_left': leftStickLeft,
		'move_right': leftStickRight
	}
	
	replace_controller_movement(leftStickActions, secondary)

func _on_right_stick_button_pressed(secondary: bool = false):
	var rightStickUp: InputEventJoypadMotion = InputEventJoypadMotion.new()
	rightStickUp.axis = JOY_AXIS_RIGHT_Y
	rightStickUp.axis_value = -1
	
	var rightStickDown: InputEventJoypadMotion = InputEventJoypadMotion.new()
	rightStickDown.axis = JOY_AXIS_RIGHT_Y
	rightStickDown.axis_value = 1
	
	var rightStickLeft: InputEventJoypadMotion = InputEventJoypadMotion.new()
	rightStickLeft.axis = JOY_AXIS_RIGHT_X
	rightStickLeft.axis_value = -1
	
	var rightStickRight: InputEventJoypadMotion = InputEventJoypadMotion.new()
	rightStickRight.axis = JOY_AXIS_RIGHT_X
	rightStickRight.axis_value = 1
	
	var rightStickActions: Dictionary[String, InputEvent] = {
		'move_up': rightStickUp,
		'move_down': rightStickDown,
		'move_left': rightStickLeft,
		'move_right': rightStickRight
	}
	replace_controller_movement(rightStickActions, secondary)

func _on_d_pad_button_pressed(secondary: bool = false):
	var dPadUp: InputEventJoypadButton = InputEventJoypadButton.new()
	dPadUp.button_index = JOY_BUTTON_DPAD_UP
	
	var dPadDown: InputEventJoypadButton = InputEventJoypadButton.new()
	dPadDown.button_index = JOY_BUTTON_DPAD_DOWN
	
	var dPadLeft: InputEventJoypadButton = InputEventJoypadButton.new()
	dPadLeft.button_index = JOY_BUTTON_DPAD_LEFT
	
	var dPadRight: InputEventJoypadButton = InputEventJoypadButton.new()
	dPadRight.button_index = JOY_BUTTON_DPAD_RIGHT
	
	var dPadActions: Dictionary[String, InputEvent] = {
		'move_up': dPadUp,
		'move_down': dPadDown,
		'move_left': dPadLeft,
		'move_right': dPadRight
	}
	replace_controller_movement(dPadActions, secondary)

func _on_left_stick_2_button_toggled(toggled_on):
	if not toggled_on:
		if secondaryControllerMovement == 'leftstick':
			clear_secondary_controller_movement()
	else:
		_on_left_stick_button_pressed(true)

func _on_right_stick_2_button_toggled(toggled_on):
	if not toggled_on:
		if secondaryControllerMovement == 'rightstick':
			clear_secondary_controller_movement()
	else:
		_on_right_stick_button_pressed(true)

func _on_d_pad_2_button_toggled(toggled_on):
	if not toggled_on:
		if secondaryControllerMovement == 'dpad':
			clear_secondary_controller_movement()
	else:
		_on_d_pad_button_pressed(true)
