extends Node
class_name CutscenePlayer

signal cutscene_completed

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
var skipCutsceneFrameIndex: int = -1

func _process(delta):
	if cutscene != null and playing and not isPaused and skipCutsceneFrameIndex == -1:
		var frame: CutsceneFrame = cutscene.get_keyframe_at_time(timer, lastFrame)
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
			
			if lastFrame.dialogues != null and len(lastFrame.dialogues) > 0 \
					and not lastFrame.get_text_was_triggered():
				for item in lastFrame.dialogues:
					PlayerFinder.player.queue_cutscene_texts(item)
				lastFrame.set_text_was_triggered()
				
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_OUT and not isFadedOut:
				PlayerFinder.player.cam.fade_out(_fade_out_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
				isFadedOut = true
				isFadingIn = false
			
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_IN:
				PlayerFinder.player.cam.fade_in(_fade_in_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
			
			if lastFrame.givesItem != null:
				PlayerResources.inventory.add_item(lastFrame.givesItem)
				PlayerFinder.player.cam.show_alert('Got Item:\n' + lastFrame.givesItem.itemName)
		
		if frame == null: # end of cutscene
			end_cutscene()
			return
				
		if lastFrame == frame:
			return
		
		animate_next_frame(frame)
		
func animate_next_frame(frame: CutsceneFrame, skipping: bool = false):
	lastFrame = frame
	for animSet in frame.actorAnimSets:
		var node = fetch_actor_node(animSet.actorTreePath, animSet.isPlayer)
		if node != null and node.has_method('set_sprite_frames'):
			node.call('set_sprite_frames', animSet.animationSet)
	for animation in frame.actorAnims:
		var node = fetch_actor_node(animation.actorTreePath, animation.isPlayer)
		if node != null and node.has_method('play_animation'):
			node.call('play_animation', animation.animation)
	for actorTween in frame.actorTweens:
		if actorTween == null:
			continue # skip null tweens
		var node = fetch_actor_node(actorTween.actorTreePath, actorTween.isPlayer)
		if node == null:
			continue # skip null actors
		if not skipping:
			var tween = create_tween().set_ease(actorTween.easeType).set_trans(actorTween.transitionType)
			tween.tween_property(node, actorTween.propertyName, actorTween.value, frame.frameLength)
			if actorTween.propertyName == 'position' and node.has_method('face_horiz'):
				node.call('face_horiz', actorTween.value.x - node.position.x)
			tweens.append(tween)
		else:
			node.set(actorTween.propertyName, actorTween.value)

func start_cutscene(newCutscene: Cutscene):
	if playing or (newCutscene.storyRequirements != null and not newCutscene.storyRequirements.is_valid()):
		return
	SaveHandler.save_data()
	for npc in get_tree().get_nodes_in_group("NPC"):
		npc.talkAlertSprite.visible = false
	cutscene = newCutscene
	timer = 0
	skipCutsceneFrameIndex = -1
	nextKeyframeTime = cutscene.cutsceneFrames[0].frameLength
	cutscene.calc_total_time()
	playing = true
	PlayerFinder.player.cutsceneTexts = []
	PlayerFinder.player.cutsceneTextIndex = 0
	PlayerFinder.player.cutsceneLineIndex = 0
	PlayerFinder.player.cam.show_letterbox()
	SceneLoader.pause_autonomous_movers()
	for actor in cutscene.activateActorsBefore:
		var actorNode = rootNode.get_node_or_null(actor)
		if actorNode != null:
			actorNode.visible = true

func fetch_actor_node(actorTreePath: String, isPlayer: bool) -> Node:
	var node = null
	if isPlayer:
		node = PlayerFinder.player
	elif rootNode != null:
		node = rootNode.get_node_or_null(actorTreePath)
	return node

func pause_cutscene():
	for tween in tweens:
		tween.pause()
	isPaused = true

func resume_cutscene():
	for tween: Tween in tweens:
		if tween.is_valid():
			tween.play()
	isPaused = false

func skip_cutscene():
	if cutscene == null:
		return
	
	isPaused = false
	PlayerFinder.player.pauseDisabled = true
	PlayerFinder.player.cam.fade_out(_fade_out_complete, 0.1)
	# reset textbox
	PlayerFinder.player.textBox.hide_textbox()
	PlayerFinder.player.set_talk_npc(null, true)
	PlayerFinder.player.cutsceneTextIndex = 0
	PlayerFinder.player.cutsceneLineIndex = 0
	PlayerFinder.player.cutsceneTexts = []
	# reset textbox END
	isFadedOut = true
	isFadingIn = false
	timer = cutscene.totalTime
	skipCutsceneFrameIndex = cutscene.get_index_for_frame(lastFrame)

func toggle_pause_cutscene():
	isPaused = not isPaused
	if isPaused:
		pause_cutscene()
	else:
		resume_cutscene()

func end_cutscene(force: bool = false):
	if cutscene == null or completeAfterFadeIn:
		return
	deactivate_actors_after()
	PlayerResources.set_cutscene_seen(cutscene.saveName)
	if cutscene.givesQuest != null:
		PlayerResources.questInventory.accept_quest(cutscene.givesQuest)
		PlayerFinder.player.cam.show_alert('Started Quest:\n' + cutscene.givesQuest.questName)
	if not isFadedOut:
		complete_cutscene()
	else:
		if force: # called when warp zone is entered while faded out; so cutscene can end
			PlayerFinder.player.fade_in_unlock_cutscene(cutscene)
		completeAfterFadeIn = true

func complete_cutscene():
	SceneLoader.unpause_autonomous_movers()
	PlayerResources.set_cutscene_seen(cutscene.saveName)
	PlayerFinder.player.show_all_talk_alert_sprites()
	if PlayerFinder.player.is_in_dialogue():
		PlayerFinder.player.inCutscene = false # be considered not in a cutscene anymore
		PlayerFinder.player.disableMovement = true # still disable movement until text box closes
	else:
		PlayerFinder.player.cam.show_letterbox(false) # otherwise hide the letterboxes and be not in cutscene
	if cutscene.unlockCameraHoldAfter and PlayerFinder.player.holdingCamera:
		PlayerFinder.player.snap_camera_back_to_player()
	playing = false
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished(cutscene)
		playingFromTrigger = null
	cutscene = null
	cutscene_completed.emit()

func deactivate_actors_after():
	if cutscene == null:
		return
	
	for actor in cutscene.deactivateActorsAfter:
		var actorNode = rootNode.get_node_or_null(actor)
		if actorNode != null:
			if 'invisible' in actorNode:
				actorNode.invisible = true
			else:
				actorNode.visible = false

func _fade_out_complete():
	if completeAfterFadeIn and not isFadingIn:
		isFadingIn = true
		PlayerFinder.player.cam.call_deferred('fade_in', _fade_in_complete)
	if skipCutsceneFrameIndex != -1:
		skip_cutscene_process()

func _fade_in_complete():
	isFadedOut = false
	isFadingIn = false
	if completeAfterFadeIn:
		complete_cutscene()
		PlayerFinder.player.pauseDisabled = false

func skip_cutscene_process():
	for idx in range(skipCutsceneFrameIndex, len(cutscene.cutsceneFrames)):
		var frame: CutsceneFrame = cutscene.cutsceneFrames[idx]
		animate_next_frame(frame, true)
		if frame.givesItem:
			PlayerResources.inventory.add_item(frame.givesItem)
			PlayerFinder.player.cam.show_alert('Got Item:\n' + frame.givesItem.itemName)
		await get_tree().process_frame
	end_cutscene()
	PlayerFinder.player.cam.call_deferred('fade_in', _fade_in_complete)
