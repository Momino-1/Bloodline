extends Node
## Global game state: progression, discoveries, settings, saving and scene transitions.

signal discovery_added(id: String)

const SAVE_PATH := "user://bloodline_save.json"
const MAIN_MENU := "res://scenes/main_menu/main_menu.tscn"
const LEVELS := [
    {"id": "level_1", "name": "Level 1 · The Lungs", "scene": "res://scenes/levels/level_1_lungs.tscn"},
]

var discovered: Array = []
var completed_levels: Array = []
var quiz_scores: Dictionary = {}
var settings := {"mouse_sensitivity": 0.0025, "volume": 0.8, "fullscreen": false}
var encyclopedia: Array = []

var _fade: ColorRect


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _setup_input()
    _setup_fade()
    var data = load_json("res://data/encyclopedia/entries.json")
    if data is Array:
        encyclopedia = data
    load_game()
    apply_settings()


# ---------------------------------------------------------------- input map
func _setup_input() -> void:
    var map := {
        "move_forward": [KEY_W],
        "move_back": [KEY_S],
        "move_left": [KEY_A],
        "move_right": [KEY_D],
        "move_up": [KEY_SPACE],
        "move_down": [KEY_CTRL, KEY_C],
        "boost": [KEY_SHIFT],
        "interact": [KEY_E],
        "toggle_encyclopedia": [KEY_TAB],
        "pause": [KEY_ESCAPE],
    }
    for action in map:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in map[action]:
            var ev := InputEventKey.new()
            ev.physical_keycode = key
            InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- data
func load_json(path: String) -> Variant:
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        push_error("Could not open " + path)
        return null
    return JSON.parse_string(f.get_as_text())


func get_entry(id: String) -> Dictionary:
    for e in encyclopedia:
        if e["id"] == id:
            return e
    return {}


func is_discovered(id: String) -> bool:
    return discovered.has(id)


func discover(id: String) -> bool:
    if discovered.has(id) or get_entry(id).is_empty():
        return false
    discovered.append(id)
    discovery_added.emit(id)
    save_game()
    return true


# ---------------------------------------------------------------- progression
func new_game() -> void:
    discovered.clear()
    completed_levels.clear()
    quiz_scores.clear()
    save_game()


func complete_level(id: String) -> void:
    if not completed_levels.has(id):
        completed_levels.append(id)
    save_game()


func next_level_index() -> int:
    for i in LEVELS.size():
        if not completed_levels.has(LEVELS[i]["id"]):
            return i
    return LEVELS.size() - 1


# ---------------------------------------------------------------- save / load
func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
    var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f == null:
        return
    f.store_string(JSON.stringify({
        "discovered": discovered,
        "completed_levels": completed_levels,
        "quiz_scores": quiz_scores,
        "settings": settings,
    }))


func load_game() -> void:
    if not has_save():
        return
    var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        return
    var d = JSON.parse_string(f.get_as_text())
    if not d is Dictionary:
        return
    discovered = d.get("discovered", [])
    completed_levels = d.get("completed_levels", [])
    quiz_scores = d.get("quiz_scores", {})
    var s = d.get("settings", {})
    if s is Dictionary:
        for k in s:
            settings[k] = s[k]


func apply_settings() -> void:
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(float(settings["volume"]), 0.0001)))
    var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
    if DisplayServer.window_get_mode() != mode:
        DisplayServer.window_set_mode(mode)


# ---------------------------------------------------------------- transitions
func _setup_fade() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 100
    add_child(layer)
    _fade = ColorRect.new()
    _fade.color = Color.BLACK
    _fade.modulate.a = 0.0
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(_fade)


func change_scene(path: String) -> void:
    _fade.mouse_filter = Control.MOUSE_FILTER_STOP
    var tw := create_tween()
    tw.tween_property(_fade, "modulate:a", 1.0, 0.35)
    await tw.finished
    get_tree().paused = false
    get_tree().change_scene_to_file(path)
    await get_tree().process_frame
    await get_tree().process_frame
    var tw2 := create_tween()
    tw2.tween_property(_fade, "modulate:a", 0.0, 0.5)
    await tw2.finished
    _fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
