extends TextureRect
class_name WeatherParticleField

func _ready() -> void:
	SettingsHandler.settings_changed.connect(_settings_changed)
	_settings_changed()

func _settings_changed() -> void:
	visible = not SettingsHandler.gameSettings.disableWeatherParticles
