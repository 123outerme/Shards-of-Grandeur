extends Camera2D
class_name PlayerCamera

const CAM_SHAKING_POSITIONS: Array[Vector2] = [
	Vector2(0,0),
	Vector2(0,2),
	Vector2(0,4),
	Vector2(0,2),
	Vector2(0,0),
	Vector2(0,-2),
	Vector2(0,-4),
	Vector2(0,-2),
]

@onready var player: PlayerController = get_node("..")
@onready var alertControl: Control = get_node('AlertControl')
@onready var letterbox: Control = get_node("Letterbox")
@onready var shade: Control = get_node("Shade")
@onready var shadeColor: ColorRect = get_node("Shade/ColorRect")
@onready var shadeLabel: RichTextLabel = get_node("Shade/ShadeLabel")

@onready var cutscenePauseButtons: VBoxContainer = get_node('Shade/ShadeLabel/CutscenePauseButtons')
@onready var resumeButton: Button = get_node('Shade/ShadeLabel/CutscenePauseButtons/ResumeButton')

var cutscenePaused: bool = false

var fadeInReady: bool = false
var fadeOutTween: Tween = null
var fadeInTween: Tween = null
var interruptTween: bool = false
var camShaking: bool = false
var camShakingTime: float = 0

var registeredFadeInCallbacks: Array[Callable] = []
var registeredFadeOutCallbacks: Array[Callable] = []

var alertPanelPrefab = preload('res://prefabs/ui/alert_panel.tscn')

func _ready():
	#set_custom_viewport(SceneLoader.subViewport)
	#SettingsHandler.settings_changed.connect(_settings_changed)
	# initialize zoom
	#_settings_changed()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fadeInReady and fadeInTween != null:
		fadeInReady = false
		fadeInTween.play()
	if camShaking and SettingsHandler.gameSettings.screenShake:
		camShakingTime += delta
		var camShakingIdx = floori(camShakingTime / 0.05) % len(CAM_SHAKING_POSITIONS)
		position = CAM_SHAKING_POSITIONS[camShakingIdx]

func play_new_act_animation(callback: Callable):
	fade_out(_new_act_fade_out.bind(callback))

func show_alert(message: String, lifetime: float = 2):
	var panel: AlertPanel = alertPanelPrefab.instantiate()
	panel.message = message
	panel.lifetime = lifetime
	alertControl.add_child(panel)

func set_alert_panels_lifetime_pause(pause: bool):
	for alertPanel: AlertPanel in get_tree().get_nodes_in_group('AlertPanel'):
		alertPanel.pauseTimer = pause

func show_letterbox(showing: bool = true):
	letterbox.visible = showing
	player.inCutscene = showing

func fade_out(callback: Callable, duration: float = 0.5):
	set_alert_panels_lifetime_pause(true)
	shade.visible = true
	cutscenePauseButtons.visible = false
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
		fadeInTween.kill()
		fadeInTween.finished.emit()
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

func start_cam_shake():
	camShaking = true
	
func stop_cam_shake():
	camShaking = false
	position = Vector2(0, 0)
	camShakingTime = 0

func toggle_cutscene_paused_shade():
	cutscenePaused = not cutscenePaused
	cutscenePauseButtons.visible = cutscenePaused
	shadeLabel.text = '[center]Cutscene: Paused[/center]'
	if fadeInTween != null and fadeInTween.is_valid():
		if cutscenePaused:
			fadeInTween.pause()
			fadeInReady = false
		else:
			fadeInReady = true
			shadeLabel.text = ''
		shade.visible = true
		shadeLabel.visible = true
	else:
		shade.visible = cutscenePaused
		shadeLabel.visible = shade.visible
	if cutscenePaused:
		shadeLabel.modulate = Color(1, 1, 1, 1) # just in case fadein messed with it and didn't properly reset it
		shadeColor.modulate = Color(0, 0, 0, 0.7)
		resumeButton.grab_focus()
	set_alert_panels_lifetime_pause(cutscenePaused)

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
	set_alert_panels_lifetime_pause(false)

func _new_act_fade_out(callback: Callable):
	shadeLabel.text = '[center]Act ' + \
			String.num(PlayerResources.questInventory.currentAct) + ': ' + \
			PlayerResources.questInventory.actNames[PlayerResources.questInventory.currentAct] + \
			'[/center]'
	shadeLabel.visible = true
	await get_tree().create_timer(2.5).timeout
	fade_in(callback)

func _on_resume_button_pressed():
	SceneLoader.cutscenePlayer.toggle_pause_cutscene()
	toggle_cutscene_paused_shade()
	player.cutscenePaused = cutscenePaused
	set_alert_panels_lifetime_pause(cutscenePaused)

func _on_skip_button_pressed():
	shadeLabel.visible = false
	cutscenePaused = false
	player.cutscenePaused = false
	set_alert_panels_lifetime_pause(cutscenePaused)
	SceneLoader.cutscenePlayer.skip_cutscene()

func _settings_changed():
	zoom = Vector2(SettingsHandler.gameSettings.playerCamZoom, SettingsHandler.gameSettings.playerCamZoom)
