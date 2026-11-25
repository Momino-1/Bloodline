extends Node
## Tracks how much oxygen is bound to the player's haemoglobin.

signal oxygen_changed(current: float, capacity: float)
signal fully_saturated
signal depleted

const CAPACITY := 100.0

var current := 0.0


func reset(start_value := 0.0) -> void:
    current = clampf(start_value, 0.0, CAPACITY)
    oxygen_changed.emit(current, CAPACITY)


## Binds oxygen to haemoglobin. Returns how much was actually accepted.
func load_oxygen(amount: float) -> float:
    var accepted := minf(amount, CAPACITY - current)
    if accepted <= 0.001:
        return 0.0
    current += accepted
    oxygen_changed.emit(current, CAPACITY)
    if current >= CAPACITY - 0.001:
        fully_saturated.emit()
    return accepted


## Releases oxygen to tissue. Returns how much was delivered.
func deliver(amount: float) -> float:
    var given := minf(amount, current)
    if given <= 0.0:
        return 0.0
    current -= given
    oxygen_changed.emit(current, CAPACITY)
    if current <= 0.001:
        depleted.emit()
    return given


func saturation() -> float:
    return current / CAPACITY
