extends Node3D
## LEVEL 1: THE LUNGS. Pulmonary capillary wrapped around alveoli.
## Flow: briefing → inspect alveolus → collect O₂ until haemoglobin is saturated → quiz → swim to pulmonary vein.

const HudScene = preload("res://scenes/ui/hud.tscn")
const InfoScene = preload("res://scenes/ui/info_panel.tscn")
const QuizScene = preload("res://scenes/ui/quiz_panel.tscn")
const EncScene = preload("res://scenes/ui/encyclopedia.tscn")
const CompletionScene = preload("res://scenes/ui/completion_screen.tscn")
const PauseScene = preload("res://scenes/ui/pause_menu.tscn")
const OxygenScene = preload("res://scenes/interactables/oxygen_molecule.tscn")
const ModelFactory = preload("res://scripts/gameplay/model_factory.gd")

const LEVEL_ID := "level_1"
const DATA_PATH := "res://data/questions/level_1.json"
const TUBE_LENGTH := 170.0
const TUBE_RADIUS := 9.0
const ALVEOLUS_RADIUS := 9.0
const FLOW_SPEED := 4.0
const MAX_MOLECULES := 50

enum State { INTRO, EXPLORE, COLLECT, QUIZ, EXIT, DONE }

var state: State = State.INTRO
var data: Dictionary = {}
@onready var player = %Player
@onready var _exit_ring: MeshInstance3D = %ExitRing
@onready var _exit_label: Label3D = %ExitLabel
var hud
var info
var quiz
var enc
var completion
var pause_menu
var _panels: Array = []
var _alveoli: Array = []
var _cells: Array = []
var _exit_mat: StandardMaterial3D
var _quiz_attempted := false
var _quiz_correct := 0
var _quiz_total := 0
var _warn_cd := 0.0
var _burst_cd := 0.0


func _ready() -> void:
	var d = GameState.load_json(DATA_PATH)
	data = d if d is Dictionary else {}
	OxygenSystem.reset()
	_gather_scene_nodes()
	_build_ui()
	OxygenSystem.fully_saturated.connect(func(): call_deferred("_on_saturated"))
	_show_intro()


# ------------------------------------------------------------------ scene wiring
## Everything you see (vessel, alveoli, cells, lights, exit ring, player) now lives in
## level_1_lungs.tscn. This just hooks the scene's nodes up to the game logic.
func _gather_scene_nodes() -> void:
	player.teleport(player.position)
	player.interaction_target_changed.connect(_on_target_changed)

	_exit_mat = _exit_ring.material_override

	for node in $Alveoli.get_children():
		_alveoli.append({"center": node.global_position, "node": node, "timer": randf() * 1.5})

	for body in $Cells.get_children():
		var mi: MeshInstance3D = body.get_node("Mesh")
		mi.material_override = mi.material_override.duplicate()   # each cell tints on its own
		body.rotation = Vector3(randf(), randf(), randf()) * TAU
		_cells.append({"body": body, "mat": mi.material_override,
				"axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(),
				"spin": randf_range(0.3, 1.0)})

	for it in get_tree().get_nodes_in_group("interactable"):
		if not it.interacted.is_connected(_on_interacted):
			it.interacted.connect(_on_interacted)


func _random_lumen_point(margin: float) -> Vector2:
	var r := sqrt(randf()) * (TUBE_RADIUS - margin)
	var a := randf() * TAU
	return Vector2(cos(a), sin(a)) * r


func _build_ui() -> void:
	hud = HudScene.instantiate()
	add_child(hud)
	hud.set_location("Pulmonary capillary · Lungs")
	var layer := CanvasLayer.new()
	layer.layer = 10
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	info = InfoScene.instantiate()
	quiz = QuizScene.instantiate()
	enc = EncScene.instantiate()
	completion = CompletionScene.instantiate()
	pause_menu = PauseScene.instantiate()
	for p in [info, quiz, enc, completion, pause_menu]:
		layer.add_child(p)
		p.visibility_changed.connect(_refresh_ui_mode)
		_panels.append(p)
	quiz.finished.connect(_on_quiz_finished)
	pause_menu.action.connect(_on_pause_action)
	completion.action.connect(_on_completion_action)


