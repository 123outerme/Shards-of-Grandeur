extends Node2D
class_name CombatantNode

signal move_sprites_finished
signal tween_to_target_finished
signal tween_returning_to_rest
signal tween_back_finished
signal sprite_animation_finished
signal toggled(button_pressed: bool, combatantNode: CombatantNode)
signal details_clicked(combatantNode: CombatantNode)

enum Role {
	ALLY = 0,
	ENEMY = 1
}

@export_category("CombatantNode - Details")
@export var combatant: Combatant = null
@export var initialCombatantLv: int = 1
@export var role: Role = Role.ALLY
@export var leftSide: bool = false
@export var spriteFacesRight: bool = false
@export var battlePosition: String = ''
@export var unlockSurgeRequirements: StoryRequirements = null
@export var shardSummoned: bool = false

@export_category("CombatantNode - Movement")
@export var allyTeamMarker: Marker2D
@export var enemyTeamMarker: Marker2D
@export var globalMarker: Marker2D

const ANIMATE_MOVE_SPEED: float = 90
const MAX_RUNES_SHOWN: int = 2
const MULTI_RUNE_DELAY_SECS: float = 0.5
const moveSpriteScene = preload('res://prefabs/battle/move_sprite.tscn')
const eventTextScene = preload('res://prefabs/battle/combatant_event_text.tscn')

var loaded: bool = false
var curHp: int = -1
var curOrbs: int = 0
var curStatus: StatusEffect = null

var disableHpTag: bool = false
var tmpAllCombatantNodes: Array[CombatantNode] = []
var battleAi: CombatantAi = null
var animateTween: Tween = null
var hpDrainTween: Tween = null
var fadeOutTween: Tween = null
var returnToPos: Vector2 = Vector2()
var playedMoveSprites: int = 0
var moveSpriteTargets: Array[CombatantNode] = []
var playingMoveSprites: Array[MoveSprite] = []
var loadedRuneSprites: Array[MoveSprite] = []
var playingRuneSprites: Array[MoveSprite] = []
var playedEventTexts: int = 0
var playingEventTexts: Array[CombatantEventText] = []
var useItemSprite: Texture2D = null
var isBeingStatusAfflicted: bool = false
var targetOfMoveAnimation: bool = false
var initialAssistMarkerPos: Vector2
var initialAttackMarkerPos: Vector2
var initialEventTextContainerPos: Vector2

@onready var eventTextContainer: Control = get_node('SpriteContainer/EventTextContainer')
@onready var hpTag: Panel = get_node('HPTag')
@onready var nameText: RichTextLabel = get_node('HPTag/NameText')
@onready var lvText: RichTextLabel = get_node('HPTag/LvText')
@onready var hpText: RichTextLabel = get_node('HPTag/LvText/HPText')
@onready var hpProgressBar: TextureProgressBar = get_node('HPTag/LvText/HPProgressBar')
@onready var weakenTargetHp: Panel = get_node('HPTag/LvText/WeakenTargetHp')
@onready var orbDisplay: OrbDisplay = get_node('HPTag/OrbDisplay')
@onready var spriteContainer: Node2D = get_node('SpriteContainer')
@onready var animatedSprite: AnimatedSprite2D = get_node('SpriteContainer/AnimatedSprite')
@onready var shardSummonAnimSprite: AnimatedSprite2D = get_node('SpriteContainer/ShardSummonAnimSprite')
@onready var selectCombatantBtn: SFXNinePatchButton = get_node('SelectCombatantBtn')
@onready var statusSprite: Sprite2D = get_node('HPTag/LvText/HPProgressBar/StatusSpriteControl/StatusSprite')
@onready var behindParticleContainer: Node2D = get_node('SpriteContainer/BehindParticleContainer')
@onready var surgeParticles: Particles = get_node('SpriteContainer/BehindParticleContainer/SurgeParticleEmitter')
@onready var behindParticles: Particles = get_node('SpriteContainer/BehindParticleContainer/BehindParticleEmitter')
@onready var frontParticleContainer: Node2D = get_node('SpriteContainer/FrontParticleContainer')
@onready var frontParticles: Particles = get_node('SpriteContainer/FrontParticleContainer/FrontParticleEmitter')
@onready var hitParticles: Particles = get_node('SpriteContainer/FrontParticleContainer/HitParticleEmitter')
@onready var shardParticles: Particles = get_node('SpriteContainer/FrontParticleContainer/ShardParticleEmitter')
@onready var onAttackMarker: Marker2D = get_node('OnAttackPos')
@onready var onAssistMarker: Marker2D = get_node('OnAssistPos')

