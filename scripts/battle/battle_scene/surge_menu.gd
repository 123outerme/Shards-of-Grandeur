extends Control
class_name SurgeMenu

@export var battleUI: BattleUI

@onready var orbControl: OrbDisplay = get_node('OrbDisplay')
@onready var surgeChangesText: RichTextLabel = get_node('SurgeChangesText')
@onready var confirmButton: Button = get_node('ConfirmButton')
@onready var backButton: Button = get_node('BackButton')

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
	orbControl.minOrbs = max(0, battleUI.commandingCombatant.combatant.command.move.surgeEffect.orbChange * -1)
	orbControl.maxOrbs = 10
	#orbControl.maxOrbs = min(10, battleUI.commandingCombatant.combatant.orbs)
	orbControl.update_orb_count(orbControl.minOrbs, false)
	_on_orb_display_orb_count_change(orbControl.minOrbs)
	initial_focus()

func _on_confirm_button_pressed():
	battleUI.commandingCombatant.combatant.command.orbChange = orbControl.currentOrbs * -1
	battleUI.complete_command()
	for cNode in battleUI.battleController.get_all_combatant_nodes():
		if cNode.is_alive():
			cNode.update_select_btn(false)
	
func _on_back_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.PICK_TARGETS, false)

func _on_orb_display_orb_count_change(change: int):
	if change > min(10, battleUI.commandingCombatant.combatant.orbs):
		confirmButton.disabled = true
	else:
		confirmButton.disabled = false
	var effectTexts: Array[String] = battleUI.commandingCombatant.combatant.command.move.surgeEffect.apply_surge_changes(change).get_short_description(battleUI.commandingCombatant.combatant.command.move.element)
	surgeChangesText.text = '[center]'
	for text in effectTexts:
		surgeChangesText.text += TextUtils.rich_text_substitute(text, Vector2i(32, 32)) + '\n'
	surgeChangesText.text += '[/center]'
	'''
	var changesText: Array[String] = battleUI.commandingCombatant.combatant.command.move.surgeEffect.get_changes_description(change)
	if len(changesText) > 0:
		surgeChangesText.text = '[center]Surge Changes:\n'
		for changeText in changesText:
			surgeChangesText.text += changeText + '\n'
		surgeChangesText.text += '[/center]'
	else:
		surgeChangesText.text = ''
	'''
