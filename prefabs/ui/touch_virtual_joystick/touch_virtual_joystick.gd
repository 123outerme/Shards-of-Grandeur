extends Control
class_name TouchVirtualJoystick

var initialTouchPosition: Vector2 = Vector2(0, 0)

@onready var baseTexture: TextureRect = get_node('JoystickBaseTexture')
@onready var stickTexture: TextureRect = get_node('JoystickBaseTexture/JoystickStickTexture')

var beingHeld: bool = false
var actionsBeingSent: Array[String] = []
var firstTouchedPosition: Vector2 = Vector2.ZERO
var lastTouchedPosition: Vector2 = Vector2.ZERO
var recheckIsHeld: bool = false

var initialPosition: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	initialPosition = baseTexture.position
	lastTouchedPosition = initialPosition
	firstTouchedPosition = initialPosition

func _physics_process(_delta):
	if visible:
		if recheckIsHeld and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			release_joystick()
		
		if beingHeld and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			lastTouchedPosition = get_local_mouse_position() - (0.5 * baseTexture.size * baseTexture.scale)
		
		baseTexture.position = firstTouchedPosition
		
		var stickPosition: Vector2 = (lastTouchedPosition - baseTexture.position)  / baseTexture.scale
		# bound inside the stick base texture
		stickPosition.x = min(baseTexture.size.x / 2.0, max(-baseTexture.size.x / 2.0, stickPosition.x))
		stickPosition.y = min(baseTexture.size.y / 2.0, max(-baseTexture.size.y / 2.0, stickPosition.y))
		
		stickTexture.position = stickPosition
		if (stickTexture.position.length()) / baseTexture.size.x > SettingsHandler.gameSettings.touchJoystickDeadzone:
			var actions: Array[String] = eight_dir_move_actions(stickPosition)
			for action: String in actions:
				if not action in actionsBeingSent:
					actionsBeingSent.append(action)
					Input.action_press(action)
			for oldAction: String in actionsBeingSent:
				if not oldAction in actions:
					actionsBeingSent.erase(oldAction)
					Input.action_release(oldAction)
		else:
			for oldAction: String in actionsBeingSent:
				actionsBeingSent.erase(oldAction)
				Input.action_release(oldAction)

func eight_dir_move_actions(input: Vector2) -> Array[String]:
	var actions: Array[String] = []
	if input == Vector2.ZERO:
		return actions
	
	var dirNum = ceili((input.angle() - PI / 8) / (PI / 4))
	# angle is [-180, -180] degrees
	# x - 22.5 degrees / 45 degrees => [-4, 4]
	if dirNum > -2 and dirNum < 2: # -1, 0, 1 => +x
		actions.append('move_right')
	if abs(dirNum) == 3 or abs(dirNum) == 4 or dirNum == 3: # -3, -4, 4, 3 => -x
		actions.append('move_left')
	if dirNum > 0 and dirNum < 4: # 1, 2, 3 => +y
		actions.append('move_down')
	if dirNum < 0 and dirNum > -4: # -1, -2, -3 => -y
		actions.append('move_up')
	
	return actions

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# this position is in the local Control coordinate space
			lastTouchedPosition = event.position - (0.5 * baseTexture.size * baseTexture.scale)
			if not beingHeld:
				if SettingsHandler.gameSettings.touchJoystickType == GameSettings.TouchJoystickType.FLOATING:
					firstTouchedPosition = lastTouchedPosition
				beingHeld = true
			baseTexture.modulate.a = 1.0
		else:
			release_joystick()

func recheck_joystick_hold():
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		release_joystick()
	else:
		recheckIsHeld = true

func release_joystick():
	firstTouchedPosition = initialPosition
	lastTouchedPosition = initialPosition
	baseTexture.modulate.a = 0.5
	beingHeld = false
	recheckIsHeld = false
	for action: String in actionsBeingSent:
		Input.action_release(action)
	actionsBeingSent = []
