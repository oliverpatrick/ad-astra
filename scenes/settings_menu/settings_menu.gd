extends Control

@onready var tab_buttons: Array[Button] = [
	$Panel/VBoxContainer/TabBar/GeneralTab,
	$Panel/VBoxContainer/TabBar/DisplayTab,
	$Panel/VBoxContainer/TabBar/AudioTab,
	$Panel/VBoxContainer/TabBar/ControlsTab,
]
@onready var tab_contents: Array[Control] = [
	$Panel/VBoxContainer/Content/GeneralContent,
	$Panel/VBoxContainer/Content/DisplayContent,
	$Panel/VBoxContainer/Content/AudioContent,
	$Panel/VBoxContainer/Content/ControlsContent,
]

# Display
@onready var window_mode_option: OptionButton = $Panel/VBoxContainer/Content/DisplayContent/WindowModeRow/WindowModeOption
@onready var vsync_toggle: CheckButton = $Panel/VBoxContainer/Content/DisplayContent/VSyncRow/VSyncToggle
@onready var resolution_option: OptionButton = $Panel/VBoxContainer/Content/DisplayContent/ResolutionRow/ResolutionOption

# Audio
@onready var master_slider: HSlider = $Panel/VBoxContainer/Content/AudioContent/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/Content/AudioContent/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/Content/AudioContent/SFXRow/SFXSlider
@onready var master_value: Label = $Panel/VBoxContainer/Content/AudioContent/MasterRow/MasterValue
@onready var music_value: Label = $Panel/VBoxContainer/Content/AudioContent/MusicRow/MusicValue
@onready var sfx_value: Label = $Panel/VBoxContainer/Content/AudioContent/SFXRow/SFXValue

# Controls
@onready var sensitivity_slider: HSlider = $Panel/VBoxContainer/Content/ControlsContent/SensitivityRow/SensitivitySlider
@onready var sensitivity_value: Label = $Panel/VBoxContainer/Content/ControlsContent/SensitivityRow/SensitivityValue
@onready var invert_y_toggle: CheckButton = $Panel/VBoxContainer/Content/ControlsContent/InvertYRow/InvertYToggle

var current_tab := 0

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const ACCENT := Color(1.0, 0.478, 0.102)
const OFF_WHITE := Color(0.78, 0.78, 0.82)


func _ready() -> void:
	_populate_options()
	_load_settings()
	_switch_tab(0)

	for i in tab_buttons.size():
		var idx := i
		tab_buttons[i].pressed.connect(_switch_tab.bind(idx))

	# Display signals
	window_mode_option.item_selected.connect(_on_window_mode_changed)
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	resolution_option.item_selected.connect(_on_resolution_changed)

	# Audio signals
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# Controls signals
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)


func _populate_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("Fullscreen", 0)
	window_mode_option.add_item("Windowed", 1)
	window_mode_option.add_item("Borderless Windowed", 2)

	resolution_option.clear()
	for res in RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [res.x, res.y])


func _load_settings() -> void:
	# Window mode
	match DisplayServer.window_get_mode():
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			window_mode_option.selected = 0
		DisplayServer.WINDOW_MODE_WINDOWED:
			window_mode_option.selected = 1
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			window_mode_option.selected = 0
		_:
			window_mode_option.selected = 1

	# VSync
	vsync_toggle.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

	# Resolution
	var current_res := DisplayServer.window_get_size()
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == current_res:
			resolution_option.selected = i
			break

	# Audio - read from AudioServer buses
	_load_bus_volume("Master", master_slider, master_value)
	_load_bus_volume("Music", music_slider, music_value)
	_load_bus_volume("SFX", sfx_slider, sfx_value)

	# Controls
	sensitivity_slider.value = 0.5
	sensitivity_value.text = "50%"


func _load_bus_volume(bus_name: String, slider: HSlider, label: Label) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var db := AudioServer.get_bus_volume_db(bus_idx)
		slider.value = db_to_linear(db) * 100.0
	else:
		slider.value = 100.0
	label.text = "%d%%" % int(slider.value)


func _switch_tab(index: int) -> void:
	current_tab = index
	for i in tab_contents.size():
		tab_contents[i].visible = (i == index)
	_update_tab_style()


func _update_tab_style() -> void:
	var selected_bg := StyleBoxFlat.new()
	selected_bg.bg_color = ACCENT
	selected_bg.content_margin_left = 12.0
	selected_bg.content_margin_right = 12.0
	selected_bg.content_margin_top = 6.0
	selected_bg.content_margin_bottom = 6.0
	selected_bg.corner_radius_top_left = 4
	selected_bg.corner_radius_top_right = 4

	for i in tab_buttons.size():
		if i == current_tab:
			tab_buttons[i].add_theme_color_override("font_color", Color.WHITE)
			tab_buttons[i].add_theme_stylebox_override("normal", selected_bg)
			tab_buttons[i].add_theme_stylebox_override("hover", selected_bg)
		else:
			tab_buttons[i].add_theme_color_override("font_color", OFF_WHITE)
			tab_buttons[i].remove_theme_stylebox_override("normal")
			tab_buttons[i].remove_theme_stylebox_override("hover")


# --- Display callbacks ---

func _on_window_mode_changed(index: int) -> void:
	match index:
		0: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		1: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)


func _on_vsync_toggled(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_resolution_changed(index: int) -> void:
	var res: Vector2i = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)


# --- Audio callbacks ---

func _on_master_changed(value: float) -> void:
	_set_bus_volume("Master", value)
	master_value.text = "%d%%" % int(value)


func _on_music_changed(value: float) -> void:
	_set_bus_volume("Music", value)
	music_value.text = "%d%%" % int(value)


func _on_sfx_changed(value: float) -> void:
	_set_bus_volume("SFX", value)
	sfx_value.text = "%d%%" % int(value)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))


# --- Controls callbacks ---

func _on_sensitivity_changed(value: float) -> void:
	sensitivity_value.text = "%d%%" % int(value)


# --- Navigation ---

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
