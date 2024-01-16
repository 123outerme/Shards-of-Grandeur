extends Camera2D
class_name PlayerCamera

@onready var player: PlayerController = get_node("..")
@onready var letterbox: Control = get_node("Letterbox")
@onready var shade: Control = get_node("Shade")
@onready var shadeColor: ColorRect = get_node("Shade/ColorRect")
@onready var shadeLabel: RichTextLabel = get_node("Shade/ShadeLabel")

var fadeInReady: bool = false
var fadeOutTween: Tween = null
var fadeInTween: Tween = null
var interruptTween: bool = false

var registeredFadeInCallbacks: Array[Callable] = []
var registeredFadeOutCallbacks: Array[Callable] = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if fadeInReady and fadeInTween != null:
		fadeInReady = false
		fadeInTween.play()

func play_new_act_animation(callback: Callable):
	fade_out(_new_act_fade_out.bind(callback))

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
	for registeredCallback in registeredFadeOutCallbacks:
		fadeOutTween.finished.connect(registeredCallback)
	registeredFadeOutCallbacks = []

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
	if shadeLabel.visible:
		fadeInTween.tween_property(shadeLabel, 'modulate', Color(1, 1, 1, 0), duration)
	fadeInTween.finished.connect(callback)
	fadeInTween.finished.connect(_fade_in_complete)
	for registeredCallback in registeredFadeInCallbacks:
		fadeInTween.finished.connect(registeredCallback)
	registeredFadeInCallbacks = []
	fadeInTween.pause()

func connect_to_fade_out(callback: Callable):
	if fadeOutTween != null and fadeOutTween.is_valid():
		fadeOutTween.finished.connect(callback)
	else:
		registeredFadeOutCallbacks.append(callback)

func connect_to_fade_in(callback: Callable):
	if fadeInTween != null and fadeInTween.is_valid():
		fadeInTween.finished.connect(callback)
	else:
		registeredFadeInCallbacks.append(callback)

func toggle_cutscene_paused_shade():
	shade.visible = not shade.visible
	shadeLabel.text = '[center]Cutscene: Paused[/center]'
	shadeLabel.visible = shade.visible
	shadeLabel.modulate = Color(1, 1, 1, 1) # just in case fadein messed with it and didn't properly reset it
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
	shadeLabel.visible = false # hide label if it was already visible
	shadeLabel.modulate.a = 1 # make it opaque again after hidden

func _new_act_fade_out(callback: Callable):
	shadeLabel.text = '[center]Act ' + \
			String.num(PlayerResources.questInventory.currentAct) + ': ' + \
			PlayerResources.questInventory.actNames[PlayerResources.questInventory.currentAct] + \
			'[/center]'
	shadeLabel.visible = true
	await get_tree().create_timer(2.5).timeout
	fade_in(callback)
