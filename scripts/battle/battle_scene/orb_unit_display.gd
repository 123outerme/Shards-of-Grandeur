extends Control
class_name OrbUnitDisplay

signal orb_clicked(index: int)
signal being_hovered(index: int)

@export var unfilledOrbSprite: Texture2D = null
@export var filledOrbSprite: Texture2D = null
@export var unfilledHoverOrbSprite: Texture2D = null
@export var filledHoverOrbSprite: Texture2D = null
@export var cannotSpendOrbSprite: Texture2D = null
@export var cannotSpendHoverOrbSprite: Texture2D = null
@export var filledOrb: bool = false
@export var cannotSpend: bool = false
@export var readOnly: bool = true

@export var gainParticlePreset: ParticlePreset = null
@export var gainCannotSpendParticlePreset: ParticlePreset = null
@export var spendParticlePreset: ParticlePreset = null

var index: int = 0

@onready var sprite: Sprite2D = get_node('Sprite2D')
@onready var particleEmitter: Particles = get_node('ParticleEmitter')

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_orb_unit_display()

func load_orb_unit_display() -> void:
	if readOnly:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		focus_mode = Control.FOCUS_NONE
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		#focus_mode = Control.FOCUS_CLICK
	if filledOrb:
		if cannotSpend and not readOnly:
			sprite.texture = cannotSpendOrbSprite
		else:
			sprite.texture = filledOrbSprite
	else:
		sprite.texture = unfilledOrbSprite

func _on_gui_input(event) -> void:
	if not readOnly:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			orb_clicked.emit(index)
			#print('orb clicked: ', index)

func _on_mouse_entered() -> void:
	if not readOnly:
		if filledOrb:
			if cannotSpend and not readOnly:
				sprite.texture = cannotSpendHoverOrbSprite
			else:
				sprite.texture = filledHoverOrbSprite
		else:
			sprite.texture = unfilledHoverOrbSprite
		being_hovered.emit(index)

func _on_mouse_exited() -> void:
	load_orb_unit_display()

func play_gain_particles() -> void:
	particleEmitter.preset = gainCannotSpendParticlePreset if cannotSpend else gainParticlePreset
	particleEmitter.set_make_particles(true)
	
func play_spend_particles(duration: float, particleCount: int, mirror: bool) -> void:
	var spendPresetCopy: ParticlePreset = spendParticlePreset.duplicate(true)
	# 0.2s lifetime per orb being spent
	spendPresetCopy.lifetime = duration
	# if orbs spent is less than 3:
	spendPresetCopy.count = particleCount
	if mirror:
		spendPresetCopy.processMaterial.direction.x *= -1
		spendPresetCopy.processMaterial.emission_shape_offset.x = -2
	particleEmitter.preset = spendPresetCopy
	particleEmitter.set_make_particles(true)
