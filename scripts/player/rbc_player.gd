extends CharacterBody3D
## The playable red blood cell: free 3D swimming, third-person camera, interaction scanning.

signal interaction_target_changed(target: Node)

const ModelFactory = preload("res://scripts/gameplay/model_factory.gd")

@export var move_speed := 9.0
@export var boost_multiplier := 1.9
@export var acceleration := 5.0

var controls_enabled := false
var current_flow := Vector3.ZERO   ## set by the level (blood current)

var _yaw := 0.0
var _pitch := -0.12
var _t := 0.0
@onready var _pivot: Node3D = $Pivot
@onready var _spring: SpringArm3D = $Pivot/SpringArm3D
@onready var _camera: Camera3D = $Pivot/SpringArm3D/Camera3D
@onready var _visual: Node3D = $Visual
var _mat: StandardMaterial3D
var _target: Node = null


func _ready() -> void:
	add_to_group("player")
	# body, mesh, lamp, motes and camera rig are all nodes in rbc_player.tscn
	_mat = $Visual/Mesh.material_override.duplicate()
	$Visual/Mesh.material_override = _mat
	_spring.add_excluded_object(get_rid())
	OxygenSystem.oxygen_changed.connect(_on_oxygen_changed)
	_on_oxygen_changed(OxygenSystem.current, OxygenSystem.CAPACITY)


func teleport(pos: Vector3) -> void:
	position = pos
	velocity = Vector3.ZERO
	_pivot.global_position = global_position + Vector3(0, 0.5, 0)


func _on_oxygen_changed(cur: float, cap: float) -> void:
	ModelFactory.apply_oxygenation(_mat, cur / cap)


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s: float = GameState.settings["mouse_sensitivity"]
		_yaw -= event.relative.x * s
		_pitch = clampf(_pitch - event.relative.y * s, -1.3, 1.2)
	elif event.is_action_pressed("interact") and _target != null:
		_target.call("interact", self)


func _physics_process(delta: float) -> void:
	_t += delta
	var dir := Vector3.ZERO
	var boosting := false
	if controls_enabled:
		var f := Input.get_axis("move_back", "move_forward")
		var r := Input.get_axis("move_left", "move_right")
		var u := Input.get_axis("move_down", "move_up")
		dir = _pivot.global_transform.basis * Vector3(r, 0, -f) + Vector3.UP * u
		if dir.length() > 1.0:
			dir = dir.normalized()
		boosting = Input.is_action_pressed("boost")
	var speed := move_speed * (boost_multiplier if boosting else 1.0)
	var target_vel := dir * speed + current_flow
	velocity = velocity.lerp(target_vel, 1.0 - exp(-acceleration * delta))
	move_and_slide()
	_update_target()
	_camera.fov = lerpf(_camera.fov, 82.0 if boosting else 70.0, 1.0 - exp(-5.0 * delta))


func _process(delta: float) -> void:
	_pivot.global_position = _pivot.global_position.lerp(global_position + Vector3(0, 0.5, 0), 1.0 - exp(-14.0 * delta))
	_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
	var lv := _pivot.global_transform.basis.inverse() * velocity
	var k := 1.0 - exp(-6.0 * delta)
	_visual.rotation.x = lerp_angle(_visual.rotation.x, clampf(lv.z * 0.04, -0.45, 0.45) + sin(_t * 1.7) * 0.06, k)
	_visual.rotation.z = lerp_angle(_visual.rotation.z, clampf(-lv.x * 0.04, -0.45, 0.45) + sin(_t * 1.3 + 1.0) * 0.06, k)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, _yaw, k)
	_visual.position.y = sin(_t * 2.0) * 0.06
	var pulse := 1.0 + sin(_t * 2.4) * 0.015
	_visual.scale = Vector3(pulse, 1.0, pulse)


func _update_target() -> void:
	var best: Node = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not n.enabled:
			continue
		var d: float = global_position.distance_to(n.global_position) - n.surface_radius
		if d < n.interact_range and d < best_d:
			best_d = d
			best = n
	if best != _target:
		_target = best
		interaction_target_changed.emit(best)