# Called when the node enters the scene tree for the first time.
func _ready():
	returnToPos = global_position
	orbDisplay.alignment = BoxContainer.ALIGNMENT_END if leftSide else BoxContainer.ALIGNMENT_BEGIN
	initialAssistMarkerPos = onAssistMarker.position
	initialAttackMarkerPos = onAttackMarker.position
	initialEventTextContainerPos = eventTextContainer.position

func load_combatant_node():
	if combatant != null:
		curHp = combatant.battleStorageHp
		curOrbs = combatant.battleStorageOrbs
		curStatus = combatant.battleStorageStatus
		animatedSprite.sprite_frames = combatant.get_sprite_frames()
		if combatant.statChanges == null:
			combatant.statChanges = StatChanges.new()
		if combatant.get_sprite_frames() == null:
			animatedSprite.sprite_frames = load("res://graphics/animations/a_missingno.tres") # show something
		spriteFacesRight = combatant.get_faces_right()
		var feetOffset: Vector2 = get_feet_pos_translation()
		feetOffset.y += 8
		animatedSprite.offset = feetOffset
		play_animation('battle_idle')
		hpProgressBar.max_value = combatant.stats.maxHp
		hpProgressBar.value = curHp
		hpProgressBar.tint_progress = Combatant.get_hp_bar_color(curHp, combatant.stats.maxHp)
		behindParticleContainer.scale.x = get_behind_particle_scale()
		behindParticleContainer.scale.y = behindParticleContainer.scale.x
		
		frontParticleContainer.scale.x = get_in_front_particle_scale()
		frontParticleContainer.scale.y = frontParticleContainer.scale.x
		surgeParticles.set_make_particles(false)
		behindParticles.set_make_particles(false)
		frontParticles.set_make_particles(false)
		hitParticles.set_make_particles(false)
		shardParticles.set_make_particles(false)
		# nudge the attack marker away from sprite by any amount over 16 wide
		if onAttackMarker.position.x < position.x:
			onAttackMarker.position.x = initialAttackMarkerPos.x - (combatant.get_idle_size().x - 16) / 2
		elif onAttackMarker.position.x > position.x:
			onAttackMarker.position.x = initialAttackMarkerPos.x + (combatant.get_idle_size().x - 16) / 2
		
		# nudge the assist marker away from sprite by any amount over 16 tall
		if onAssistMarker.position.y < position.y:
			onAssistMarker.position.y = initialAssistMarkerPos.y - (combatant.get_idle_size().y - 16) / 2
		elif onAssistMarker.position.y > position.y:
			onAssistMarker.position.y = initialAssistMarkerPos.y + (combatant.get_idle_size().y - 16) / 2
	
	if not is_alive():
		visible = false
	else:
		visible = true
		if shardSummoned:
			animatedSprite.visible = false
		else:
			animatedSprite.visible = true
		shardSummonAnimSprite.visible = false
		update_select_btn(false)
		weakenTargetHp.visible = false
		update_hp_tag()
	
	eventTextContainer.position = initialEventTextContainerPos
	if combatant != null and combatant.get_idle_size().y > 16:
		eventTextContainer.position.y -= (combatant.get_idle_size().y - 16) / 2
	
	loaded = true

func get_feet_pos_translation() -> Vector2:
	var feetOffset: Vector2 = -1 * combatant.get_feet_pos()
	animatedSprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
	if animatedSprite.flip_h:
		# mirror x position if sprite is flipped
		feetOffset.x = (combatant.get_max_size().x + feetOffset.x) * -1
	return feetOffset

func get_in_front_particle_scale() -> float:
		# scale of particles in front of combatant: 1*, plus 0.25 for every 16 px larger
	return 1 + round(max(0, max(combatant.get_idle_size().x, combatant.get_idle_size().y) - 16) / 16) / 4

func get_behind_particle_scale() -> float:
	# scale of particles behind combatant: 1.5*, plus 0.25 for every 16 px larger
	return 1.5 + round(max(0, max(combatant.get_idle_size().x, combatant.get_idle_size().y) - 16) / 16) / 4

func change_current_hp(hpChange: int) -> void:
	if hpChange < 0 and curStatus != null and curStatus is Endure:
		var curEndure: Endure = curStatus as Endure
		var lowestHp: int = max(1, min(curEndure.lowestHp, roundi(combatant.stats.maxHp * curEndure.get_min_hp_percent())))
		#print('HP change: ', hpChange, ' / lowest HP calcd: ', lowestHp, ' / curEndure lowest: ', curEndure.lowestHp, ' / min HP from status: ', roundi(combatant.stats.maxHp * curEndure.get_min_hp_percent()))
		# if endured and the lowest HP was reduced below the lowest, set the change so that the next current HP will be the lowest Endured HP
		if curHp + hpChange < lowestHp and curEndure.endured:
			hpChange = lowestHp - curHp
		
	curHp = min(combatant.stats.maxHp, max(0, curHp + hpChange))
	update_hp_tag()

