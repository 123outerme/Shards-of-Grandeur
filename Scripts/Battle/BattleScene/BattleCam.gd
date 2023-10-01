extends Camera2D
class_name BattleUI

@export var menuState: BattleState.Menu = BattleState.Menu.SUMMON
@export var commandingMinion: bool = false

@onready var summonMenu: SummonMenu = get_node("BattleTextBox/TextContainer/MarginContainer/Summon")
@onready var allCommands: AllCommands = get_node("BattleTextBox/TextContainer/MarginContainer/AllCommands")
@onready var textBoxText: RichTextLabel = get_node("BattleTextBox/TextContainer/MarginContainer/TextBoxText")

@onready var inventoryPanel: InventoryMenu = get_node("UI/InventoryPanelNode")

func _ready():
	summonMenu.battleUI = self
	allCommands.battleUI = self

func set_menu_state(newState: BattleState.Menu):
	menuState = newState
	apply_menu_state()

func apply_menu_state():
	summonMenu.visible = menuState == BattleState.Menu.SUMMON
	allCommands.visible = menuState == BattleState.Menu.ALL_COMMANDS
	allCommands.commandingMinion = commandingMinion
	textBoxText.visible = menuState == BattleState.Menu.RESULTS

func open_inventory(forSummon: bool):
	inventoryPanel.toggle()
