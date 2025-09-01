extends SFXButton
class_name SFXNinePatchButton

## sets the NinePatchRect.draw_center bool (whether or not to also draw the center slice tiled)
@export var drawCenter: bool = false

@export_subgroup('Unselected Texture')
@export var unselectedTexture: Texture2D = null

## if > 0, overrides NinePatchRect.patch_margin_left
@export var overrideUnselectedPatchMarginLeft: int = 0

## if > 0, overrides NinePatchRect.patch_margin_top
@export var overrideUnselectedPatchMarginTop: int = 0
@export var overrideUnselectedPatchMarginRight: int = 0
@export var overrideUnselectedPatchMarginBottom: int = 0

@export_subgroup('Selected Texture')
@export var selectedTexture: Texture2D = null

## if > 0, overrides NinePatchRect.patch_margin_left
@export var overrideSelectedPatchMarginLeft: int = 0

## if > 0, overrides NinePatchRect.patch_margin_top
@export var overrideSelectedPatchMarginTop: int = 0

## if > 0, overrides NinePatchRect.patch_margin_right
@export var overrideSelectedPatchMarginRight: int = 0

## if > 0, overrides NinePatchRect.patch_margin_bottom
@export var overrideSelectedPatchMarginBottom: int = 0

@export_subgroup('Unselected Focused Texture')
@export var unselectedFocusedTexture: Texture2D = null

## if > 0, overrides NinePatchRect.patch_margin_left
@export var overrideUnselectedFocusedPatchMarginLeft: int = 0

## if > 0, overrides NinePatchRect.patch_margin_top
@export var overrideUnselectedFocusedPatchMarginTop: int = 0

## if > 0, overrides NinePatchRect.patch_margin_right
@export var overrideUnselectedFocusedPatchMarginRight: int = 0

## if > 0, overrides NinePatchRect.patch_margin_bottom
@export var overrideUnselectedFocusedPatchMarginBottom: int = 0

@export_subgroup('Selected Focused Texture')
@export var selectedFocusedTexture: Texture2D = null

## if > 0, overrides NinePatchRect.patch_margin_left
@export var overrideSelectedFocusedPatchMarginLeft: int = 0

## if > 0, overrides NinePatchRect.patch_margin_top
@export var overrideSelectedFocusedPatchMarginTop: int = 0

## if > 0, overrides NinePatchRect.patch_margin_right
@export var overrideSelectedFocusedPatchMarginRight: int = 0

## if > 0, overrides NinePatchRect.patch_margin_bottom
@export var overrideSelectedFocusedPatchMarginBottom: int = 0

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
	
	if button_pressed:
		if isFocused:
			if overrideSelectedFocusedPatchMarginTop > 0:
				textureRect.patch_margin_top = overrideSelectedFocusedPatchMarginTop
			if overrideSelectedFocusedPatchMarginBottom > 0:
				textureRect.patch_margin_bottom = overrideSelectedFocusedPatchMarginBottom
			if overrideSelectedFocusedPatchMarginLeft > 0:
				textureRect.patch_margin_left = overrideSelectedFocusedPatchMarginLeft
			if overrideSelectedFocusedPatchMarginRight > 0:
				textureRect.patch_margin_right = overrideSelectedFocusedPatchMarginRight
		else:
			if overrideSelectedPatchMarginTop > 0:
				textureRect.patch_margin_top = overrideSelectedPatchMarginTop
			if overrideSelectedPatchMarginBottom > 0:
				textureRect.patch_margin_bottom = overrideSelectedPatchMarginBottom
			if overrideSelectedPatchMarginLeft > 0:
				textureRect.patch_margin_left = overrideSelectedPatchMarginLeft
			if overrideSelectedPatchMarginRight > 0:
				textureRect.patch_margin_right = overrideSelectedPatchMarginRight
	else:
		if isFocused:
			if overrideUnselectedFocusedPatchMarginTop > 0:
				textureRect.patch_margin_top = overrideUnselectedFocusedPatchMarginTop
			if overrideUnselectedFocusedPatchMarginBottom > 0:
				textureRect.patch_margin_bottom = overrideUnselectedFocusedPatchMarginBottom
			if overrideUnselectedFocusedPatchMarginLeft > 0:
				textureRect.patch_margin_left = overrideUnselectedFocusedPatchMarginLeft
			if overrideUnselectedFocusedPatchMarginRight > 0:
				textureRect.patch_margin_right = overrideUnselectedFocusedPatchMarginRight
		else:
			if overrideUnselectedPatchMarginTop > 0:
				textureRect.patch_margin_top = overrideUnselectedPatchMarginTop
			if overrideUnselectedPatchMarginBottom > 0:
				textureRect.patch_margin_bottom = overrideUnselectedPatchMarginBottom
			if overrideUnselectedPatchMarginLeft > 0:
				textureRect.patch_margin_left = overrideUnselectedPatchMarginLeft
			if overrideUnselectedPatchMarginRight > 0:
				textureRect.patch_margin_right = overrideUnselectedPatchMarginRight

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
