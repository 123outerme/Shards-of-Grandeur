extends Resource
class_name WinCon

enum TurnResult {
	NOTHING = 0,
	PLAYER_WIN = 1,
	ENEMY_WIN = 2,
	ESCAPE = 3,
}

static var DEFAULT_WIN_TEXT: String = 'You won the battle!'
static var DEFAULT_LOSE_TEXT: String = 'You were defeated...'
static var DEFAULT_ESCAPE_TEXT: String = 'You escaped successfully!'

@export var winText: String = 'You won the battle!'
@export var loseText: String = 'You were defeated...'
@export var escapeText: String = 'You escaped successfully!'

func _init(
	i_winText: String = WinCon.DEFAULT_WIN_TEXT,
	i_loseText: String = WinCon.DEFAULT_LOSE_TEXT,
	i_escapeText: String = WinCon.DEFAULT_ESCAPE_TEXT
):
	winText = i_winText
	loseText = i_loseText
	escapeText = i_escapeText

func get_result(combatants: Array[CombatantNode], _battleState: BattleState) -> TurnResult:
	var alliesDown: int = 0
	var enemiesDown: int = 0
	for combatantNode in combatants:
		if not combatantNode.is_alive(): # if combatant is not alive (after being updated)
			if combatantNode.role == CombatantNode.Role.ALLY:
				alliesDown += 1 # ally down
			else:
				enemiesDown += 1 # enemy down
	if alliesDown == 2: # all allies are down:
		return WinCon.TurnResult.ENEMY_WIN
	if enemiesDown == 3: # all enemies are down:
		return WinCon.TurnResult.PLAYER_WIN
	return WinCon.TurnResult.NOTHING

func get_win_text(combatants: Array[CombatantNode]) -> String:
	return winText

func get_lose_text(combatants: Array[CombatantNode]) -> String:
	return loseText

func get_escape_text(combatants: Array[CombatantNode]) -> String:
	return escapeText
