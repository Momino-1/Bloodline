extends SubViewportContainer
## A small rotating 3D illustration of a biological structure.

const ModelFactory = preload("res://scripts/gameplay/model_factory.gd")

var _vp: SubViewport
var _pivot: Node3D


func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(250, 250)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 3.9)
	cam.rotation_degrees = Vector3(-14, 0, 0)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.45, 0.5)
	env.ambient_light_energy = 0.8
	cam.environment = env
	_vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.2
	_vp.add_child(sun)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)


func set_model(shape: String) -> void:
	for c in _pivot.get_children():
		c.queue_free()
	if shape != "":
		_pivot.add_child(ModelFactory.make_model(shape))


func _process(delta: float) -> void:
	if visible:
		_pivot.rotate_y(delta * 0.8)
