extends Control
class_name SurgeMenu

@export var battleUI: BattleUI

var minOrbs: int = 1
var maxOrbs: int = 10

@onready var orbControl: OrbDisplay = get_node('OrbDisplay')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed.call_deferred()

func initial_focus():
	orbControl.grab_focus()

func load_surge():
	minOrbs = battleUI.commandingCombatant.combatant.command.move.surgeEffect.orbChange * -1
	maxOrbs = battleUI.commandingCombatant.combatant.orbs
	orbControl.update_orb_count(minOrbs)
	initial_focus()

func _on_confirm_button_pressed():
	battleUI.commandingCombatant.combatant.command.orbChange = orbControl.currentOrbs * -1
	battleUI.complete_command()
	
func _on_back_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.PICK_TARGETS)

func _on_orb_display_orb_count_change(change: int):
	var newCount = max(minOrbs, min(orbControl.currentOrbs + change, maxOrbs))
	orbControl.update_orb_count(newCount, newCount != orbControl.currentOrbs)