func change_current_orbs(orbChange: int) -> void:
	curOrbs = min(Combatant.MAX_ORBS, max(0, curOrbs + orbChange))
	update_hp_tag()

func change_current_status(newStatus: StatusEffect) -> void:
	if newStatus != null and newStatus.type == StatusEffect.Type.NONE:
		curStatus = null # cleanse status
	else:
		curStatus = newStatus
	update_hp_tag()

func update_current_tag_stats(updateBattleStorage: bool = true) -> void:
	# updates the battle storage and/or HP tag with the current battle storage
	if combatant == null:
		return
	if updateBattleStorage:
		combatant.update_battle_storage()
	curHp = combatant.battleStorageHp
	curOrbs = combatant.battleStorageOrbs
	curStatus = combatant.battleStorageStatus
	update_hp_tag()

func update_hp_tag():
	if not is_alive():
		if visible and fadeOutTween == null:
			animatedSprite.pause() # pause idle animation
			fadeOutTween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
			fadeOutTween.tween_property(self, 'modulate', Color(0, 0, 0, 0), 0.75)
			fadeOutTween.finished.connect(_fade_out_finished)
			# TODO: play death sfx here...
		else:
			return
	
	hpTag.visible = not disableHpTag
	var alignTag: String = 'right' if leftSide else 'left'
	nameText.text = '[' + alignTag + ']' + combatant.disp_name() + '[/' + alignTag + ']'
	nameText.position.x = -10 if leftSide else 0
	lvText.text = 'Lv ' + String.num_int64(combatant.stats.level)
	lvText.size.x = len(lvText.text) * 13 # about 13 pixels per character
	hpText.text = TextUtils.num_to_comma_string(curHp) + ' / ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
	#hpText.size.x = len(hpText.text) * 13 - 10 # magic number
	hpProgressBar.max_value = combatant.stats.maxHp
	if hpProgressBar.value != curHp:
		if hpDrainTween != null and hpDrainTween.is_valid():
			hpDrainTween.kill()
		hpDrainTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		hpDrainTween.parallel().tween_property(hpProgressBar, 'value', curHp, 1)
		hpDrainTween.parallel().tween_property(hpProgressBar, 'tint_progress', Combatant.get_hp_bar_color(curHp, combatant.stats.maxHp), 1)
		hpDrainTween.finished.connect(_on_hp_drain_tween_finished)
	
	#hpTag.size.x = (lvText.size.x + hpText.size.x) * lvText.scale.x + 8 # magic number
	if leftSide:
		hpTag.position = Vector2(-1 * hpTag.size.x - selectCombatantBtn.size.x * 0.5 - 2, -0.5 * hpTag.size.y)
	else:
		hpTag.position = Vector2(selectCombatantBtn.size.x * 0.5 + 2, -0.5 * hpTag.size.y)
	
	#if ((unlockSurgeRequirements == null or unlockSurgeRequirements.is_valid()) and leftSide) or ((Combatant.useSurgeReqs == null or Combatant.useSurgeReqs.is_valid()) and not leftSide):
		#orbDisplay.visible = true
	update_orb_display()
	#else:
		#orbDisplay.visible = false
	update_rune_sprites()
	if curStatus != null:
		statusSprite.texture = curStatus.get_icon()
	else:
		statusSprite.texture = null

func set_weaken_target_hp_display(targetPercent: float) -> void:
	weakenTargetHp.visible = true
	weakenTargetHp.size.x = 156 * targetPercent

func update_orb_display():
	orbDisplay.update_orb_count(curOrbs, false, loaded)

func update_select_btn(showing: bool, disable: bool = false):
	if not is_alive():
		return
		
	selectCombatantBtn.visible = showing
	selectCombatantBtn.disabled = disable
	selectCombatantBtn.z_index = 1 if selectCombatantBtn.button_pressed else 0
	
	selectCombatantBtn.size = combatant.get_idle_size() + Vector2(14, 14) # set size of selecting button to sprite size + 8px
	
	# button has to bottom out at the combatant's feet position, and the top must be at the top of the idle boundaries
	selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button
	selectCombatantBtn.position.y -= combatant.get_idle_size().y / 2 - 6
	
	# update the position to be centered on the combatant's idle sprite boundaries (not its center of mass)
	#selectCombatantBtn.position += animatedSprite.offset + (combatant.get_idle_size() / 2)

