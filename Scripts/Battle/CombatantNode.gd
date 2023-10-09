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
		var move: Move = combatant.stats.moves[0] # TODO: pick move better
		var targetableCombatants: Array[CombatantNode] = get_targetable_combatant_nodes(combatantNodes, move.targets)
		var targetPositions: Array[String] = []
		if BattleCommand.is_command_multi_target(move.targets):
			for targetableCombatant in targetableCombatants:
				targetPositions.append(targetableCombatant.battlePosition)
		else:
			targetPositions = [targetableCombatants[randi_range(0, len(targetableCombatants) - 1)].battlePosition] # pick a random target
			# TODO: pick target better
		combatant.command = BattleCommand.new(BattleCommand.Type.MOVE, move, null, targetPositions, randf())

func is_alive() -> bool:
	if combatant == null:
		return false
	return not combatant.downed

func _on_select_combatant_btn_toggled(button_pressed):
	toggled.emit(button_pressed, self)

func _on_click_combatant_btn_pressed():
	print('show details for ', combatant.save_name())
	details_clicked.emit(self)
