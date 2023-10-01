extends Control
class_name AllCommands

@export var battleUI: BattleUI
var commandingCombatant: CombatantNode = null
var commandingMinion: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_moves_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.MOVES)
	
func _on_inventory_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.ITEMS)
	
func _on_guard_button_pressed():
	commandingCombatant.combatant.command = BattleCommand.command_guard()
	battleUI.complete_command()

func _on_escape_button_pressed():
	commandingCombatant.combatant.command = BattleCommand.command_escape()
	battleUI.complete_command()
