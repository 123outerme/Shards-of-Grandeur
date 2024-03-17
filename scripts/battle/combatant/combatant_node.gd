extends Node2D
class_name CombatantNode

enum Role {
	ALLY = 0,
	ENEMY = 1
}

class ChosenMove:
	var move: Move = null
	var effectType: Move.MoveEffectType = Move.MoveEffectType.NONE
	
	func _init(i_move = null, i_effectType = Move.MoveEffectType.NONE):
		move = i_move
		effectType = i_effectType

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

const ANIMATE_MOVE_SPEED = 60
var tmpAllCombatantNodes: Array[CombatantNode] = []
var selectBtnNotSelectedSprite: Texture2D = null
var animateTween: Tween = null
var hpDrainTween: Tween = null
var returnToPos: Vector2 = Vector2()
var playHitQueued: ParticlePreset = null
var playParticlesQueued: ParticlePreset = null

@onready var hpTag: Panel = get_node('HPTag')
@onready var lvText: RichTextLabel = get_node('HPTag/LvText')
@onready var hpText: RichTextLabel = get_node('HPTag/LvText/HPText')
@onready var hpProgressBar: TextureProgressBar = get_node('HPTag/LvText/HPProgressBar')
@onready var orbDisplay: OrbDisplay = get_node('HPTag/OrbDisplay')
@onready var animatedSprite: AnimatedSprite2D = get_node('AnimatedSprite')
@onready var clickCombatantBtn: TextureButton = get_node('ClickCombatantBtn')
@onready var selectCombatantBtn: TextureButton = get_node('SelectCombatantBtn')
@onready var behindParticleContainer: Node2D = get_node('BehindParticleContainer')
@onready var behindParticles: Particles = get_node('BehindParticleContainer/BehindParticleEmitter')
@onready var frontParticleContainer: Node2D = get_node('FrontParticleContainer')
@onready var frontParticles: Particles = get_node('FrontParticleContainer/FrontParticleEmitter')
@onready var hitParticles: Particles = get_node('FrontParticleContainer/HitParticleEmitter')
@onready var shardParticles: Particles = get_node('FrontParticleContainer/ShardParticleEmitter')
@onready var onAttackMarker: Marker2D = get_node('OnAttackPos')
@onready var onAssistMarker: Marker2D = get_node('OnAssistPos')

# Called when the node enters the scene tree for the first time.
func _ready():
	selectBtnNotSelectedSprite = selectCombatantBtn.texture_normal
	returnToPos = global_position
	if battleController != null:
		battleController.combatant_finished_moving.connect(_combatant_finished_moving)
		battleController.combatant_finished_animating.connect(_combatant_finished_animating)
	orbDisplay.alignment = BoxContainer.ALIGNMENT_END if leftSide else BoxContainer.ALIGNMENT_BEGIN

func load_combatant_node():
	if not is_alive():
		visible = false
	else:
		visible = true
		if combatant.statChanges == null:
			combatant.statChanges = StatChanges.new()
		animatedSprite.sprite_frames = combatant.spriteFrames
		if combatant.spriteFrames == null:
			animatedSprite.sprite_frames = load("res://graphics/animations/a_player.tres") # TEMP prevent crashing
		animatedSprite.play('stand')
		animatedSprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
		update_select_btn(false)
		hpProgressBar.max_value = combatant.stats.maxHp
		hpProgressBar.value = combatant.currentHp
		hpProgressBar.tint_progress = Combatant.get_hp_bar_color(combatant.currentHp, combatant.stats.maxHp)
		update_hp_tag()
		clickCombatantBtn.disabled = role == Role.ENEMY # don't let the player see the raw stats/moves of enemies
		# scale of particles behind combatant: 1.5*, plus 0.25 for every 16 px larger
		behindParticleContainer.scale.x = 1.5 + round(max(0, max(combatant.maxSize.x, combatant.maxSize.y) - 16) / 16) / 4
		behindParticleContainer.scale.y = behindParticleContainer.scale.x
		
		# scale of particles in front of combatant: 1*, plus 0.25 for every 16 px larger
		frontParticleContainer.scale.x = 1 + round(max(0, max(combatant.maxSize.x, combatant.maxSize.y) - 16) / 16) / 4
		frontParticleContainer.scale.y = frontParticleContainer.scale.x
		behindParticles.set_make_particles(false)
		frontParticles.set_make_particles(false)
		hitParticles.set_make_particles(false)
		shardParticles.set_make_particles(false)
		
		# nudge the attack marker away from sprite by any amount over 16 wide
		if onAttackMarker.position.x < position.x:
			onAttackMarker.position.x -= (combatant.maxSize.x - 16) / 2
		elif onAttackMarker.position.x > position.x:
			onAttackMarker.position.x += (combatant.maxSize.x - 16) / 2
		
		# nudge the assist marker away from sprite by any amount over 16 tall
		if onAssistMarker.position.y < position.y:
			onAssistMarker.position.y -= (combatant.maxSize.y - 16) / 2
		elif onAssistMarker.position.y > position.y:
			onAssistMarker.position.y += (combatant.maxSize.y - 16) / 2
			
