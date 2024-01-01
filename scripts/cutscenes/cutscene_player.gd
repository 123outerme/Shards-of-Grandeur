extends Node
class_name CutscenePlayer

@export var cutscene: Cutscene = null
@export var playing: bool = false
@export var rootNode: Node = null

var playingFromTrigger: CutsceneTrigger = null
var timer: float = 0
var lastFrame: CutsceneFrame = null
var nextKeyframeTime: float = 0
var tweens: Array = []
var isPaused: bool = false
var isFadedOut: bool = false
var isFadingIn: bool = false
var completeAfterFadeIn: bool = false

func _process(delta):
	if cutscene != null and playing and not isPaused:
		var frame: CutsceneFrame = cutscene.get_keyframe_at_time(timer)
		timer += delta
		
		if PlayerFinder.player.is_in_dialogue() and lastFrame != null and lastFrame.endTextBoxPauses:
			if frame != lastFrame:
				timer -= delta
			return
		
		if lastFrame != null and frame != lastFrame:
			if lastFrame.endHoldCamera and not PlayerFinder.player.holdingCamera:
				PlayerFinder.player.hold_camera_at(PlayerFinder.player.position)
			if not lastFrame.endHoldCamera and PlayerFinder.player.holdingCamera:
				PlayerFinder.player.snap_camera_back_to_player()
			
			if lastFrame.endTextBoxTexts != null and len(lastFrame.endTextBoxTexts) > 0 \
					and not lastFrame.get_text_was_triggered():
				PlayerFinder.player.set_cutscene_texts(lastFrame.endTextBoxTexts, lastFrame.endTextBoxSpeaker)
				lastFrame.set_text_was_triggered()
				
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_OUT and not isFadedOut:
				PlayerFinder.player.cam.fade_out(_fade_out_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
				isFadedOut = true
				isFadingIn = false
			
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_IN:
				PlayerFinder.player.cam.fade_in(_fade_in_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
			
			if lastFrame.givesItem != null:
				PlayerResources.inventory.add_item(lastFrame.givesItem)
		
		if frame == null: # end of cutscene
			end_cutscene()
			return
		
		if lastFrame == frame:
			return
		
		lastFrame = frame
		tweens = []
		for animation in frame.actorAnims:
			var node = null
			if animation.isPlayer:
				node = PlayerFinder.player
			else:
				node = rootNode.get_node(animation.actorTreePath)
			if node != null and node.has_method('play_animation'):
				node.call('play_animation', animation.animation)
		for actorTween in frame.actorTweens:
			var node = null
			if actorTween == null:
				continue # skip null tweens
			if actorTween.isPlayer:
				node = PlayerFinder.player
			else:
				node = rootNode.get_node(actorTween.actorTreePath)
			var tween = create_tween().set_ease(actorTween.easeType).set_trans(actorTween.transitionType)
			tween.tween_property(node, actorTween.propertyName, actorTween.value, frame.frameLength)
			if actorTween.propertyName == 'position' and node.has_method('face_horiz'):
				node.call('face_horiz', actorTween.value.x - node.position.x)
			tweens.append(tween)

func start_cutscene(newCutscene: Cutscene):
	if playing or (newCutscene.storyRequirements != null and not newCutscene.storyRequirements.is_valid()):
		return
	SaveHandler.save_data()
	for npc in get_tree().get_nodes_in_group("NPC"):
		npc.talkAlertSprite.visible = false
	cutscene = newCutscene
	timer = 0
	nextKeyframeTime = cutscene.cutsceneFrames[0].frameLength
	cutscene.calc_total_time()
	playing = true
	PlayerFinder.player.cam.show_letterbox()
	SceneLoader.pause_autonomous_movers()

func pause_cutscene():
	for tween in tweens:
		tween.pause()
	isPaused = true

func resume_cutscene():
	for tween in tweens:
		tween.play()
	isPaused = false

func toggle_pause_cutscene():
	isPaused = not isPaused
	if isPaused:
		pause_cutscene()
	else:
		resume_cutscene()

func end_cutscene(force: bool = false):
	if cutscene == null:
		return
	if not isFadedOut:
		complete_cutscene()
	else:
		if force: # called when warp zone is entered while faded out; so cutscene can end 
			PlayerFinder.player.fade_in_unlock_cutscene()
		completeAfterFadeIn = true

func complete_cutscene():
	SceneLoader.unpause_autonomous_movers()
	if PlayerFinder.player.is_in_dialogue():
		PlayerFinder.player.inCutscene = false # be considered not in a cutscene anymore
		PlayerFinder.player.disableMovement = true # still disable movement until text box closes
	else:
		PlayerFinder.player.cam.show_letterbox(false) # otherwise hide the letterboxes and be not in cutscene
	if cutscene.unlockCameraHoldAfter and PlayerFinder.player.holdingCamera:
		PlayerFinder.player.snap_camera_back_to_player()
	playing = false
	for actor in cutscene.deactivateActorsAfter:
		var actorNode = rootNode.get_node_or_null(actor)
		if actorNode != null:
			actorNode.visible = false
	
	if cutscene.givesQuest != null:
		PlayerResources.questInventory.accept_quest(cutscene.givesQuest)
	PlayerResources.set_cutscene_seen(cutscene.saveName)
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished()
		playingFromTrigger = null
	cutscene = null

func _fade_out_complete():
	if completeAfterFadeIn and not isFadingIn:
		isFadingIn = true
		PlayerFinder.player.cam.call_deferred('fade_in', _fade_in_complete)

func _fade_in_complete():
	isFadedOut = false
	isFadingIn = false
	if completeAfterFadeIn:
		complete_cutscene()
