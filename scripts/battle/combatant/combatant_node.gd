extends Node2D
class_name CombatantNode

enum Role {
	ALLY = 0,
	ENEMY = 1
}

signal toggled(button_pressed: bool, combatantNode: CombatantNode)
signal details_clicked(combatantNode: CombatantNode)

@export_category("CombatantNode - Details")
@export var combatant: Combatant = null
@export var initialCombatantLv: int = 1
@export var role: Role = Role.ALLY
@export var leftSide: bool = false
@export var spriteFacesRight: bool = false
@export var battlePosition: String = ''

@export_category("CombatantNode - SFX")
@export var hitSfx: AudioStream = null
@export var physAtkSfx: AudioStream = null
@export var magicAtkSfx: AudioStream = null
@export var affinitySfx: AudioStream = null
@export var shardSfx: AudioStream = null

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
var playHitQueued: bool = false
var playPhysQueued: bool = false

@onready var hpTag: Panel = get_node('HPTag')
@onready var lvText: RichTextLabel = get_node('HPTag/LvText')
@onready var hpText: RichTextLabel = get_node('HPTag/LvText/HPText')
@onready var hpProgressBar: TextureProgressBar = get_node('HPTag/LvText/HPProgressBar')
@onready var animatedSprite: AnimatedSprite2D = get_node('AnimatedSprite')
@onready var clickCombatantBtn: TextureButton = get_node('ClickCombatantBtn')
@onready var selectCombatantBtn: TextureButton = get_node('SelectCombatantBtn')
@onready var behindParticleContainer: Node2D = get_node('BehindParticleContainer')
@onready var affinityParticles: Particles = get_node('BehindParticleContainer/AffinityParticles')
@onready var magicParticles: Particles = get_node('BehindParticleContainer/MagicParticles')
@onready var frontParticleContainer: Node2D = get_node('FrontParticleContainer')
@onready var hitParticles: Particles = get_node('FrontParticleContainer/HitParticles')
@onready var physParticles: Particles = get_node('FrontParticleContainer/PhysicalParticles')
@onready var shardParticles: Particles = get_node('FrontParticleContainer/ShardParticles')
@onready var onAttackMarker: Marker2D = get_node('OnAttackPos')
@onready var onAssistMarker: Marker2D = get_node('OnAssistPos')

# Called when the node enters the scene tree for the first time.
func _ready():
	selectBtnNotSelectedSprite = selectCombatantBtn.texture_normal
	returnToPos = global_position
	if battleController != null:
		battleController.combatant_finished_moving.connect(_combatant_finished_moving)

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
		affinityParticles.set_make_particles(false)
		magicParticles.set_make_particles(false)
		hitParticles.set_make_particles(false)
		physParticles.set_make_particles(false)
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

func update_select_btn(showing: bool, disable: bool = false):
	if not is_alive():
		return
		
	selectCombatantBtn.visible = showing
	selectCombatantBtn.disabled = disable
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
	var finalPos = pos
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

func play_particles(preset: ParticlePreset):
	if preset.count == 0:
		return
	
	match preset.type:
		'affinity':
			affinityParticles.set_num_particles(preset.count)
			affinityParticles.set_make_particles(true)
			SceneLoader.audioHandler.play_sfx(affinitySfx)
		'magic':
			magicParticles.set_num_particles(preset.count)
			magicParticles.set_make_particles(true)
			SceneLoader.audioHandler.play_sfx(magicAtkSfx)
		'phys':
			physParticles.set_num_particles(preset.count)
			playPhysQueued = true
		'hit':
			hitParticles.set_num_particles(preset.count)
			playHitQueued = true
		'shard':
			shardParticles.set_num_particles(preset.count)
			shardParticles.set_make_particles(true)
			SceneLoader.audioHandler.play_sfx(shardSfx)

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
		var move: Move = ai_pick_move(combatantNodes)
		var targetableCombatants: Array[CombatantNode] = get_targetable_combatant_nodes(combatantNodes, move.targets)
		var targetPositions: Array[String] = []
		if BattleCommand.is_command_multi_target(move.targets):
			for targetableCombatant in targetableCombatants:
				targetPositions.append(targetableCombatant.battlePosition)
		else:
			targetPositions = [ai_pick_single_target(move, targetableCombatants)]
		combatant.command = BattleCommand.new(BattleCommand.Type.MOVE, move, null, targetPositions)

