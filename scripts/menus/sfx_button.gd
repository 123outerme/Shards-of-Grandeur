extends BaseButton
class_name SFXButton

@export var sfx: AudioStream = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_pressed():
	SceneLoader.audioHandler.play_sfx(sfx)
