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
var skipping: bool = false
var awaitingPlayer: bool = false
var lastFrameCameraPos: Vector2 = Vector2.ZERO

var collisionDisabledNodes: Array = []
var collisionPrevEnabledNodes: Dictionary[String, bool] = {}

func _process(delta):
	if cutscene != null and playing and not isPaused and not awaitingPlayer and skipCutsceneFrameIndex == -1:
		var frame: CutsceneFrame = cutscene.get_keyframe_at_time(timer, lastFrame)
		timer += delta
		
		if is_in_dialogue() and lastFrame != null and lastFrame.endTextBoxPauses:
			if frame != lastFrame:
				timer -= delta
			return
		
		if frame != lastFrame:
			if frame != null and frame.playSfxs != null:
				handle_play_sfx(frame.playSfxs)

			if lastFrame != null:
				handle_camera(frame)
				if lastFrame.dialogues != null and len(lastFrame.dialogues) > 0 \
						and not lastFrame.get_text_was_triggered():
					for item in lastFrame.dialogues:
						queue_text(item.get_cutscene_dialogue(), frame)
					lastFrame.set_text_was_triggered()
					
				if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_OUT and not isFadedOut:
					handle_fade_out()
				
				if lastFrame.endFade == CutsceneFrame.CameraFade.FADE_IN:
					handle_fade_in()
				
				if lastFrame.givesItem != null:
					handle_give_item()
				
				if lastFrame.healsPlayer:
					handle_heal_player()
				
				if lastFrame.addsFollowerId != '':
					handle_add_follower()
				
				if lastFrame.removesFollowerId != '':
					handle_remove_follower()
				
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

func handle_camera_move(percentTime: float, frame: CutsceneFrame, lFrame: CutsceneFrame) -> void:
	if frame != null and frame.cameraMovement != null and lFrame != null and lFrame.endHoldCamera and PlayerFinder.player != null and (PlayerFinder.player.holdCameraX and PlayerFinder.player.holdCameraY):
		var camPosition: Vector2 = frame.cameraMovement.get_camera_position_at_time(percentTime, 1, lastFrameCameraPos, PlayerFinder.player.position)
		PlayerFinder.player.holdingCameraAt = camPosition

