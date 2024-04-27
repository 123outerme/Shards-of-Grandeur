extends Control
class_name VirtualKeyboard
signal keyboard_hidden
signal key_pressed(character: String)
signal backspace_pressed
signal enter_pressed

@export var enabled: bool = true
@export var rows: Array[String] = [
	'`1234567890-',
	'qwertyuiop[]',
	'asdfghjkl;\'=',
	'zxcvbnm ,./\\',
	''
]

# if a character is the same as the non-shifted row, it will just attempt to uppercase it
@export var customShiftRows: Array[String] = [
	'~!@#$%^&*()_',
	'qwertyuiop{}',
	'asdfghjkl:"+',
	'zxcvbnm <>?|'
]

@export var backspaceRow: int = 4
@export var cancelRow: int = 4
@export var enterRow: int = 4
@export var shiftRow: int = 4
@export var capsLockRow: int = 4
@export var startShifted: bool = false
@export var startCapsLock: bool = false
var shift: bool = false
var capsLock: bool = false

# access to control that the user focused
var editingControl: Control = null

var buttonsArr: Array = []

var focusButton: BaseButton = null
var spaceButton: BaseButton = null

const buttonScene: PackedScene = preload('res://prefabs/ui/sfx_button.tscn')

@onready var rowContainers: Array[HBoxContainer] = [
	get_node('Panel/MarginContainer/VBoxContainer/Row1'),
	get_node('Panel/MarginContainer/VBoxContainer/Row2'),
	get_node('Panel/MarginContainer/VBoxContainer/Row3'),
	get_node('Panel/MarginContainer/VBoxContainer/Row4'),
	get_node('Panel/MarginContainer/VBoxContainer/Row5')
]

# Called when the node enters the scene tree for the first time.
func _ready():
	#visible = false
	build_keyboard()
	get_viewport().gui_focus_changed.connect(_show_on_edit)
	shift = startShifted
	capsLock = startCapsLock

func _unhandled_input(event):
	if visible:
		# TODO maybe there can be better logic for handling whether or not a key should be consumed for text input?
		var textInput: bool = false
		if event is InputEventKey:
			textInput = true
		if event.is_action_pressed('game_decline') and not textInput:
			get_viewport().set_input_as_handled()
			_press_backspace()
		if event.is_action_pressed('game_pause') and not textInput:
			get_viewport().set_input_as_handled()
			_press_enter()
		if event.is_action_pressed('game_stats') and not textInput:
			get_viewport().set_input_as_handled()
			hide_keyboard()
		if event.is_action_pressed('game_inventory') and not textInput:
			get_viewport().set_input_as_handled()
			_press_key(spaceButton)
		if event.is_action_pressed('game_quests') and not textInput:
			get_viewport().set_input_as_handled()
			_press_caps_lock()

func _show_on_edit(control: Control):
	if enabled and (control is LineEdit or control is TextEdit or control is SpinBox) and get_parent().is_visible_in_tree():
		editingControl = control
		show_keyboard()

func show_keyboard():
	visible = true
	focusButton.grab_focus()

func hide_keyboard():
	if visible:
		keyboard_hidden.emit()
	visible = false
	reset_keyboard_state()

func build_keyboard():
	var firstButton: BaseButton = null
	buttonsArr = []
	for idx in range(len(rows)):
		var rowArr: Array[BaseButton] = []
		buttonsArr.append(rowArr)
		for charIdx in range(len(rows[idx])):
			var character = rows[idx][charIdx]
			#var button: BaseButton = buttonScene.instantiate()
			var text: String = character
			var shiftChar = character.to_upper()
			if idx < len(customShiftRows) and customShiftRows[idx][charIdx] != character:
				shiftChar = customShiftRows[idx][charIdx]
			if text == ' ':
				text = 'Space'
			var button = build_keyboard_button(_press_key, text, character, shiftChar)
			if text == 'Space':
				spaceButton = button
			rowArr.append(button)
			if firstButton == null:
				firstButton = button
			rowContainers[idx].add_child(button)
		if idx == backspaceRow:
			var button: BaseButton = build_keyboard_button(_press_backspace, 'Backspace')
			rowArr.append(button)
			rowContainers[idx].add_child(button)
		if idx == cancelRow:
			var button: BaseButton = build_keyboard_button(_press_cancel, 'Cancel')
			rowArr.append(button)
			rowContainers[idx].add_child(button)
			focusButton = button
		if idx == enterRow:
			var button: BaseButton = build_keyboard_button(_press_enter, 'Enter')
			rowArr.append(button)
			rowContainers[idx].add_child(button)
		if idx == shiftRow:
			var button: BaseButton = build_keyboard_button(_press_shift, 'Shift')
			rowArr.append(button)
			rowContainers[idx].add_child(button)
		if idx == capsLockRow:
			var text = 'CAPS'
			if capsLock:
				text = 'caps'
			var button: BaseButton = build_keyboard_button(_press_caps_lock, text)
			rowArr.append(button)
			rowContainers[idx].add_child(button)
	if focusButton == null:
		focusButton = firstButton
	update_keyboard_focus_neighbors.call_deferred()

