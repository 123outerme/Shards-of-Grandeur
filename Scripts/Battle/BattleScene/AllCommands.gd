extends Control
class_name AllCommands

@export var battleUI: BattleUI
var commandingCombatant: CombatantNode = null
var commandingMinion: bool = false

@onready var commandLabel: RichTextLabel = get_node("CommandLabel")
@onready var backToPlayerCmdBtn: Button = get_node("BackToPlayerButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func load_all_commands():
	backToPlayerCmdBtn.visible = commandingMinion
	commandLabel.text = '[center]Command ' + commandingCombatant.combatant.stats.displayName + '[/center]'

func _on_moves_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.MOVES)
	
func _on_inventory_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.ITEMS)
	
func _on_guard_button_pressed():
	commandingCombatant.combatant.command = BattleCommand.command_guard(commandingCombatant)
	battleUI.complete_command()

func _on_escape_button_pressed():
	var allCombatants: Array[CombatantNode] = battleUI.battleController.get_all_combatant_nodes()
	
	commandingCombatant.combatant.command = BattleCommand.command_escape(commandingCombatant, allCombatants)
	battleUI.complete_command()

func _on_back_to_player_button_pressed():
	battleUI.return_to_player_command()