# ------------------------------------------------------------------ per-frame
func _flow_at(p: Vector3) -> Vector3:
	var r := Vector2(p.x, p.y).length() / TUBE_RADIUS
	return Vector3(0, 0, -FLOW_SPEED * (1.0 - 0.75 * r * r))


func _physics_process(delta: float) -> void:
	_warn_cd = maxf(0.0, _warn_cd - delta)
	_burst_cd = maxf(0.0, _burst_cd - delta)
	player.current_flow = _flow_at(player.position) * 0.75
	if Vector2(player.position.x, player.position.y).length() > TUBE_RADIUS + 3.0:
		player.teleport(Vector3(0, 0, player.position.z))

	for c in _cells:
		var b: AnimatableBody3D = c["body"]
		var p: Vector3 = b.position + _flow_at(b.position) * delta
		if p.z < -TUBE_LENGTH + 6.0:
			var xy := _random_lumen_point(3.5)
			p = Vector3(xy.x, xy.y, -2.0)
		b.position = p
		b.rotate(c["axis"], c["spin"] * delta)
		ModelFactory.apply_oxygenation(c["mat"], clampf((-p.z - 25.0) / 55.0, 0.0, 1.0))

	var molecules := get_tree().get_nodes_in_group("oxygen").size()
	for a in _alveoli:
		a["timer"] -= delta
		if a["timer"] <= 0.0:
			a["timer"] = randf_range(0.8, 1.6)
			if molecules < MAX_MOLECULES and player.position.distance_to(a["center"]) < 50.0:
				_spawn_oxygen(a)
				molecules += 1


func _spawn_oxygen(a: Dictionary) -> void:
	var c: Vector3 = a["center"]
	var toward := Vector3(-c.x, -c.y, 0.0).normalized()
	var best := c + toward * ALVEOLUS_RADIUS
	var dir := toward
	for attempt in 8:
		var rnd := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		var d := (toward + rnd * 0.55).normalized()
		var p := c + d * ALVEOLUS_RADIUS
		if Vector2(p.x, p.y).length() < TUBE_RADIUS - 0.8:
			best = p
			dir = d
			break
	var m = OxygenScene.instantiate()
	m.position = best
	m.drift = dir * randf_range(2.0, 3.5)
	add_child(m)


# ------------------------------------------------------------------ flow of the mission
func _show_intro() -> void:
	state = State.INTRO
	hud.set_objective("Read the mission briefing.")
	var t: Dictionary = data["text"]["briefing"]
	info.show_info({"title": t["title"], "topic": t["topic"], "body": t["body"], "shape": "disc"})
	await info.dismissed
	GameState.discover("erythrocyte")
	GameState.discover("capillary")
	state = State.EXPLORE
	hud.set_objective("Swim downstream to a glowing alveolus (pale blue dome) and press E to inspect it.")


func _entry_panel(id: String, extra := "", with_quiz := false) -> String:
	var e: Dictionary = GameState.get_entry(id)
	var body := "[b]Function[/b]\n%s\n\n[b]Scientific explanation[/b]\n%s" % [e.get("function", ""), e.get("explanation", "")]
	if extra != "":
		body = extra + "\n\n" + body
	info.show_info({"title": e.get("name", id), "topic": e.get("topic", ""), "body": body, "shape": e.get("shape", ""), "quiz": with_quiz})
	GameState.discover(id)
	return await info.dismissed


func _on_target_changed(t: Node) -> void:
	hud.set_prompt("" if t == null else "[E]  " + String(t.prompt))


func _on_interacted(it) -> void:
	match String(it.interact_id):
		"alveolus":
			_interact_alveolus(it)
		"erythrocyte":
			_entry_panel("erythrocyte", data["text"]["cell_extra"])
		"capillary":
			_entry_panel("capillary", data["text"]["capillary_extra"])


