extends Camera2D
class_name PlayerCamera
signal new_act_anim_complete

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

@onready var cutscenePauseButtons: HBoxContainer = get_node('Shade/ShadeLabel/CutscenePauseButtons')
@onready var resumeButton: Button = get_node('Shade/ShadeLabel/CutscenePauseButtons/ResumeButton')
@onready var cutsceneSettingsButton: Button = get_node('Shade/ShadeLabel/CutscenePauseButtons/SettingsButton')

var cutscenePaused: bool = false

var fadedOrFadingOut: bool = false
var fadeInReady: bool = false
var fadeOutTween: Tween = null
var fadeInTween: Tween = null
var interruptTween: bool = false
var camShaking: bool = false
var camShakingTime: float = 0
var storedShakingOffset: Vector2 = Vector2.ZERO
var newActAnimPlaying: bool = false

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
func _process(_delta):
	if fadeInReady and fadeInTween != null:
		fadeInReady = false
		fadeInTween.play()

# camera movement is jittery in _process, so move in _physics_process
func _physics_process(delta):
	if camShaking and SettingsHandler.gameSettings.screenShake:
		storedShakingOffset = get_cam_shaking_offset(delta)
		camShakingTime += delta
		if not (player.holdCameraX or player.holdCameraY):
			position = storedShakingOffset

func get_cam_shaking_offset(delta: float = 0.0) -> Vector2:
	var camShakingIdx: int = floori((camShakingTime + delta) / 0.05) % len(CAM_SHAKING_POSITIONS)
	return CAM_SHAKING_POSITIONS[camShakingIdx]

func play_new_act_animation(callback: Callable):
	fade_out(_new_act_fade_out.bind(callback))

func show_alert(message: String, icon: Texture2D = null, sfx: AudioStream = null, disableSfx: bool = false, lifetime: float = 2):
	if player.actChanged:
		await new_act_anim_complete
	
	var panel: AlertPanel = alertPanelPrefab.instantiate()
	panel.message = message
	panel.lifetime = lifetime
	
	if icon != null:
		panel.alertIcon = icon
	
	if sfx != null or disableSfx:
		panel.alertSfx = sfx if not disableSfx else null
	
	alertControl.add_child(panel)

func set_alert_panels_lifetime_pause(pause: bool):
	for alertPanel: AlertPanel in get_tree().get_nodes_in_group('AlertPanel'):
		alertPanel.pauseTimer = pause

func show_letterbox(showing: bool = true):
	letterbox.visible = showing
	player.inCutscene = showing
	player.overworldTouchControls.set_in_cutscene(showing)

func fade_out(callback: Callable, duration: float = 0.5):
	fadedOrFadingOut = true
	set_alert_panels_lifetime_pause(true)
	shade.visible = true
	cutscenePauseButtons.visible = false
	PlayerFinder.player.overworldTouchControls.set_all_visible(false)
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
	# recheck that the joystick is still considered as held now
	PlayerFinder.player.overworldTouchControls.touchVirtualJoystick.recheck_joystick_hold()
	fadedOrFadingOut = false # not faded out anymore, fading in
	# after half the duration of the fade up, set the controls to be visible again (invisible from fading out)
	await get_tree().create_timer(duration / 2).timeout
	PlayerFinder.player.overworldTouchControls.set_all_visible()

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
	camShakingTime = 0
	storedShakingOffset = Vector2.ZERO
	camShaking = true
	
func stop_cam_shake():
	camShaking = false
	position = Vector2(0, 0)
	if player.holdCameraX:
		position.x = player.holdingCameraAt.x - player.position.x
	if player.holdCameraY:
		position.y = player.holdingCameraAt.y - player.position.y
	camShakingTime = 0
	storedShakingOffset = Vector2.ZERO

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
		shade.visible = cutscenePaused or fadedOrFadingOut 
		shadeLabel.visible = cutscenePaused
	if cutscenePaused:
		shadeLabel.modulate = Color(1, 1, 1, 1) # just in case fadein messed with it and didn't properly reset it
		shadeColor.modulate = Color(0, 0, 0, max(shadeColor.modulate.a, 0.7))
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
	#PlayerFinder.player.overworldTouchControls.set_all_visible(true)

func _new_act_fade_out(callback: Callable):
	shadeLabel.text = '[center]Act ' + \
			String.num(PlayerResources.questInventory.currentAct) + ': ' + \
			PlayerResources.questInventory.actNames[PlayerResources.questInventory.currentAct] + \
			'[/center]'
	shadeLabel.visible = true
	await get_tree().create_timer(2.5).timeout
	registeredFadeInCallbacks.append(_emit_new_act_anim_complete)
	fade_in(callback)

func _emit_new_act_anim_complete():
	newActAnimPlaying = false
	new_act_anim_complete.emit()

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

func _on_cutscene_settings_button_pressed() -> void:
	player.pausePanel.settingsOnly = true
	player.pausePanel.resume_game.connect(_cutscene_settings_back)
	player.animatedBgPanel.visible = true
	player.pausePanel.pause_game()

func _settings_changed():
	zoom = Vector2(SettingsHandler.gameSettings.playerCamZoom, SettingsHandler.gameSettings.playerCamZoom)

func _cutscene_settings_back() -> void:
	cutsceneSettingsButton.grab_focus()
	player.pausePanel.settingsOnly = false
	if player.pausePanel.resume_game.is_connected(_cutscene_settings_back):
		player.pausePanel.resume_game.disconnect(_cutscene_settings_back)
