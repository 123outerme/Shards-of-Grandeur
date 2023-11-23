extends Camera2D
class_name PlayerCamera

@onready var player: PlayerController = get_node("..")
@onready var letterbox: Control = get_node("Letterbox")
@onready var shade: Control = get_node("Shade")
@onready var shadeColor: ColorRect = get_node("Shade/ColorRect")
@onready var cutscenePausedLabel: RichTextLabel = get_node("Shade/CutscenePauseLabel")

var fadeInReady: bool = false
var fadeInTween: Tween = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if fadeInReady and fadeInTween != null and position == Vector2(0, 0):
		fadeInReady = false
		fadeInTween.play()

func show_letterbox(showing: bool = true):
	letterbox.visible = showing
	player.inCutscene = showing

func fade_out(callback: Callable, duration: float = 0.5):
	shadeColor.modulate = Color(0, 0, 0, 0)
	shade.visible = true
	var tween = create_tween().tween_property(shadeColor, 'modulate', Color(0, 0, 0, 1.0), duration)
	tween.finished.connect(callback)

func fade_in(callback: Callable, duration: float = 0.5):
	fadeInReady = true
	shadeColor.modulate = Color(0, 0, 0, 1.0)
	shade.visible = true
	if fadeInTween != null:
		fadeInTween.kill()
	fadeInTween = create_tween()
	fadeInTween.tween_property(shadeColor, 'modulate', Color(0, 0, 0, 0), duration)
	fadeInTween.finished.connect(callback)
	fadeInTween.finished.connect(func(): shade.visible = false)
	fadeInTween.pause()

func toggle_cutscene_paused_shade():
	shade.visible = not shade.visible
	cutscenePausedLabel.visible = shade.visible
	shadeColor.modulate = Color(0, 0, 0, 0.7)
