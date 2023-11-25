extends Camera2D
class_name PlayerCamera

@onready var player: PlayerController = get_node("..")
@onready var letterbox: Control = get_node("Letterbox")
@onready var shade: Control = get_node("Shade")
@onready var shadeColor: ColorRect = get_node("Shade/ColorRect")
@onready var cutscenePausedLabel: RichTextLabel = get_node("Shade/CutscenePauseLabel")

var fadeInReady: bool = false
var fadeOutTween: Tween = null
var fadeInTween: Tween = null
var interruptTween: bool = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if fadeInReady and fadeInTween != null:
		fadeInReady = false
		fadeInTween.play()

func show_letterbox(showing: bool = true):
	letterbox.visible = showing
	player.inCutscene = showing

func fade_out(callback: Callable, duration: float = 0.5):
	shade.visible = true
	if fadeInTween != null and fadeInTween.is_valid():
		interruptTween = true
		fadeInTween.kill()
		fadeInTween.finished.emit()
	if fadeOutTween != null and fadeOutTween.is_valid():
		interruptTween = true
		fadeOutTween.kill()
		fadeOutTween.finished.emit()
	fadeOutTween = create_tween()
	fadeOutTween.tween_property(shadeColor, 'modulate', Color(0, 0, 0, 1.0), duration)
	fadeOutTween.finished.connect(callback)
	fadeOutTween.finished.connect(_fade_out_complete)

func fade_in(callback: Callable, duration: float = 0.5):
	fadeInReady = true
	shade.visible = true
	if fadeInTween != null and fadeInTween.is_valid():
		interruptTween = true
		fadeInTween.finished.emit()
		fadeInTween.kill()
	if fadeOutTween != null and fadeOutTween.is_valid():
		interruptTween = true
		fadeOutTween.kill()
		fadeOutTween.finished.emit()
	fadeInTween = create_tween()
	fadeInTween.tween_property(shadeColor, 'modulate', Color(0, 0, 0, 0), duration)
	fadeInTween.finished.connect(callback)
	fadeInTween.finished.connect(_fade_in_complete)
	fadeInTween.pause()

func toggle_cutscene_paused_shade():
	shade.visible = not shade.visible
	cutscenePausedLabel.visible = shade.visible
	shadeColor.modulate = Color(0, 0, 0, 0.7)

func _fade_out_complete():
	if not interruptTween:
		shadeColor.modulate = Color(0, 0, 0, 1.0)
	interruptTween = false
	fadeOutTween = null
	
func _fade_in_complete():
	if not interruptTween:
		shade.visible = false
		shadeColor.modulate = Color(0, 0, 0, 0)
	interruptTween = false
	fadeInTween = null
	
