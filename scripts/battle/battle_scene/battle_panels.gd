extends Node2D
class_name BattlePanels

@export var battleUI: BattleUI

@onready var inventoryMenu: InventoryMenu = get_node("InventoryPanelNode")
@onready var questsMenu: QuestsMenu = get_node("QuestsPanelNode")
@onready var statsMenu: StatsMenu = get_node("StatsPanelNode")
@onready var summonMinionPanel: SummonMinionPanel = get_node("SummonMinionPanel")
@onready var pauseMenu: PauseMenu = get_node("PauseMenu")
@onready var flowOfBattle: FlowOfBattle = get_node("FlowOfBattle")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _unhandled_input(event):
	if event.is_action_pressed("game_inventory") and not pauseMenu.isPaused and (inventoryMenu.visible or battleUI.menuState == BattleState.Menu.ALL_COMMANDS):
		if battleUI.menuState == BattleState.Menu.ALL_COMMANDS or battleUI.menuState == BattleState.Menu.ITEMS:
			var newMenuState: BattleState.Menu = BattleState.Menu.ITEMS # if in all commands, go to items
			if battleUI.menuState == BattleState.Menu.ITEMS:
				newMenuState = BattleState.Menu.ALL_COMMANDS # if in items, go back to all commands
				inventoryMenu.toggle() # and turn off the menu
			battleUI.set_menu_state(newMenuState) # if all commands, menu will come up
			questsMenu.visible = false
			statsMenu.visible = false
			summonMinionPanel.visible = false

	if event.is_action_pressed("game_quests") and not pauseMenu.isPaused:
		questsMenu.toggle()
		inventoryMenu.visible = false
		statsMenu.visible = false
		summonMinionPanel.visible = false
		
	if event.is_action_pressed("game_stats") and not pauseMenu.isPaused:
		statsMenu.stats = battleUI.battleController.playerCombatant.combatant.stats
		statsMenu.curHp = battleUI.battleController.playerCombatant.combatant.currentHp
		statsMenu.readOnly = true
		statsMenu.isPlayer = true
		statsMenu.toggle()
		inventoryMenu.visible = false
		questsMenu.visible = false
		summonMinionPanel.visible = false
	
	if event.is_action_pressed("game_pause") and not inventoryMenu.visible and not questsMenu.visible and not statsMenu.visible and not summonMinionPanel.visible:
		pauseMenu.toggle_pause()

func _on_pause_menu_resume_game():
	battleUI.restore_focus()
