extends Panel
class_name RuneEffectDetailsPanel

signal loaded_panel
signal tooltip_panel_opened
signal status_button_onscreen_update(isOnscreen: bool)
signal rune_help_button_onscreen_update(isOnscreen: bool)

@export var rune: Rune = null
@export var isSurgeEffect: bool = false
@export var tooltipPanel: TooltipPanel
@export var casterPosition: String = ''

@onready var detailsTitleLabel: RichTextLabel = get_node('DetailsTitle')

@onready var runeHelpButton: Button = get_node('DetailsTitle/RuneHelpSection/RuneHelpButton')

@onready var triggerConditionsLabel: RichTextLabel = get_node('BaseEffectPanel/TriggerConditionsRow/TriggerConditions')
@onready var runePowerLabel: RichTextLabel = get_node("BaseEffectPanel/RunePower")
@onready var runeCategoryElementLabel: RichTextLabel = get_node("BaseEffectPanel/RuneCategoryElement")

@onready var boostsRow: HBoxContainer = get_node('BaseEffectPanel/VBoxContainer/BoostsRow')
@onready var statChangesLabel: RichTextLabel = get_node("BaseEffectPanel/VBoxContainer/BoostsRow/BoostsStatChanges")

@onready var statusEffectRow: HBoxContainer = get_node('BaseEffectPanel/VBoxContainer/StatusEffectRow')
@onready var statusLabel: RichTextLabel = get_node('BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusLabel')
@onready var runeStatusEffect: RichTextLabel = get_node("BaseEffectPanel/VBoxContainer/StatusEffectRow/RuneStatusEffect")
@onready var runeStatusIcon: Sprite2D = get_node('BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusEffectIconGroup/StatusEffectIconControl/StatusEffectIcon')
@onready var statusHelpButton: Button = get_node('BaseEffectPanel/VBoxContainer/StatusEffectRow/StatusHelpSection/StatusHelpButton')

@onready var surgePanel: Panel = get_node('SurgePanel')
@onready var surgeVBox: VBoxContainer = get_node('SurgePanel/VBoxContainer')

@onready var casterRow: HBoxContainer = get_node('CasterRow')
@onready var casterNameLabel: RichTextLabel = get_node('CasterRow/CasterName')

var surgeChangesRowScene: PackedScene = preload('res://prefabs/ui/stats/surge_changes_row.tscn')

var helpButtonPressed: Button = null

var runeHelpButtonOnscreen: bool = false
var statusHelpButtonOnscreen: bool = false

const MAX_CHARGE_HEIGHT = 242
const MAX_SURGE_HEIGHT = 491
const MAX_BATTLE_HEIGHT = 276

