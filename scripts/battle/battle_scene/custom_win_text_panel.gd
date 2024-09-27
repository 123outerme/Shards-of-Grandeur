extends Control
class_name CustomWinTextPanel

@export var customText: String = ''

@onready var panel: Panel = get_node('Panel')
@onready var customTextLabel: RichTextLabel = get_node('Panel/CustomTextLabel')

var showTween: Tween = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_custom_win_text_panel():
	if customText == '':
		visible = false
		return
	visible = true
	showTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	var panelSize: Vector2 = panel.size
	panel.size = Vector2.ZERO
	showTween.tween_property(panel, 'size', panelSize, 0.75)
	showTween.finished.connect(_tween_finished)

func _tween_finished():
	customTextLabel.text = '[center]' + TextUtils.rich_text_substitute(customText, Vector2i(32, 32)) + '[/center]'
