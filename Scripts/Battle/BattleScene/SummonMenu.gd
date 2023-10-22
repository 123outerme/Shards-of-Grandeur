extends Control
class_name SummonMenu

@export var battleUI: BattleUI

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_yes_summon_pressed():
	battleUI.open_inventory(true)
	
func _on_no_summon_pressed():
	battleUI.set_menu_state(BattleState.Menu.PRE_BATTLE)
