extends Resource
class_name PuzzleMechanic

func can_solve() -> bool:
	push_error('PuzzleMechanic ', get_script().get_global_name(), ' did not implement can_solve()')
	return false

func solve() -> bool:
	push_error('PuzzleMechanic ', get_script().get_global_name(), ' did not implement solve()')
	return false
