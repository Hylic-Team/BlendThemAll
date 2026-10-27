extends Node
class_name DebtGauge

signal changed(time_left: float, max_time: float)
signal depleted

@export var max_time: float = 60.0
@export var drain_rate: float = 1.0
@export var refill_amount: float = 5.0
@export var running: bool = true

var time_left: float


func _ready() -> void:
	time_left = max_time
	changed.emit(time_left, max_time)


func _process(delta: float) -> void:
	if not running or time_left <= 0.0:
		return
	time_left = maxf(time_left - drain_rate * delta, 0.0)
	changed.emit(time_left, max_time)
	if time_left <= 0.0:
		running = false
		depleted.emit()


func refill() -> void:
	if time_left <= 0.0:
		return
	time_left = minf(time_left + refill_amount, max_time)
	changed.emit(time_left, max_time)


func get_ratio() -> float:
	return time_left / max_time
