extends Control

@onready var modal: VBoxContainer = $Modal
@onready var buttons = [
	$LeftContainer/Panel/LeftUIContainer/ButtonsContainer/SwapLobbyButton,
	$LeftContainer/Panel/LeftUIContainer/ButtonsContainer/SceneButton,
	$LeftContainer/Panel/LeftUIContainer/ButtonsContainer/DifficultyButton,
	$LeftContainer/Panel/LeftUIContainer/ButtonsContainer/StartGameButton
]

var selected := 0

func _ready():
	update_selection()

func _input(event):
	if event.is_action_pressed("ui_down"):
		selected = (selected + 1) % buttons.size()
		update_selection()

	if event.is_action_pressed("ui_up"):
		selected = (selected - 1 + buttons.size()) % buttons.size()
		update_selection()

	if event.is_action_pressed("ui_accept"):
		activate(buttons[selected].text)

func update_selection():
	for i in buttons.size():
		if i == selected:
			buttons[i].add_theme_color_override("font_color", Color(1,0.6,0.2))
		else:
			buttons[i].add_theme_color_override("font_color", Color.WHITE)

func activate(name: String):
	match name:
		"SWITCH LOBBY":
			print("Switching lobby")
		"START GAME":
			print("Starting game")
		"EDIT CAMPAIGN OPTIONS":
			print("Opening options")

func _on_scene_button_pressed() -> void:
	modal.visible = true


func _on_back_button_pressed() -> void:
	modal.visible = false


func _on_back_to_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
