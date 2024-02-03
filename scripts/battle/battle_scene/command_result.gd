extends Resource
class_name CommandResult

@export var damagesDealt: Array[int] = []
@export var damageOnInterceptingTargets: Array[int] = []
@export var afflictedStatuses: Array[bool] = []

func _init(
	i_damagesDealt: Array[int] = [],
	i_damageOnInterceptingTargets: Array[int] = [],
	i_afflictedStatuses: Array[bool] = [],
):
	damagesDealt = i_damagesDealt
	damageOnInterceptingTargets = i_damageOnInterceptingTargets
	afflictedStatuses = i_afflictedStatuses
