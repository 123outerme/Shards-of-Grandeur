extends Resource
class_name EnemyEncounter

enum SpecialRules {
	NONE = 0b0000,
	NO_ITEMS = 0b0001, # inventory use is disabled
	NO_SUMMONS = 0b0010,
	RESTAND_ON_DEFEAT = 0b0100, # revive with full HP right where you were defeated
}

@export var combatant1: Combatant = null
@export_flags('No Items:1', 'No Summons:2', 'Restand On Defeat:4') var specialRules: int = SpecialRules.NONE
@export var winCon: WinCon = null
@export_multiline var customWinText: String = ''

func _init(
	i_combatant1 = null,
	i_specialRules = SpecialRules.NONE,
	i_winCon = null,
	i_customWinText = '',
):
	combatant1 = i_combatant1
	specialRules = i_specialRules
	winCon = i_winCon
	customWinText = i_customWinText

func has_special_rule(rule: SpecialRules) -> bool:
	return (specialRules & rule) != 0

func get_win_con_result(combatants: Array[CombatantNode], battleState: BattleState):
	if winCon == null:
		winCon = TotalDefeatWinCon.new()
	return winCon.get_result(combatants, battleState)
