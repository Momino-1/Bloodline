@tool
extends MeshInstance3D
## Gives this node the biconcave red-blood-cell mesh so it shows up in the 3D viewport.
## The mesh is shared between all cells and is not saved into the .tscn (see pre-save below).

const ModelFactory = preload("res://scripts/gameplay/model_factory.gd")
static var _shared: ArrayMesh


func _ready() -> void:
	if mesh == null:
		if _shared == null:
			_shared = ModelFactory.biconcave_disc(1.0)
		mesh = _shared


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		mesh = null
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_ready()
