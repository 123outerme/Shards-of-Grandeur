extends Node2D

@export var battleUI: BattleUI

@onready var inventoryMenu: InventoryMenu = get_node("InventoryPanelNode")
@onready var questsMenu: QuestsMenu = get_node("QuestsPanelNode")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _unhandled_input(event):
	if event.is_action_pressed("game_inventory") and (inventoryMenu.visible or battleUI.menuState == BattleState.Menu.ALL_COMMANDS):
		if battleUI.menuState == BattleState.Menu.ALL_COMMANDS or battleUI.menuState == BattleState.Menu.ITEMS:
			var newMenuState: BattleState.Menu = BattleState.Menu.ITEMS # if in all commands, go to items
			if battleUI.menuState == BattleState.Menu.ITEMS:
				newMenuState = BattleState.Menu.ALL_COMMANDS # if in items, go back to all commands
				inventoryMenu.toggle() # and turn off the menu
			battleUI.set_menu_state(newMenuState) # if all commands, menu will come up

	if event.is_action_pressed("game_quests"):
		questsMenu.toggle()
