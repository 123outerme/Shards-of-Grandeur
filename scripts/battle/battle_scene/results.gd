extends Control
class_name Results

@export var battleUI: BattleUI
var result: WinCon.TurnResult = WinCon.TurnResult.NOTHING
var okPressed: bool = false
var moveTweenFinished: bool = false
var moveTweenStarted: bool = false

var ignoreOkPressed: bool = false

@onready var textBoxText: RichTextLabel = get_node("TextBoxText")
@onready var okBtn: Button = get_node("OkButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	textBoxText.text = '' # clear editor testing text

func initial_focus():
	okBtn.grab_focus()

func show_text(newText: String):
	textBoxText.text = TextUtils.rich_text_substitute(newText, Vector2i(32, 32))
	ignoreOkPressed = false

func tween_started():
	moveTweenStarted = true

func _on_ok_button_pressed(queued: bool = false) -> void:
	if ignoreOkPressed:
		return
	
	ignoreOkPressed = true
	if battleUI.menuState == BattleState.Menu.PRE_BATTLE or battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
		# if no win has been determined yet, check on this post-battle results display step
		if result == WinCon.TurnResult.NOTHING and battleUI.menuState == BattleState.Menu.POST_ROUND:
			result = PlayerResources.playerInfo.encounter.get_win_con_result(battleUI.battleController.get_all_combatant_nodes(), battleUI.battleController.state)
			update_battle_ui_with_results()
		if battleUI.battleController.turnExecutor.advance_precalcd_text(): # if was final
			battleUI.advance_intermediate_state(result)
		return # don't fall-through and potentially run the results code below
	
	if not moveTweenStarted or moveTweenFinished:
		okPressed = false
		okBtn.disabled = false
		moveTweenStarted = false
		moveTweenFinished = false
		
		if battleUI.menuState == BattleState.Menu.RESULTS:
			# update HP tags just to be safe, in case we missed any updates
			battleUI.update_hp_tags() # TODO: I think this can be taken out?
			
			# wait one frame to ensure that all emitted signals related to animations have been emitted
			await get_tree().process_frame
			
			# if the OK press was queued: we didn't yet tween the battlefield shade up, so we need to reset these things manually
			if queued:
				if battleUI.battleController.turnExecutor.is_on_last_turn():
					battleUI.battleController.modulate_battlefield_shade_to(Color(0, 0, 0, 0), 0.25)
				else:
					battleUI.battleController.reset_all_combatants_shade_z_indices()
			result = battleUI.battleController.turnExecutor.finish_turn()
			
			update_battle_ui_with_results()
			if result != WinCon.TurnResult.NOTHING:
				battleUI.set_menu_state(BattleState.Menu.POST_ROUND)
	else:
		okPressed = true
		okBtn.disabled = true

func update_battle_ui_with_results():
	if result != WinCon.TurnResult.NOTHING:
		battleUI.playerWins = result == WinCon.TurnResult.PLAYER_WIN
		battleUI.escapes = result == WinCon.TurnResult.ESCAPE

func _move_tween_finished():
	if not moveTweenStarted:
		return
	moveTweenFinished = true
	if okPressed == true:
		ignoreOkPressed = false
		_on_ok_button_pressed(true)
	else:
		battleUI.battleController.modulate_battlefield_shade_to(Color(0, 0, 0, 0), 0.25)
