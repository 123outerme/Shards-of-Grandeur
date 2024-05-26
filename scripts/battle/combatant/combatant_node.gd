extends Node2D
class_name CombatantNode

enum Role {
	ALLY = 0,
	ENEMY = 1
}

class ChosenMove:
	var move: Move = null
	var effectType: Move.MoveEffectType = Move.MoveEffectType.NONE
	var weight: float = 0
	
	func _init(i_move = null, i_effectType = Move.MoveEffectType.NONE, i_weight = 0.0):
		move = i_move
		effectType = i_effectType
		weight = i_weight

signal toggled(button_pressed: bool, combatantNode: CombatantNode)
signal details_clicked(combatantNode: CombatantNode)

@export_category("CombatantNode - Details")
@export var combatant: Combatant = null
@export var initialCombatantLv: int = 1
@export var role: Role = Role.ALLY
@export var leftSide: bool = false
@export var spriteFacesRight: bool = false
@export var battlePosition: String = ''
@export var unlockSurgeRequirements: StoryRequirements = null

@export_category("CombatantNode - Movement")
@export var allyTeamMarker: Marker2D
@export var enemyTeamMarker: Marker2D
@export var battleController: Node2D
# NOTE: if this is of type BattleController, then the SFX Button scene breaks.... no joke. WHYYYYYYY??

const statusWeights: Dictionary = {
	StatusEffect.Potency.WEAK: 30,
	StatusEffect.Potency.STRONG: 45,
	StatusEffect.Potency.OVERWHELMING: 60
}
const ANIMATE_MOVE_SPEED = 90
const moveSpriteScene = preload('res://prefabs/battle/move_sprite.tscn')
var tmpAllCombatantNodes: Array[CombatantNode] = []
var animateTween: Tween = null
var hpDrainTween: Tween = null
var fadeOutTween: Tween = null
var returnToPos: Vector2 = Vector2()
var playHitQueued: ParticlePreset = null
var playHitTimingDelay: float = 0
var playHitEnabled: bool = false
var playParticlesQueued: ParticlePreset = null
var playParticlesTimingDelay: float = 0
var playMoveSpritesQueued: Array[MoveAnimSprite] = []
var playedMoveSprites: int = 0
var moveSpriteTargets: Array[CombatantNode] = []
var moveSpritesCallback: Callable = Callable()
var useItemSprite: Texture2D = null
var isBeingStatusAfflicted: bool = false

@onready var hpTag: Panel = get_node('HPTag')
@onready var lvText: RichTextLabel = get_node('HPTag/LvText')
@onready var hpText: RichTextLabel = get_node('HPTag/LvText/HPText')
@onready var hpProgressBar: TextureProgressBar = get_node('HPTag/LvText/HPProgressBar')
@onready var orbDisplay: OrbDisplay = get_node('HPTag/OrbDisplay')
@onready var spriteContainer: Node2D = get_node('SpriteContainer')
@onready var animatedSprite: AnimatedSprite2D = get_node('SpriteContainer/AnimatedSprite')
@onready var selectCombatantBtn: TextureButton = get_node('SelectCombatantBtn')
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
	if battleController != null:
		battleController.combatant_finished_moving.connect(_combatant_finished_moving)
		battleController.combatants_play_hit.connect(_combatants_play_hit)
		battleController.combatant_finished_animating.connect(_combatant_finished_animating)
	orbDisplay.alignment = BoxContainer.ALIGNMENT_END if leftSide else BoxContainer.ALIGNMENT_BEGIN

func load_combatant_node():
	if not is_alive():
		visible = false
	else:
		visible = true
		if combatant.statChanges == null:
			combatant.statChanges = StatChanges.new()
		animatedSprite.sprite_frames = combatant.get_sprite_frames()
		if combatant.get_sprite_frames() == null:
			animatedSprite.sprite_frames = load("res://graphics/animations/a_player.tres") # TEMP prevent crashing
		var feetOffset: Vector2 = -1 * combatant.get_feet_pos()
		animatedSprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
		if animatedSprite.flip_h:
			# mirror x position if sprite is flipped
			feetOffset.x = (combatant.get_max_size().x + feetOffset.x) * -1
		feetOffset.y += 8
		animatedSprite.offset = feetOffset
		play_animation('battle_idle')
		update_select_btn(false)
		hpProgressBar.max_value = combatant.stats.maxHp
		hpProgressBar.value = combatant.currentHp
		hpProgressBar.tint_progress = Combatant.get_hp_bar_color(combatant.currentHp, combatant.stats.maxHp)
		update_hp_tag()
		
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
			onAttackMarker.position.x -= (combatant.get_max_size().x - 16) / 2
		elif onAttackMarker.position.x > position.x:
			onAttackMarker.position.x += (combatant.get_max_size().x - 16) / 2
		
		# nudge the assist marker away from sprite by any amount over 16 tall
		if onAssistMarker.position.y < position.y:
			onAssistMarker.position.y -= (combatant.get_max_size().y - 16) / 2
		elif onAssistMarker.position.y > position.y:
			onAssistMarker.position.y += (combatant.get_max_size().y - 16) / 2