func load_rune_effect_details() -> void:
	if rune == null or not Combatant.are_runes_allowed():
		visible = false
		return
	visible = true
	
	var titleText: String = '[center]' + rune.get_rune_type()
	
	var orbText: String = ''
	if rune.orbChange != 0:
		orbText = ' ('
		if rune.orbChange > 0:
			orbText += '+'
		else:
			orbText += '-' 
		orbText += str(absi(rune.orbChange)) + ' $orb)'
	
	detailsTitleLabel.text = TextUtils.rich_text_substitute(titleText + orbText, Vector2i(32, 32))
	
	triggerConditionsLabel.text = '[center]' + rune.get_rune_trigger_description() + '[/center]'
	
	if rune.power >= 0:
		runePowerLabel.text = str(rune.power) + ' Power'
	else:
		runePowerLabel.text = str(rune.power * -1) + ' Heal Power'
	
	if rune.lifesteal > 0 and rune.power != 0:
		runePowerLabel.text += ' (' + String.num(roundi(100 * max(0, rune.lifesteal))) + '% Lifesteal)'
	
	runeCategoryElementLabel.text = '[right]'
	if rune.element != Move.Element.NONE:
		runeCategoryElementLabel.text += Move.element_to_string(rune.element) + ' / '
	runeCategoryElementLabel.text += Move.dmg_category_to_string(rune.category) + '[/right]'

	if rune.statChanges != null and rune.statChanges.has_stat_changes():
		var multipliers: Array[StatMultiplierText] = rune.statChanges.get_multipliers_text()
		statChangesLabel.text = '[center]' + StatMultiplierText.multiplier_text_list_to_string(multipliers) + '\n [/center]'
		boostsRow.visible = true
	else:
		boostsRow.visible = false

	if rune.statusEffect != null:
		runeStatusEffect.text = '[center]'
		if rune.statusEffect.type != StatusEffect.Type.NONE:
			runeStatusEffect.text += StatusEffect.potency_to_string(rune.statusEffect.potency) \
					+ ' ' + rune.statusEffect.get_status_type_string()
		else:
			runeStatusEffect.text += 'Cures ' + StatusEffect.potency_to_string(rune.statusEffect.potency) + ' Statuses'
		if rune.statusEffect.overwritesOtherStatuses:
			runeStatusEffect.text += ' (Replaces)'
		runeStatusEffect.text += '[/center]'
		runeStatusIcon.texture = rune.statusEffect.get_icon()
		statusEffectRow.visible = true
	else:
		statusEffectRow.visible = false
	
	if isSurgeEffect and rune.surgeChanges != null:
		var changes: Array[SurgeChanges.SurgeChangeDescRow] = rune.surgeChanges.get_description()
		for change: SurgeChanges.SurgeChangeDescRow in changes:
			var row: SurgeChangesRow = surgeChangesRowScene.instantiate()
			if change.title == 'Target(s) Boost Per Orb:':
				row.changeHeader = 'Boosts Per Orb:'
			else:
				row.changeHeader = change.title
			row.changeDetails = change.description
			surgeVBox.add_child(row)
		surgePanel.visible = true
		size.y = MAX_SURGE_HEIGHT
		custom_minimum_size.y = MAX_SURGE_HEIGHT
	else:
		surgePanel.visible = false
		size.y = MAX_CHARGE_HEIGHT
		custom_minimum_size.y = MAX_CHARGE_HEIGHT
	if casterPosition != '' and rune.caster != null:
		size.y = MAX_BATTLE_HEIGHT
		custom_minimum_size.y = MAX_BATTLE_HEIGHT
		surgePanel.visible = false
		casterNameLabel.text = '[center]' + rune.caster.disp_name() + ' (' + casterPosition + ')[/center]'
		casterRow.visible = true
	else:
		casterRow.visible = false
	loaded_panel.emit()

func get_bottom_most_button() -> Button:
	if statusEffectRow.visible:
		return statusHelpButton
	return runeHelpButton

func _on_status_help_button_pressed():
	if rune.statusEffect == null:
		return
	helpButtonPressed = statusHelpButton
	tooltipPanel.title = rune.statusEffect.get_status_type_string()
	tooltipPanel.details = rune.statusEffect.get_status_effect_tooltip()
	tooltipPanel.load_tooltip_panel()
	tooltip_panel_opened.emit()

func _on_status_button_onscreen_notifier_screen_entered() -> void:
	if statusEffectRow.visible:
		statusHelpButtonOnscreen = true
		status_button_onscreen_update.emit(true)

func _on_status_button_onscreen_notifier_screen_exited() -> void:
	if statusEffectRow.visible:
		statusHelpButtonOnscreen = false
		status_button_onscreen_update.emit(false)

func _on_rune_help_button_pressed() -> void:
	helpButtonPressed = runeHelpButton
	tooltipPanel.title = rune.get_rune_type()
	tooltipPanel.details = rune.get_rune_tooltip()
	tooltipPanel.load_tooltip_panel()
	tooltip_panel_opened.emit()

func _on_rune_help_button_onscreen_notifier_screen_entered() -> void:
	runeHelpButtonOnscreen = true
	rune_help_button_onscreen_update.emit(true)

func _on_rune_help_button_onscreen_notifier_screen_exited() -> void:
	runeHelpButtonOnscreen = false
	rune_help_button_onscreen_update.emit(false)
