extends Camera2D
class_name BattleUI

@export var menuState: BattleState.Menu = BattleState.Menu.SUMMON
@export var commandingMinion: bool = false

@onready var summonMenu: SummonMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Summon")
@onready var allCommands: AllCommands = get_node("BattleTextBox/TextContainer/MarginContainer/AllCommands")
@onready var results: Results = get_node("BattleTextBox/TextContainer/MarginContainer/Results")

@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")

func _ready():
	summonMenu.battleUI = self
	allCommands.battleUI = self
	results.battleUI = self

func set_menu_state(newState: BattleState.Menu):
	menuState = newState
	apply_menu_state()

func apply_menu_state():
	summonMenu.visible = menuState == BattleState.Menu.SUMMON
	allCommands.visible = menuState == BattleState.Menu.ALL_COMMANDS
	allCommands.commandingMinion = commandingMinion
	results.visible = menuState == BattleState.Menu.RESULTS

func open_inventory(forSummon: bool):
	inventoryPanel.summoning = forSummon
	if forSummon:
		inventoryPanel.lockFilters = true
		inventoryPanel.selectedFilter = Item.Type.SHARD
	inventoryPanel.toggle()

func _on_inventory_panel_node_item_used(item: Item):
	if menuState == BattleState.Menu.SUMMON:
		pass # TODO: summon
	if menuState == BattleState.Menu.ITEMS:
		if commandingMinion:
			pass # TODO: set minion command
		else:
			pass # TODO: set player command