func get_in_front_particle_scale() -> float:
		# scale of particles in front of combatant: 1*, plus 0.25 for every 16 px larger
	return 1 + round(max(0, max(combatant.get_max_size().x, combatant.get_max_size().y) - 16) / 16) / 4

func get_behind_particle_scale() -> float:
	# scale of particles behind combatant: 1.5*, plus 0.25 for every 16 px larger
	return 1.5 + round(max(0, max(combatant.get_max_size().x, combatant.get_max_size().y) - 16) / 16) / 4

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
	
	hpTag.visible = true
	lvText.text = 'Lv ' + String.num(combatant.stats.level)
	lvText.size.x = len(lvText.text) * 13 # about 13 pixels per character
	hpText.text = TextUtils.num_to_comma_string(combatant.currentHp) + ' / ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
	#hpText.size.x = len(hpText.text) * 13 - 10 # magic number
	hpProgressBar.max_value = combatant.stats.maxHp
	if hpProgressBar.value != combatant.currentHp:
		if hpDrainTween != null and hpDrainTween.is_valid():
			hpDrainTween.kill()
		hpDrainTween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		hpDrainTween.parallel().tween_property(hpProgressBar, 'value', combatant.currentHp, 1)
		hpDrainTween.parallel().tween_property(hpProgressBar, 'tint_progress', Combatant.get_hp_bar_color(combatant.currentHp, combatant.stats.maxHp), 1)
		hpDrainTween.finished.connect(_on_hp_drain_tween_finished)
	
	#hpTag.size.x = (lvText.size.x + hpText.size.x) * lvText.scale.x + 8 # magic number
	if leftSide:
		hpTag.position = Vector2(-1 * hpTag.size.x - selectCombatantBtn.size.x * 0.5 - 4, -0.5 * hpTag.size.y)
	else:
		hpTag.position = Vector2(selectCombatantBtn.size.x * 0.5 + 4, -0.5 * hpTag.size.y)
	
	#if ((unlockSurgeRequirements == null or unlockSurgeRequirements.is_valid()) and leftSide) or ((Combatant.useSurgeReqs == null or Combatant.useSurgeReqs.is_valid()) and not leftSide):
		#orbDisplay.visible = true
	orbDisplay.currentOrbs = combatant.orbs
	orbDisplay.update_orb_display()
	#else:
		#orbDisplay.visible = false
	if combatant.statusEffect != null:
		statusSprite.texture = combatant.statusEffect.get_icon()
	else:
		statusSprite.texture = null

func update_select_btn(showing: bool, disable: bool = false):
	if not is_alive():
		return
		
	selectCombatantBtn.visible = showing
	selectCombatantBtn.disabled = disable
	update_select_btn_texture()
	
	selectCombatantBtn.size = combatant.get_max_size() + Vector2(8, 8) # set size of selecting button to sprite size + 8px
	selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button
	# update the position to be centered on the combatant's full sprite boundaries (not its center of mass)
	selectCombatantBtn.position += animatedSprite.offset + (combatant.get_max_size() / 2)

func update_select_btn_texture():
	if selectCombatantBtn.disabled:
		if is_selected():
			selectCombatantBtn.texture_disabled = selectCombatantBtn.texture_pressed
		else:
			selectCombatantBtn.texture_disabled = selectCombatantBtn.texture_normal

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
	update_select_btn_texture()
	
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

