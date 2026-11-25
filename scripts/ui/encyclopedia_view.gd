extends Control
## Biology encyclopedia: lists every entry, unlocks it when the player discovers the structure in-game.

signal closed

const UIKit = preload("res://scripts/ui/ui_kit.gd")
const ModelPreview = preload("res://scripts/ui/model_preview.gd")

var _count: Label
var _list: ItemList
var _preview: SubViewportContainer
var _name: Label
var _topic: Label
var _text: RichTextLabel


func _ready() -> void:
	theme = UIKit.make_theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	UIKit.dim_background(self, 0.75)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)
	var head := HBoxContainer.new()
	root.add_child(head)
	var t := UIKit.label("BIOLOGY ENCYCLOPEDIA", 26)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	_count = UIKit.label("", 16, UIKit.ACCENT)
	head.add_child(_count)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	root.add_child(row)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(290, 420)
	_list.item_selected.connect(_on_selected)
	row.add_child(_list)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	right.add_child(top)
	_preview = ModelPreview.new()
	top.add_child(_preview)
	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(names)
	_topic = UIKit.label("", 14, UIKit.ACCENT)
	names.add_child(_topic)
	_name = UIKit.label("", 26, UIKit.TEXT, true)
	_name.custom_minimum_size = Vector2(380, 0)
	names.add_child(_name)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 190)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_text)
	var close := UIKit.button("Close")
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(close_view)
	root.add_child(close)


func open(select_id := "") -> void:
	_list.clear()
	var found := 0
	var select := 0
	for i in GameState.encyclopedia.size():
		var e: Dictionary = GameState.encyclopedia[i]
		var known := GameState.is_discovered(e["id"])
		if known:
			found += 1
		_list.add_item(e["name"] if known else "???  (undiscovered)")
		_list.set_item_disabled(i, false)
		if e["id"] == select_id:
			select = i
	_count.text = "%d / %d discovered" % [found, GameState.encyclopedia.size()]
	visible = true
	_list.select(select)
	_on_selected(select)
	_list.grab_focus()


func close_view() -> void:
	visible = false
	closed.emit()


func _on_selected(i: int) -> void:
	var e: Dictionary = GameState.encyclopedia[i]
	if GameState.is_discovered(e["id"]):
		_name.text = e["name"]
		_topic.text = String(e["topic"]).to_upper()
		_text.text = "[b]Function[/b]\n%s\n\n[b]Scientific explanation[/b]\n%s" % [e["function"], e["explanation"]]
		(_preview as Object).call("set_model", e["shape"])
	else:
		_name.text = "Undiscovered"
		_topic.text = "LOCKED"
		_text.text = "Explore the circulatory system and inspect structures with [b]E[/b] to unlock this entry."
		(_preview as Object).call("set_model", "")


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("toggle_encyclopedia")):
		close_view()
		get_viewport().set_input_as_handled()
