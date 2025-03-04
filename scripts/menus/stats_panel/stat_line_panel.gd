extends Panel
class_name StatLinePanel

signal stats_saved

@export var stats: Stats = null
@export var curHp: int = -1
@export var readOnly: bool = false
@export var battleStats: bool = false
@export var statChanges: StatChanges = null
@export var levelUp: bool = false
@export var newLvs: int = 0
@export var showExp: bool = true

var statsCopy: Stats = null
var modified: bool = false

@onready var statPtsIndicator: Control = get_node('StatPtsIndicator')

@onready var levelText: RichTextLabel = get_node("StatsVBox/LevelDisplay/Level")

@onready var hpText: RichTextLabel = get_node("StatsVBox/HpDisplay/Hp")
@onready var hpProgressBar: TextureProgressBar = get_node("StatsVBox/HpDisplay/HpProgressBar")
@onready var hpLvUp: RichTextLabel = get_node("StatsVBox/HpDisplay/Extras/LvUpIncrease")

@onready var expText: RichTextLabel = get_node("StatsVBox/ExpDisplay/Exp")
@onready var expProgressBar: TextureProgressBar = get_node('StatsVBox/ExpDisplay/ExpProgressBar')

@onready var physAtkText: RichTextLabel = get_node("StatsVBox/PhysAtkDisplay/PhysAtk")
@onready var physAtkBtns: HBoxContainer = get_node("StatsVBox/PhysAtkDisplay/Extras/ButtonsHBox")
@onready var physAtkUp: Button = get_node("StatsVBox/PhysAtkDisplay/Extras/ButtonsHBox/IncreaseButton")
@onready var physAtkDown: Button = get_node("StatsVBox/PhysAtkDisplay/Extras/ButtonsHBox/DecreaseButton")
@onready var physAtkModifier: RichTextLabel = get_node("StatsVBox/PhysAtkDisplay/Extras/StatModifier")
@onready var physAtkLvUp: RichTextLabel = get_node("StatsVBox/PhysAtkDisplay/Extras/LvUpIncrease")

@onready var magicAtkText: RichTextLabel = get_node("StatsVBox/MagicAtkDisplay/MagicAtk")
@onready var magicAtkBtns: HBoxContainer = get_node("StatsVBox/MagicAtkDisplay/Extras/ButtonsHBox")
@onready var magicAtkUp: Button = get_node("StatsVBox/MagicAtkDisplay/Extras/ButtonsHBox/IncreaseButton")
@onready var magicAtkDown: Button = get_node("StatsVBox/MagicAtkDisplay/Extras/ButtonsHBox/DecreaseButton")
@onready var magicAtkModifier: RichTextLabel = get_node("StatsVBox/MagicAtkDisplay/Extras/StatModifier")
@onready var magicAtkLvUp: RichTextLabel = get_node('StatsVBox/MagicAtkDisplay/Extras/LvUpIncrease')

@onready var affinityText: RichTextLabel = get_node("StatsVBox/AffinityDisplay/Affinity")
@onready var affinityBtns: HBoxContainer = get_node("StatsVBox/AffinityDisplay/Extras/ButtonsHBox")
@onready var affinityUp: Button = get_node("StatsVBox/AffinityDisplay/Extras/ButtonsHBox/IncreaseButton")
@onready var affinityDown: Button = get_node("StatsVBox/AffinityDisplay/Extras/ButtonsHBox/DecreaseButton")
@onready var affinityModifier: RichTextLabel = get_node("StatsVBox/AffinityDisplay/Extras/StatModifier")
@onready var affinityLvUp: RichTextLabel = get_node("StatsVBox/AffinityDisplay/Extras/LvUpIncrease")

@onready var resistanceText: RichTextLabel = get_node("StatsVBox/ResistanceDisplay/Resistance")
@onready var resistanceBtns: HBoxContainer = get_node("StatsVBox/ResistanceDisplay/Extras/ButtonsHBox")
@onready var resistanceUp: Button = get_node("StatsVBox/ResistanceDisplay/Extras/ButtonsHBox/IncreaseButton")
@onready var resistanceDown: Button = get_node("StatsVBox/ResistanceDisplay/Extras/ButtonsHBox/DecreaseButton")
@onready var resistanceModifier: RichTextLabel = get_node("StatsVBox/ResistanceDisplay/Extras/StatModifier")
@onready var resistanceLvUp: RichTextLabel = get_node("StatsVBox/ResistanceDisplay/Extras/LvUpIncrease")