func tween_to(pos: Vector2):
	if combatant.get_max_size().x > 16:
		if pos.x > global_position.x:
			pos.x -= (combatant.get_max_size().x - 16) / 2
		else:
			pos.x += (combatant.get_max_size().x - 16) / 2
	
	if combatant.get_max_size().y > 16:
		if pos.y > global_position.y:
			pos.y -= (combatant.get_max_size().y - 16) / 2
		else:
			pos.y += (combatant.get_max_size().y - 16) / 2
	
	if animateTween != null and animateTween.is_valid():
		animateTween.kill()
		global_position = returnToPos
	animateTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	returnToPos = global_position
	var moveTime = pos.length() / ANIMATE_MOVE_SPEED
	if animatedSprite.animation != 'battle_idle':
		# if there's an animation playing:
		moveTime = 0
		var fps = animatedSprite.sprite_frames.get_animation_speed(animatedSprite.animation)
		for frameIdx in range(animatedSprite.sprite_frames.get_frame_count(animatedSprite.animation)):
			# add (duration of frame / per-frame time) = amount of time to display this frame
			moveTime += animatedSprite.sprite_frames.get_frame_duration(animatedSprite.animation, frameIdx) / fps
		moveTime *= 0.5 #0.667 # half the time so the destination is reached for the latter half of the animation
		
	# move to target position
	animateTween.tween_property(spriteContainer, 'global_position', pos, moveTime)
	# emit that the move was completed
	animateTween.tween_callback(_on_animate_tween_target_move_finished)
	# wait
	animateTween.tween_property(spriteContainer, 'rotation', 0, 1) # will not rotate, is simply doing nothing for a beat
	# and return at a constant rate
	animateTween.finished.connect(_on_animate_tween_finished)

func tween_back_to_return_pos():
	if animateTween != null:
		animateTween.kill()
	if battleController != null:
		# plays hit particles ONLY unless the combatant really is done
		battleController.combatants_play_hit.emit()
	animateTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	animateTween.tween_property(spriteContainer, 'global_position', returnToPos, (returnToPos - spriteContainer.global_position).length() / ANIMATE_MOVE_SPEED)
	animateTween.finished.connect(_on_combatant_tween_returned)

func play_particles(preset: ParticlePreset, delay: bool = false, timingDelay: float = 0):
	if preset == null or preset.count == 0:
		return
	
	var presetCopy: ParticlePreset = preset.duplicate(true)
	if leftSide: # particles are designed & saved as they would play on an enemy (right side)
		presetCopy.processMaterial.direction.x *= -1 # invert inital X emission direction
	
	if presetCopy.emitter == 'hit' and delay:
		playHitQueued = presetCopy
		playHitTimingDelay = timingDelay
		return
		
	if delay:
		playParticlesQueued = presetCopy
		playParticlesTimingDelay = timingDelay
	else:
		make_particles_now(presetCopy, timingDelay)

func make_particles_now(preset: ParticlePreset, timingDelay: float = 0):
	if timingDelay > 0:
		await get_tree().create_timer(timingDelay).timeout
	
	match preset.emitter:
		'surge':
			surgeParticles.preset = preset
			surgeParticles.set_make_particles(true)
		'behind':
			behindParticles.preset = preset
			behindParticles.set_make_particles(true)
		'front':
			frontParticles.preset = preset
			frontParticles.set_make_particles(true)
		'hit':
			hitParticles.preset = preset
			hitParticles.set_make_particles(true)
		'shard':
			shardParticles.preset = preset
			shardParticles.set_make_particles(true)
	SceneLoader.audioHandler.play_sfx(preset.sfx)

func play_move_sprites(moveSprites: Array[MoveAnimSprite]):
	playMoveSpritesQueued = []
	for moveAnimSprite in moveSprites:
		if moveAnimSprite.delayedUntilReposition:
			playMoveSpritesQueued.append(moveAnimSprite)
		else:
			play_move_sprite(moveAnimSprite)

func play_move_sprite(moveAnimSprite: MoveAnimSprite):
	var nodes: Array[CombatantNode] = moveSpriteTargets
	if not moveAnimSprite.onePerTarget and len(nodes) > 0:
		nodes = [moveSpriteTargets[0]]
	for node in nodes:
		var spriteNode: MoveSprite = moveSpriteScene.instantiate()
		spriteNode.user = self
		spriteNode.anim = moveAnimSprite
		spriteNode.target = node
		spriteNode.globalMarker = battleController.globalMarker
		spriteNode.userTeam = allyTeamMarker
		spriteNode.enemyTeam = enemyTeamMarker
		spriteNode.staticSprite = useItemSprite
		spriteNode.move_sprite_complete.connect(_move_sprite_complete)
		#spriteNode.call_deferred('play_sprite_animation')
		add_child(spriteNode)
		playedMoveSprites += 1

func move_animation_callback(callback: Callable):
	moveSpritesCallback = callback

