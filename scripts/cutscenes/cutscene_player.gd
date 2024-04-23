@tool
extends Node
class_name CutscenePlayer

signal cutscene_fadeout_done
signal cutscene_completed

@export var cutscene: Cutscene = null
@export var playing: bool = false
@export var rootNode: Node = null

var playingFromTrigger: CutsceneTrigger = null
var timer: float = 0
var lastFrame: CutsceneFrame = null
var tweens: Array = []
var isPaused: bool = false
var isFadedOut: bool = false
var isFadingIn: bool = false
var completeAfterFadeIn: bool = false
var skipCutsceneFrameIndex: int = -1
var skipping: bool = true
var awaitingPlayer: bool = false

func _process(delta):
	if cutscene != null and playing and not isPaused and not awaitingPlayer and skipCutsceneFrameIndex == -1:
		var frame: CutsceneFrame = cutscene.get_keyframe_at_time(timer, lastFrame)
		timer += delta
		
		if is_in_dialogue() and lastFrame != null and lastFrame.endTextBoxPauses:
			if frame != lastFrame:
				timer -= delta
			return
		
		if lastFrame != null and frame != lastFrame:
			handle_camera(frame)
			if frame != null:
				handle_play_sfx(frame.playSfx)
			
			if lastFrame.dialogues != null and len(lastFrame.dialogues) > 0 \
					and not lastFrame.get_text_was_triggered():
				for item in lastFrame.dialogues:
					queue_text(item, frame)
				lastFrame.set_text_was_triggered()
				
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_OUT and not isFadedOut:
				handle_fade_out()
			
			if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_IN:
				handle_fade_in()
			
			if lastFrame.givesItem != null:
				handle_give_item()
				
			if lastFrame.endStartsShardLearnTutorial:
				handle_start_shard_learn_tutorial()
		
		if frame == null: # end of cutscene
			end_cutscene()
			return
				
		if lastFrame == frame:
			return
		
		animate_next_frame(frame)

func is_in_dialogue() -> bool:
	return PlayerFinder.player.is_in_dialogue()

