extends Control
class_name OrbUnitDisplay

signal orb_clicked(index: int)

@export var unfilledOrbSprite: Texture2D = null
@export var filledOrbSprite: Texture2D = null
@export var unfilledHoverOrbSprite: Texture2D = null
@export var filledHoverOrbSprite: Texture2D = null
@export var filledOrb: bool = false
@export var readOnly: bool = true

var index: int = 0

@onready var sprite: Sprite2D = get_node('Sprite2D')

# Called when the node enters the scene tree for the first time.
func _ready():
	if readOnly:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		focus_mode = Control.FOCUS_NONE
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		#focus_mode = Control.FOCUS_CLICK
	load_orb_unit_display()

func load_orb_unit_display():
	sprite.texture = filledOrbSprite if filledOrb else unfilledOrbSprite

func _on_gui_input(event):
	if not readOnly:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			orb_clicked.emit(index)
			#print('orb clicked: ', index)

func _on_mouse_entered():
	if not readOnly:
		sprite.texture = filledHoverOrbSprite if filledOrb else unfilledHoverOrbSprite

func _on_mouse_exited():
	load_orb_unit_display()