func build_keyboard_button(pressedCallback: Callable, text: String, character: String = '', shiftCharacter: String = '') -> BaseButton:
	var button: BaseButton = buttonScene.instantiate()
	button.text = text
	button.add_to_group('VirtualKeyboardButton')
	if character != '':
		button.set_meta('character', character)
	if shiftCharacter != '':
		button.set_meta('shift_character', shiftCharacter)
	
	button.pressed.connect(pressedCallback.bind(button))
	button.custom_minimum_size = Vector2(80, 40)
	#button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button
	
func update_keyboard_focus_neighbors():
	for idx in range(0, len(rows)):
		for charIdx in range(len(rows[idx])):
			var button: BaseButton = buttonsArr[idx][charIdx]
			var topIdx = (idx - 1) % len(buttonsArr)
			if charIdx < len(buttonsArr[topIdx]):
				var topButton: BaseButton = buttonsArr[topIdx][charIdx]
				button.focus_neighbor_top = button.get_path_to(topButton)
				topButton.focus_neighbor_bottom = topButton.get_path_to(button)
			else:
				var topButton: BaseButton = buttonsArr[topIdx][len(buttonsArr[topIdx]) - 1]
				button.focus_neighbor_top = button.get_path_to(topButton)
			
			var bottomIdx = (idx + 1) % len(buttonsArr)
			if charIdx < len(buttonsArr[bottomIdx]):
				var bottomButton: BaseButton = buttonsArr[bottomIdx][charIdx]
				button.focus_neighbor_bottom = button.get_path_to(bottomButton)
				bottomButton.focus_neighbor_top = bottomButton.get_path_to(button)
			else:
				var bottomButton: BaseButton = buttonsArr[bottomIdx][len(buttonsArr[bottomIdx]) - 1]
				button.focus_neighbor_bottom = button.get_path_to(bottomButton)
			
			var leftIdx = (charIdx - 1) % len(buttonsArr[idx])
			var leftButton: BaseButton = buttonsArr[idx][leftIdx]
			button.focus_neighbor_left = button.get_path_to(leftButton)
			leftButton.focus_neighbor_right = leftButton.get_path_to(button)
			
			var rightIdx = (charIdx + 1) % len(buttonsArr[idx])
			var rightButton: BaseButton = buttonsArr[idx][rightIdx]
			button.focus_neighbor_right = button.get_path_to(rightButton)
			rightButton.focus_neighbor_left = rightButton.get_path_to(button)

func update_keyboard_text():
	for node in get_tree().get_nodes_in_group('VirtualKeyboardButton'):
		var button: BaseButton = node as BaseButton
		if len(button.text) == 1:
			if shift or capsLock:
				button.text = button.get_meta('shift_character' , 'ERROR')
			else:
				button.text = button.get_meta('character' , 'ERROR')

func reset_keyboard_state():
	shift = startShifted
	update_keyboard_text()

func _press_key(button: BaseButton):
	if button == null:
		return
	
	var character = button.get_meta('character', 'ERROR')
	if shift or capsLock:
		character = button.get_meta('shift_character', 'ERROR')
		if shift:
			shift = false
			update_keyboard_text()
	key_pressed.emit(character)

func _press_backspace(button: BaseButton = null):
	backspace_pressed.emit()

func _press_cancel(button: BaseButton = null):
	hide_keyboard()

func _press_enter(button: BaseButton = null):
	enter_pressed.emit()
	visible = false

func _press_shift(button: BaseButton = null):
	shift = not shift
	update_keyboard_text()

func _press_caps_lock(button: BaseButton = null):
	capsLock = not capsLock
	shift = false
	update_keyboard_text()
