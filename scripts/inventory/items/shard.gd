extends Item
class_name Shard

@export var combatantSaveName: String = ''

func _init(
	i_sprite = null,
	i_name = "",
	i_type = Type.SHARD,
	i_itemDescription = "",
	i_cost = 0,
	i_maxCount = 5,
	i_usable = true,
	i_battleUsable = true,
	i_consumable = true,
	i_equippable = false,
	i_targets = BattleCommand.Targets.NONE,
	i_combatantSaveName = '',
):
	super._init(i_sprite, i_name, i_type, i_itemDescription, i_cost, i_maxCount, i_usable, i_battleUsable, i_consumable, i_equippable, i_targets)
	combatantSaveName = i_combatantSaveName

func use(_target: Combatant):
	pass # all using of Shard handled in Player/Battle scenes

func get_combatant() -> Combatant:
	return Combatant.load_combatant_resource(combatantSaveName)

func get_use_message(_target: Combatant) -> String:
	return ''

func get_effect_text() -> String:
	return 'Use to Learn a Move ' + get_combatant().disp_name() + ' Knows, or Use in Battle to Summon!'
