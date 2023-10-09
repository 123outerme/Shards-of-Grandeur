extends Node2D
class_name BattlePanels

@export var battleUI: BattleUI

@onready var inventoryMenu: InventoryMenu = get_node("InventoryPanelNode")
var inventoryWasVisible: bool = false
@onready var questsMenu: QuestsMenu = get_node("QuestsPanelNode")
var questsWereVisible: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _unhandled_input(event):
	if event.is_action_pressed("game_inventory") and (inventoryMenu.visible or battleUI.menuState == BattleState.Menu.ALL_COMMANDS or battleUI.menuState == BattleState.Menu.SUMMON):			
		if battleUI.menuState == BattleState.Menu.ALL_COMMANDS or battleUI.menuState == BattleState.Menu.ITEMS:
			var newMenuState: BattleState.Menu = BattleState.Menu.ITEMS # if in all commands, go to items
			if battleUI.menuState == BattleState.Menu.ITEMS:
				newMenuState = BattleState.Menu.ALL_COMMANDS # if in items, go back to all commands
				inventoryMenu.toggle() # and turn off the menu
			battleUI.set_menu_state(newMenuState) # if all commands, menu will come up
		elif battleUI.menuState == BattleState.Menu.SUMMON:
			if not inventoryMenu.visible:
				battleUI.open_inventory(true)
			else:
				inventoryMenu.toggle()
		questsMenu.visible = false

	if event.is_action_pressed("game_quests"):
		questsMenu.toggle()
		inventoryMenu.visible = false
