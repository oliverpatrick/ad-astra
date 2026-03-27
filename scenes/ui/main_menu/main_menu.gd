extends Control

@onready var buttons = $MenuPanel/VBoxContainer.get_children()
@onready var settings_menu: Control = $"../SettingsMenu"
@onready var main_menu: Control = $"."

var index := 0

func _ready():
	update_selection()

func _input(event):	
	if event.is_action_pressed("ui_down"):
		index = (index + 1) % buttons.size()
		update_selection()

	if event.is_action_pressed("ui_up"):
		index = (index - 1 + buttons.size()) % buttons.size()
		update_selection()

	if event.is_action_pressed("ui_accept"):
		activate(buttons[index].text)

func update_selection():
	var off_white := Color(0.78, 0.78, 0.82)
	var selected_bg := StyleBoxFlat.new()
	selected_bg.bg_color = Color(1.0, 0.478, 0.102)
	selected_bg.content_margin_left = 8.0
	selected_bg.content_margin_right = 8.0
	selected_bg.content_margin_top = 4.0
	selected_bg.content_margin_bottom = 4.0
	for i in buttons.size():
		if i == index:
			buttons[i].add_theme_color_override("font_color", Color.WHITE)
			buttons[i].add_theme_stylebox_override("normal", selected_bg)
		else:
			buttons[i].add_theme_color_override("font_color", off_white)
			buttons[i].remove_theme_stylebox_override("normal")

func activate(option):
	print(option)
	match option:
		"Start":
			_on_start_button_pressed()
		"Scene Select":
			_on_scene_select_button_pressed()
		"Settings":
			_on_settings_button_pressed()
		_:
			print(option)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_start_button_pressed() -> void:
	print("Start pressed")
	get_tree().change_scene_to_file("res://scenes/levels/main.tscn")


func _on_scene_select_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby_menu/lobby_menu.tscn")


func _on_settings_button_pressed() -> void:
	main_menu.visible = false
	settings_menu.visible = true
