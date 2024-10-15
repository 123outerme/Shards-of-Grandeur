extends Control
class_name CountChooseControl

signal line_edit_submitted(text: String)
signal value_changed(newVal: int)
signal intercepted_input_in_line_edit

## the current value the control has
@export var value: int = 0

## the minimum value the control can accept
@export var minValue: int = 1

## if false, no minimum will be enforced
@export var useMin: bool = true

## the maximum value the control can accept
@export var maxValue: int = 10

## if true, no maximum will be enforced
@export var useMax: bool = true

@onready var incOneButton: Button = get_node('ButtonsHboxContainer/IncOneButton')
@onready var lineEdit: LineEdit = get_node('LineEdit')

var allCountTextSelected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SettingsHandler.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("game_decline") and lineEdit.has_focus():
		get_viewport().set_input_as_handled()
		var focusCancel: bool = true
		
		# if Shift key is pressed:
		# this is involved in text input without being a character that the LineEdit consumes, so we need to handle it here
		if event is InputEventKey:
			if event.keycode == KEY_SHIFT:
				focusCancel = false
			
		if focusCancel:
			intercepted_input_in_line_edit.emit()

func load_count_choose_control() -> void:
	set_count_value(value)

func initial_focus() -> void:
	incOneButton.grab_focus()

func set_count_value(newVal: int) -> void:
	value = enforce_min_max(newVal)
	lineEdit.text = String.num(value)
	if lineEdit.has_focus():
		lineEdit.caret_column = len(lineEdit.text)
	value_changed.emit(value)

func enforce_min_max(value: int) -> int:
	var newVal: int = value
	if useMin:
		newVal = max(minValue, newVal)
	if useMax:
		newVal = min(maxValue, newVal)
	return newVal

func set_lineedit_bottom_focus_neighbor(control: Control) -> void:
	lineEdit.focus_neighbor_bottom = lineEdit.get_path_to(control)
	control.focus_neighbor_top = control.get_path_to(lineEdit)

func _on_button_pressed(changeVal: int) -> void:
	set_count_value(value + changeVal)

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text == '':
		value = 0
		value_changed.emit(value)
		# don't do anything else yet, the user may yet type something
		return
	
	if new_text.is_valid_int():
		set_count_value(new_text.to_int())

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == '':
		set_count_value(0)
	elif new_text.is_valid_int():
		set_count_value(new_text.to_int())
	line_edit_submitted.emit(new_text)

func _on_line_edit_focus_entered() -> void:
	allCountTextSelected = true

func _on_line_edit_focus_exited() -> void:
	_on_line_edit_text_submitted(lineEdit.text)

func _on_settings_changed():
	lineEdit.virtual_keyboard_enabled = not SettingsHandler.gameSettings.useVirtualKeyboard
