extends AudioHandler

func play_music(stream: AudioStream, loops: int = 0):
	pass

func play_sfx(stream: AudioStream, loops: int = 0, varyPitch: bool = false, sfxPlayerIdx: int = -1) -> int:
	return -1

func fade_out_music(sec: float = 0.5):
	music_fade_completed.emit()

func fade_in_music(sec: float = 0.5, loops: int = -1):
	music_fade_completed.emit()

func fade_in_new_music(stream: AudioStream, loops: int, ms: float):
	pass
