extends Control
## Mission completion screen with a summary of what the player learned.

signal action(act: String)   ## "replay", "next", "menu"

const UIKit = preload("res://scripts/ui/ui_kit.gd")

var _title: Label
var _stats: Label
var _summary: RichTextLabel
var _next: Button
var _replay: Button


func _ready() -> void:
    theme = UIKit.make_theme()
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    visible = false
    UIKit.dim_background(self, 0.8)
    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel := PanelContainer.new()
    center.add_child(panel)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 12)
    panel.add_child(col)
    col.add_child(UIKit.label("MISSION COMPLETE", 14, UIKit.ACCENT))
    _title = UIKit.label("", 32)
    col.add_child(_title)
    col.add_child(HSeparator.new())
    _stats = UIKit.label("", 17, UIKit.ACCENT, true)
    _stats.custom_minimum_size = Vector2(680, 0)
    col.add_child(_stats)
    col.add_child(UIKit.label("What you learned", 20))
    _summary = RichTextLabel.new()
    _summary.bbcode_enabled = true
    _summary.fit_content = true
    _summary.scroll_active = false
    _summary.custom_minimum_size = Vector2(680, 0)
    col.add_child(_summary)
    var row := HBoxContainer.new()
    row.alignment = BoxContainer.ALIGNMENT_END
    row.add_theme_constant_override("separation", 12)
    col.add_child(row)
    var menu := UIKit.button("Main menu")
    menu.pressed.connect(_emit.bind("menu"))
    row.add_child(menu)
    _replay = UIKit.button("Replay level")
    _replay.pressed.connect(_emit.bind("replay"))
    row.add_child(_replay)
    _next = UIKit.button("Next mission")
    _next.pressed.connect(_emit.bind("next"))
    row.add_child(_next)


## data keys: title, stats (Array of String), summary (Array of String), has_next (bool)
func show_results(data: Dictionary) -> void:
    _title.text = data.get("title", "")
    _stats.text = "   ·   ".join(data.get("stats", []))
    var lines := ""
    for s in data.get("summary", []):
        lines += "•  %s\n" % s
    _summary.text = lines.strip_edges()
    _next.visible = data.get("has_next", false)
    visible = true
    (_next if _next.visible else _replay).grab_focus()


func _emit(act: String) -> void:
    visible = false
    action.emit(act)
