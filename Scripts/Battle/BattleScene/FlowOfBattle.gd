extends Control
class_name FlowOfBattle

@export var battleController: BattleController

var battleStatsPanelScene = preload("res://Prefabs/Battle/BattleStatsPanel.tscn")

@onready var fobTabs: TabContainer = get_node("TabContainer")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_toggle_fob_button_toggled(button_pressed: bool):
	fobTabs.visible = button_pressed
	if button_pressed:
		for node in battleController.combatantNodes:
			var combatantNode: CombatantNode = node as CombatantNode
			if combatantNode.is_alive():
				var instantiatedPanel: BattleStatsPanel = battleStatsPanelScene.instantiate()
				instantiatedPanel.combatant = combatantNode.combatant
				instantiatedPanel.battlePosition = combatantNode.battlePosition
				fobTabs.call_deferred('add_child', instantiatedPanel)
	else:
		for node in get_tree().get_nodes_in_group('BattleStatsPanel'):
			node.queue_free()
