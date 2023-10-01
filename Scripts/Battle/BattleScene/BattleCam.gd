extends Camera2D
class_name BattleUI

@export var menuState: BattleState.Menu = BattleState.Menu.SUMMON
@export var commandingMinion: bool = false
@export var battleController: BattleController

@onready var summonMenu: SummonMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Summon")
@onready var allCommands: AllCommands = get_node("BattleTextBox/TextContainer/MarginContainer/AllCommands")
@onready var moves: Control = get_node("BattleTextBox/TextContainer/MarginContainer/Moves")
@onready var results: Results = get_node("BattleTextBox/TextContainer/MarginContainer/Results")

@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")

func _ready():
	pass
	
func set_menu_state(newState: BattleState.Menu):
	menuState = newState
	apply_menu_state()

func apply_menu_state():
	summonMenu.visible = menuState == BattleState.Menu.SUMMON
	
	allCommands.visible = menuState == BattleState.Menu.ALL_COMMANDS or menuState == BattleState.Menu.ITEMS
	if allCommands.visible:
		allCommands.commandingMinion = commandingMinion
		allCommands.commandingCombatant = battleController.playerCombatant if commandingMinion else battleController.minionCombatant
		allCommands.load_all_commands()
	if menuState == BattleState.Menu.ITEMS:
		open_inventory(false)
	
	moves.visible = menuState == BattleState.Menu.MOVES
	
	results.visible = menuState == BattleState.Menu.RESULTS

func complete_command():
	if not commandingMinion and battleController.minionCombatant.minion != null and battleController.minionCombatant.is_alive():
		commandingMinion = true
		set_menu_state(BattleState.Menu.ALL_COMMANDS)
	else:
		set_menu_state(BattleState.Menu.RESULTS)

func open_inventory(forSummon: bool):
	inventoryPanel.summoning = forSummon
	if forSummon:
		inventoryPanel.lockFilters = true
		inventoryPanel.selectedFilter = Item.Type.SHARD
	inventoryPanel.toggle()

func _on_inventory_panel_node_item_used(slot: InventorySlot):
	if menuState == BattleState.Menu.SUMMON:
		PlayerResources.inventory.trash_item(slot)
		var shard = slot.item as Shard
		battleController.summon_minion(shard)
		set_menu_state(BattleState.Menu.ALL_COMMANDS)
	if menuState == BattleState.Menu.ITEMS:
		if commandingMinion:
			battleController.minionCombatant.combatant.command = \
					BattleCommand.new(BattleCommand.Type.USE_ITEM, null, slot, [])
		else:
			pass # TODO: set player command
		set_menu_state(BattleState.Menu.PICK_TARGETS)
	inventoryPanel.toggle()
