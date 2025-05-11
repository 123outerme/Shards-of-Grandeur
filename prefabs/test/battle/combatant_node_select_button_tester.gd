extends Node2D

@export var combatant: Combatant
@export var evolution: Evolution

@onready var combatantNode: CombatantNode = get_node('CombatantNode')
@onready var flipButton: Button = get_node('FlipButton')
@onready var lineEdit: LineEdit = get_node('LineEdit')
@onready var evoLineEdit: LineEdit = get_node('EvoLineEdit')
@onready var audioHandler: AudioHandler = get_node('AudioHandler')

func _ready() -> void:
	SceneLoader.audioHandler = audioHandler
	combatantNode.combatant = combatant.copy()
	lineEdit.text = combatant.save_name()
	if evolution != null:
		combatant.stats.equippedArmor = evolution.requiredArmor
		combatant.stats.equippedWeapon = evolution.requiredWeapon
		combatant.stats.equippedAccessory = evolution.requiredAccessory
		combatant.switch_evolution(evolution, null)
		evoLineEdit.text = evolution.evolutionSaveName
	else:
		evoLineEdit.text = ''
	combatantNode.load_combatant_node()
	combatantNode.update_select_btn(true)

func _on_reload_button_pressed() -> void:
	combatantNode.load_combatant_node()
	combatantNode.update_select_btn(true)

func _on_flip_button_toggled(toggled_on: bool) -> void:
	combatantNode.leftSide = toggled_on
	combatantNode.load_combatant_node()
	combatantNode.update_select_btn(true)
	flipButton.text = 'Left Side' if toggled_on else 'Right Side'

func _on_load_button_pressed(_text: String = '') -> void:
	var newCombatant: Combatant = Combatant.load_combatant_resource(lineEdit.text)
	if newCombatant == null:
		print('Combatant was not found: ', lineEdit.text)
	else:
		combatantNode.combatant = newCombatant
		var oldEvo: Evolution = evolution if newCombatant.save_name() == combatant.save_name() else null
		var newEvo: Evolution = null
		for evo: Evolution in newCombatant.evolutions.evolutionList:
			if evo.evolutionSaveName == evoLineEdit.text:
				newEvo = evo
				break
		if newEvo != null:
			newCombatant.stats.equippedArmor = newEvo.requiredArmor
			newCombatant.stats.equippedWeapon = newEvo.requiredWeapon
			newCombatant.stats.equippedAccessory = newEvo.requiredAccessory
		else:
			newCombatant.stats.equippedArmor = null
			newCombatant.stats.equippedWeapon = null
			newCombatant.stats.equippedAccessory = null
		newCombatant.switch_evolution(newEvo, oldEvo)
		combatantNode.load_combatant_node()
		combatantNode.update_select_btn(true)
		combatant = newCombatant
		evolution = newEvo