@onready var speedText: RichTextLabel = get_node("StatsVBox/SpeedDisplay/Speed")
@onready var speedBtns: HBoxContainer = get_node("StatsVBox/SpeedDisplay/Extras/ButtonsHBox")
@onready var speedUp: Button = get_node("StatsVBox/SpeedDisplay/Extras/ButtonsHBox/IncreaseButton")
@onready var speedDown: Button = get_node("StatsVBox/SpeedDisplay/Extras/ButtonsHBox/DecreaseButton")
@onready var speedModifier: RichTextLabel = get_node("StatsVBox/SpeedDisplay/Extras/StatModifier")
@onready var speedLvUp: RichTextLabel = get_node("StatsVBox/SpeedDisplay/Extras/LvUpIncrease")

@onready var statPtsDisplay: Control = get_node("StatsVBox/StatPtsDisplay")
@onready var statPtsText: RichTextLabel = get_node("StatsVBox/StatPtsDisplay/StatPts")
@onready var statPtsLvUp: RichTextLabel = get_node("StatsVBox/StatPtsDisplay/LvUpIncrease")

@onready var statPtsBtns: HBoxContainer = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox")
@onready var saveStatChanges: Button = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox/SaveChangesButton")
@onready var cancelStatChanges: Button = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox/CancelChangesButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_statline_panel(recopyStats: bool = false):
	if stats == null:
		return
		
	if statsCopy == null or recopyStats:
		statsCopy = stats.copy()
	
	var hp: int = curHp
	if curHp == -1:
		hp = statsCopy.maxHp
	
	statPtsIndicator.visible = not readOnly and stats.statPts > 0 and not battleStats
	
	statPtsDisplay.visible = not battleStats
	
	levelText.text = String.num_int64(statsCopy.level)
	
	hpText.text = TextUtils.num_to_comma_string(hp) + ' / ' + TextUtils.num_to_comma_string(statsCopy.maxHp)
	hpProgressBar.max_value = statsCopy.maxHp
	hpProgressBar.value = hp
	hpProgressBar.tint_progress = Combatant.get_hp_bar_color(hp, statsCopy.maxHp)
	
	# since player and minions share level, show player exp progress to level up, always
	if showExp:
		expText.text = TextUtils.num_to_comma_string(PlayerResources.playerInfo.combatant.stats.experience) + ' / ' + TextUtils.num_to_comma_string(Stats.get_required_exp(PlayerResources.playerInfo.combatant.stats.level))
		expProgressBar.max_value = Stats.get_required_exp(PlayerResources.playerInfo.combatant.stats.level)
		expProgressBar.value = PlayerResources.playerInfo.combatant.stats.experience
	expText.visible = showExp
	expProgressBar.visible = showExp
	
	physAtkText.text = TextUtils.num_to_comma_string(statsCopy.physAttack)
	magicAtkText.text = TextUtils.num_to_comma_string(statsCopy.magicAttack)
	resistanceText.text = TextUtils.num_to_comma_string(statsCopy.resistance)
	affinityText.text = TextUtils.num_to_comma_string(statsCopy.affinity)
	speedText.text = TextUtils.num_to_comma_string(statsCopy.speed)
	statPtsText.text = String.num_int64(statsCopy.statPts)
	
	physAtkBtns.visible = not readOnly
	magicAtkBtns.visible = not readOnly
	resistanceBtns.visible = not readOnly
	affinityBtns.visible = not readOnly
	speedBtns.visible = not readOnly
	statPtsBtns.visible = not readOnly
	
	physAtkModifier.visible = battleStats
	magicAtkModifier.visible = battleStats
	resistanceModifier.visible = battleStats
	affinityModifier.visible = battleStats
	speedModifier.visible = battleStats
	
	hpLvUp.visible = levelUp
	physAtkLvUp.visible = levelUp
	magicAtkLvUp.visible = levelUp
	affinityLvUp.visible = levelUp
	resistanceLvUp.visible = levelUp
	speedLvUp.visible = levelUp
	statPtsLvUp.visible = levelUp
	if levelUp:
		var prevLvBase: Stats = Stats.calculate_base_stats(statsCopy, statsCopy.level - newLvs)
		var newLvBase: Stats = Stats.calculate_base_stats(statsCopy, statsCopy.level)
		hpLvUp.text = '[right]+' + String.num_int64(newLvBase.maxHp - prevLvBase.maxHp) + '[/right]'
		physAtkLvUp.text = '[right]+' + String.num_int64(newLvBase.physAttack - prevLvBase.physAttack) + '[/right]'
		magicAtkLvUp.text = '[right]+' + String.num_int64(newLvBase.magicAttack - prevLvBase.magicAttack) + '[/right]'
		affinityLvUp.text = '[right]+' + String.num_int64(newLvBase.affinity - prevLvBase.affinity) + '[/right]'
		resistanceLvUp.text = '[right]+' + String.num_int64(newLvBase.resistance - prevLvBase.resistance) + '[/right]'
		speedLvUp.text = '[right]+' + String.num_int64(newLvBase.speed - prevLvBase.speed) + '[/right]'
		statPtsLvUp.text = '[right]+' + String.num_int64(newLvBase.statPts - prevLvBase.statPts) + '[/right]'
	else:
		hpLvUp.text = ''
		physAtkLvUp.text = ''
		magicAtkLvUp.text = ''
		affinityLvUp.text = ''
		resistanceLvUp.text = ''
		speedLvUp.text = ''
		speedLvUp.text = ''
	
	if battleStats:
		physAtkModifier.text = statChanges.get_phys_atk_multiplier().print_multiplier(false)
		magicAtkModifier.text = statChanges.get_magic_atk_multiplier().print_multiplier(false)
		resistanceModifier.text = statChanges.get_resistance_multiplier().print_multiplier(false)
		affinityModifier.text = statChanges.get_affinity_multiplier().print_multiplier(false)
		speedModifier.text = statChanges.get_speed_multiplier().print_multiplier(false)
	
	var canChangeStats: bool = statsCopy.statPts > 0
	physAtkUp.disabled = not canChangeStats
	physAtkDown.disabled = not modified or statsCopy.physAttack <= stats.physAttack
	magicAtkUp.disabled = not canChangeStats
	magicAtkDown.disabled = not modified or statsCopy.magicAttack <= stats.magicAttack
	resistanceUp.disabled = not canChangeStats
	resistanceDown.disabled = not modified or statsCopy.resistance <= stats.resistance
	affinityUp.disabled = not canChangeStats
	affinityDown.disabled = not modified or statsCopy.affinity <= stats.affinity
	speedUp.disabled = not canChangeStats
	speedDown.disabled = not modified or statsCopy.speed <= stats.speed
	
	saveStatChanges.disabled = not modified
	cancelStatChanges.disabled = not modified

