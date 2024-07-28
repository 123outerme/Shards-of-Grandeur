extends SFXButton
class_name SFXNinePatchButton

@export var unselectedTexture: Texture2D = null
@export var selectedTexture: Texture2D = null
@export var unselectedFocusedTexture: Texture2D = null
@export var selectedFocusedTexture: Texture2D = null
@export var drawCenter: bool = false

@onready var textureRect: NinePatchRect = get_node('NinePatchRect')

var isFocused: bool = false
var shaderParamDisabled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	update_nine_patch_drawing()

func _process(_delta):
	update_nine_patch_drawing()

func _on_pressed_update_texture():
	if toggle_mode:
		var newTexture: Texture2D = null
		if button_pressed:
			if isFocused:
				newTexture = selectedFocusedTexture
			else:
				newTexture = selectedTexture
		else:
			if isFocused:
				newTexture = unselectedFocusedTexture
			else:
				newTexture = unselectedTexture
		textureRect.texture = newTexture
		update_nine_patch_slicing()

func update_nine_patch_slicing():
	var texture: Texture2D = textureRect.texture
	var verticalTileHeight: int = roundi(texture.get_height() / 3.0)
	var horizontalTitleHeight: int = roundi(texture.get_width() / 3.0)
	textureRect.patch_margin_top = verticalTileHeight
	textureRect.patch_margin_bottom = verticalTileHeight
	textureRect.patch_margin_left = horizontalTitleHeight
	textureRect.patch_margin_right = horizontalTitleHeight

func update_nine_patch_drawing():
	textureRect.draw_center = drawCenter
	if textureRect.size.x != size.x or textureRect.size.y != size.y:
		textureRect.size.x = size.x
		textureRect.size.y = size.y
		size = textureRect.size
	if disabled != shaderParamDisabled:
		(textureRect.material as ShaderMaterial).set_shader_parameter('disabled', disabled)
		shaderParamDisabled = disabled

func _on_focus_entered():
	isFocused = true
	if textureRect.texture == unselectedTexture:
		textureRect.texture = unselectedFocusedTexture
		update_nine_patch_slicing()
	if textureRect.texture == selectedTexture:
		textureRect.texture = selectedFocusedTexture
		update_nine_patch_slicing()

func _on_focus_exited():
	isFocused = false
	if textureRect.texture == unselectedFocusedTexture:
		textureRect.texture = unselectedTexture
		update_nine_patch_slicing()
	if textureRect.texture == selectedFocusedTexture:
		textureRect.texture = selectedTexture
		update_nine_patch_slicing()

func _on_button_down():
	if not toggle_mode:
		textureRect.texture = selectedFocusedTexture
		update_nine_patch_slicing()

func _on_button_up():
	if not toggle_mode:
		textureRect.texture = unselectedFocusedTexture
		update_nine_patch_slicing()
