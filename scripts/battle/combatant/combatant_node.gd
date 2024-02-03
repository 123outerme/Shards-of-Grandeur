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

@export_category("CombatantNode - Tree")
@export var clickCombatantBtn: TextureButton
@export var selectCombatantBtn: TextureButton
#@export var sprite: Sprite2D
@export var animatedSprite: AnimatedSprite2D
@export var hpTag: Panel
@export var lvText: RichTextLabel
@export var hpText: RichTextLabel

var tmpAllCombatantNodes: Array[CombatantNode] = []
var selectBtnNotSelectedSprite: Texture2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	selectBtnNotSelectedSprite = selectCombatantBtn.texture_normal

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
		update_hp_tag()
		clickCombatantBtn.disabled = role == Role.ENEMY # don't let the player see the raw stats/moves of enemies

func update_hp_tag():
	if not is_alive():
		visible = false
		return
	
	hpTag.visible = true
	lvText.text = 'Lv ' + String.num(combatant.stats.level)
	lvText.size.x = len(lvText.text) * 13 # about 13 pixels per character
	hpText.text = TextUtils.num_to_comma_string(combatant.currentHp) + ' / ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
	hpText.size.x = len(hpText.text) * 13 - 10 # magic number
	hpTag.size.x = (lvText.size.x + hpText.size.x) * lvText.scale.x + 8 # magic number
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
