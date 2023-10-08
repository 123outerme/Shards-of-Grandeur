extends Panel
class_name StatLinePanel

@export var stats: Stats = null
@export var curHp: int = -1
@export var readOnly: bool = false

var statsCopy: Stats = null
var modified: bool = false

@onready var levelText: RichTextLabel = get_node("StatsVBox/LevelDisplay/Level")

@onready var hpText: RichTextLabel = get_node("StatsVBox/HpDisplay/Hp")

@onready var expText: RichTextLabel = get_node("StatsVBox/ExpDisplay/Exp")

@onready var physAtkText: RichTextLabel = get_node("StatsVBox/PhysAtkDisplay/PhysAtk")
@onready var physAtkBtns: HBoxContainer = get_node("StatsVBox/PhysAtkDisplay/ButtonsHBox")
@onready var physAtkUp: Button = get_node("StatsVBox/PhysAtkDisplay/ButtonsHBox/IncreaseButton")
@onready var physAtkDown: Button = get_node("StatsVBox/PhysAtkDisplay/ButtonsHBox/DecreaseButton")

@onready var magicAtkText: RichTextLabel = get_node("StatsVBox/MagicAtkDisplay/MagicAtk")
@onready var magicAtkBtns: HBoxContainer = get_node("StatsVBox/MagicAtkDisplay/ButtonsHBox")
@onready var magicAtkUp: Button = get_node("StatsVBox/MagicAtkDisplay/ButtonsHBox/IncreaseButton")
@onready var magicAtkDown: Button = get_node("StatsVBox/MagicAtkDisplay/ButtonsHBox/DecreaseButton")

@onready var resistanceText: RichTextLabel = get_node("StatsVBox/ResistanceDisplay/Resistance")
@onready var resistanceBtns: HBoxContainer = get_node("StatsVBox/ResistanceDisplay/ButtonsHBox")
@onready var resistanceUp: Button = get_node("StatsVBox/ResistanceDisplay/ButtonsHBox/IncreaseButton")
@onready var resistanceDown: Button = get_node("StatsVBox/ResistanceDisplay/ButtonsHBox/DecreaseButton")

@onready var affinityText: RichTextLabel = get_node("StatsVBox/AffinityDisplay/Affinity")
@onready var affinityBtns: HBoxContainer = get_node("StatsVBox/AffinityDisplay/ButtonsHBox")
@onready var affinityUp: Button = get_node("StatsVBox/AffinityDisplay/ButtonsHBox/IncreaseButton")
@onready var affinityDown: Button = get_node("StatsVBox/AffinityDisplay/ButtonsHBox/DecreaseButton")

@onready var speedText: RichTextLabel = get_node("StatsVBox/SpeedDisplay/Speed")
@onready var speedBtns: HBoxContainer = get_node("StatsVBox/SpeedDisplay/ButtonsHBox")
@onready var speedUp: Button = get_node("StatsVBox/SpeedDisplay/ButtonsHBox/IncreaseButton")
@onready var speedDown: Button = get_node("StatsVBox/SpeedDisplay/ButtonsHBox/DecreaseButton")

@onready var statPtsText: RichTextLabel = get_node("StatsVBox/StatPtsDisplay/StatPts")
@onready var statPtsBtns: HBoxContainer = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox")
@onready var saveStatChanges: Button = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox/SaveChangesButton")
@onready var cancelStatChanges: Button = get_node("StatsVBox/StatPtsDisplay/ButtonsHBox/CancelChangesButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_statline_panel():
	if stats == null:
		return
		
	if statsCopy == null:
		statsCopy = stats.copy()
	
	var hp: int = curHp
	if curHp == -1:
		hp = statsCopy.maxHp
	
	levelText.text = String.num(statsCopy.level)
	hpText.text = TextUtils.num_to_comma_string(hp) + ' / ' + TextUtils.num_to_comma_string(statsCopy.maxHp)
	expText.text = TextUtils.num_to_comma_string(statsCopy.experience) + ' / ' + TextUtils.num_to_comma_string(Stats.get_required_exp(statsCopy.level))
	physAtkText.text = TextUtils.num_to_comma_string(statsCopy.physAttack)
	magicAtkText.text = TextUtils.num_to_comma_string(statsCopy.magicAttack)
	resistanceText.text = TextUtils.num_to_comma_string(statsCopy.resistance)
	affinityText.text = TextUtils.num_to_comma_string(statsCopy.affinity)
	speedText.text = TextUtils.num_to_comma_string(statsCopy.speed)
	statPtsText.text = String.num(statsCopy.statPts)
	
	physAtkBtns.visible = not readOnly
	magicAtkBtns.visible = not readOnly
	resistanceBtns.visible = not readOnly
	affinityBtns.visible = not readOnly
	speedBtns.visible = not readOnly
	statPtsBtns.visible = not readOnly
	
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

func _on_cancel_changes_button_pressed():
	statsCopy = stats.copy() # copy original stats back into editing stats
	modified = false
	load_statline_panel()
