extends Panel
class_name EvolutionListItemPanel

signal evolution_selected(evoListItemPanel: EvolutionListItemPanel)

@export var combatant: Combatant
@export var evolution: Evolution

@onready var evolutionSprite: AnimatedSprite2D = get_node('SpriteControl/EvolutionSprite')
@onready var selectButton: Button = get_node('HBoxContainer/SelectButton')
@onready var selectLabel: RichTextLabel = get_node('HBoxContainer/SelectButton/SelectLabel')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_evolution_list_item_panel()

func load_evolution_list_item_panel() -> void:
	if combatant == null:
		visible = false
		return
	
	var combatantSprite: CombatantSprite = null
	if evolution != null:
		combatantSprite = evolution.combatantSprite
	else:
		combatantSprite = combatant.sprite
	evolutionSprite.sprite_frames = combatantSprite.spriteFrames
	if evolutionSprite.sprite_frames == null:
		evolutionSprite.sprite_frames = load('res://graphics/animations/a_missingno.tres') # prevent crashing
	# for this menu specifically, this logic is less consistent for sizing BETWEEN DIFFERENT COMBATANTS
	# but it allows the max rendered sprite size to be 64x64 (32x32 x2) which saves space
	evolutionSprite.offset = (combatantSprite.maxSize / 2) - combatantSprite.centerPosition
	evolutionSprite.flip_h = combatantSprite.spriteFacesRight
	if combatantSprite.spriteFacesRight: # if flipping, invert the X offset
		evolutionSprite.offset.x *= -1
	if combatantSprite.idleSize.x > 32 or combatantSprite.idleSize.y > 32:
		evolutionSprite.scale = Vector2.ONE
	else:
		evolutionSprite.scale = 2 * Vector2.ONE
	evolutionSprite.play('battle_idle')
	selectLabel.text = '[center]' + combatant.get_evolution_stats(evolution).displayName + '[/center]'

func _on_select_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		evolution_selected.emit(self)

func _on_evolution_switched(evo: Evolution) -> void:
	if evolution == evo and not selectButton.button_pressed:
		selectButton.button_pressed = true
	if evolution != evo and selectButton.button_pressed:
		selectButton.button_pressed = false
