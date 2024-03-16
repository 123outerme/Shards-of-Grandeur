extends Control
class_name FlowOfBattle

@export var battleController: BattleController

var battleStatsPanelScene = preload("res://prefabs/battle/battle_stats_panel.tscn")
var prevMenuControlFobBtnNeighbor: NodePath = ''

@onready var fobButton: Button = get_node("ToggleFobButton")
@onready var fobTabs: TabContainer = get_node("TabContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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
	return fobButton.disabled

func hide_fob_tabs():
	fobButton.button_pressed = false

func _on_toggle_fob_button_toggled(button_pressed: bool):
	if button_pressed:
		prevMenuControlFobBtnNeighbor = fobButton.focus_neighbor_bottom
		fobButton.focus_neighbor_bottom = ''
	
	fobTabs.visible = button_pressed
	if button_pressed:
		for node in battleController.combatantNodes:
			var combatantNode: CombatantNode = node as CombatantNode
			if combatantNode.is_alive():
				var instantiatedPanel: BattleStatsPanel = battleStatsPanelScene.instantiate()
				instantiatedPanel.combatant = combatantNode.combatant
				instantiatedPanel.battlePosition = combatantNode.battlePosition
				fobTabs.call_deferred('add_child', instantiatedPanel)
				call_deferred('_set_battle_stats_item_details_panel_pos', instantiatedPanel)
	else:
		for node in get_tree().get_nodes_in_group('BattleStatsPanel'):
			node.queue_free()
		set_fob_button_enabled(false)
		fobButton.focus_neighbor_bottom = prevMenuControlFobBtnNeighbor

func _set_battle_stats_item_details_panel_pos(panel: BattleStatsPanel):
	panel.equipmentPanel.itemDetailsPanel.position = Vector2(-662, -352)
	# NOTE: these coordinates are magic numbers to make the item details panel centered.
	# we can't center it in the Equipment Panel because that would affect the centering elsewhere
	# needs to be called deferred so the equipment panel can be @onready 'd, same for the item details panel
