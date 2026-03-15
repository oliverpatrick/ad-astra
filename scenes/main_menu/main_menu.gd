extends Control

@onready var buttons = $MenuPanel/VBoxContainer.get_children()
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
		"Campaign":
			print("Start campaign")
		"Matchmaking":
			print("Matchmaking")
		_:
			print(option)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