func ai_pick_move(combatantNodes: Array[CombatantNode]) -> Move:
	var pickedMove: Move = null
	var currentStats: Stats = combatant.statChanges.apply(combatant.stats)
	var randomValue: float = randf()
	tmpAllCombatantNodes = combatantNodes
	var moveCandidates: Array[Move] = combatant.stats.moves.filter(ai_filter_move_candidates)
	tmpAllCombatantNodes = []
	if len(moveCandidates) == 0: # if no moves fit the stricter criteria
		moveCandidates = combatant.stats.moves.filter(filter_out_null) # just don't use a null move
	
	if combatant.aiType == Combatant.AiType.DEBUFFER and randomValue > combatant.aiOverrideWeight:
		# first, check if any opponent has no status and there's a move that can give status
		for combatantNode in combatantNodes:
			if combatantNode.role != role and combatantNode.is_alive():
				var opponentHasStatus: bool = combatantNode.combatant.statusEffect != null
				for move in moveCandidates:
					if not opponentHasStatus and move.statusEffect != null and BattleCommand.is_command_enemy_targeting(move.targets):
						pickedMove = move
						break
			if pickedMove != null:
				break
		# if no statusing needs to be done, pick a random move that debuffs
		if pickedMove == null:
			var moveChoices: Array[int] = []
			for moveIdx in range(len(moveCandidates)):
				var move: Move = moveCandidates[moveIdx]
				if BattleCommand.is_command_enemy_targeting(move.targets) and move.role == Move.Role.DEBUFF:
					moveChoices.append(moveIdx)
			if len(moveChoices) > 0 and randomValue > combatant.aiOverrideWeight: # 65% of the time pick a debuff
				pickedMove = moveCandidates[moveChoices.pick_random()]
	
	if combatant.aiType == Combatant.AiType.BUFFER and randomValue > combatant.aiOverrideWeight:
		# if random chance > override, pick a buff
		var moveChoices: Array[int] = []
		for moveIdx in range(len(moveCandidates)):
			var move: Move = moveCandidates[moveIdx]
			for combatantNode in get_targetable_combatant_nodes(combatantNodes, move.targets):
				if combatantNode.role == role and combatantNode.is_alive():
					var allyHasStatus: bool = combatantNode.combatant.statusEffect != null
					if not allyHasStatus and move.statusEffect != null and \
							not BattleCommand.is_command_enemy_targeting(move.targets) and \
							move.role == Move.Role.BUFF:
						moveChoices.append(moveIdx)
		
		if len(moveChoices) > 0:
			pickedMove = moveCandidates[moveChoices.pick_random()]
			
	if combatant.aiType == Combatant.AiType.SUPPORT and randomValue > combatant.aiOverrideWeight:
		# if random chance > override, pick a support/heal move
		# first, check if any allies need healing
		for combatantNode in combatantNodes:
			if combatantNode.role == role and combatantNode.is_alive():
				var needsHealing: bool = combatantNode.combatant.currentHp < roundi(combatantNode.combatant.stats.maxHp / 2.0)
				for move in moveCandidates:
					if needsHealing and move.power < 0 and BattleCommand.is_command_enemy_targeting(move.targets) and move.role == Move.Role.HEAL:
						pickedMove = move
						break
			if pickedMove != null:
				break
		# otherwise, pick a random support (role == Other) move
		var moveChoices: Array[int] = []
		for moveIdx in range(len(moveCandidates)):
			var move: Move = moveCandidates[moveIdx]
			if move.role == Move.Role.OTHER:
				moveChoices.append(moveIdx)
		if len(moveChoices) > 0:
			pickedMove = moveCandidates[moveChoices.pick_random()]
	
	if combatant.aiType == Combatant.AiType.DAMAGE or pickedMove == null: # pick the absolute strongest move
		if combatant.aiType == Combatant.AiType.DAMAGE and randomValue > combatant.aiOverrideWeight:
			pickedMove = moveCandidates.pick_random() # if damage AI is overrided, just pick a random move
		else:
			var approxMaxDmg: float = 0
			for move in moveCandidates: # for each move
				var approxDmg: float = currentStats.get_stat_for_dmg_category(move.category) * move.power
				if BattleCommand.is_command_multi_target(move.targets): # if multi-targeting
					approxDmg *= len(get_targetable_combatant_nodes(combatantNodes, move.targets)) # take into account the amount of targetable combatants
				if pickedMove == null or \
						(approxMaxDmg < approxDmg and BattleCommand.is_command_enemy_targeting(move.targets)): # if this move is approx. stronger
					pickedMove = move # pick it instead
	
	return pickedMove

func filter_out_null(a) -> bool:
	return a != null

func ai_filter_move_candidates(a: Move) -> bool:
	if a == null:
		return false
	if a.statusEffect != null: # if move has a status
		var enemyTargeting: bool = BattleCommand.is_command_enemy_targeting(a.targets)
		if a.power == 0 or (a.power > 0 and not enemyTargeting) or (a.power < 0 and enemyTargeting): # if move is purely status or deals damage to an ally to apply status/heals an enemy to apply status:
			var affects: bool = false
			for combatantNode in get_targetable_combatant_nodes(tmpAllCombatantNodes, a.targets):
				if combatantNode.combatant.statusEffect == null:
					affects = true # if the combatant can be statused, it can be affected
					break
			return affects
	return true

func ai_pick_single_target(move: Move, targetableCombatants: Array[CombatantNode]) -> String:
	var pickedTarget: String = ''
	var randValue: float = randf()
	if (move.role == Move.Role.SINGLE_TARGET_DAMAGE or move.role == Move.Role.HEAL) and randValue > combatant.aiOverrideWeight:
		var minHealth: int = -1
		for combatantNode in targetableCombatants:
			if minHealth == -1 or minHealth > combatantNode.combatant.currentHp:
				minHealth = combatantNode.combatant.currentHp
				pickedTarget = combatantNode.battlePosition
	
	if move.role == Move.Role.BUFF or move.role == Move.Role.DEBUFF:
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

func _on_animate_tween_target_move_finished():
	if battleController != null:
		battleController.combatant_finished_moving.emit()

func _combatant_finished_moving():
	if playHitQueued:
		hitParticles.set_make_particles(true)
		SceneLoader.audioHandler.play_sfx(hitSfx)
	if playPhysQueued:
		physParticles.set_make_particles(true)
		SceneLoader.audioHandler.play_sfx(physAtkSfx)
	playHitQueued = false
	playPhysQueued = false

func _on_animate_tween_finished():
	animateTween = null

func _on_hp_drain_tween_finished():
	hpDrainTween = null