func on_increment():
	modified = true
	statsCopy.statPts -= 1
	load_statline_panel()
	
func on_decrement():
	statsCopy.statPts += 1
	load_statline_panel()

func _on_physatk_inc_button_pressed():
	statsCopy.physAttack += 1
	on_increment()

func _on_physatk_dec_button_pressed():
	statsCopy.physAttack -= 1
	on_decrement()

func _on_magicatk_inc_button_pressed():
	statsCopy.magicAttack += 1
	on_increment()

func _on_magicatk_dec_button_pressed():
	statsCopy.magicAttack -= 1
	on_decrement()

func _on_resistance_inc_button_pressed():
	statsCopy.resistance += 1
	on_increment()

func _on_resistance_dec_button_pressed():
	statsCopy.resistance -= 1
	on_decrement()

func _on_affinity_inc_button_pressed():
	statsCopy.affinity += 1
	on_increment()

func _on_affinity_dec_button_pressed():
	statsCopy.affinity -= 1
	on_decrement()
	
func _on_speed_inc_button_pressed():
	statsCopy.speed += 1
	on_increment()

func _on_speed_dec_button_pressed():
	statsCopy.speed -= 1
	on_decrement()

func _on_save_changes_button_pressed():
	stats.save_from_object(statsCopy)
	modified = false
	load_statline_panel()
	stats_saved.emit()

func _on_cancel_changes_button_pressed():
	statsCopy = stats.copy() # copy original stats back into editing stats
	modified = false
	load_statline_panel()
