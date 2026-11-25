extends SubViewportContainer
## Slowly drifting red blood cells behind the main menu.
## The cells, camera, light and environment are nodes in menu_background.tscn; this only animates them.

@onready var _cam: Camera3D = $SubViewport/Camera3D

var _cells: Array = []
var _t := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for n in $SubViewport/Cells.get_children():
		_cells.append({"node": n, "spin": Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5), rng.randf_range(-0.3, 0.3))})


func _process(delta: float) -> void:
	_t += delta
	for c in _cells:
		var n: MeshInstance3D = c["node"]
		n.rotation += c["spin"] * delta
		n.position.z += delta * 0.8
		if n.position.z > 6.0:
			n.position.z = -30.0
	_cam.position.x = sin(_t * 0.15) * 1.2
	_cam.position.y = cos(_t * 0.11) * 0.6