func _interact_alveolus(it) -> void:
	var a: Dictionary = {}
	for x in _alveoli:
		if x["node"] == it.get_parent():
			a = x
	if state == State.EXPLORE:
		await _entry_panel("alveolus", data["text"]["alveolus_extra"])
		await _entry_panel("diffusion", data["text"]["diffusion_extra"])
		state = State.COLLECT
		hud.set_objective("Collect the light-blue oxygen molecules until your haemoglobin is fully saturated.")
		for i in 10:
			_spawn_oxygen(a)
	elif _burst_cd <= 0.0:
		_burst_cd = 4.0
		for i in 8:
			_spawn_oxygen(a)
		hud.toast("O₂ diffuses into the blood: its partial pressure is higher in the alveolus than in your blood.")
	else:
		hud.toast("Oxygen is still crossing the membrane…")


func _on_saturated() -> void:
	if state != State.COLLECT and state != State.EXPLORE:
		return
	state = State.QUIZ
	var action: String = await _entry_panel("haemoglobin", data["text"]["saturated"], true)
	if action == "quiz":
		quiz.start(DATA_PATH)
	else:
		_begin_exit()


func _on_quiz_finished(correct: int, total: int) -> void:
	_quiz_attempted = true
	_quiz_correct = correct
	_quiz_total = total
	GameState.quiz_scores[LEVEL_ID] = {"correct": correct, "total": total}
	hud.toast("Knowledge check: %d / %d correct" % [correct, total], Color(0.5, 0.9, 0.58))
	_begin_exit()


func _begin_exit() -> void:
	state = State.EXIT
	_exit_mat.emission_energy_multiplier = 3.0
	_exit_label.visible = true
	hud.set_objective("Swim to the glowing ring at the end of the capillary. The pulmonary vein carries your oxygen-rich blood to the heart.")


func _on_exit_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or state == State.DONE:
		return
	if state == State.EXIT:
		_complete()
	elif _warn_cd <= 0.0:
		_warn_cd = 4.0
		hud.toast("Fill your haemoglobin with oxygen before leaving the lungs.")


func _complete() -> void:
	state = State.DONE
	GameState.complete_level(LEVEL_ID)
	var stats: Array = ["Haemoglobin saturation %d %%" % roundi(OxygenSystem.saturation() * 100.0)]
	if _quiz_attempted:
		stats.append("Knowledge check %d / %d" % [_quiz_correct, _quiz_total])
	else:
		stats.append("Knowledge check skipped (replay to try it)")
	stats.append("Discoveries %d / %d" % [GameState.discovered.size(), GameState.encyclopedia.size()])
	completion.show_results({
		"title": String(data["title"]) + " · complete",
		"stats": stats,
		"summary": data["summary"],
		"has_next": _level_index() + 1 < GameState.LEVELS.size(),
	})


# ------------------------------------------------------------------ UI plumbing
func _refresh_ui_mode() -> void:
	var open := false
	for p in _panels:
		if p.visible:
			open = true
	get_tree().paused = open
	player.controls_enabled = not open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_menu.open()
	elif event.is_action_pressed("toggle_encyclopedia"):
		enc.open()


func _on_pause_action(act: String) -> void:
	match act:
		"encyclopedia":
			enc.open()
		"menu":
			GameState.change_scene(GameState.MAIN_MENU)


func _level_index() -> int:
	for i in GameState.LEVELS.size():
		if GameState.LEVELS[i]["id"] == LEVEL_ID:
			return i
	return 0


func _on_completion_action(act: String) -> void:
	match act:
		"replay":
			GameState.change_scene(scene_file_path)
		"next":
			GameState.change_scene(GameState.LEVELS[mini(_level_index() + 1, GameState.LEVELS.size() - 1)]["scene"])
		"menu":
			GameState.change_scene(GameState.MAIN_MENU)
