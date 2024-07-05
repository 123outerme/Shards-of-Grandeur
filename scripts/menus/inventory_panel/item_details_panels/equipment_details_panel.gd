extends Panel
class_name EquipmentDetailsPanel

@export var item: Item = null

@onready var hboxTiming: HBoxContainer = get_node('MarginContainer/VBoxContainer/HBoxTiming')
@onready var timingText: RichTextLabel = get_node('MarginContainer/VBoxContainer/HBoxTiming/TimingText')

@onready var hboxBoosts: HBoxContainer = get_node('MarginContainer/VBoxContainer/HBoxBoosts')
@onready var boostsText: RichTextLabel = get_node('MarginContainer/VBoxContainer/HBoxBoosts/BoostsText')

@onready var hboxElBoosts: HBoxContainer = get_node('MarginContainer/VBoxContainer/HBoxElBoosts')
@onready var elBoostsText: RichTextLabel = get_node('MarginContainer/VBoxContainer/HBoxElBoosts/BoostsText')

@onready var hboxOrbs: HBoxContainer = get_node('MarginContainer/VBoxContainer/HBoxOrbs')
@onready var orbsText: RichTextLabel = get_node('MarginContainer/VBoxContainer/HBoxOrbs/OrbsText')

# Called when the node enters the scene tree for the first time.
func load_equipment_details_panel():
	if item.itemType != Item.Type.WEAPON and item.itemType != Item.Type.ARMOR:
		visible = false
		return
	visible = true
	var statChanges: StatChanges = item.statChanges
	if statChanges != null:
		var statMultipliersText: Array[StatMultiplierText] = statChanges.get_stat_multiplier_texts()
		if len(statMultipliersText) == 0:
			hboxBoosts.visible = false
		else:
			hboxBoosts.visible = true
			boostsText.text = '[center]' + StatMultiplierText.multiplier_text_list_to_string(statMultipliersText) + '[/center]'
		
		var elMultipliersText: Array[StatMultiplierText] = statChanges.get_element_multiplier_texts()
		if len(elMultipliersText) == 0:
			hboxElBoosts.visible = false
		else:
			hboxElBoosts.visible = true
			elBoostsText.text = '[center]' + StatMultiplierText.multiplier_text_list_to_string(elMultipliersText) + '[/center]'
	else:
		hboxBoosts.visible = false
		hboxElBoosts.visible = false
		
		if hboxBoosts.visible or hboxElBoosts.visible:
			hboxTiming.visible = true
			timingText.text = '[center]' + BattleCommand.apply_timing_to_string(item.timing) + '[/center]'
		else:
			hboxTiming.visible = false
	
	if item.bonusOrbs == 0:
		hboxOrbs.visible = false
	else:
		hboxOrbs.visible = true
		orbsText.text = '[center]' + TextUtils.rich_text_substitute('+' + String.num(item.bonusOrbs) + ' $orb At The Start Of Battle', Vector2i(24, 24)) + '[/center]'
	