func update_hp_tag():
	if not is_alive():
		visible = false
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
	
	if ((unlockSurgeRequirements == null or unlockSurgeRequirements.is_valid()) and leftSide) or ((Combatant.useSurgeReqs == null or Combatant.useSurgeReqs.is_valid()) and not leftSide):
		orbDisplay.visible = true
		orbDisplay.currentOrbs = combatant.orbs
		orbDisplay.update_orb_display()
	else:
		orbDisplay.visible = false

func update_select_btn(showing: bool, disable: bool = false):
	if not is_alive():
		return
		
	selectCombatantBtn.visible = showing
	selectCombatantBtn.disabled = disable
	if selectCombatantBtn.disabled:
		if is_selected():
			selectCombatantBtn.texture_disabled = selectCombatantBtn.texture_pressed
		else:
			selectCombatantBtn.texture_disabled = selectCombatantBtn.texture_normal
	
	selectCombatantBtn.size = combatant.maxSize + Vector2(8, 8) # set size of selecting button to sprite size + 8px
	selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button

func focus_select_btn():
	selectCombatantBtn.grab_focus()

func set_buttons_left_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_left = selectCombatantBtn.get_path_to(control)
	clickCombatantBtn.focus_neighbor_left = clickCombatantBtn.get_path_to(control)
	control.focus_neighbor_right = control.get_path_to(selectCombatantBtn)
	
func set_buttons_right_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_right = selectCombatantBtn.get_path_to(control)
	clickCombatantBtn.focus_neighbor_right = clickCombatantBtn.get_path_to(control)
	control.focus_neighbor_left = control.get_path_to(selectCombatantBtn)
	
func set_buttons_top_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_top = selectCombatantBtn.get_path_to(control)
	clickCombatantBtn.focus_neighbor_top = clickCombatantBtn.get_path_to(control)
	control.focus_neighbor_bottom = control.get_path_to(selectCombatantBtn)
	
func set_buttons_bottom_neighbor(control: Control):
	selectCombatantBtn.focus_neighbor_bottom = selectCombatantBtn.get_path_to(control)
	clickCombatantBtn.focus_neighbor_bottom = clickCombatantBtn.get_path_to(control)
	control.focus_neighbor_top = control.get_path_to(selectCombatantBtn)

