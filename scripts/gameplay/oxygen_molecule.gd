extends Area3D
## An O₂ molecule that diffuses out of an alveolus and can be collected by the player.

signal collected

const OXYGEN_PER_MOLECULE := 4.0
const LIFETIME := 45.0

var drift := Vector3.ZERO
var _age := 0.0
var _phase := randf() * TAU
@onready var _visual: Node3D = $Visual
var _taken := false


func _ready() -> void:
    add_to_group("oxygen")
    body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
    _age += delta
    position += (drift + Vector3(0, 0, -1.4)) * delta
    drift = drift.move_toward(Vector3.ZERO, delta * 1.3)
    _visual.position.y = sin(_age * 3.0 + _phase) * 0.12
    _visual.rotate_y(delta * 1.5)
    _visual.rotate_z(delta * 0.9)
    if _age > LIFETIME and not _taken:
        queue_free()


func _on_body_entered(body: Node3D) -> void:
    if _taken or not body.is_in_group("player"):
        return
    if OxygenSystem.load_oxygen(OXYGEN_PER_MOLECULE) <= 0.0:
        return
    _taken = true
    collected.emit()
    var tw := create_tween()
    tw.set_parallel(true)
    tw.tween_property(_visual, "scale", Vector3.ZERO, 0.25)
    tw.tween_property(self, "global_position", body.global_position, 0.25)
    tw.chain().tween_callback(queue_free)
