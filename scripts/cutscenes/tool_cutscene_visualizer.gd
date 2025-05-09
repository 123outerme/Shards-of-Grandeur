@tool
extends CutscenePlayer
class_name CutsceneVisualizer

@export var triggerOrNPC: Node
@export var customStartPos: Vector2 = Vector2.ZERO
@export var useCustomStartPos: bool = false

@export var useRealNpcs: bool = false
@export var resetRealNpcsAfterComplete: bool = true

@export var startVisualizing: bool:
	get:
		return false
	set(value):
		if value and playing:
			return
		start_visualizing()

@export var pauseVisualization: bool:
	get:
		return isPaused
	set(value):
		if not playing and not pauseVisualization:
			return
		
		if value:
			pause_cutscene()
		else:
			resume_cutscene()

@export var stopVisualization: bool:
	get:
		return false
	set(value):
		if not playing:
			return
		end_cutscene(true)
		isPaused = false

var saveCutscene: Cutscene = null
var fadeOutTween: Tween = null
var fadeInTween: Tween = null
var shownTextNotPaused: bool = false

var fetchedActors: Array[Node2D] = []

@onready var mockPlayer: MockPlayer = get_node('MockPlayer')

func _init():
	if not Engine.is_editor_hint():
		queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)

func fetch_actor_node(actorTreePath: String, isPlayer: bool) -> Node:
	var node = null
	if isPlayer:
		node = mockPlayer
	elif rootNode != null:
		if not useRealNpcs:
			var pathSegments = actorTreePath.split('/')
			node = get_node_or_null(pathSegments[len(pathSegments) - 1])
			if node == null:
				var origNode = rootNode.get_node_or_null(actorTreePath)
				if origNode != null:
					node = origNode.duplicate(1 + 2 + 4) # no instancing
					add_child(node)
		else:
			node = super.fetch_actor_node(actorTreePath, isPlayer)
			if node != null and not (node in fetchedActors):
				fetchedActors.append(node)
	return node


func is_in_dialogue() -> bool:
	return false

func handle_camera_move(percentTime: float, frame: CutsceneFrame, lFrame: CutsceneFrame) -> void:
	if frame != null and frame.cameraMovement != null and lFrame != null and lFrame.endHoldCamera and (mockPlayer.holdCameraX or mockPlayer.holdCameraY):
		var camPosition: Vector2 = frame.cameraMovement.get_camera_position_at_time(percentTime, 1, lastFrameCameraPos, mockPlayer.position)
		mockPlayer.hold_camera_at(camPosition)

func get_last_player_cam_pos() -> Vector2:
	return mockPlayer.holdCameraPos if lastFrame != null and lastFrame.cameraMovement != null else mockPlayer.position

func handle_camera(frame: CutsceneFrame):
	if lastFrame.endHoldCamera and not (mockPlayer.holdCameraX or mockPlayer.holdCameraY):
		mockPlayer.hold_camera_at(mockPlayer.position)
	if not lastFrame.endHoldCamera and (mockPlayer.holdCameraX or mockPlayer.holdCameraY):
		mockPlayer.snap_camera_back_to_player()
	if lastFrame.shakeCamForDuration and (frame == null or not frame.shakeCamForDuration):
		mockPlayer.stop_cam_shake()
	
	# not camera related but run every new CutsceneFrame: if we have shown text but not paused the cutscene for it yet:
	if shownTextNotPaused and lastFrame.endTextBoxPauses:
		shownTextNotPaused = false
		call_deferred('pause_cutscene') # do so

func handle_play_sfx(sfxs: Array[AudioStream]):
	for sfx: AudioStream in sfxs:
		if sfx != null:
			print('Play SFX ' + sfx.resource_name)

func handle_start_cam_shake():
	mockPlayer.start_cam_shake()

func queue_text(item: CutsceneDialogue, frame: CutsceneFrame):
	print(item.speaker + ' will say: ')
	for text in item.texts:
		print(text)
	shownTextNotPaused = true
	if frame == null:
		printerr('ToolCutsceneVisualizer queue_text() error: frame == null (was there no pausing frame created for the frame after this dialog?)')
	elif frame.endTextBoxPauses:
		call_deferred('pause_cutscene')
		shownTextNotPaused = false

func handle_fade_out():
	fadeOutTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	fadeOutTween.tween_property(mockPlayer.mockShadeCenter, 'modulate:a', 1.0, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
	fadeOutTween.finished.connect(_mock_fade_out_finished)

func handle_fade_in():
	fadeInTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	fadeInTween.tween_property(mockPlayer.mockShadeCenter, 'modulate:a', 0.0, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
	fadeInTween.finished.connect(_mock_fade_in_finished)

func handle_give_item():
	if lastFrame.givesItem != null:
		print('Cutscene gives item ' + lastFrame.givesItem.itemName)

func handle_add_follower() -> void:
	print('Cutscene sets follower "', lastFrame.addsFollowerId, '" active')

func handle_remove_follower() -> void:
	print('Cutscene removes follower "', lastFrame.removesFollowerId, '"')

func handle_heal_player():
	print('Player gets fully healed.')

func handle_start_shard_learn_tutorial():
	print('Start Shard Learn Tutorial Here')

func start_visualizing():
	if useCustomStartPos:
		mockPlayer.position = customStartPos
	elif triggerOrNPC != null:
		mockPlayer.position = triggerOrNPC.position
	
	mockPlayer.mockShadeCenter.modulate.a = 0.0
	mockPlayer.snap_camera_back_to_player()
	cutscene.reset_internals()
	saveCutscene = cutscene
	fetchedActors = []
	start_cutscene(cutscene.duplicate(true))

func pause_cutscene():
	for tween in tweens:
		tween.pause()
	isPaused = true

func resume_cutscene():
	for tween: Tween in tweens:
		if tween != null and tween.is_valid():
			tween.play()
	isPaused = false

func end_cutscene(_force: bool = false):
	if cutscene == null or completeAfterFadeIn:
		return
	if cutscene.givesQuest != null:
		print('Given quest ' + cutscene.givesQuest.questName)
	complete_cutscene()

func complete_cutscene():
	lastFrame = null
	playing = false
	completeAfterFadeIn = false
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished(cutscene)
		playingFromTrigger = null
	cutscene = saveCutscene
	cutscene_completed.emit()
	for tween in tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	tweens = []
	timer = 0
	isPaused = false
	if not useRealNpcs:
		for child in get_children():
			if child != mockPlayer:
				child.queue_free() # NOTE could be unsafe in editor
	elif resetRealNpcsAfterComplete:
		for actor in fetchedActors:
			if actor is NPCScript:
				actor.position = actor.data.position
				actor.invisible = not actor.data.visible
				actor.flip_h = actor.data.flipH
				if actor.data.animSet:
					actor.set_sprite_frames(actor.data.animSet)

func _mock_fade_out_finished():
	fadeOutTween = null
	
func _mock_fade_in_finished():
	fadeInTween = null