func set_focus_left_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_left = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	clickCombatantBtn.focus_neighbor_left = clickCombatantBtn.get_path_to(combatantNode.clickCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_right = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	combatantNode.clickCombatantBtn.focus_neighbor_right = combatantNode.clickCombatantBtn.get_path_to(clickCombatantBtn)

func set_focus_right_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_right = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	clickCombatantBtn.focus_neighbor_right = clickCombatantBtn.get_path_to(combatantNode.clickCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_left = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	combatantNode.clickCombatantBtn.focus_neighbor_left = combatantNode.clickCombatantBtn.get_path_to(clickCombatantBtn)

func set_focus_bottom_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_bottom = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	clickCombatantBtn.focus_neighbor_bottom = clickCombatantBtn.get_path_to(combatantNode.clickCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_top = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	combatantNode.clickCombatantBtn.focus_neighbor_top = combatantNode.clickCombatantBtn.get_path_to(clickCombatantBtn)

func set_focus_top_combatant_node_neighbor(combatantNode: CombatantNode):
	selectCombatantBtn.focus_neighbor_top = selectCombatantBtn.get_path_to(combatantNode.selectCombatantBtn)
	clickCombatantBtn.focus_neighbor_top = clickCombatantBtn.get_path_to(combatantNode.clickCombatantBtn)
	combatantNode.selectCombatantBtn.focus_neighbor_bottom = combatantNode.selectCombatantBtn.get_path_to(selectCombatantBtn)
	combatantNode.clickCombatantBtn.focus_neighbor_bottom = combatantNode.clickCombatantBtn.get_path_to(clickCombatantBtn)

func set_selected(selected: bool = true):
	if selected and selectCombatantBtn.disabled:
		selectCombatantBtn.texture_normal = selectCombatantBtn.texture_pressed
	elif selectCombatantBtn.texture_normal == selectCombatantBtn.texture_pressed:
		selectCombatantBtn.texture_normal = selectBtnNotSelectedSprite
	selectCombatantBtn.button_pressed = selected
	
func is_selected() -> bool:
	return selectCombatantBtn.button_pressed

func play_animation(animationName: String):
	animatedSprite.play(animationName)

func tween_to(pos: Vector2, callback: Callable):
	if combatant.maxSize.x > 16:
		if pos.x > global_position.x:
			pos.x -= (combatant.maxSize.x - 16) / 2
		else:
			pos.x += (combatant.maxSize.x - 16) / 2
	
	if combatant.maxSize.y > 16:
		if pos.y > global_position.y:
			pos.y -= (combatant.maxSize.y - 16) / 2
		else:
			pos.y += (combatant.maxSize.y - 16) / 2
	
	if animateTween != null and animateTween.is_valid():
		animateTween.kill()
		global_position = returnToPos
	animateTween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	returnToPos = global_position
	var moveTime = pos.length() / ANIMATE_MOVE_SPEED
	if animatedSprite.animation != 'stand':
		# if there's an animation playing:
		moveTime = 0
		var fps = animatedSprite.sprite_frames.get_animation_speed(animatedSprite.animation)
		for frameIdx in range(animatedSprite.sprite_frames.get_frame_count(animatedSprite.animation)):
			# add (duration of frame / per-frame time) = amount of time to display this frame
			moveTime += animatedSprite.sprite_frames.get_frame_duration(animatedSprite.animation, frameIdx) / fps
		moveTime *= 0.5 #0.667 # half the time so the destination is reached for the latter half of the animation
		
	# move to target position
	animateTween.tween_property(self, 'global_position', pos, moveTime)
	# emit that the move was completed
	animateTween.tween_callback(_on_animate_tween_target_move_finished)
	# wait
	animateTween.tween_property(self, 'rotation', 0, 1) # will not rotate, is simply doing nothing for a beat
	# and return at a constant rate
	animateTween.tween_property(self, 'global_position', returnToPos, pos.length() / ANIMATE_MOVE_SPEED)
	animateTween.finished.connect(_on_animate_tween_finished)
	animateTween.finished.connect(callback)

func play_particles(preset: ParticlePreset, delay: bool = false):
	if preset == null or preset.count == 0:
		return
	
	var presetCopy: ParticlePreset = preset.duplicate(true)
	if leftSide: # particles are designed & saved as they would play on an enemy (right side)
		presetCopy.processMaterial.direction.x *= -1 # invert inital X emission direction
	
	if presetCopy.emitter == 'hit' and delay:
		playHitQueued = presetCopy
		return
		
	if delay:
		playParticlesQueued = presetCopy
	else:
		make_particles_now(presetCopy)

func make_particles_now(preset: ParticlePreset):
	battleController.battleUI.update_hp_tags()
	match preset.emitter:
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

func get_targetable_combatant_nodes(allCombatantNodes: Array[CombatantNode], targets: BattleCommand.Targets) -> Array[CombatantNode]:
	if targets == BattleCommand.Targets.SELF:
		return [self]
	
	var targetableList: Array[CombatantNode] = []
	for combatantNode in allCombatantNodes:
		if not combatantNode.is_alive():
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
			targetPositions = [ai_pick_single_target(chosenEffect, targetableCombatants)]
		var orbChange: int = combatant.get_orbs_change_choice(chosenEffect)
		combatant.command = BattleCommand.new(BattleCommand.Type.MOVE, chosenMove.move, chosenMove.effectType, orbChange, null, targetPositions)
	else:
		combatant.command = null

func ai_pick_move(combatantNodes: Array[CombatantNode]) -> ChosenMove:
	var pickedMove: ChosenMove = ChosenMove.new()
	var currentStats: Stats = combatant.statChanges.apply(combatant.stats)
	var randomValue: float = randf()
	tmpAllCombatantNodes = combatantNodes
	var moveCandidates: Array[Move] = combatant.stats.moves.filter(ai_filter_move_candidates)
	if len(moveCandidates) == 0: # if no moves fit the stricter criteria
		moveCandidates = combatant.stats.moves.filter(filter_out_unusable) # just don't use a strictly unusable move
	tmpAllCombatantNodes = []
	
	if combatant.aiType == Combatant.AiType.DEBUFFER and randomValue > combatant.aiOverrideWeight:
		# first, check if any opponent has no status and there's a move that can give status
		for combatantNode in combatantNodes:
			if combatantNode.role != role and combatantNode.is_alive():
				var opponentHasStatus: bool = combatantNode.combatant.statusEffect != null
				for move in moveCandidates:
					var effectType: Move.MoveEffectType = move.effects_with_status()
					if not opponentHasStatus and effectType != Move.MoveEffectType.NONE and BattleCommand.is_command_enemy_targeting(move.targets):
						if effectType != Move.MoveEffectType.SURGE or combatant.would_ai_spend_orbs(move.get_effect_of_type(effectType)):
							pickedMove.move = move
							pickedMove.effectType = effectType
							break
			if pickedMove.move != null:
				break
		# if no statusing needs to be done, pick a random move that debuffs
		if pickedMove.move == null:
			var moveChoices: Array[int] = []
			var effectTypeChoices: Array[Move.MoveEffectType] = []
			for moveIdx in range(len(moveCandidates)):
				var move: Move = moveCandidates[moveIdx]
				var moveEffects: Array[MoveEffect] = [move.chargeEffect, move.surgeEffect]
				var moveEffectTypes: Array[Move.MoveEffectType] = [Move.MoveEffectType.CHARGE, Move.MoveEffectType.SURGE]
				for moveEffIdx in range(len(moveEffects)):
					var moveEffect: MoveEffect = moveEffects[moveEffIdx]
					if BattleCommand.is_command_enemy_targeting(moveEffect.targets) and moveEffect.role == MoveEffect.Role.DEBUFF:
						moveChoices.append(moveEffect)
						effectTypeChoices.append(moveEffectTypes[moveEffIdx])
			if len(moveChoices) > 0: # 65% of the time pick a debuff
				var randIdx = randi_range(0, len(moveChoices) - 1)
				pickedMove.move = moveCandidates[moveChoices[randIdx]]
				pickedMove.effectType = effectTypeChoices[randIdx]
	
	if combatant.aiType == Combatant.AiType.BUFFER and randomValue > combatant.aiOverrideWeight:
		# if random chance > override, pick a buff
		var moveChoices: Array[int] = []
		var effectTypeChoices: Array[Move.MoveEffectType] = []
		for moveIdx in range(len(moveCandidates)):
			var move: Move = moveCandidates[moveIdx]
			var moveEffects: Array[MoveEffect] = [move.chargeEffect, move.surgeEffect]
			var moveEffectTypes: Array[Move.MoveEffectType] = [Move.MoveEffectType.CHARGE, Move.MoveEffectType.SURGE]
			for moveEffIdx in range(len(moveEffects)):
				var moveEffect: MoveEffect = moveEffects[moveEffIdx]
				var effectType: Move.MoveEffectType = moveEffectTypes[moveEffIdx]
				for combatantNode in get_targetable_combatant_nodes(combatantNodes, moveEffect.targets):
					if combatantNode.role == role and combatantNode.is_alive():
						var allyHasStatus: bool = combatantNode.combatant.statusEffect != null
						if not allyHasStatus and effectType != Move.MoveEffectType.NONE and \
								not BattleCommand.is_command_enemy_targeting(moveEffect.targets) and \
								moveEffect.role == MoveEffect.Role.BUFF:
							if effectType != Move.MoveEffectType.SURGE or combatant.would_ai_spend_orbs(moveEffect):
								moveChoices.append(moveIdx)
								effectTypeChoices.append(effectType)
		
		if len(moveChoices) > 0:
			var randIdx = randi_range(0, len(moveChoices) - 1)
			pickedMove.move = moveCandidates[moveChoices[randIdx]]
			pickedMove.effectType = effectTypeChoices[randIdx]
			
	if combatant.aiType == Combatant.AiType.SUPPORT and randomValue > combatant.aiOverrideWeight:
		# if random chance > override, pick a support/heal move
		# first, check if any allies need healing
		for combatantNode in combatantNodes:
			if combatantNode.role == role and combatantNode.is_alive():
				var needsHealing: bool = combatantNode.combatant.currentHp < roundi(combatantNode.combatant.stats.maxHp / 2.0)
				for move in moveCandidates:
					var effectType: Move.MoveEffectType = move.effects_with_role(MoveEffect.Role.HEAL)
					if needsHealing and effectType != Move.MoveEffectType.NONE:
						if effectType != Move.MoveEffectType.SURGE or combatant.would_ai_spend_orbs(move.get_effect_of_type(effectType)):
							pickedMove.move = move
							pickedMove.effectType = effectType
							break
			if pickedMove.move != null:
				break
		# otherwise, pick a random support (role == Other) move
		var moveChoices: Array[int] = []
		var effectTypeChoices: Array[Move.MoveEffectType] = []
		for moveIdx in range(len(moveCandidates)):
			var move: Move = moveCandidates[moveIdx]
			var effectType: Move.MoveEffectType = move.effects_with_role(MoveEffect.Role.OTHER)
			if effectType != Move.MoveEffectType.NONE:
				if effectType != Move.MoveEffectType.SURGE or combatant.would_ai_spend_orbs(move.get_effect_of_type(effectType)):
					moveChoices.append(moveIdx)
					moveChoices.append(effectType)
		if len(moveChoices) > 0:
			var randIdx = randi_range(0, len(moveChoices) - 1)
			pickedMove.move = moveCandidates[moveChoices[randIdx]]
			pickedMove.effectType = effectTypeChoices[randIdx]
	
	if combatant.aiType == Combatant.AiType.DAMAGE or pickedMove.move == null: # pick the absolute strongest move
		if combatant.aiType == Combatant.AiType.DAMAGE and randomValue > combatant.aiOverrideWeight:
			pickedMove.move = moveCandidates.pick_random() # if damage AI is overrided, just pick a random move
			pickedMove.effectType = Move.MoveEffectType.BOTH
		else:
			var approxMaxDmg: float = 0
			for move in moveCandidates: # for each move
				var effectTypes: Array[Move.MoveEffectType] = [Move.MoveEffectType.CHARGE, Move.MoveEffectType.SURGE]
				var effects: Array[MoveEffect] = [move.chargeEffect, move.surgeEffect]
				for effectIdx in range(len(effects)):
					var effect = effects[effectIdx]
					var effectType = effectTypes[effectIdx]
					var approxDmg: float = currentStats.get_stat_for_dmg_category(move.category) * effect.power
					if BattleCommand.is_command_multi_target(effect.targets): # if multi-targeting
						approxDmg *= len(get_targetable_combatant_nodes(combatantNodes, effect.targets)) # take into account the amount of targetable combatants
					if pickedMove.move == null or \
							(approxMaxDmg < approxDmg and BattleCommand.is_command_enemy_targeting(effect.targets)): # if this move is approx. stronger
						if effectType != Move.MoveEffectType.SURGE or combatant.would_ai_spend_orbs(move.get_effect_of_type(effectType)):
							pickedMove.move = move # pick it instead
							pickedMove.effectType = effectType
							approxMaxDmg = approxDmg
	
	if pickedMove.move == null or pickedMove.effectType == Move.MoveEffectType.NONE:
		printerr('MAJOR ERROR: ai did not find a move to use ', combatant.save_name(), ': ', battlePosition)
	
	return pickedMove

func filter_out_unusable(a) -> bool:
	if a == null:
		return false
	
	var hasAllies: bool = false
	for combatantNode in tmpAllCombatantNodes:
		if combatantNode.role == role and combatantNode.is_alive() and combatantNode != self:
			hasAllies = true
			break
	
	var numCanUse: int = 2
	for effect in [a.chargeEffect, a.surgeEffect]:
		if (not hasAllies and effect.targets == BattleCommand.Targets.NON_SELF_ALLY) or \
		effect.orbChange * -1 > combatant.orbs:
			numCanUse -= 1 # move cannot be used by the game rules
	return numCanUse > 0 # move could be used

func ai_filter_move_candidates(a: Move) -> bool:
	if a == null:
		return false
	var moveEffectType: Move.MoveEffectType = a.effects_with_status()
	var hasAllies: bool = false
	for combatantNode in tmpAllCombatantNodes:
		if combatantNode.role == role and combatantNode.is_alive() and combatantNode != self:
			hasAllies = true
			break
	if moveEffectType != Move.MoveEffectType.NONE: # if move has a status
		var moveEffects: Array[MoveEffect] = []
		if moveEffectType == Move.MoveEffectType.BOTH:
			moveEffectType = Move.MoveEffectType.SURGE
			moveEffects.append(a.get_effect_of_type(Move.MoveEffectType.CHARGE))
		moveEffects.append(a.get_effect_of_type(moveEffectType))
		var statusCanLand: bool = false
		for effect: MoveEffect in moveEffects:
			var enemyTargeting: bool = BattleCommand.is_command_enemy_targeting(effect.targets)
			if (not hasAllies and effect.targets == BattleCommand.Targets.NON_SELF_ALLY) or \
					effect.orbChange * -1 > combatant.orbs:
				# if this move is other-ally only and we don't have a valid target: don't consider it
				# or if the combatant can't pay for this version, don't consider it
				continue 
			if effect.power == 0 or (effect.power > 0 and not enemyTargeting) or (effect.power < 0 and enemyTargeting): # if move effect is purely status or deals damage to an ally to apply status/heals an enemy to apply status:
				for combatantNode in get_targetable_combatant_nodes(tmpAllCombatantNodes, effect.targets):
					if combatantNode.combatant.statusEffect == null:
						statusCanLand = true # if the combatant can be statused, it can be affected
						break
			else:
				# if the move has a secondary status-effect but primarily does heal/damage, consider it regardless
				statusCanLand = true
				break
		return statusCanLand
	var numCanUse: int = 2
	for effect in [a.chargeEffect, a.surgeEffect]:
		if (not hasAllies and effect.targets == BattleCommand.Targets.NON_SELF_ALLY) or \
		effect.orbChange * -1 > combatant.orbs:
			numCanUse -= 1 # move cannot be used by the game rules
	return numCanUse > 0 # move could be used

func ai_pick_single_target(effect: MoveEffect, targetableCombatants: Array[CombatantNode]) -> String:
	var pickedTarget: String = ''
	var randValue: float = randf()
	if (effect.role == MoveEffect.Role.SINGLE_TARGET_DAMAGE or effect.role == MoveEffect.Role.HEAL) and randValue > combatant.aiOverrideWeight:
		var minHealth: int = -1
		for combatantNode in targetableCombatants:
			if minHealth == -1 or minHealth > combatantNode.combatant.currentHp:
				minHealth = combatantNode.combatant.currentHp
				pickedTarget = combatantNode.battlePosition
	
	if effect.role == MoveEffect.Role.BUFF or effect.role == MoveEffect.Role.DEBUFF:
		var maxHealth: int = 0
		for combatantNode in targetableCombatants:
			if maxHealth < combatantNode.combatant.currentHp:
				maxHealth = combatantNode.combatant.currentHp
				pickedTarget = combatantNode.battlePosition
	
	if pickedTarget == '':
		pickedTarget = targetableCombatants.pick_random().battlePosition
	return pickedTarget

func is_alive() -> bool:
	if combatant == null:
		return false
	return not combatant.downed

func _on_select_combatant_btn_toggled(button_pressed):
	toggled.emit(button_pressed, self)

func _on_click_combatant_btn_pressed():
	print('show details for ', combatant.save_name())
	details_clicked.emit(self)

func _on_animated_sprite_animation_finished():
	animatedSprite.play('stand')
	battleController.combatant_finished_animating.emit()

func _on_animate_tween_target_move_finished():
	if battleController != null:
		battleController.combatant_finished_moving.emit()

func _combatant_finished_moving():
	if playParticlesQueued != null:
		make_particles_now(playParticlesQueued)
	playParticlesQueued = null

func _combatant_finished_animating():
	if playHitQueued != null:
		make_particles_now(playHitQueued)
	playHitQueued = null

func _on_animate_tween_finished():
	animateTween = null

func _on_hp_drain_tween_finished():
	hpDrainTween = null
