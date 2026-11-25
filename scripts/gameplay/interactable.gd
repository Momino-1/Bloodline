extends Node3D
## Marks something the player can inspect with E. The player finds these through the "interactable" group.

signal interacted(who: Node3D)

@export var interact_id := ""
@export var prompt := "Inspect"
@export var interact_range := 5.0
@export var surface_radius := 0.0
var enabled := true


func _ready() -> void:
	add_to_group("interactable")


func interact(who: Node3D) -> void:
	if enabled:
		interacted.emit(self)
