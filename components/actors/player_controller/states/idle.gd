extends State
class_name Idle


func check_relevance(input) -> String:
	input.actions.sort_custom(state_priority_sort)
	return input.actions[0]
