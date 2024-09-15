extends Resource
class_name CommandResult

@export var damagesDealt: Array[int] = []
@export var damageOnInterceptingTargets: Array[int] = []
@export var afflictedStatuses: Array[bool] = []
@export var wasBoosted: Array[bool] = []
@export var equipmentProcd: Array = []
@export var selfBoosted: bool = false
@export var selfRecoilDmg: int = 0
@export var selfAfflictedStatus: bool = false

func _init(
	i_damagesDealt: Array[int] = [],
	i_damageOnInterceptingTargets: Array[int] = [],
	i_afflictedStatuses: Array[bool] = [],
	i_wasBoosted: Array[bool] = [],
	i_equipmentProcd: Array = [],
	i_selfBoosted: bool = false,
	i_selfRecoilDmg: int = 0,
	i_selfAfflictedStatus: bool = false,
):
	damagesDealt = i_damagesDealt
	damageOnInterceptingTargets = i_damageOnInterceptingTargets
	afflictedStatuses = i_afflictedStatuses
	wasBoosted = i_wasBoosted
	equipmentProcd = i_equipmentProcd
	selfBoosted = i_selfBoosted
	selfRecoilDmg = i_selfRecoilDmg
	selfAfflictedStatus = i_selfAfflictedStatus