func get_targetable_combatant_nodes(allCombatantNodes: Array[CombatantNode], targets: BattleCommand.Targets) -> Array[CombatantNode]:
	if targets == BattleCommand.Targets.SELF:
		return [self]
	
	var targetableList: Array[CombatantNode] = []
	for combatantNode in allCombatantNodes:
		if combatantNode == null or not combatantNode.is_alive():
			continue # skip this combatant if not alive
		if self == combatantNode and (targets == BattleCommand.Targets.ALL_EXCEPT_SELF or targets == BattleCommand.Targets.NON_SELF_ALLY):
			continue # skip user if user is not targetable
		
		if targets == BattleCommand.Targets.ALL or targets == BattleCommand.Targets.ALL_EXCEPT_SELF:
			targetableList.append(combatantNode)
		else:
			var targetRole: CombatantNode.Role = combatantNode.role
			if ((targets == BattleCommand.Targets.ALL_ALLIES or targets == BattleCommand.Targets.ALLY or targets == BattleCommand.Targets.NON_SELF_ALLY) and targetRole == role) or \
				((targets == BattleCommand.Targets.ALL_ENEMIES or targets == BattleCommand.Targets.ENEMY) and targetRole != role):
				targetableList.append(combatantNode)
	return targetableList

func get_command(combatantNodes: Array[CombatantNode]):
	if combatant.command == null and is_alive():
		var chosenMove: ChosenMove = ai_pick_move(combatantNodes)
		if chosenMove.effectType == Move.MoveEffectType.BOTH:
			if combatant.would_ai_spend_orbs(chosenMove.move.surgeEffect):
				chosenMove.effectType = Move.MoveEffectType.SURGE
			else:
				chosenMove.effectType = Move.MoveEffectType.CHARGE
		elif chosenMove.effectType == Move.MoveEffectType.SURGE:
			# TEST THIS: just in case somehow the surge move got through but it can't be used, use charge instead
			if chosenMove.move.surgeEffect.orbChange * -1 > combatant.orbs:
				chosenMove.effectType = Move.MoveEffectType.CHARGE
		
		var chosenEffect = chosenMove.move.get_effect_of_type(chosenMove.effectType)
		var targetableCombatants: Array[CombatantNode] = get_targetable_combatant_nodes(combatantNodes, chosenEffect.targets)
		if len(targetableCombatants) == 0:
			printerr('BATTLE ERROR NO TARGETABLE COMBATANTS')
			combatant.command = BattleCommand.new(BattleCommand.Type.NONE)
			return
		var targetPositions: Array[String] = []
		if BattleCommand.is_command_multi_target(chosenEffect.targets):
			for targetableCombatant in targetableCombatants:
				targetPositions.append(targetableCombatant.battlePosition)
		else:
			targetPositions = [ai_pick_single_target(chosenMove.move, chosenEffect, targetableCombatants)]
		var orbChange: int = combatant.get_orbs_change_choice(chosenEffect)
		combatant.command = BattleCommand.new(BattleCommand.Type.MOVE, chosenMove.move, chosenMove.effectType, orbChange, null, targetPositions)
	elif not is_alive():
		combatant.command = null

func ai_pick_move(combatantNodes: Array[CombatantNode]) -> ChosenMove:
	var candidateMoves = ai_get_move_effect_weights(combatantNodes)
	var pickedMove = null
	if len(candidateMoves) > 0:
		pickedMove = candidateMoves[0]
	
	if pickedMove == null or pickedMove.move == null or pickedMove.effectType == Move.MoveEffectType.NONE:
		printerr('MAJOR ERROR: ai did not find a move to use ', combatant.save_name(), ': ', battlePosition)
	
	return pickedMove

func filter_out_unusable(a) -> bool:
	if a == null:
		return false
	
	var hasAllies: bool = false
	for combatantNode in tmpAllCombatantNodes:
		if combatantNode != null and combatantNode.role == role and combatantNode.is_alive() and combatantNode.battlePosition != battlePosition:
			hasAllies = true
			break
	
	var numCanUse: int = 2
	for effect in [a.chargeEffect, a.surgeEffect]:
		if (not hasAllies and effect.targets == BattleCommand.Targets.NON_SELF_ALLY) or \
			not combatant.could_combatant_surge(effect):
			numCanUse -= 1 # move cannot be used by the game rules
	return numCanUse > 0 # move could be used

