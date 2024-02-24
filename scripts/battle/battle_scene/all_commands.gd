extends Control
class_name AllCommands

@export var battleUI: BattleUI
var commandingCombatant: CombatantNode = null
var commandingMinion: bool = false

@onready var commandLabel: RichTextLabel = get_node("CommandLabel")
@onready var movesBtn: Button = get_node("MovesButton")
@onready var inventoryBtn: Button = get_node("InventoryButton")
@onready var backToPlayerCmdBtn: Button = get_node("BackToPlayerButton")
@onready var escapeButton: Button = get_node("EscapeButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	if PlayerResources.playerInfo.staticEncounter != null:
		escapeButton.disabled = not PlayerResources.playerInfo.staticEncounter.canEscape

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and backToPlayerCmdBtn.visible:
		get_viewport().set_input_as_handled()
		_on_back_to_player_button_pressed.call_deferred()

func load_all_commands():
	backToPlayerCmdBtn.visible = commandingMinion and battleUI.battleController.playerCombatant.is_alive()
	commandLabel.text = '[center]Command ' + commandingCombatant.combatant.disp_name() + '[/center]'
	initial_focus()
	
func initial_focus():
	movesBtn.grab_focus()

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