func update_rune_sprites(createNew: bool = true, createTriggered: bool = false, playCreatedTriggeredRunes: bool = false) -> void:
	if combatant == null or not is_alive():
		return
	
	var currentlyShowingSprites: Array[MoveSprite] = []
	for runeSpr: MoveSprite in playingRuneSprites:
		if runeSpr != null:
			currentlyShowingSprites.append(runeSpr)

	playingRuneSprites = playingRuneSprites.filter(_filter_out_null)
	loadedRuneSprites = loadedRuneSprites.filter(_filter_out_null)
	var runes: Array[Rune] = []
	runes.append_array(combatant.runes)
	if createTriggered:
		runes.append_array(combatant.triggeredRunes)
	
	for rune: Rune in runes:
		var hasSprite: bool = false
		for runeSprite: MoveSprite in loadedRuneSprites:
			if runeSprite.linkedResource == rune:
				hasSprite = true
		if hasSprite or not (createNew or (createTriggered and rune in combatant.triggeredRunes)):
			continue
		var spriteNode: MoveSprite = moveSpriteScene.instantiate()
		spriteNode.z_index -= 1
		spriteNode.linkedResource = rune
		spriteNode.looping = true
		spriteNode.user = self
		spriteNode.anim = rune.get_rune_anim_sprite()
		if spriteNode.anim == null:
			printerr('ERROR in update_rune_sprites(): new rune sprite is null')
		spriteNode.target = self
		spriteNode.globalMarker = globalMarker
		spriteNode.userTeam = allyTeamMarker
		spriteNode.enemyTeam = enemyTeamMarker
		spriteNode.halt = true
		#if createTriggered and rune in combatant.triggeredRunes and not playCreatedTriggeredRunes:
			#spriteNode.halt = true
		spriteNode.move_sprite_complete.connect(_rune_sprite_complete)
		add_child(spriteNode)
		loadedRuneSprites.append(spriteNode)
		#print('Add rune sprite => ' , len(loadedRuneSprites))
		if len(playingRuneSprites) < min(MAX_RUNES_SHOWN, len(loadedRuneSprites)): # if we don't have enough sprites being shown:
			playingRuneSprites.append(spriteNode) # add this sprite to the list
	
	# calc the shortest duration a Rune sprite has been onscreen for:
	var minPlaySecs: float = -1
	for runeSpr: MoveSprite in playingRuneSprites:
		# ignore minPlaySecs of 0 if there is a timer that has ticked onwards
		if not runeSpr.halt and (minPlaySecs <= 0 or runeSpr.totalTimer < minPlaySecs):
			minPlaySecs = runeSpr.totalTimer

	# number of runes this update has already started playing
	var countStartedPlaying: int = 0
	# for each rune sprite this combatant has:
	for runeSpr: MoveSprite in loadedRuneSprites:
		# if this sprite is in the list of showing idxs:
		if runeSpr in playingRuneSprites:
			# if this combatant is being targeted in a move animation or we're not yet playing created triggered runes and this was triggered:
			if targetOfMoveAnimation or \
					(createTriggered and runeSpr.linkedResource in combatant.triggeredRunes and not playCreatedTriggeredRunes):
				_set_rune_sprite_playing_and_shown(runeSpr, false)
			else:
				# otherwise: this should be shown
				if runeSpr.playing:
					# if this rune was just created: increment the started playing counter too
					if runeSpr.totalTimer == 0:
						countStartedPlaying += 1
					continue # unless it's already shown
				var playWaitTime: float = MULTI_RUNE_DELAY_SECS * countStartedPlaying
				if minPlaySecs > 0:
					playWaitTime += minPlaySecs

				if playWaitTime > 0:
					_set_rune_sprite_playing_and_shown(runeSpr, false)
					get_tree().create_timer(playWaitTime).timeout.connect(_set_rune_sprite_playing_and_shown.bind(runeSpr, true))
				else:
					_set_rune_sprite_playing_and_shown(runeSpr, true)
				countStartedPlaying += 1
		elif runeSpr.playing:
			# otherwise, if this sprite is playing, it shouldn't be anymore
			_set_rune_sprite_playing_and_shown(runeSpr, false)

func focus_select_btn():
	selectCombatantBtn.grab_focus()

func set_buttons_left_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_left = selectCombatantBtn.get_path_to(control)
	control.focus_neighbor_right = control.get_path_to(selectCombatantBtn)
	
func set_buttons_right_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_right = selectCombatantBtn.get_path_to(control)
	control.focus_neighbor_left = control.get_path_to(selectCombatantBtn)
	
