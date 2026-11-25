extends Control
## Reusable educational panel: heading, 3D illustration, explanation, Continue / Knowledge check.

signal dismissed(action: String)   ## "continue" or "quiz"

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ModelPreview = preload("res://scripts/ui/model_preview.gd")

var _title: Label
var _topic: Label
var _body: RichTextLabel
var _preview: SubViewportContainer
var _continue: Button
var _quiz: Button


func _ready() -> void:
	theme = UIKit.make_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	UIKit.dim_background(self, 0.55)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	panel.add_child(row)
	_preview = ModelPreview.new()
	_preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_preview)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	_topic = UIKit.label("", 14, UIKit.ACCENT)
	col.add_child(_topic)
	_title = UIKit.label("", 30)
	col.add_child(_title)
	col.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, 300)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)
	_quiz = UIKit.button("Knowledge check")
	_quiz.pressed.connect(_finish.bind("quiz"))
	buttons.add_child(_quiz)
	_continue = UIKit.button("Continue")
	_continue.pressed.connect(_finish.bind("continue"))
	buttons.add_child(_continue)


## data keys: title, topic, body (BBCode), shape, quiz (bool)
func show_info(data: Dictionary) -> void:
	_title.text = data.get("title", "")
	_topic.text = String(data.get("topic", "")).to_upper()
	_body.text = data.get("body", "")
	(_preview as Object).call("set_model", data.get("shape", ""))
	_quiz.visible = data.get("quiz", false)
	visible = true
	if _quiz.visible:
		_quiz.grab_focus()
	else:
		_continue.grab_focus()


func _finish(action: String) -> void:
	visible = false
	dismissed.emit(action)
