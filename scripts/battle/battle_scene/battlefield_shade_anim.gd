extends Resource
class_name BattlefieldShadeAnim

## seconds from move animation start to start the shade animating
@export var startSecs: float = 0

## how long the shade should last. -1 to automatically last until the end of the move animation
@export var lastsSecs: float = -1

## the color the shade should take on
@export var color: Color = Color(0, 0, 0, 0.35)

## fade in transition time 
@export var fadeInSecs: float = 0.5

## fade out transition time
@export var fadeOutSecs: float = 0.25

func _init(
	i_startSecs = 0,
	i_lastsSecs = -1,
	i_color = Color(0, 0, 0, 0.35),
	i_fadeInSecs = 0.5,
	i_fadeOutSecs = 0.25,
):
	startSecs = i_startSecs
	lastsSecs = i_lastsSecs
	color = i_color
	fadeInSecs = i_fadeInSecs
	fadeOutSecs = i_fadeOutSecs
