extends Control
class_name AllCommands

@export var battleUI: BattleUI
@export var surgeIcon: Texture2D = null

var commandingCombatant: CombatantNode = null
var commandingMinion: bool = false

@onready var commandLabel: RichTextLabel = get_node("CommandLabel")
@onready var chargeMovesBtn: Button = get_node("ChargeButton")
@onready var inventoryBtn: Button = get_node("InventoryButton")
@onready var surgeMovesBtn: Button = get_node('SurgeButton')
@onready var escapeButton: Button = get_node("EscapeButton")
@onready var backToPlayerCmdBtn: Button = get_node("BackToPlayerButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	if PlayerResources.playerInfo.encounter is StaticEncounter:
		var staticEncounter: StaticEncounter = PlayerResources.playerInfo.encounter as StaticEncounter
		escapeButton.disabled = not staticEncounter.canEscape
	if PlayerResources.playerInfo.encounter == null:
		printerr('Error: Encounter is null!')
		return
	
	inventoryBtn.disabled = PlayerResources.playerInfo.encounter.has_special_rule(EnemyEncounter.SpecialRules.NO_ITEMS)
	surgeMovesBtn.disabled = not Combatant.are_surge_moves_allowed()
	if surgeMovesBtn.disabled:
		chargeMovesBtn.text = 'Moves'
		surgeMovesBtn.text = '???'
	else:
		chargeMovesBtn.text = 'Charge Moves'
		surgeMovesBtn.text = 'Surge Moves'
	surgeMovesBtn.icon = null

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and backToPlayerCmdBtn.visible:
		get_viewport().set_input_as_handled()
		_on_back_to_player_button_pressed.call_deferred()

func load_all_commands():
	backToPlayerCmdBtn.visible = commandingMinion and battleUI.battleController.playerCombatant.is_alive()
	commandLabel.text = '[center]Command ' + commandingCombatant.combatant.disp_name() + '[/center]'
	initial_focus()
	# if Surge moves have been unlocked, update whether the surge icon appears next to the button
	if Combatant.are_surge_moves_allowed():
		var canSurgeAMove: bool = false
		for move: Move in commandingCombatant.combatant.stats.moves:
			if move == null:
				continue
			if commandingCombatant.combatant.orbs >= (move.surgeEffect.orbChange * -1):
				canSurgeAMove = true
				break
		surgeMovesBtn.icon = surgeIcon if canSurgeAMove else null
	
func initial_focus():
	if battleUI.battleController.state.moveEffectType == Move.MoveEffectType.SURGE:
		surgeMovesBtn.grab_focus()
	else:
		chargeMovesBtn.grab_focus()

func _on_charge_moves_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.CHARGE_MOVES)
	
func _on_inventory_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.ITEMS)
	
func _on_surge_button_pressed():
	battleUI.set_menu_state(BattleState.Menu.SURGE_MOVES)

func _on_escape_button_pressed():
	var allCombatants: Array[CombatantNode] = battleUI.battleController.get_all_combatant_nodes()
	
	commandingCombatant.combatant.command = BattleCommand.command_escape(commandingCombatant, allCombatants)
	battleUI.complete_command()

func _on_back_to_player_button_pressed():
	battleUI.return_to_player_command()