func set_buttons_top_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_top = selectCombatantBtn.get_path_to(control)
	control.focus_neighbor_bottom = control.get_path_to(selectCombatantBtn)
	
func set_buttons_bottom_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_bottom = selectCombatantBtn.get_path_to(control)
	control.focus_neighbor_top = control.get_path_to(selectCombatantBtn)

func set_focus_left_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_left = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_right = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)

func set_focus_right_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_right = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_left = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	
func set_focus_bottom_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_bottom = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_top = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	
func set_focus_top_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_top = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_bottom = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	
func set_selected(selected: bool = true):
	selectCombatantBtn.button_pressed = selected
	selectCombatantBtn.z_index = 1 if selected else 0
	selectCombatantBtn._on_pressed_update_texture()
	
func is_selected() -> bool:
	return selectCombatantBtn.button_pressed

func play_animation(animationName: String):
	if animationName == '':
		animatedSprite.stop()
		return
	animatedSprite.play(animationName)
	if animationName == 'walk':
		await animatedSprite.animation_looped
		await animatedSprite.animation_looped
		animatedSprite.stop()
		_on_animated_sprite_animation_finished()

func stop_animation(stopSpriteAnim: bool, stopParticles: bool, stopMoveAnim: bool, stopEventTexts: bool):
	hpTag.visible = true
	
	if stopSpriteAnim:
		animatedSprite.stop()
	
	if stopParticles:
		surgeParticles.makeParticles = false
		surgeParticles.preset = null
		behindParticles.makeParticles = false
		behindParticles.preset = null
		frontParticles.makeParticles = false
		frontParticles.preset = null
		hitParticles.makeParticles = false
		hitParticles.preset = null
		shardParticles.makeParticles = false
	
	if stopMoveAnim:
		for moveSprite: MoveSprite in playingMoveSprites:
			if moveSprite != null:
				moveSprite.visible = false
				moveSprite.destroy.call_deferred()
		playingMoveSprites = []
		playedMoveSprites = 0
		
	if stopEventTexts:
		for eventText: CombatantEventText in playingEventTexts:
			if eventText != null:
				eventText.visible = false
				if not eventText.callableCalled and eventText.eventCallable != Callable():
					eventText.eventCallable.call()
				eventText.destroy.call_deferred()
		playingEventTexts = []
		playedEventTexts = 0
	
	if animateTween != null and animateTween.is_valid():
		animateTween.kill()
		global_position = returnToPos
		_on_combatant_tween_returned()

func get_animation_fps(animationName: String) -> float:
	return animatedSprite.sprite_frames.get_animation_speed(animationName)

func get_total_anim_time(animationName: String) -> float:
	var fps: float = get_animation_fps(animationName)
	var moveTime: float = 0
	for frameIdx in range(animatedSprite.sprite_frames.get_frame_count(animatedSprite.animation)):
		# add (duration of frame / per-frame time) = amount of time to display this frame
		moveTime += animatedSprite.sprite_frames.get_frame_duration(animatedSprite.animation, frameIdx) / fps
	return moveTime

func get_auto_reposition_tween_time(animationName: String) -> float:
	return get_total_anim_time(animationName) * 0.5

