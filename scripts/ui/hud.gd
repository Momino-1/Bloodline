extends CanvasLayer
## In-game HUD: oxygen capacity, location, objective, discoveries, interaction prompt, toasts.

const UIKit = preload("res://scripts/ui/ui_kit.gd")

## The layout (panels, labels, oxygen bar, prompt, toast container) lives in hud.tscn.
@onready var _location: Label = %Location
@onready var _objective: Label = %Objective
@onready var _discoveries: Label = %Discoveries
@onready var _o2_bar: ProgressBar = %OxygenBar
@onready var _o2_label: Label = %OxygenLabel
@onready var _prompt_panel: PanelContainer = %PromptPanel
@onready var _prompt: Label = %Prompt
@onready var _toasts: VBoxContainer = %Toasts


func _ready() -> void:
	_o2_bar.max_value = OxygenSystem.CAPACITY
	OxygenSystem.oxygen_changed.connect(_on_oxygen)
	GameState.discovery_added.connect(_on_discovery)
	_on_oxygen(OxygenSystem.current, OxygenSystem.CAPACITY)
	_update_discoveries()


func set_location(text: String) -> void:
	_location.text = text


func set_objective(text: String) -> void:
	_objective.text = text
	_objective.modulate = Color(1.6, 1.6, 1.6)
	create_tween().tween_property(_objective, "modulate", Color.WHITE, 1.0)


func set_prompt(text: String) -> void:
	_prompt_panel.visible = text != ""
	_prompt.text = text


func toast(text: String, color := UIKit.TEXT) -> void:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UIKit.label(text, 17, color, true)
	l.custom_minimum_size = Vector2(0, 0)
	p.add_child(l)
	_toasts.add_child(p)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


func _on_oxygen(cur: float, cap: float) -> void:
	_o2_bar.value = cur
	_o2_label.text = "%d / %d     Haemoglobin saturation %d %%" % [roundi(cur), roundi(cap), roundi(cur / cap * 100.0)]


func _on_discovery(id: String) -> void:
	_update_discoveries()
	toast("New discovery: " + String(GameState.get_entry(id).get("name", id)), UIKit.ACCENT)


func _update_discoveries() -> void:
	_discoveries.text = "Discoveries  %d / %d" % [GameState.discovered.size(), GameState.encyclopedia.size()]
