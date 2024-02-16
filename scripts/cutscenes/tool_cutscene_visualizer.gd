@tool
extends CutscenePlayer
class_name CutsceneVisualizer

@export var triggerOrNPC: Node

@export var useRealNpcs: bool = false
@export var resetRealNpcsAfterComplete: bool = true

@export var startVisualizing: bool:
	get:
		return false
	set(value):
		if value and playing:
			return
		
		if triggerOrNPC:
			mockPlayer.global_position = triggerOrNPC.position
		start_visualizing()

@export var pauseVisualization: bool:
	get:
		return isPaused
	set(value):
		if playing:
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

var fetchedActors: Array[Node2D] = []

@onready var mockPlayer: Node = get_node('MockPlayer')

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

func handle_camera(frame: CutsceneFrame):
	if lastFrame.endHoldCamera and not mockPlayer.holdingCamera:
		mockPlayer.hold_camera_at(mockPlayer.position)
	if not lastFrame.endHoldCamera and mockPlayer.holdingCamera:
		mockPlayer.snap_camera_back_to_player()
	if lastFrame.shakeCamForDuration and (frame == null or not frame.shakeCamForDuration):
		mockPlayer.stop_cam_shake()

func handle_play_sfx(sfx: AudioStream):
	if sfx != null:
		print('Play SFX ' + sfx.resource_name)

func handle_start_cam_shake():
	mockPlayer.start_cam_shake()

func queue_text(item: CutsceneDialogue):
	print(item.speaker + ' will say: ')
	for text in item.texts:
		print(text)

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

func start_visualizing():
	mockPlayer.mockShadeCenter.modulate.a = 0.0
	saveCutscene = cutscene
	fetchedActors = []
	start_cutscene(cutscene.duplicate(true))

func pause_cutscene():
	for tween in tweens:
		tween.pause()
	isPaused = true

func resume_cutscene():
	for tween: Tween in tweens:
		if tween.is_valid():
			tween.play()
	isPaused = false

func end_cutscene(force: bool = false):
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
