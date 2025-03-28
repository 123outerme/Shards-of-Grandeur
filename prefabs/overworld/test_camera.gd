extends Camera2D
class_name TestCamera

const WALK_SPEED = 80
const RUN_SPEED = 120

var fullscreenTimeout: float = 0
var speed: float = WALK_SPEED

# Called when the node enters the scene tree for the first time.
func _ready():
	if PlayerFinder.player != null:
		enabled = false
		queue_free()

func _physics_process(delta):
	var velocity: Vector2 = eight_dir_movement(Input.get_vector("move_left", "move_right", "move_up", "move_down")) * speed
	position += velocity * delta
	if fullscreenTimeout > 0:
		fullscreenTimeout -= delta

func eight_dir_movement(input: Vector2) -> Vector2:
	var output: Vector2 = Vector2.ZERO
	if input == output:
		return output
	
	var dirNum = ceili((input.angle() - PI / 8) / (PI / 4))
	# angle is [-180, -180] degrees
	# x - 22.5 degrees / 45 degrees => [-4, 4]
	if dirNum > -2 and dirNum < 2: # -1, 0, 1 => +x
		output.x = 1
	if abs(dirNum) == 3 or abs(dirNum) == 4 or dirNum == 3: # -3, -4, 4, 3 => -x
		output.x = -1
	if dirNum > 0 and dirNum < 4: # 1, 2, 3 => +y
		output.y = 1
	if dirNum < 0 and dirNum > -4: # -1, -2, -3 => -y
		output.y = -1
	
	return output.normalized()

func _unhandled_input(event: InputEvent) -> void:
	if fullscreenTimeout <= 0 and event is InputEventKey and event.keycode == KEY_F11:
		fullscreenTimeout = 1
		SettingsHandler.gameSettings.fullscreen = not SettingsHandler.gameSettings.fullscreen
		SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		SettingsHandler.gameSettings.fullscreen = false
		SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	if event.is_action_pressed('game_decline'):
		speed = RUN_SPEED if speed == WALK_SPEED else WALK_SPEED
	if event.is_action_pressed("game_console"):
		print(position)