func tween_to(pos: Vector2, targetCombatantNode: CombatantNode):
	#var xLargestCombatant: Combatant = combatant
	var yLargestCombatant: Combatant = combatant
	
	if targetCombatantNode != null:
		#if targetCombatantNode.combatant.get_idle_size().x > combatant.get_idle_size().x:
		#	xLargestCombatant = targetCombatantNode.combatant
		if targetCombatantNode.combatant.get_idle_size().y > combatant.get_idle_size().y:
			yLargestCombatant = targetCombatantNode.combatant
	
	# if the greater distance to move is horizontal, then only affect the horizontal target position
	# otherwise if the greater distance is vertical, then only affect vertical
	# (generally combatants approach from the top/bottom when that y is a longer distance than x, and vice versa)
	var diffX: bool = abs(pos.x - global_position.x)
	var diffY: bool = abs(pos.y - global_position.y)
	
	if combatant.get_idle_size().x > 16:
		if pos.x > global_position.x:
			pos.x -= (combatant.get_idle_size().x - 16) / 2
		else:
			pos.x += (combatant.get_idle_size().x - 16) / 2
	
	if yLargestCombatant.get_idle_size().y > 16 and diffX < diffY:
		if pos.y > global_position.y:
			pos.y -= (yLargestCombatant.get_idle_size().y - 16) / 2
		else:
			pos.y += (yLargestCombatant.get_idle_size().y - 16) / 2
	
	if animateTween != null and animateTween.is_valid():
		animateTween.kill()
		global_position = returnToPos
	animateTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	returnToPos = global_position
	var fps: float = get_animation_fps(animatedSprite.animation)
	var moveTime: float = ((returnToPos - pos) / global_scale).length() / ANIMATE_MOVE_SPEED
	var downTime: float = 0
	# if there's an animation playing:
	if animatedSprite.animation != 'battle_idle':
		moveTime = get_auto_reposition_tween_time(animatedSprite.animation)
		var arriveFrame = combatant.get_sprite_obj().get_arrive_frame(animatedSprite.animation)
		# if no arrive frame (value < 0), auto-time (arrive at the destination with halfway through the animation)
		if arriveFrame >= 0:
			# arrive at the chosen arrival frame and wait the remainder of the move time
			downTime = moveTime - (arriveFrame / fps)
			moveTime = arriveFrame / fps
	
	# get the frame that the combatant starts moving at
	var startMoveFrame: int = combatant.get_sprite_obj().get_start_move_frame(animatedSprite.animation)
	if startMoveFrame > 0:
		# if there's any delay to start moving, do nothing
		var waitTime: float = startMoveFrame / fps
		animateTween.tween_property(spriteContainer, 'rotation', 0, waitTime) # will not rotate, is doing nothing for the length of the wait time

	# move to target position
	animateTween.tween_property(spriteContainer, 'global_position', pos, moveTime)
	# emit that the move was completed
	animateTween.tween_callback(_on_animate_tween_target_move_finished)
	# wait for any downtime as a result of an earlier arrival frame
	if downTime > 0:
		animateTween.tween_property(spriteContainer, 'rotation', 0, downTime) # will not rotate, is simply doing nothing for the length of the down time
	# wait
	animateTween.tween_property(spriteContainer, 'rotation', 0, 1) # will not rotate, is simply doing nothing for a beat
	# and return at a constant rate
	animateTween.finished.connect(_on_animate_tween_finished)

func tween_back_to_return_pos():
	if animateTween != null:
		animateTween.kill()
		if returnToPos != spriteContainer.global_position:
			tween_returning_to_rest.emit()
	animateTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	animateTween.tween_property(spriteContainer, 'global_position', returnToPos, ((returnToPos - spriteContainer.global_position) / global_scale).length() / ANIMATE_MOVE_SPEED)
	animateTween.finished.connect(_on_combatant_tween_returned)

func play_particles(preset: ParticlePreset, timingDelay: float = 0):
	if preset == null or preset.count == 0:
		return
	
	var presetCopy: ParticlePreset = preset.duplicate(true)
	if leftSide: # particles are designed & saved as they would play on an enemy (right side)
		presetCopy.processMaterial.direction.x *= -1 # invert inital X emission direction
		presetCopy.processMaterial.emission_shape_offset.x *= -1 # invert emission shape X offset direction
		# flip orbit (tangential) velocity to correspond with flipped sprite
		var orbitVelMin: float = presetCopy.processMaterial.orbit_velocity_min
		presetCopy.processMaterial.orbit_velocity_min = -1 * presetCopy.processMaterial.orbit_velocity_max
		presetCopy.processMaterial.orbit_velocity_max = -1 * orbitVelMin
		# flip tangential acceleration to correspond with flipped sprite
		var tangentialAccelMin: float = presetCopy.processMaterial.tangential_accel_min
		presetCopy.processMaterial.tangential_accel_min = -1 * presetCopy.processMaterial.tangential_accel_max
		presetCopy.processMaterial.tangential_accel_max = -1 * tangentialAccelMin

	if timingDelay > 0:
		await get_tree().create_timer(timingDelay).timeout
	
	match preset.emitter:
		'surge':
			surgeParticles.preset = presetCopy
			surgeParticles.set_make_particles(true)
		'behind':
			behindParticles.preset = presetCopy
			behindParticles.set_make_particles(true)
		'front':
			frontParticles.preset = presetCopy
			frontParticles.set_make_particles(true)
		'hit':
			hitParticles.preset = presetCopy
			hitParticles.set_make_particles(true)
		'shard':
			shardSummonAnimSprite.visible = true
			shardSummonAnimSprite.frame = 0
			await get_tree().create_timer(0.5).timeout # show the shard for 1/4 of a sec before starting the animation
			shardSummonAnimSprite.play()
			await get_tree().create_timer(6 / 8.0).timeout # 6 frames into the animation (or 6/8 of a sec)
			shardParticles.preset = presetCopy
			shardParticles.set_make_particles(true)
			SceneLoader.audioHandler.play_sfx(presetCopy.sfx)
			await get_tree().create_timer(3 / 8.0).timeout # +3 frames into the animation (or 9/8 secs total)
			animatedSprite.visible = true
			shardSummoned = false
			return
	SceneLoader.audioHandler.play_sfx(presetCopy.sfx)

