extends Node
class_name Humanoid

@onready var player_character: PlayerCharacter = $".."
# // skeleton
# // animator

# active_weapon

@onready var current_state: State

@onready var states = {
	"idle": $StateMachine/Grounded/Idle,
	#"walk": $StateMachine/Grounded/Walk,
	"run": $StateMachine/Grounded/Run,
	#"jump": $StateMachine/Airborne/Jump,
	#"crouch": $StateMachine/Grounded/Crouch
}

func _ready():
	current_state = states["idle"]
	for state in states.values():
		state.player = player_character


func update(input : InputPackage, delta : float):
	var relevance = current_state.check_relevance(input)
	if relevance != "okay":
		switch_to(relevance)
	current_state.update(input, delta)


func switch_to(state : String):
	current_state.on_exit_state()
	current_state = states[state]
	current_state.on_enter_state()
