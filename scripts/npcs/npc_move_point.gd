extends Resource
class_name NPCMovePoint

## the position to move the NPC to at this step
@export var position: Vector2 = Vector2.ZERO
## if true, the NPC's move point will be located this many units away from its current position. If false, will be treated as absolute map coordinates
@export var relativeToCurrentPos: bool = false
## if above 0, will pause the NPC after making this move, for the specified amount of time
@export var pauseSecs: float = 0.0

func _init(
	i_position = Vector2.ZERO,
	i_relative = false,
	i_pauseSecs = 0.0,
):
	position = i_position
	relativeToCurrentPos = i_relative
	pauseSecs = i_pauseSecs