func play_move_sprite(moveAnimSprite: MoveAnimSprite):
	var nodes: Array[CombatantNode] = moveSpriteTargets
	if not moveAnimSprite.onePerTarget and len(nodes) > 0:
		nodes = [moveSpriteTargets[0]]
	# for each target in the list of target nodes at this point, one sprite will be spawned 
	playedMoveSprites += len(nodes)

	var impactFrame: int = combatant.get_sprite_obj().get_impact_frame(animatedSprite.animation)
	if impactFrame > 0 and moveAnimSprite.playsOnImpactFrame:
		# wait to spawn the move sprite until the impact frame arrives
		var fps: float = animatedSprite.sprite_frames.get_animation_speed(animatedSprite.animation)
		var timeUntilImpact: float = impactFrame / fps
		# if the sprite also delays until reposition: take the arrival frame into account
		if moveAnimSprite.delayedUntilReposition:
			var arrivalFrame: float = combatant.get_sprite_obj().get_arrive_frame(animatedSprite.animation)
			if arrivalFrame < 0:
				arrivalFrame = get_auto_reposition_tween_time(animatedSprite.animation)
			timeUntilImpact -= arrivalFrame / fps
		if timeUntilImpact > 0:
			await get_tree().create_timer(timeUntilImpact).timeout
	
	for node in nodes:
		var spriteNode: MoveSprite = moveSpriteScene.instantiate()
		spriteNode.user = self
		spriteNode.anim = moveAnimSprite
		spriteNode.target = node
		spriteNode.globalMarker = globalMarker
		spriteNode.userTeam = allyTeamMarker
		spriteNode.enemyTeam = enemyTeamMarker
		spriteNode.staticSprite = useItemSprite
		spriteNode.move_sprite_complete.connect(_move_sprite_complete)
		#spriteNode.call_deferred('play_sprite_animation')
		playingMoveSprites.append(spriteNode)
		add_child(spriteNode)

func play_event_text(text: String, callable: Callable = Callable(), delay: float = 0, center: bool = true, sfx: AudioStream = null, varySfxPitch: bool = false) -> void:
	var instantiatedText: CombatantEventText = eventTextScene.instantiate()
	playedEventTexts += 1
	instantiatedText.event_text_completed.connect(_event_text_completed.bind(instantiatedText))
	playingEventTexts.append(instantiatedText)
	instantiatedText.load_event_text(text, callable, delay, center, sfx, varySfxPitch)
	eventTextContainer.add_child(instantiatedText)

func get_targetable_combatant_nodes(allCombatantNodes: Array[CombatantNode], targets: BattleCommand.Targets) -> Array[CombatantNode]:
	if targets == BattleCommand.Targets.SELF:
		return [self]
	
	var targetableList: Array[CombatantNode] = []
	for combatantNode in allCombatantNodes:
		if combatantNode == null or not combatantNode.is_alive():
			continue # skip this combatant if not alive
		if self == combatantNode and (targets == BattleCommand.Targets.ALL_EXCEPT_SELF or targets == BattleCommand.Targets.NON_SELF_ALLY or targets == BattleCommand.Targets.ANY_EXCEPT_SELF):
			continue # skip user if user is not targetable
		
		if targets == BattleCommand.Targets.ALL or targets == BattleCommand.Targets.ALL_EXCEPT_SELF or targets == BattleCommand.Targets.ANY or targets == BattleCommand.Targets.ANY_EXCEPT_SELF:
			targetableList.append(combatantNode)
		else:
			var targetRole: CombatantNode.Role = combatantNode.role
			if ((targets == BattleCommand.Targets.ALL_ALLIES or targets == BattleCommand.Targets.ALLY or targets == BattleCommand.Targets.NON_SELF_ALLY) and targetRole == role) or \
				((targets == BattleCommand.Targets.ALL_ENEMIES or targets == BattleCommand.Targets.ENEMY) and targetRole != role):
				targetableList.append(combatantNode)
	return targetableList

## combatant sets its own command object based on its AI
func get_command(combatantNodes: Array[CombatantNode], battleState: BattleState) -> void:
	if battleAi != null:
		combatant.command = battleAi.get_command_for_turn(self, combatantNodes, battleState)
		battleAi.set_move_used(combatant.command.move, combatant.command.moveEffectType)
	else:
		printerr('Error: combatant ', combatant.disp_name(), '(', combatant.save_name(),') did not have a defined AI')
		combatant.command = BattleCommand.new()

func is_alive() -> bool:
	if combatant == null:
		return false
	return not combatant.downed

