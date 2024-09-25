extends Panel
class_name AnimatedBgPanel

@onready var shardsTexture: TextureRect = get_node('ShardsTexture')

var textureX: int = 48
var textureY: int = 48

func _ready() -> void:
	shardsTexture.position = Vector2.ZERO
	textureX = roundi(shardsTexture.texture.get_size().x) * shardsTexture.scale.x
	textureY = roundi(shardsTexture.texture.get_size().y) * shardsTexture.scale.y
	SettingsHandler.settings_changed.connect(_settings_changed)

func _process(delta: float) -> void:
	if SettingsHandler.gameSettings.backgroundMotion and is_visible_in_tree():
		# position ranges from 0,0 to -1 * (textureX - 1), -1 * (textureY - 1)
		shardsTexture.position -= Vector2(60 * delta, 60 * delta)
		if shardsTexture.position.x < -1 * textureX:
			shardsTexture.position.x += textureX
		if shardsTexture.position.y < -1 * textureY:
			shardsTexture.position.y += textureY

func _settings_changed() -> void:
	if not SettingsHandler.gameSettings.backgroundMotion:
		shardsTexture.position = Vector2(0, 0)
