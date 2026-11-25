extends Control
## Pause menu (Esc).

signal action(act: String)   ## "resume", "encyclopedia", "menu"

const UIKit = preload("res://scripts/ui/ui_kit.gd")
var _first: Button


func _ready() -> void:
	theme = UIKit.make_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	UIKit.dim_background(self, 0.6)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(UIKit.label("PAUSED", 28))
	_first = UIKit.button("Resume", Vector2(280, 46))
	_first.pressed.connect(_emit.bind("resume"))
	col.add_child(_first)
	var enc := UIKit.button("Biology encyclopedia", Vector2(280, 46))
	enc.pressed.connect(_emit.bind("encyclopedia"))
	col.add_child(enc)
	var menu := UIKit.button("Quit to main menu", Vector2(280, 46))
	menu.pressed.connect(_emit.bind("menu"))
	col.add_child(menu)


func open() -> void:
	visible = true
	_first.grab_focus()


func _emit(act: String) -> void:
	visible = false
	action.emit(act)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		_emit("resume")
		get_viewport().set_input_as_handled()
