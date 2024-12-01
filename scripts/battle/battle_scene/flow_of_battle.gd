extends Control
class_name FlowOfBattle

@export var battleController: BattleController

var battleStatsPanelScene = preload("res://prefabs/battle/battle_stats_panel.tscn")
var prevMenuControlFobBtnNeighbor: NodePath = ''

@onready var fobButton: Button = get_node("ToggleFobButton")
@onready var fobTabs: TabContainer = get_node("TabContainer")
@onready var fobShade: ColorRect = get_node('ColorRect')

var leftOfFobControl: Control = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# await one frame since this _ready() will fire before the parent UIPanels node
	await get_tree().process_frame
	if battleController.battlePanels.pauseButton.visible:
		leftOfFobControl = battleController.battlePanels.pauseButton
	else:
		leftOfFobControl = battleController.battlePanels.statsOpenButton
	fobButton.focus_neighbor_left = fobButton.get_path_to(leftOfFobControl)

func _unhandled_input(event):
	if fobTabs.visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		hide_fob_tabs.call_deferred()

func set_fob_button_enabled(enabled: bool = true):
	if not enabled:
		if battleController.battleUI.menuState == BattleState.Menu.BATTLE_COMPLETE or \
				battleController.battleUI.menuState == BattleState.Menu.LEVEL_UP:
			return # if after battle is over; don't worry about disabling the FoB button
	
	fobButton.disabled = not enabled

func get_fob_button_enabled() -> bool:
	return not fobButton.disabled

func hide_fob_tabs():
	fobButton.button_pressed = false

func connect_fob_focus_button_to(bottomNeighbor: Control):
	fobButton.focus_neighbor_bottom = fobButton.get_path_to(bottomNeighbor)
	bottomNeighbor.focus_neighbor_top = bottomNeighbor.get_path_to(fobButton)

func _on_toggle_fob_button_toggled(button_pressed: bool):
	if button_pressed and fobButton.focus_neighbor_bottom.get_concatenated_names() != '':
		prevMenuControlFobBtnNeighbor = fobButton.focus_neighbor_bottom
		fobButton.focus_neighbor_bottom = ''
		fobButton.focus_neighbor_left = '.'
	
	fobTabs.visible = button_pressed
	fobShade.visible = button_pressed
	if button_pressed:
		for node in battleController.get_all_combatant_nodes():
			var combatantNode: CombatantNode = node as CombatantNode
			if combatantNode.is_alive():
				var instantiatedPanel: BattleStatsPanel = battleStatsPanelScene.instantiate()
				instantiatedPanel.combatant = combatantNode.combatant
				instantiatedPanel.battlePosition = combatantNode.battlePosition
				instantiatedPanel.combatantNode = combatantNode
				instantiatedPanel.allCombatantNodes = battleController.get_all_combatant_nodes()
				fobTabs.call_deferred('add_child', instantiatedPanel)
				call_deferred('_set_battle_stats_item_details_panel_pos', instantiatedPanel)
	else:
		for node in get_tree().get_nodes_in_group('BattleStatsPanel'):
			node.queue_free()
		fobButton.focus_neighbor_bottom = prevMenuControlFobBtnNeighbor
		fobButton.focus_neighbor_left = fobButton.get_path_to(leftOfFobControl)
		fobButton.grab_focus.call_deferred()

func _set_battle_stats_item_details_panel_pos(panel: BattleStatsPanel):
	panel.equipmentPanel.itemDetailsPanel.position = Vector2(-662, -256)
	panel.equipmentPanel.itemDetailsPanel.z_index = 1
	panel.battleRunesPanel.set_deferred('size', Vector2(1280, 718))
	panel.battleRunesPanel.z_index = 1
	panel.battleRunesPanel.position = Vector2(-52, -155)
	# NOTE: these coordinates are magic numbers to make the item details panel centered.
	# we can't center it in the Equipment Panel because that would affect the centering elsewhere
	# needs to be called deferred so the equipment panel can be @onready 'd, same for the item details panel
