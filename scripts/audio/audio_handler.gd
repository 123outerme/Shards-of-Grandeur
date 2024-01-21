extends Node
class_name AudioHandler

var musicLoops: int = 0
var sfxLoops: int = 0

@onready var musicStreamPlayer: AudioStreamPlayer = get_node('MusicStreamPlayer')
@onready var sfxStreamPlayer: AudioStreamPlayer = get_node('SfxStreamPlayer')

# Called when the node enters the scene tree for the first time.
func _ready():
	call_deferred('load_audio_settings')
	
func load_audio_settings():
	musicStreamPlayer.volume_db = vol_percent_to_db(SettingsHandler.gameSettings.musicVolume) - 3
	sfxStreamPlayer.volume_db = vol_percent_to_db(SettingsHandler.gameSettings.sfxVolume)

func vol_percent_to_db(percent: float) -> float: # percent as a float between 0 and 1
	if percent < 0.06:
		return -40 # less than 0.06% is below -40 db
	
	# ~-40 db = 0% volume
	# ~10 db = 50%
	# 0 db = 100% volume?
	return 33.22 * log(percent) / log(10) ## 33.22 * log10(percent)

func play_music(stream: AudioStream, loops: int = 0):
	musicStreamPlayer.stream = stream
	musicLoops = loops
	musicStreamPlayer.play()

func play_sfx(stream: AudioStream, loops: int = 0):
	sfxStreamPlayer.stream = stream
	sfxLoops = loops
	sfxStreamPlayer.play()

func _on_music_stream_player_finished():
	if musicLoops > 0:
		musicLoops -= 1
	
	if musicLoops != 0:
		musicStreamPlayer.play()

func _on_sfx_stream_player_finished():
	if sfxLoops > 0:
		sfxLoops -= 1
	
	if sfxLoops != 0:
		sfxStreamPlayer.play()
