@tool
extends StaticBody3D
## Blood vessel tube. Needs children: MeshInstance3D "Mesh" and CollisionShape3D "Shape".
## Mesh, collision AND material are all rebuilt from here, so nothing can get lost.

const VesselBuilder = preload("res://scripts/gameplay/vessel_builder.gd")

@export var length := 170.0:
	set(v):
		length = v
		_rebuild()
@export var radius := 9.0:
	set(v):
		radius = v
		_rebuild()
@export var noise_seed := 7:
	set(v):
		noise_seed = v
		_rebuild()
@export_range(20, 300) var rings := 100:
	set(v):
		rings = v
		_rebuild()
@export_range(12, 120) var segments := 40:
	set(v):
		segments = v
		_rebuild()

static var _material: StandardMaterial3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	var mi: MeshInstance3D = get_node_or_null("Mesh")
	var cs: CollisionShape3D = get_node_or_null("Shape")
	if mi == null or cs == null:
		return
	var m := VesselBuilder.build_tube(length, radius, rings, segments, noise_seed)
	mi.mesh = m
	if _material == null:
		_material = VesselBuilder.wall_material()
	mi.material_override = _material
	var shape := m.create_trimesh_shape()
	shape.backface_collision = true
	cs.shape = shape


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	var mi: MeshInstance3D = get_node_or_null("Mesh")
	var cs: CollisionShape3D = get_node_or_null("Shape")
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		if mi:
			mi.mesh = null
			mi.material_override = null
		if cs:
			cs.shape = null
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_rebuild()
