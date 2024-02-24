extends Control
class_name MovesMenu

@export var battleUI: BattleUI

@onready var backButton: Button = get_node("BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed.call_deferred()

func initial_focus():
	for i in range(4): # for all 4 buttons
		var moveBtn: Button = get_node("MoveButton" + String.num(i + 1))
		if moveBtn.text != '-----':
			moveBtn.grab_focus()
	backButton.grab_focus()

func load_moves():
	var setFocus: bool = false
	for i in range(4): # for all 4 buttons
		var moveBtn: Button = get_node("MoveButton" + String.num(i + 1))
		if i < len(battleUI.commandingCombatant.combatant.stats.moves) and battleUI.commandingCombatant.combatant.stats.moves[i] != null: # if this move slot exists
			moveBtn.text = battleUI.commandingCombatant.combatant.stats.moves[i].moveName
			moveBtn.disabled = false
			if not setFocus:
				moveBtn.grab_focus()
				setFocus = true
		else: # if the move slot doesn't exist
			moveBtn.text = '-----'
			moveBtn.disabled = true
			
	if not setFocus:
		backButton.grab_focus()

func move_click(idx: int):
	battleUI.commandingCombatant.combatant.command = BattleCommand.new(
		BattleCommand.Type.MOVE,
		battleUI.commandingCombatant.combatant.stats.moves[idx],
		null,
		[]
	)
	battleUI.set_menu_state(BattleState.Menu.PICK_TARGETS)

func _on_move_button_1_pressed():
	move_click(0)
	
func _on_move_button_2_pressed():
	move_click(1)

func _on_move_button_3_pressed():
	move_click(2)

func _on_move_button_4_pressed():
	move_click(3)

func _on_back_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.ALL_COMMANDS)
