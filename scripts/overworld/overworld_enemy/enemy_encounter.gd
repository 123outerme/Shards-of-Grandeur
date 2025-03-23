extends Resource
class_name EnemyEncounter

enum SpecialRules {
	NONE = 0b0000,
	NO_ITEMS = 0b0001, # inventory use is disabled
	NO_SUMMONS = 0b0010, # summoning minions is disabled
	RESTAND_ON_DEFEAT = 0b0100, # revive with full HP right where you were defeated
}

@export var combatant1: Combatant = null
@export var combatant1Weapon: Weapon = null
@export var combatant1Armor: Armor = null
@export var combatant1Accessory: Accessory = null
@export var combatant1StatAllocStrat: StatAllocationStrategy = null
@export_flags('No Items:1', 'No Summons:2', 'Restand On Defeat:4') var specialRules: int = SpecialRules.NONE
@export var winCon: WinCon = null
@export_multiline var customWinText: String = ''
@export var battleMapPath: String = ''

func _init(
	i_combatant1: Combatant = null,
	i_combatant1Weapon: Weapon = null,
	i_combatant1Armor: Armor = null,
	i_combatant1Accessory: Accessory = null,
	i_combatant1StatAllocStrat: StatAllocationStrategy = null,
	i_specialRules: int = SpecialRules.NONE,
	i_winCon: WinCon = null,
	i_customWinText: String = '',
	i_battleMap: String = '',
):
	combatant1 = i_combatant1
	combatant1Armor = i_combatant1Armor
	combatant1Weapon = i_combatant1Weapon
	combatant1Accessory = i_combatant1Accessory
	combatant1StatAllocStrat = i_combatant1StatAllocStrat
	specialRules = i_specialRules
	winCon = i_winCon
	customWinText = i_customWinText
	battleMapPath = i_battleMap

func has_special_rule(rule: SpecialRules) -> bool:
	return (specialRules & rule) != 0

func get_win_con_result(combatants: Array[CombatantNode], battleState: BattleState):
	if winCon == null:
		winCon = TotalDefeatWinCon.new()
	return winCon.get_result(combatants, battleState)
