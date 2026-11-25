@tool
extends StaticBody3D
## The blood vessel tube. Edit length / radius / seed in the Inspector and the tube rebuilds in the viewport.
## Needs two children: a MeshInstance3D called "Mesh" and a CollisionShape3D called "Shape".

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


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	var mi: MeshInstance3D = get_node_or_null("Mesh")
	var cs: CollisionShape3D = get_node_or_null("Shape")
	if mi == null or cs == null:
		return
	var m := VesselBuilder.build_tube(length, radius, 100, 40, noise_seed)
	mi.mesh = m
	var shape := m.create_trimesh_shape()
	shape.backface_collision = true
	cs.shape = shape


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		($Mesh as MeshInstance3D).mesh = null
		($Shape as CollisionShape3D).shape = null
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_rebuild()
