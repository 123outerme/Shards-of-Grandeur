extends Control
class_name Results

@export var battleUI: BattleUI

@onready var textBoxText: RichTextLabel = get_node("TextBoxText")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_text(newText: String):
	textBoxText.text = newText

func _on_ok_button_pressed():
	var result: TurnExecutor.TurnResult = battleUI.battleController.turnExecutor.finish_turn()
	if result != TurnExecutor.TurnResult.NOTHING:
		battleUI.playerWins = result == TurnExecutor.TurnResult.PLAYER_WIN
		if battleUI.playerWins:
			for combatantNode in battleUI.battleController.get_all_combatant_nodes():
				if combatantNode.combatant != null and combatantNode.role == CombatantNode.Role.ENEMY:
					PlayerResources.questInventory.progress_quest(combatantNode.combatant.save_name(), QuestStep.Type.DEFEAT)
					print('progress defeat quest for ', combatantNode.combatant.save_name())
		battleUI.set_menu_state(BattleState.Menu.BATTLE_COMPLETE)
