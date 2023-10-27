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
@export var sprite: Sprite2D
@export var hpTag: Panel
@export var lvText: RichTextLabel
@export var hpText: RichTextLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_combatant_node():
	if not is_alive():
		visible = false
	else:
		visible = true
		sprite.texture = combatant.sprite
		sprite.flip_h = (leftSide and not spriteFacesRight) or (not leftSide and spriteFacesRight)
		update_hp_tag()
		update_select_btn(false)
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
		hpTag.position = Vector2(-1 * hpTag.size.x - selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)
	else:
		hpTag.position = Vector2(selectCombatantBtn.size.x * 0.5, -0.5 * hpTag.size.y)

func update_select_btn(showing: bool, disable: bool = false):
	if not is_alive():
		return
		
	selectCombatantBtn.visible = showing
	selectCombatantBtn.disabled = disable
	selectCombatantBtn.size = combatant.sprite.get_size() + Vector2(4, 4) # set size of selecting button to sprite size + 4px
	selectCombatantBtn.position = -0.5 * selectCombatantBtn.size # center button

func set_selected(selected: bool = true):
	selectCombatantBtn.button_pressed = selected
	
func is_selected() -> bool:
	return selectCombatantBtn.button_pressed

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
	
	if combatant.aiType == Combatant.AiType.DEBUFFER and randomValue > combatant.aiOverrideWeight:
		# first, check if any opponent has no status and there's a move that can give status
		for combatantNode in combatantNodes:
			if combatantNode.role != role:
				var opponentHasStatus: bool = combatantNode.combatant.statusEffect != null
				for move in combatant.stats.moves:
					if not opponentHasStatus and move.statusEffect != null and BattleCommand.is_command_enemy_targeting(move.targets):
						pickedMove = move
						break
			if pickedMove != null:
				break
		# if no statusing needs to be done, potentially pick a random move that debuffs
		if pickedMove == null:
			var moveChoices: Array[int] = []
			for moveIdx in range(len(combatant.stats.moves)):
				var move: Move = combatant.stats.moves[moveIdx]
				if BattleCommand.is_command_enemy_targeting(move.targets) and move.role == Move.Role.DEBUFF:
					moveChoices.append(moveIdx)
			if len(moveChoices) > 0 and randomValue > combatant.aiOverrideWeight: # 65% of the time pick a debuff
				pickedMove = combatant.stats.moves[moveChoices.pick_random()]
	
	if combatant.aiType == Combatant.AiType.BUFFER and randomValue > combatant.aiOverrideWeight:
		# 65% of the time, pick a buff
		var moveChoices: Array[int] = []
		for moveIdx in range(len(combatant.stats.moves)):
			var move: Move = combatant.stats.moves[moveIdx]
			if not BattleCommand.is_command_enemy_targeting(move.targets) and move.role == Move.Role.BUFF:
				moveChoices.append(moveIdx)
		if len(moveChoices) > 0:
			pickedMove = combatant.stats.moves[moveChoices.pick_random()]
			
	if combatant.aiType == Combatant.AiType.SUPPORT and randomValue > combatant.aiOverrideWeight:
		# 65% of the time, pick a support/heal move
		var moveChoices: Array[int] = []
		for moveIdx in range(len(combatant.stats.moves)):
			var move: Move = combatant.stats.moves[moveIdx]
			if (not BattleCommand.is_command_enemy_targeting(move.targets) and move.role == Move.Role.HEAL) or move.role == Move.Role.OTHER:
				moveChoices.append(moveIdx)
		if len(moveChoices) > 0:
			pickedMove = combatant.stats.moves[moveChoices.pick_random()]
	
	if combatant.aiType == Combatant.AiType.DAMAGE or pickedMove == null: # pick the absolute strongest move
		if combatant.aiType == Combatant.AiType.DAMAGE and randomValue > combatant.aiOverrideWeight:
			pickedMove = combatant.stats.moves.pick_random() # if damage AI is overrided, just pick a random move
		else:
			var approxMaxDmg: float = 0
			for move in combatant.stats.moves: # for each move	
				if move != null:
					var approxDmg: float = currentStats.get_stat_for_dmg_category(move.category) * move.power
					# TODO maybe take into account AOE moves hitting multiple targets?
					if pickedMove == null or \
							(approxMaxDmg < approxDmg and BattleCommand.is_command_enemy_targeting(move.targets)): # if this move is approx. stronger
						pickedMove = move # pick it instead
	
	return pickedMove

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