func handle_camera(frame: CutsceneFrame):
	if lastFrame.endHoldCamera and not (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.hold_camera_at(PlayerFinder.player.position)
	if not lastFrame.endHoldCamera and (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.snap_camera_back_to_player()
	if lastFrame.shakeCamForDuration and (frame == null or not frame.shakeCamForDuration):
		PlayerFinder.player.cam.stop_cam_shake()

func handle_play_sfx(sfx: AudioStream):
	SceneLoader.audioHandler.play_sfx(sfx)

func queue_text(item: CutsceneDialogue, frame: CutsceneFrame):
	PlayerFinder.player.queue_cutscene_texts(item)

func handle_fade_out():
	PlayerFinder.player.cam.fade_out(_fade_out_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
	isFadedOut = true
	isFadingIn = false
	
func handle_fade_in():
	PlayerFinder.player.cam.fade_in(_fade_in_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)

func handle_give_item():
	PlayerResources.inventory.add_item(lastFrame.givesItem)
	PlayerFinder.player.cam.show_alert('Got Item:\n' + lastFrame.givesItem.itemName)

func handle_start_shard_learn_tutorial():
	awaitingPlayer = true
	PlayerFinder.player.inventoryPanel.start_learn_shard_tutorial()
	PlayerFinder.player.inventoryPanel.learn_shard_tutorial_finished.connect(_learn_shard_tutorial_finished)

func animate_next_frame(frame: CutsceneFrame, isSkipping: bool = false):
	lastFrame = frame
	if frame.shakeCamForDuration:
		handle_start_cam_shake()
	
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
		if not isSkipping:
			var tween = create_tween().set_ease(actorTween.easeType).set_trans(actorTween.transitionType)
			tween.tween_property(node, actorTween.propertyName, actorTween.value, frame.frameLength)
			if actorTween.propertyName == 'position' and node.has_method('face_horiz'):
				node.call('face_horiz', actorTween.value.x - node.position.x)
			tweens.append(tween)
		else:
			node.set(actorTween.propertyName, actorTween.value)

func handle_start_cam_shake():
	PlayerFinder.player.cam.start_cam_shake()

func start_cutscene(newCutscene: Cutscene):
	if newCutscene == null:
		return
	
	if completeAfterFadeIn and cutscene != null:
		complete_cutscene()
	if playing:
		return
		
	if newCutscene.storyRequirements != null:
		if not newCutscene.storyRequirements.is_valid():
			return
	
	lastFrame = null
	if not Engine.is_editor_hint():
		SaveHandler.save_data()
		for npc in get_tree().get_nodes_in_group("NPC"):
			npc.talkAlertSprite.visible = false
	cutscene = newCutscene
	timer = 0
	skipCutsceneFrameIndex = -1
	cutscene.calc_total_time()
	playing = true
	if not Engine.is_editor_hint() and PlayerFinder.player != null:
		PlayerFinder.player.cutsceneTexts = []
		PlayerFinder.player.cutsceneTextIndex = 0
		PlayerFinder.player.cutsceneLineIndex = 0
		PlayerFinder.player.cam.show_letterbox()
		PlayerFinder.player.snap_camera_back_to_player(0.25)
		if PlayerFinder.player.pausePanel.isPaused:
			PlayerFinder.player.pausePanel.toggle_pause() # unpause if somehow the game was paused when the cutscene started
		SceneLoader.pause_autonomous_movers()
	for actor in cutscene.activateActorsBefore:
		var actorNode = fetch_actor_node(actor, false)
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
	PlayerFinder.player.cam.stop_cam_shake()

func resume_cutscene():
	for tween: Tween in tweens:
		if tween.is_valid():
			tween.play()
	isPaused = false
	if lastFrame.shakeCamForDuration:
		PlayerFinder.player.cam.start_cam_shake()

func skip_cutscene():
	if cutscene == null:
		return
	
	isPaused = false
	skipping = true
	PlayerFinder.player.pauseDisabled = true
	PlayerFinder.player.cam.stop_cam_shake()
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
	completeAfterFadeIn = false
	await cutscene_fadeout_done
	timer = cutscene.totalTime
	skipCutsceneFrameIndex = cutscene.get_index_for_frame(lastFrame)
	skip_cutscene_process()

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
	PlayerFinder.player.cam.stop_cam_shake()
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
	if playing == false:
		return
	
	lastFrame = null
	skipping = false
	PlayerFinder.player.pauseDisabled = false
	SceneLoader.unpause_autonomous_movers()
	PlayerFinder.player.show_all_talk_alert_sprites()
	if PlayerFinder.player.is_in_dialogue():
		PlayerFinder.player.inCutscene = false # be considered not in a cutscene anymore
		PlayerFinder.player.disableMovement = true # still disable movement until text box closes
	else:
		PlayerFinder.player.cam.show_letterbox(false) # otherwise hide the letterboxes and be not in cutscene
	if cutscene.unlockCameraHoldAfter and (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.snap_camera_back_to_player()
	playing = false
	completeAfterFadeIn = false
	PlayerFinder.player.cam.stop_cam_shake()
	mark_cutscene_seen()
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished(cutscene)
		playingFromTrigger = null
	cutscene = null
	cutscene_completed.emit()
	for tween in tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	tweens = []
	timer = 0
	isPaused = false
	skipCutsceneFrameIndex = -1

func mark_cutscene_seen():
	if cutscene != null:
		PlayerResources.set_cutscene_seen(cutscene.saveName)

func deactivate_actors_after():
	if cutscene == null:
		return
	
	for actor in cutscene.deactivateActorsAfter:
		var actorNode = fetch_actor_node(actor, false)
		if actorNode != null:
			if 'invisible' in actorNode:
				actorNode.invisible = true
			else:
				actorNode.visible = false

func _fade_out_complete():
	cutscene_fadeout_done.emit()
	if completeAfterFadeIn and not isFadingIn:
		isFadingIn = true
		PlayerFinder.player.cam.call_deferred('fade_in', _fade_in_complete)

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

func _learn_shard_tutorial_finished():
	awaitingPlayer = false