func handle_camera(frame: CutsceneFrame) -> void:
	if lastFrame.endHoldCamera and not (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.hold_camera_at(PlayerFinder.player.position)
	if not lastFrame.endHoldCamera and (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.snap_camera_back_to_player()
	if lastFrame.shakeCamForDuration and (frame == null or not frame.shakeCamForDuration):
		PlayerFinder.player.cam.stop_cam_shake()

func handle_play_sfx(sfxs: Array[AudioStream]):
	for sfx: AudioStream in sfxs:
		SceneLoader.audioHandler.play_sfx(sfx)

func queue_text(item: CutsceneDialogue, frame: CutsceneFrame):
	PlayerFinder.player.queue_cutscene_texts(item)

func handle_fade_out():
	PlayerFinder.player.cam.fade_out(_fade_out_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
	
	isFadedOut = true
	isFadingIn = false
	
func handle_fade_in():
	PlayerFinder.player.cam.fade_in(_fade_in_complete, lastFrame.endFadeLength if lastFrame.endFadeLength > 0 else 0.5)
	isFadedOut = false
	isFadingIn = true

func handle_add_follower() -> void:
	PlayerResources.set_follower_active(lastFrame.addsFollowerId)
	
func handle_remove_follower() -> void:
	PlayerResources.remove_follower(lastFrame.removesFollowerId)

func handle_give_item():
	PlayerResources.inventory.add_item(lastFrame.givesItem)
	PlayerFinder.player.cam.show_alert('Got Item:\n' + lastFrame.givesItem.itemName, lastFrame.givesItem.itemSprite)

func handle_heal_player():
	PlayerResources.playerInfo.combatant.currentHp = PlayerResources.playerInfo.combatant.stats.maxHp
	PlayerFinder.player.cam.show_alert('Fully Healed!')

func handle_start_shard_learn_tutorial():
	awaitingPlayer = true
	PlayerFinder.player.animatedBgPanel.visible = true
	PlayerFinder.player.inventoryPanel.start_learn_shard_tutorial()
	PlayerFinder.player.inventoryPanel.learn_shard_tutorial_finished.connect(_learn_shard_tutorial_finished)

func get_all_actor_nodes_in_cutscene() -> Array:
	var nodeDict: Dictionary[String, Node] = {}
	for frame: CutsceneFrame in cutscene.cutsceneFrames:
		for animSet: ActorAnimSet in frame.actorAnimSets:
			if animSet == null:
				continue
			var node = fetch_actor_node(animSet.actorTreePath, animSet.isPlayer)
			if node != null and not nodeDict.has(node.name):
				nodeDict[node.name] = node
		for animation: ActorSpriteAnim in frame.actorAnims:
			if animation == null:
				continue
			var node = fetch_actor_node(animation.actorTreePath, animation.isPlayer)
			if node != null and not nodeDict.has(node.name):
				nodeDict[node.name] = node
		for actorTween: ActorTween in frame.actorTweens:
			if actorTween == null:
				continue
			var node = fetch_actor_node(actorTween.actorTreePath, actorTween.isPlayer)
			if node != null and not nodeDict.has(node.name):
				nodeDict[node.name] = node
		for actorFaceTarget: ActorFaceTarget in frame.actorFaceTargets:
			if actorFaceTarget == null:
				continue
			var node = fetch_actor_node(actorFaceTarget.actorTreePath, actorFaceTarget.isPlayer)
			if node != null and not nodeDict.has(node.name):
				nodeDict[node.name] = node
	return nodeDict.values()

func get_last_player_cam_pos() -> Vector2:
	return PlayerFinder.player.holdingCameraAt if lastFrame != null and lastFrame.cameraMovement != null else PlayerFinder.player.position

func animate_next_frame(frame: CutsceneFrame, isSkipping: bool = false):
	var prevLastFrame: CutsceneFrame = lastFrame
	lastFrame = frame
	lastFrameCameraPos = get_last_player_cam_pos()
	if frame.shakeCamForDuration:
		handle_start_cam_shake()
	
	if frame.cameraMovement != null:
		var camMoveTween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		camMoveTween.tween_method(handle_camera_move.bind(frame, prevLastFrame), 0.0, 1.0, frame.frameLength)
		tweens.append(camMoveTween)
	
	for animSet in frame.actorAnimSets:
		var node = fetch_actor_node(animSet.actorTreePath, animSet.isPlayer)
		if node != null and node.has_method('set_sprite_state'):
			node.call('set_sprite_state', animSet.spriteState)
	for animation in frame.actorAnims:
		var node = fetch_actor_node(animation.actorTreePath, animation.isPlayer)
		if node != null and node.has_method('play_animation'):
			node.call('play_animation', animation.animation)
	for actorTween in frame.actorTweens:
		if actorTween == null:
			continue # skip null tweens
		var node = fetch_actor_node(actorTween.actorTreePath, actorTween.isPlayer)
		if node == null:
			print('Actor ', actorTween.actorTreePath, ' (player: ', actorTween.isPlayer, ') was found null. Attempted property/value tween: ', actorTween.propertyName, ' // ', actorTween.value)
			continue # skip null actors
		if not isSkipping:
			var tween = create_tween().set_ease(actorTween.easeType).set_trans(actorTween.transitionType)
			tween.tween_property(node, actorTween.propertyName, actorTween.value, frame.frameLength)
			if actorTween.propertyName == 'position' and node.has_method('face_horiz'):
				node.call('face_horiz', actorTween.value.x - node.position.x)
			tweens.append(tween)
			#print('actor ', actorTween.actorTreePath, ' animates ', actorTween.propertyName, ' to ', actorTween.value, ' (current is ', node[actorTween.propertyName], ')')
		else:
			node.set(actorTween.propertyName, actorTween.value)
	for actorFaceTarget: ActorFaceTarget in frame.actorFaceTargets:
		#print(actorFaceTarget.actorTreePath, ' faces ', actorFaceTarget.targetTreePath)
		if actorFaceTarget == null:
			continue
		var actorNode = fetch_actor_node(actorFaceTarget.actorTreePath, actorFaceTarget.isPlayer)
		if actorNode == null or not actorNode.has_method('face_horiz'):
			printerr('actor node ', actorFaceTarget.actorTreePath, ' was null')
			continue
		var targetPos: Vector2 = Vector2.ZERO
		if actorFaceTarget.targetTreePath != '' or actorFaceTarget.targetIsPlayer:
			var targetNode = fetch_actor_node(actorFaceTarget.targetTreePath, actorFaceTarget.targetIsPlayer)
			if targetNode != null:
				targetPos = targetNode.global_position
			else:
				printerr('face target node ', actorFaceTarget.targetTreePath, ' was null')
				continue
		else:
			targetPos = actorFaceTarget.targetPosition
		#print(targetPos.x - actorNode.global_position.x)
		if actorNode.has_method('face_horiz'):
			actorNode.face_horiz(targetPos.x - actorNode.global_position.x)

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
		#SaveHandler.save_data()
		for npc in get_tree().get_nodes_in_group("NPC"):
			npc.talkAlertSprite.visible = false
	cutscene = newCutscene
	cutscene.reset_internals()
	timer = 0
	skipCutsceneFrameIndex = -1
	cutscene.calc_total_time()
	playing = true
	
	# disable the collision of all actors in the 
	var allActors: Array = get_all_actor_nodes_in_cutscene()
	for node in allActors:
		if node.has_method('disable_collision') and node.has_method('is_collision_enabled'):
			collisionPrevEnabledNodes[node.name] = node.call('is_collision_enabled')
			node.call('disable_collision')
			collisionDisabledNodes.append(node)
		#if node.has_method('disable_event_collisions'):
			#node.call('disable_event_collisions')
	
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

func fetch_actor_sprite_frames(actorTreePath: String, isPlayer: bool) -> SpriteFrames:
	var actorNode: Node = fetch_actor_node(actorTreePath, isPlayer)
	if actorNode == null:
		return null
	
	if actorNode.has_method('get_sprite_frames'):
		return actorNode.call('get_sprite_frames')
	return null

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
	isPaused = false
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
		var accepted: bool = PlayerResources.questInventory.accept_quest(cutscene.givesQuest)
		if accepted:
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
	
	# re-enable the collision for nodes whose collision was enabled
	for node in collisionDisabledNodes:
		if node != null and node.has_method('enable_collision') and collisionPrevEnabledNodes[node.name]:
			node.call('enable_collision')
		#if node.has_method('enable_event_collisions'):
			#node.call('enable_event_collisions')
	collisionDisabledNodes = []
	
	PlayerFinder.player.pauseDisabled = false
	PlayerFinder.player.show_all_talk_alert_sprites()
	if PlayerFinder.player.is_in_dialogue():
		PlayerFinder.player.inCutscene = false # be considered not in a cutscene anymore
		PlayerFinder.player.disableMovement = true # still disable movement until text box closes
	else:
		PlayerFinder.player.cam.show_letterbox(false) # otherwise hide the letterboxes and be not in cutscene
	if cutscene.unlockCameraHoldAfter and (PlayerFinder.player.holdCameraX or PlayerFinder.player.holdCameraY):
		PlayerFinder.player.snap_camera_back_to_player()
	SceneLoader.unpause_autonomous_movers()
	playing = false
	completeAfterFadeIn = false
	PlayerFinder.player.cam.stop_cam_shake()
	mark_cutscene_seen()
	
	if playingFromTrigger != null:
		playingFromTrigger.cutscene_finished(cutscene)
		playingFromTrigger = null
	if cutscene.staticEncounter != null:
		PlayerResources.playerInfo.encounter = cutscene.staticEncounter
		PlayerFinder.player.start_battle()
	
	cutscene = null
	cutscene_completed.emit()
	if PlayerFinder.player.actChanged:
		PlayerFinder.player.play_act_changed_animation.call_deferred()
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
	for tween: Tween in tweens:
		if tween.is_valid():
			tween.kill()
	tweens = []
	var skipAnims: bool = false
	PlayerFinder.player.snap_camera_back_to_player(0)
	
	for idx in range(skipCutsceneFrameIndex, len(cutscene.cutsceneFrames)):
		var frame: CutsceneFrame = cutscene.cutsceneFrames[idx]
		if not skipAnims:
			animate_next_frame(frame, true)
		if PlayerFinder.player.enteredWarpZone and not skipAnims:
			skipAnims = true
		if frame.givesItem:
			PlayerResources.inventory.add_item(frame.givesItem)
			PlayerFinder.player.cam.show_alert('Got Item:\n' + frame.givesItem.itemName, frame.givesItem.itemSprite)
		if frame.healsPlayer:
			handle_heal_player()
		if frame.addsFollowerId != '':
			PlayerResources.set_follower_active(frame.addsFollowerId)
		if frame.removesFollowerId != '':
			PlayerResources.remove_follower(frame.removesFollowerId)
		await get_tree().process_frame
	# fetching static encounter before end_cutscene() just in case complete_cutscene() is called from that, which sets cutscene as null
	var staticEncounter: StaticEncounter = cutscene.staticEncounter
	end_cutscene()
	# if there is a static encounter at the end of this cutscene, don't bother fading in, because the battle will start soon
	if staticEncounter == null:
		PlayerFinder.player.cam.call_deferred('fade_in', _fade_in_complete)
	else:
		PlayerResources.playerInfo.encounter = staticEncounter
		PlayerFinder.player.start_battle()
		#PlayerFinder.player._after_start_battle_fade_out()

func _learn_shard_tutorial_finished():
	awaitingPlayer = false
