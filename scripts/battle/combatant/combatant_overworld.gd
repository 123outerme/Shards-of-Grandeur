extends Resource
class_name CombatantOverworld

## the dimensions of the rectangle for the encounter collision box
@export var encounterCollisionSize: Vector2 = Vector2(16, 16)

## the offset from the center of the sprite that the encounter collision should be at
@export var encounterCollisionCenter: Vector2 = Vector2.ZERO

## the radius at which the enemy starts chasing the player
@export var chaseRange: float = 48

## the radius at which the enemy starts chasing a running player
@export var runningChaseRange: float = 96

## the speed at which the enemy patrols and chases a walking player
@export var maxSpeed: float = 40

## the speed at which the enemy chases a running player
@export var runningMaxSpeed: float = 80

func _init(
	i_encounterSize: Vector2 = Vector2(16, 16),
	i_encounterCenter: Vector2 = Vector2.ZERO,
	i_chaseRange: float = 48,
	i_runningChaseRange: float = 96,
	i_maxSpeed: float = 40,
	i_runningMaxSpeed: float = 80,
):
	encounterCollisionSize = i_encounterSize
	encounterCollisionCenter = i_encounterCenter
	chaseRange = i_chaseRange
	runningChaseRange = i_runningChaseRange
	maxSpeed = i_maxSpeed
	runningMaxSpeed = i_runningMaxSpeed
