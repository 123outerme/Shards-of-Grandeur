extends Panel
class_name GameLogsPanel

signal back_pressed

@onready var logsOutput: RichTextLabel = get_node('LogsOutput')
@onready var backButton: Button = get_node('BackButton')

func show_game_logs(logFile: String = 'godot.log') -> bool:
	var file: FileAccess = FileAccess.open('user://logs/' + logFile, FileAccess.READ)
	if file != null:
		logsOutput.text = file.get_as_text()
		file.close()
		visible = true
		backButton.grab_focus()
		return true
	return false

func _on_back_button_pressed() -> void:
	visible = false
	back_pressed.emit()
