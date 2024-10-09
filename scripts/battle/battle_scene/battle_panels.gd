extends Node2D
class_name BattlePanels

@export var battleUI: BattleUI

@onready var animatedBgPanel: AnimatedBgPanel = get_node('AnimatedBgPanel')
@onready var inventoryMenu: InventoryMenu = get_node("InventoryPanelNode")
@onready var questsMenu: QuestsMenu = get_node("QuestsPanelNode")
@onready var statsMenu: StatsMenu = get_node("StatsPanelNode")
@onready var summonMinionPanel: SummonMinionPanel = get_node("SummonMinionPanel")
@onready var pauseMenu: PauseMenu = get_node("PauseMenu")
@onready var flowOfBattle: FlowOfBattle = get_node("FlowOfBattle")

@onready var questsOpenButton: Button = get_node('PanelsButtons/QuestsOpenButton')
@onready var statsOpenButton: Button = get_node('PanelsButtons/StatsOpenButton')
@onready var pauseButton: Button = get_node('PanelsButtons/PauseButton')

@onready var turnCounter: RichTextLabel = get_node('VBoxContainer/TurnCounterPanel/TurnCounter')

@onready var surviveCounterPanel: Panel = get_node('VBoxContainer/SurviveCounterPanel')
@onready var surviveCounter: RichTextLabel = get_node('VBoxContainer/SurviveCounterPanel/SurviveCounter')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass #pauseButton.visible = SettingsHandler.isMobile

func _unhandled_input(event):
	if event.is_action_pressed("game_inventory") and not pauseMenu.isPaused and (inventoryMenu.visible or battleUI.menuState == BattleState.Menu.ALL_COMMANDS):
		if battleUI.menuState == BattleState.Menu.ALL_COMMANDS or battleUI.menuState == BattleState.Menu.ITEMS:
			animatedBgPanel.visible = true
			var newMenuState: BattleState.Menu = BattleState.Menu.ITEMS # if in all commands, go to items
			if battleUI.menuState == BattleState.Menu.ITEMS:
				newMenuState = BattleState.Menu.ALL_COMMANDS # if in items, go back to all commands
				inventoryMenu.toggle() # and turn off the menu
			battleUI.set_menu_state(newMenuState) # if all commands, menu will come up
			questsMenu.visible = false
			statsMenu.visible = false
			summonMinionPanel.visible = false

	if event.is_action_pressed("game_quests") and not pauseMenu.isPaused and battleUI.menuState != BattleState.Menu.LEVEL_UP:
		animatedBgPanel.visible = true
		questsMenu.toggle()
		inventoryMenu.visible = false
		statsMenu.visible = false
		summonMinionPanel.visible = false
		
	if event.is_action_pressed("game_stats") and not pauseMenu.isPaused:
		statsMenu.stats = battleUI.battleController.playerCombatant.combatant.stats
		statsMenu.curHp = battleUI.battleController.playerCombatant.combatant.currentHp
		statsMenu.readOnly = true
		statsMenu.isPlayer = true
		animatedBgPanel.visible = true
		statsMenu.toggle()
		inventoryMenu.visible = false
		questsMenu.visible = false
		summonMinionPanel.visible = false
	
	if event.is_action_pressed("game_pause") and not inventoryMenu.visible and not questsMenu.visible and not statsMenu.visible and not summonMinionPanel.visible:
		animatedBgPanel.visible = true
		pauseMenu.toggle_pause()

func set_turn_counter(turnCount: int, winCon: WinCon) -> void:
	turnCounter.text = '[center]Turn ' + String.num(turnCount) + '[/center]'
	
	if winCon != null and winCon is SurviveWinCon:
		surviveCounterPanel.visible = true
		var surviveWinCon: SurviveWinCon = winCon as SurviveWinCon
		surviveCounter.text = '[center]Survive' \
				+ String.num(max(0, surviveWinCon.minTurns - turnCount)) \
				+ ' Turns![/center]'
	else:
		surviveCounterPanel.visible = false

func _on_pause_menu_resume_game():
	animatedBgPanel.visible = false
	battleUI.restore_focus()

func connect_top_left_panel_buttons_bottom_neighbor(bottomNeighbor: Control):
	questsOpenButton.focus_neighbor_bottom = questsOpenButton.get_path_to(bottomNeighbor)
	# process stats last so if quests/stats are both the same, stats is prioritized
	statsOpenButton.focus_neighbor_bottom = statsOpenButton.get_path_to(bottomNeighbor)
	pauseButton.focus_neighbor_bottom = pauseButton.get_path_to(bottomNeighbor)
	bottomNeighbor.focus_neighbor_top = bottomNeighbor.get_path_to(pauseButton)

func _on_stats_open_button_pressed():
	statsMenu.stats = battleUI.battleController.playerCombatant.combatant.stats
	statsMenu.curHp = battleUI.battleController.playerCombatant.combatant.currentHp
	statsMenu.readOnly = true
	statsMenu.isPlayer = true
	statsMenu.toggle()
	animatedBgPanel.visible = true
	inventoryMenu.visible = false
	questsMenu.visible = false
	summonMinionPanel.visible = false

func _on_quests_open_button_pressed():
	questsMenu.toggle()
	animatedBgPanel.visible = true
	inventoryMenu.visible = false
	statsMenu.visible = false
	summonMinionPanel.visible = false

func _on_pause_button_pressed():
	pauseMenu.pause_game()
	animatedBgPanel.visible = true
	inventoryMenu.visible = false
	statsMenu.visible = false
	summonMinionPanel.visible = false
	questsMenu.visible = false
