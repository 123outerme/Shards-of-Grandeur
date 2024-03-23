extends Resource
class_name CommandResult

@export var damagesDealt: Array[int] = []
@export var damageOnInterceptingTargets: Array[int] = []
@export var afflictedStatuses: Array[bool] = []
@export var wasBoosted: Array[bool] = []
@export var selfBoosted: bool = false

func _init(
	i_damagesDealt: Array[int] = [],
	i_damageOnInterceptingTargets: Array[int] = [],
	i_afflictedStatuses: Array[bool] = [],
	i_wasBoosted: Array[bool] = [],
	i_selfBoosted: bool = false
):
	damagesDealt = i_damagesDealt
	damageOnInterceptingTargets = i_damageOnInterceptingTargets
	afflictedStatuses = i_afflictedStatuses
	wasBoosted = i_wasBoosted
	selfBoosted = i_selfBoosted