func _fade_out_finished():
	fadeOutTween = null
	visible = false
	modulate = Color(1,1,1,1)

func _on_select_combatant_btn_toggled(button_pressed: bool) -> void:
	selectCombatantBtn.z_index = 1 if button_pressed else 0
	toggled.emit(button_pressed, self)

func _on_click_combatant_btn_pressed():
	print('show details for ', combatant.save_name())
	details_clicked.emit(self)

func _on_animated_sprite_animation_finished():
	sprite_animation_finished.emit()
	play_animation('battle_idle')

func _on_animate_tween_target_move_finished():
	tween_to_target_finished.emit()

func _on_animate_tween_finished():
	animateTween = null

func _on_combatant_tween_returned():
	tween_back_finished.emit()
	animateTween = null

func _on_hp_drain_tween_finished():
	hpDrainTween = null

func _move_sprite_complete(sprite: MoveSprite):
	if sprite.move_sprite_complete.is_connected(_move_sprite_complete):
		sprite.move_sprite_complete.disconnect(_move_sprite_complete)
	playedMoveSprites -= 1 # a number and an array are both kept track of, in case some sprites are freed at this time the erase may not work but the count will
	playingMoveSprites.erase(sprite)
	# if the combatant's sprite animation is done and all move sprites have finished
	if playedMoveSprites == 0:
		playingMoveSprites = []
		move_sprites_finished.emit()

func _rune_sprite_complete(sprite: MoveSprite):
	if sprite == null:
		# if the sprite was already freed... what can we do here?
		#var prevSprite: MoveSprite = loadedRuneSprites[playingRuneSpriteIdx]
		#loadedRuneSprites = loadedRuneSprites.filter(_filter_out_null)
		#playingRuneSpriteIdx = loadedRuneSprites.find(prevSprite)
		return
	_set_rune_sprite_playing_and_shown(sprite, false)
	var spriteIdx: int = loadedRuneSprites.find(sprite)
	if len(loadedRuneSprites) == 0:
		playingRuneSprites = [] # if we're now out of runes; get rid of them all
	else:
		# make a new rune sprite show up
		var showingRuneSpriteIdxs: Array[int] = []
		for runeSpr: MoveSprite in playingRuneSprites:
			var sprIdx: int = loadedRuneSprites.find(runeSpr)
			if sprIdx != -1:
				showingRuneSpriteIdxs.append(sprIdx)

		if spriteIdx != -1:
			var nextIdx: int = (showingRuneSpriteIdxs[len(showingRuneSpriteIdxs) - 1] + 1) % len(loadedRuneSprites)
			playingRuneSprites.erase(sprite)
			playingRuneSprites.append(loadedRuneSprites[nextIdx])
			
			var minPlaySecs: float = -1
			for runeSpr: MoveSprite in playingRuneSprites:
				# ignore minPlaySecs of 0 if there is a timer that has ticked onwards
				if not runeSpr.halt and (minPlaySecs <= 0 or runeSpr.totalTimer < minPlaySecs):
					minPlaySecs = runeSpr.totalTimer
			
			# if the last rune has played MULTI_RUNE_DELAY_SECS ago or more: play instantly, otherwise delay the difference 
			if minPlaySecs >= MULTI_RUNE_DELAY_SECS:
				_set_rune_sprite_playing_and_shown(loadedRuneSprites[nextIdx], true)
			else:
				get_tree().create_timer(MULTI_RUNE_DELAY_SECS - minPlaySecs).timeout.connect(_set_rune_sprite_playing_and_shown.bind(loadedRuneSprites[nextIdx], true))
	if not sprite.looping:
		sprite.destroy(false)
		loadedRuneSprites.erase(sprite)
		playingRuneSprites.erase(sprite)

func _set_rune_sprite_playing_and_shown(runeSprite: MoveSprite, playing: bool = true) -> void:
	if runeSprite == null or runeSprite.destroying:
		return
	runeSprite.halt = not playing
	if playing and not runeSprite.playing:
		runeSprite.play_sprite_animation()
	
	if not playing and runeSprite.playing:
		runeSprite.reset_animation(true)
	
	runeSprite.visible = playing

func _event_text_completed(eventText: CombatantEventText):
	playedEventTexts -= 1 # a number and an array are both kept track of, in case some texts are freed at this time the erase may not work but the count will
	playingEventTexts.erase(eventText)
	if playedEventTexts == 0:
		playingEventTexts = []
		#event_texts_finished.emit()

func _on_shard_summon_anim_sprite_animation_finished() -> void:
	shardSummonAnimSprite.visible = false

func _filter_out_null(val) -> bool:
	return val != null
