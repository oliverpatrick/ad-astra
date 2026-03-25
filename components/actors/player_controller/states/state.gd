#@abstract
extends Node
class_name State

# all-move flags and variables here
var player : CharacterBody3D

static var states_priority : Dictionary = {
	"idle" : 1,
	"run" : 2,
	"jump" : 10  # be generous to not edit this to much when sprint, dash, crouch etc are added
}

static func state_priority_sort(a : String, b : String):
	if states_priority[a] > states_priority[b]:
		return true
	else:
		return false


func check_relevance(_input: InputPackage) -> String:
	print_debug("error, implement the check_relevance function on your state")
	return "error, implement the check_relevance function on your state"


func update(_input: InputPackage, _delta: float):
	pass

func on_enter_state():
	pass
	
func  on_exit_state():
	pass
	
