extends Control
## Main menu: Start game, Continue, Biology encyclopedia, Settings, Exit.
## The layout (background, buttons, settings panel, confirm dialog) lives in main_menu.tscn.

@onready var _start: Button = %StartButton
@onready var _continue: Button = %ContinueButton
@onready var _wiki: Button = %WikiButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _exit: Button = %ExitButton
@onready var _enc: Control = %Encyclopedia
@onready var _settings: Control = %Settings
@onready var _confirm: ConfirmationDialog = %ConfirmDialog
@onready var _sens: HSlider = %SensSlider
@onready var _vol: HSlider = %VolSlider
@onready var _fs: CheckButton = %FullscreenCheck
@onready var _close: Button = %CloseButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	_continue.disabled = not GameState.has_save()
	_start.pressed.connect(_on_start)
	_continue.pressed.connect(_on_continue)
	_wiki.pressed.connect(func(): _enc.call("open"))
	_settings_btn.pressed.connect(func(): _settings.visible = true)
	_exit.pressed.connect(func(): get_tree().quit())
	_start.grab_focus()

	_sens.value = GameState.settings["mouse_sensitivity"]
	_sens.value_changed.connect(func(v: float): GameState.settings["mouse_sensitivity"] = v)
	_vol.value = GameState.settings["volume"]
	_vol.value_changed.connect(func(v: float):
		GameState.settings["volume"] = v
		GameState.apply_settings())
	_fs.button_pressed = GameState.settings["fullscreen"]
	_fs.toggled.connect(func(on: bool):
		GameState.settings["fullscreen"] = on
		GameState.apply_settings())
	_close.pressed.connect(func():
		GameState.save_game()
		_settings.visible = false)

	_confirm.confirmed.connect(_begin_new)


func _on_start() -> void:
	if GameState.has_save() and (GameState.completed_levels.size() > 0 or GameState.discovered.size() > 0):
		_confirm.popup_centered()
	else:
		_begin_new()


func _begin_new() -> void:
	GameState.new_game()
	GameState.change_scene(GameState.LEVELS[0]["scene"])


func _on_continue() -> void:
	GameState.change_scene(GameState.LEVELS[GameState.next_level_index()]["scene"])