func ai_get_move_effect_weight(move: Move, moveEffect: MoveEffect, randValue: float) -> float:
	if moveEffect == null:
		return 0
	if not combatant.could_combatant_surge(moveEffect):
		return 0
	var hasAllies: bool = false
	var numCanStatus: int = 0
	var combatantCouldUseHealing: bool = false
	for combatantNode in tmpAllCombatantNodes:
		if combatantNode != null and combatantNode.role == role and combatantNode.is_alive() and combatantNode.battlePosition != battlePosition:
			hasAllies = true
			break
	
	var enemyIsWeakToElement: bool = false
	var allEnemiesResistElement: bool = true
	var allEnemiesResistStatus: bool = moveEffect.statusEffect != null
	var allEnemiesImmuneToStatus: bool = moveEffect.statusEffect != null
	for combatantNode in get_targetable_combatant_nodes(tmpAllCombatantNodes, moveEffect.targets):
		if combatantNode.combatant.statusEffect == null or \
				(moveEffect.statusEffect != null and moveEffect.statusEffect.overwritesOtherStatuses):
			numCanStatus += 1
		var maxHp: float = combatantNode.combatant.stats.maxHp
		# if 60% or less health, could use healing
		if combatantNode.combatant.currentHp / maxHp < 0.6:
			combatantCouldUseHealing = true
		if combatantNode.combatant.get_element_effectiveness_multiplier(move.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective:
			enemyIsWeakToElement = true
			allEnemiesResistElement = false
		if combatantNode.combatant.get_element_effectiveness_multiplier(move.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.effective:
			allEnemiesResistElement = false
		if moveEffect.statusEffect != null and combatantNode.combatant.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) != Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.resisted:
			allEnemiesResistStatus = false
		if moveEffect.statusEffect != null and combatantNode.combatant.get_status_effectiveness_multiplier(moveEffect.statusEffect.type) != Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.immune:
			allEnemiesImmuneToStatus = false
	
	if not hasAllies and moveEffect.targets == BattleCommand.Targets.NON_SELF_ALLY:
		return 0
	
	var weightModifier: float = 1
	if not combatant.would_ai_spend_orbs(moveEffect):
		weightModifier = 0.5
	elif moveEffect.orbChange >= 0:
		# modifier is [0.8, 3] based on the amount of orbs that can be gained by using the move
		var gainableOrbs: int = max(Combatant.MAX_ORBS, moveEffect.orbChange + combatant.orbs) - combatant.orbs
		weightModifier *= max(0.8, 1 - ((gainableOrbs - 1) * 0.2))
	# at 40% health or less, non-SUPPORT AIs should prioritize attacking more
	var isLowHealth: bool = (combatant.currentHp / (combatant.stats.maxHp as float)) <= 0.4
	if combatant.get_ai_type() != Combatant.AiType.SUPPORT and (moveEffect.role == MoveEffect.Role.HEAL or moveEffect.role == MoveEffect.Role.OTHER):
		weightModifier *= 0.75 # de-prioritize support moves if the combatant is not an explicit Support AI

	if randValue > combatant.aiOverrideWeight and \
			((combatant.get_ai_type() == Combatant.AiType.DAMAGE or (combatant.get_ai_type() != Combatant.AiType.SUPPORT and isLowHealth)) \
			and (moveEffect.role == MoveEffect.Role.AOE_DAMAGE or moveEffect.role == MoveEffect.Role.SINGLE_TARGET_DAMAGE)) or \
			(combatant.get_ai_type() == Combatant.AiType.BUFFER and moveEffect.role == MoveEffect.Role.BUFF) or \
			(combatant.get_ai_type() == Combatant.AiType.DEBUFFER and moveEffect.role == MoveEffect.Role.DEBUFF) or \
			(combatant.get_ai_type() == Combatant.AiType.SUPPORT and ((moveEffect.role == MoveEffect.Role.HEAL and combatantCouldUseHealing) or moveEffect.role == MoveEffect.Role.OTHER)): 
		weightModifier *= 1.5 # prioritize moves aligning with AI type
	var boostedStats: Stats = combatant.statChanges.apply(combatant.stats)
	var damageStat: int = boostedStats.physAttack
	if move.category == Move.DmgCategory.MAGIC:
		damageStat = boostedStats.magicAttack
	elif move.category == Move.DmgCategory.AFFINITY:
		damageStat = boostedStats.affinity
	var maxDamageStat: float = boostedStats.physAttack
	if boostedStats.magicAttack > maxDamageStat:
		maxDamageStat = boostedStats.magicAttack
	if boostedStats.affinity > maxDamageStat:
		maxDamageStat = boostedStats.affinity
	var weight: float = 1
	if (moveEffect.role == MoveEffect.Role.AOE_DAMAGE or moveEffect.role == MoveEffect.Role.SINGLE_TARGET_DAMAGE) and \
			combatant.get_ai_type() == Combatant.AiType.DAMAGE and randValue < combatant.aiOverrideWeight:
		weight = randf() * moveEffect.power * weightModifier + 1
	else:
		if BattleCommand.is_command_multi_target(moveEffect.targets):
			var numEnemies: int = 0
			for combatantNode: CombatantNode in tmpAllCombatantNodes:
				if combatantNode.role != role and combatantNode.is_alive():
					numEnemies += 1
			weight = abs(moveEffect.power) * numEnemies * weightModifier + 1
		else:
			weight = abs(moveEffect.power) * weightModifier + 1
	if moveEffect.power != 0:
		weight *= damageStat / maxDamageStat
		if enemyIsWeakToElement:
			weight *= Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective
		elif allEnemiesResistElement:
			weight *= Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.resisted
	if moveEffect.statusEffect != null and numCanStatus > 0:
		# 50% of the time, Damage AIs don't care about doing status as much
		var dmgAiWeight: float = 0.5 if combatant.get_ai_type() == Combatant.AiType.DAMAGE and randf() > 0.5 else 1.0
		var multiStatusWeight: float = 1.25 if BattleCommand.is_command_multi_target(moveEffect.targets) and numCanStatus > 1 else 1.0
		var statusTurnsWeight: float = max(1, 1 + 0.05 * (moveEffect.statusEffect.turnsLeft - 1))
		weight += statusWeights[moveEffect.statusEffect.potency] * moveEffect.statusChance * statusTurnsWeight * multiStatusWeight * weightModifier * dmgAiWeight
	if moveEffect.selfStatChanges != null and moveEffect.selfStatChanges.has_stat_changes():
		if not (moveEffect.statusEffect != null and moveEffect.selfGetsStatus and numCanStatus <= 0):
			var boostedStatsTotal: float = boostedStats.get_stat_total()
			var newBoostedStats: Stats = moveEffect.selfStatChanges.apply(boostedStats)
			weight *= newBoostedStats.get_stat_total() / boostedStatsTotal
	if moveEffect.targetStatChanges != null and moveEffect.targetStatChanges.has_stat_changes():
		# make dummy stats to easily detect percentage of stats that will be changed
		var newStats: Stats = Stats.new('Dummy', 'dummy_stats', 1, 0, 50, 100, 100, 100, 100, 100)
		var newStatsTotal: float = newStats.get_stat_total()
		var newBoostedStats: Stats = moveEffect.targetStatChanges.apply(newStats)
		if BattleCommand.is_command_enemy_targeting(moveEffect.targets):
			weight *= newStatsTotal / newBoostedStats.get_stat_total()
		else:
			weight *= newBoostedStats.get_stat_total() / newStatsTotal
	return weight

func ai_get_move_effect_weights(combatantNodes: Array[CombatantNode]) -> Array[ChosenMove]:
	var moveEffects: Array[ChosenMove] = []
	var randValue: float = randf()
	if randValue >= combatant.aiOverrideWeight:
		print(battlePosition, ': move choice override triggered')
	tmpAllCombatantNodes = combatantNodes
	for move: Move in combatant.stats.moves:
		if not filter_out_unusable(move):
			continue
		for effectType: Move.MoveEffectType in [Move.MoveEffectType.CHARGE, Move.MoveEffectType.SURGE]:
			var effect: MoveEffect = move.get_effect_of_type(effectType)
			if effect == null:
				continue
			var weight = ai_get_move_effect_weight(move, effect, randValue)
			print(battlePosition, ': move ', move.moveName, ' effect ', effectType, ' weight ', weight)
			if weight != 0:
				moveEffects.append(ChosenMove.new(move, effectType, weight))
	moveEffects.sort_custom(_sort_chosen_moves_by_weight)
	for choiceIdx in range(len(moveEffects)):
		var choice: ChosenMove = moveEffects[choiceIdx]
		print(battlePosition, ' Choice ', choiceIdx + 1, ': ', choice.move.moveName, ' type ', choice.effectType, ', weight ', choice.weight)
	tmpAllCombatantNodes = []
	return moveEffects

func ai_pick_single_target(move: Move, effect: MoveEffect, targetableCombatants: Array[CombatantNode]) -> String:
	var pickedTarget: String = ''
	var randValue: float = randf()
	if randValue >= combatant.aiOverrideWeight:
		print(battlePosition, ': target override triggered')
	else:
		var superEffectiveElementTargets: Array[CombatantNode] = []
		for combatantNode: CombatantNode in targetableCombatants:
			if combatantNode.combatant.get_element_effectiveness_multiplier(move.element) == Combatant.ELEMENT_EFFECTIVENESS_MULTIPLIERS.superEffective and effect.power > 0:
				# if this move will deal super-effective damage, consider it for bypassing the normal targeting AI
				superEffectiveElementTargets.append(combatantNode)
		# if not all targets would take super-effective damage:
		if len(superEffectiveElementTargets) != len(targetableCombatants):
			for combatantNode: CombatantNode in superEffectiveElementTargets:
				# on a 50% chance, just pick the super-effective enemy as the target
				var randValueToChoose: float = randf()
				if randValueToChoose > 0.5:
					return combatantNode.battlePosition
	
	if (effect.role == MoveEffect.Role.SINGLE_TARGET_DAMAGE or effect.role == MoveEffect.Role.HEAL) and randValue > combatant.aiOverrideWeight:
		var timesOverrided: int = 0
		if combatant.get_aggro_type() == Combatant.AggroType.LOWEST_HP:
			# pick lowest health
			var minHealth: int = -1
			for combatantNode in targetableCombatants:
				if minHealth == -1 or minHealth > combatantNode.combatant.currentHp:
					minHealth = combatantNode.combatant.currentHp
					pickedTarget = combatantNode.battlePosition
					timesOverrided += 1
		if combatant.get_aggro_type() == Combatant.AggroType.MOST_ORBS:
			# pick most orbs
			var maxOrbs: int = 0
			for combatantNode in targetableCombatants:
				if maxOrbs < combatantNode.combatant.orbs:
					maxOrbs = combatantNode.combatant.orbs
					pickedTarget = combatantNode.battlePosition
					timesOverrided += 1
		if combatant.get_aggro_type() == Combatant.AggroType.HIGHEST_STATS:
			# pick highest (current) stats
			var maxStatTotal: int = 0
			for combatantNode in targetableCombatants:
				var stats: Stats = combatantNode.combatant.statChanges.apply(combatantNode.combatant.stats)
				var statTotal: int = stats.get_stat_total()
				if maxStatTotal < statTotal:
					maxStatTotal = statTotal
					pickedTarget = combatantNode.battlePosition
					timesOverrided += 1
		if combatant.get_aggro_type() == Combatant.AggroType.HIGHEST_HP or timesOverrided == len(targetableCombatants):
			# if all are equal from a previous comparison, or the aggro type is highest HP:
			# pick highest health
			var maxHealth: int = 0
			for combatantNode in targetableCombatants:
				if maxHealth < combatantNode.combatant.currentHp:
					maxHealth = combatantNode.combatant.currentHp
					pickedTarget = combatantNode.battlePosition

	if effect.role == MoveEffect.Role.BUFF and randValue > combatant.aiOverrideWeight:
		# pick highest base stat changes in buffing categories if friendly targeting, pick lowest if enemy targeting
		# and modify by percentage of HP remaining relative to the highest HP of targets
		var maxHealth: float = 0
		for combatantNode in targetableCombatants:
			if maxHealth < combatantNode.combatant.currentHp:
				maxHealth = combatantNode.combatant.currentHp
		# NOTE what to do with All targeting? Will there be such a move?
		var multiplier: float = -1.0 if BattleCommand.is_command_enemy_targeting(effect.targets) and not (effect.targets == BattleCommand.Targets.ALL) else 1.0
		var maxBaseStatTotalChange: float = -INF * multiplier
		var statChanges: StatChanges = StatChanges.new()
		if effect.targetStatChanges != null:
			statChanges.stack(effect.targetStatChanges)
		for combatantNode in targetableCombatants:
			multiplier = -1 if BattleCommand.is_command_enemy_targeting(effect.targets) and not (effect.targets == BattleCommand.Targets.ALL) else 1
			# having higher HP makes a buff more worthwhile
			multiplier *= (combatantNode.combatant.currentHp / maxHealth)
			var stats: Stats = combatantNode.combatant.statChanges.apply(combatantNode.combatant.stats)
			var appliedStats: Stats = statChanges.apply(stats)
			var baseStatTotalChange: int = appliedStats.get_stat_total() - stats.get_stat_total()
			if maxBaseStatTotalChange < baseStatTotalChange * multiplier:
				maxBaseStatTotalChange = baseStatTotalChange * multiplier
				pickedTarget = combatantNode.battlePosition

	if effect.role == MoveEffect.Role.DEBUFF and randValue > combatant.aiOverrideWeight:
		# pick highest base stat changes in debuffing categories if friendly targeting, pick lowest if enemy targeting
		var multiplier: float = -1.0 if BattleCommand.is_command_enemy_targeting(effect.targets) and not (effect.targets == BattleCommand.Targets.ALL) else 1.0
		# NOTE: what to do with All targeting? Will there be such a move?
		var statChanges: StatChanges = StatChanges.new()
		if effect.targetStatChanges != null and effect.targetStatChanges.has_stat_changes():
			statChanges.stack(effect.targetStatChanges)
		var maxBaseStatTotalChange: float = -INF * multiplier
		for combatantNode in targetableCombatants:
			if effect.statusEffect != null and effect.power == 0:
				if combatantNode.combatant.get_status_effectiveness_multiplier(effect.statusEffect.type) == Combatant.STATUS_EFFECTIVENESS_MULTIPLIERS.immune \
						and (effect.targetStatChanges == null or not effect.targetStatChanges.has_stat_changes()):
					continue # skip this combatant if immune to the status and there are no stat changes or damage involved
			
			var stats: Stats = combatantNode.combatant.statChanges.apply(combatantNode.combatant.stats)
			var appliedStats: Stats = statChanges.apply(stats)
			var baseStatTotalChange: int = appliedStats.get_stat_total() - stats.get_stat_total()
			if maxBaseStatTotalChange < baseStatTotalChange * multiplier:
				maxBaseStatTotalChange = baseStatTotalChange * multiplier
				pickedTarget = combatantNode.battlePosition

	if pickedTarget == '':
		pickedTarget = targetableCombatants.pick_random().battlePosition
	return pickedTarget

func is_alive() -> bool:
	if combatant == null:
		return false
	return not combatant.downed

func _fade_out_finished():
	fadeOutTween = null
	visible = false
	modulate = Color(1,1,1,1)

func _on_select_combatant_btn_toggled(button_pressed):
	toggled.emit(button_pressed, self)

func _on_click_combatant_btn_pressed():
	print('show details for ', combatant.save_name())
	details_clicked.emit(self)

func _on_animated_sprite_animation_finished():
	play_animation('battle_idle')
	# if all move sprites have finished and move tween has completely finished
	if playedMoveSprites == 0 and animateTween == null and spriteContainer.global_position != returnToPos:
		tween_back_to_return_pos()
	elif battleController != null and playedMoveSprites == 0 and animateTween == null and spriteContainer.global_position == returnToPos:
		battleController.combatant_finished_animating.emit()
	# in case the combatant (currently using a move) is finished with the move animation and there wasn't any movement, update HP tag
	update_hp_tag()

func _on_animate_tween_target_move_finished():
	if battleController != null:
		battleController.combatant_finished_moving.emit()
	# when the combatant reaches the target on a "contact" movement, update HP tag
	update_hp_tag()

func _combatant_finished_moving():
	if playParticlesQueued != null:
		# if the turn combatant (who's currently using a move) doesn't need this combatant to play hit particles, this is when the tag updates
		if playHitQueued == null:
			update_hp_tag()
		make_particles_now(playParticlesQueued, playParticlesTimingDelay)
	else:
		# otherwise if no particles are going to play on this combatant but it is getting status'd, update the HP tag
		if playHitQueued == null and isBeingStatusAfflicted:
			update_hp_tag()
	playParticlesQueued = null
	isBeingStatusAfflicted = false
	if len(playMoveSpritesQueued) > 0:
		for moveSprite in playMoveSpritesQueued:
			play_move_sprite(moveSprite)
	playMoveSpritesQueued = []
	moveSpriteTargets = [] # no longer needed; all move sprites have been played!
	useItemSprite = null
	if playHitQueued != null:
		playHitEnabled = true

func _combatants_play_hit():
	if playHitQueued != null and playHitEnabled:
		update_hp_tag()
		make_particles_now(playHitQueued, playHitTimingDelay)
		playHitQueued = null
		playHitEnabled = false

func _combatant_finished_animating():
	_combatants_play_hit()
	if moveSpritesCallback != Callable() and animateTween == null and playedMoveSprites == 0:
		moveSpritesCallback.call()
		moveSpritesCallback = Callable()

func _on_animate_tween_finished():
	animateTween = null
	if playedMoveSprites == 0 and (animatedSprite.animation == 'battle_idle' or animatedSprite.animation == 'hide'):
		if animatedSprite.animation == 'hide':
			_on_animated_sprite_animation_finished()
		tween_back_to_return_pos()

func _on_combatant_tween_returned():
	animateTween = null
	if playedMoveSprites == 0:
		battleController.combatant_finished_animating.emit()
		if moveSpritesCallback != Callable():
			moveSpritesCallback.call()
			moveSpritesCallback = Callable()

func _on_hp_drain_tween_finished():
	hpDrainTween = null

func _move_sprite_complete():
	playedMoveSprites -= 1
	# if the combatant's sprite animation is done and all move sprites have finished
	if battleController != null and playedMoveSprites == 0 and (animatedSprite.animation == 'battle_idle' or animatedSprite.animation == 'hide'):
		if animatedSprite.animation == 'hide':
			_on_animated_sprite_animation_finished()
		if animateTween == null:
			if spriteContainer.global_position != returnToPos:
				tween_back_to_return_pos()
			else:
				battleController.combatant_finished_animating.emit()

func _sort_chosen_moves_by_weight(a: ChosenMove, b: ChosenMove) -> bool:
	if a.weight > b.weight:
		return true
	return false
