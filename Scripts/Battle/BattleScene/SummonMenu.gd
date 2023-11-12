extends Control
class_name SummonMenu

@export var battleUI: BattleUI

@onready var yesSummonBtn: Button = get_node('YesSummon')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initial_focus():
	yesSummonBtn.grab_focus()

func _on_yes_summon_pressed():
	battleUI.open_inventory(true)
	
func _on_no_summon_pressed():
	battleUI.start_pre_battle()
