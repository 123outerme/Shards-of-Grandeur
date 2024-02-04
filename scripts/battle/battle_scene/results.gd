extends Control
class_name Results

@export var battleUI: BattleUI
var result: TurnExecutor.TurnResult = TurnExecutor.TurnResult.NOTHING
var okPressed: bool = false
var moveTweenFinished: bool = false
var moveTweenStarted: bool = false

@onready var textBoxText: RichTextLabel = get_node("TextBoxText")
@onready var okBtn: Button = get_node("OkButton")



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func initial_focus():
	okBtn.grab_focus()

func show_text(newText: String):
	textBoxText.text = newText
	battleUI.update_hp_tags()

func tween_started():
	moveTweenStarted = true

func _on_ok_button_pressed():
	if battleUI.menuState == BattleState.Menu.PRE_BATTLE or battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
		if battleUI.battleController.turnExecutor.advance_precalcd_text(): # if was final
			battleUI.advance_intermediate_state(result)
		battleUI.update_hp_tags()
		return # don't fall-through and potentially run the results code below
	
	if not moveTweenStarted or moveTweenFinished:
		okPressed = false
		moveTweenStarted = false
		moveTweenFinished = false
		if battleUI.menuState == BattleState.Menu.RESULTS:
			result = battleUI.battleController.turnExecutor.finish_turn()
			if result != TurnExecutor.TurnResult.NOTHING:
				battleUI.playerWins = result == TurnExecutor.TurnResult.PLAYER_WIN
				battleUI.escapes = result == TurnExecutor.TurnResult.ESCAPE
				battleUI.set_menu_state(BattleState.Menu.POST_ROUND)
		battleUI.update_hp_tags()
	else:
		okPressed = true

func _move_tween_finished():
	moveTweenFinished = true
	if okPressed == true:
		_on_ok_button_pressed()
