extends Camera2D
class_name BattleUI

@export var menuState: BattleState.Menu = BattleState.Menu.SUMMON
@export var commandingMinion: bool = false
@export var battleController: BattleController

var commandingCombatant: CombatantNode = null
var prevMenu: BattleState.Menu = BattleState.Menu.SUMMON

@onready var summonMenu: SummonMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Summon")
@onready var allCommands: AllCommands = get_node("BattleTextBox/TextContainer/MarginContainer/AllCommands")
@onready var moves: MovesMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Moves")
@onready var targets: TargetsMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Targets")
@onready var results: Results = get_node("BattleTextBox/TextContainer/MarginContainer/Results")

@onready var inventoryPanel: InventoryMenu = get_node("UIPanels/InventoryPanelNode")

func _ready():
	pass
	
func set_menu_state(newState: BattleState.Menu, savePrevState: bool = true):
	if savePrevState:
		prevMenu = menuState
	menuState = newState
	commandingCombatant = battleController.minionCombatant if commandingMinion else battleController.playerCombatant
	apply_menu_state()

func apply_menu_state():
	summonMenu.visible = menuState == BattleState.Menu.SUMMON
	if prevMenu == BattleState.Menu.SUMMON: # if PREVIOUS menu was summoning, reset the filter
		inventoryPanel.selectedFilter = Item.Type.ALL
	
	allCommands.visible = menuState == BattleState.Menu.ALL_COMMANDS or menuState == BattleState.Menu.ITEMS
	if allCommands.visible:
		allCommands.commandingMinion = commandingMinion
		allCommands.commandingCombatant = commandingCombatant
		allCommands.load_all_commands()
	if menuState == BattleState.Menu.ITEMS:
		open_inventory(false)
	
	moves.visible = menuState == BattleState.Menu.MOVES
	if moves.visible:
		moves.load_moves()
	
	targets.visible = menuState == BattleState.Menu.PICK_TARGETS
	if targets.visible:
		targets.referringMenu = prevMenu
		targets.load_targets()
	
	results.visible = menuState == BattleState.Menu.RESULTS
	if results.visible:
		battleController.turnExecutor.play_turn()

func return_to_player_command():
	commandingMinion = false
	commandingCombatant = battleController.playerCombatant
	set_menu_state(BattleState.Menu.ALL_COMMANDS)

func complete_command():
	if not commandingMinion and battleController.minionCombatant.is_alive():
		commandingMinion = true
		set_menu_state(BattleState.Menu.ALL_COMMANDS)
	else:
		battleController.turnExecutor.start_simulation()
		set_menu_state(BattleState.Menu.RESULTS)

func round_complete():
	battleController.state.turnNumber += 1
	return_to_player_command()

func open_inventory(forSummon: bool):
	inventoryPanel.summoning = forSummon
	inventoryPanel.lockFilters = forSummon
	if forSummon:
		inventoryPanel.selectedFilter = Item.Type.SHARD
	inventoryPanel.toggle()

func _on_inventory_panel_node_item_used(slot: InventorySlot):
	if menuState == BattleState.Menu.SUMMON:
		PlayerResources.inventory.trash_item(slot)
		var shard = slot.item as Shard
		battleController.summon_minion(shard)
		set_menu_state(BattleState.Menu.ALL_COMMANDS)
	if menuState == BattleState.Menu.ITEMS:
		commandingCombatant.combatant.command = \
				BattleCommand.new(BattleCommand.Type.USE_ITEM, null, slot, [])
		set_menu_state(BattleState.Menu.PICK_TARGETS)
	inventoryPanel.toggle()
