
@tool
extends MeshInstance3D
## Gives this node the biconcave red-blood-cell mesh so it shows up in the 3D viewport.
## The mesh is shared between all cells and is not saved into the .tscn.

const ModelFactory = preload("res://scripts/gameplay/model_factory.gd")
static var _shared: ArrayMesh

# Rare sound settings
@export_group("Rare Sound")
@export var rare_sound_chance: int = 25
@export var sound_player_path: NodePath = ^"../../AudioStreamPlayer2D"


func _ready() -> void:
	if mesh == null:
		if _shared == null:
			_shared = ModelFactory.biconcave_disc(1.0)
		mesh = _shared

	# Don't play sounds inside the editor
	if Engine.is_editor_hint():
		return

	# 1 in 50 chance to play the sound
	if rare_sound_chance > 0 and randi_range(1, rare_sound_chance) == 1:
		var sound_player = get_node_or_null(sound_player_path)

		if sound_player is AudioStreamPlayer2D:
			sound_player.play()


func _notification(what: int) -> void:
	if not Engine.is_editor_hint():
		return

	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		mesh = null
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_ready()
