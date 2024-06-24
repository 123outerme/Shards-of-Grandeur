extends Panel
class_name StatResetCombatantPanel

@export var combatant: Combatant = null

var parentPanel: StatResetPanel = null

@onready var animatedCombatantSprite: AnimatedSprite2D = get_node('SpriteControl/CombatantSprite')
@onready var combatantName: RichTextLabel = get_node('CenterCombatantName/CombatantName')
@onready var statsButton: Button = get_node('CenterButtons/HBoxContainer/StatsButton')
@onready var resetButton: Button = get_node('CenterButtons/HBoxContainer/ResetButton')

@onready var maxHpLabel: RichTextLabel = get_node('CenterCombatantName/MaxHpLabel')
@onready var physAtkLabel: RichTextLabel = get_node('CenterStats/HBoxContainer/PhysAtkLabel')
@onready var magicAtkLabel: RichTextLabel = get_node('CenterStats/HBoxContainer2/MagicAtkLabel')
@onready var affinityLabel: RichTextLabel = get_node('CenterStats/HBoxContainer3/AffinityLabel')
@onready var resistanceLabel: RichTextLabel = get_node('CenterStats/HBoxContainer/ResistanceLabel')
@onready var speedLabel: RichTextLabel = get_node('CenterStats/HBoxContainer2/SpeedLabel')
@onready var statPtsLabel: RichTextLabel = get_node('CenterStats/HBoxContainer3/StatPtsLabel')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_stat_reset_combatant_panel()

func initial_focus():
	resetButton.grab_focus()

func focus_stats_button():
	statsButton.grab_focus()

func load_stat_reset_combatant_panel():
	if combatant == null or parentPanel == null:
		return
	
	combatantName.text = combatant.disp_name()
	
	animatedCombatantSprite.sprite_frames = combatant.get_sprite_frames()
	if combatant.get_idle_size().x <= 16 and combatant.get_idle_size().y <= 16:
		animatedCombatantSprite.scale = Vector2(3, 3)
	elif combatant.get_idle_size().x < 48 and combatant.get_idle_size().y < 48:
		animatedCombatantSprite.scale = Vector2(2, 2)
	else:
		animatedCombatantSprite.scale = Vector2(2, 2)
	animatedCombatantSprite.play('battle_idle')
	
	maxHpLabel.text = 'Max HP: ' + TextUtils.num_to_comma_string(combatant.stats.maxHp)
	physAtkLabel.text = 'Phys Atk:  ' + TextUtils.num_to_comma_string(combatant.stats.physAttack)
	magicAtkLabel.text = 'Magic Atk: ' + TextUtils.num_to_comma_string(combatant.stats.magicAttack)
	affinityLabel.text = 'Affinity:    ' + TextUtils.num_to_comma_string(combatant.stats.affinity)
	resistanceLabel.text = 'Resistance: ' + TextUtils.num_to_comma_string(combatant.stats.resistance)
	speedLabel.text = 'Speed:          ' + TextUtils.num_to_comma_string(combatant.stats.speed)
	statPtsLabel.text = 'Stat Pts:      ' + TextUtils.num_to_comma_string(combatant.stats.statPts)

func connect_to_reset_button(control: Control, isBottomPanel: bool = true):
	if isBottomPanel:
		control.focus_neighbor_top = control.get_path_to(resetButton)
	else:
		control.focus_neighbor_bottom = control.get_path_to(resetButton)
		resetButton.focus_neighbor_top = resetButton.get_path_to(control)

func _on_reset_button_pressed():
	parentPanel.reset_pressed(combatant)
	
func _on_stats_button_pressed():
	parentPanel.stats_pressed(combatant)
