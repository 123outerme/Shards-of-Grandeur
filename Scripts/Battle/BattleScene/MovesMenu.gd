extends Control
class_name MovesMenu

@export var battleUI: BattleUI

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_moves():
	for i in range(4): # for all 4 buttons
		var moveBtn: Button = get_node("MoveButton" + String.num(i + 1))
		if i < len(battleUI.commandingCombatant.combatant.stats.moves): # if this move slot exists
			moveBtn.text = battleUI.commandingCombatant.combatant.stats.moves[i].moveName
			moveBtn.disabled = false
		else: # if the move slot doesn't exist
			moveBtn.text = '-----'
			moveBtn.disabled = true

func move_click(idx: int):
	battleUI.commandingCombatant.combatant.command = BattleCommand.new(
		BattleCommand.Type.MOVE,
		battleUI.commandingCombatant.combatant.stats.moves[idx],
		null,
		[]
	)
	battleUI.set_menu_state(BattleState.Menu.PICK_TARGETS)

func _on_move_button_1_pressed():
	move_click(0)
	
func _on_move_button_2_pressed():
	move_click(1)

func _on_move_button_3_pressed():
	move_click(2)

func _on_move_button_4_pressed():
	move_click(3)

func _on_back_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.ALL_COMMANDS)
