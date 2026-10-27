extends Node3D
class_name Arena

signal score_changed(score: int)

@export var enemy_scene: PackedScene
@export var player: Node3D
@export var throw_target: Node3D
@export var debt_gauge: DebtGauge
@export var kill_zone: Area3D
@export var spawn_points: Array[Node3D] = []
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 8

var score: int = 0
var spawn_time_left: float = 0.0
var game_over: bool = false
var label := Label.new()


func _ready() -> void:
	if not debt_gauge and player:
		for child in player.get_children():
			if child is DebtGauge:
				debt_gauge = child

	var hud := CanvasLayer.new()
	label.position = Vector2(32.0, 16.0)
	label.add_theme_font_size_override("font_size", 64)
	hud.add_child(label)
	add_child(hud)

	if debt_gauge:
		debt_gauge.changed.connect(on_gauge_changed)
		debt_gauge.depleted.connect(on_gauge_depleted)
		on_gauge_changed(debt_gauge.time_left, debt_gauge.max_time)
	if kill_zone:
		kill_zone.body_entered.connect(on_kill_zone_entered)


func _physics_process(delta: float) -> void:
	if game_over:
		return
	spawn_time_left -= delta
	if spawn_time_left <= 0.0:
		spawn_time_left = spawn_interval
		spawn_enemy()


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


func spawn_enemy() -> void:
	if spawn_points.is_empty() or get_tree().get_nodes_in_group("enemy").size() >= max_enemies:
		return
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.player = player
	enemy.throw_target = throw_target
	enemy.scored.connect(on_enemy_scored)
	add_child(enemy)
	enemy.global_position = spawn_points.pick_random().global_position


func on_enemy_scored() -> void:
	score += 1
	score_changed.emit(score)
	if is_instance_valid(debt_gauge):
		debt_gauge.refill()


func on_gauge_changed(time_left: float, _max_time: float) -> void:
	label.text = "%d" % ceili(time_left)


func on_gauge_depleted() -> void:
	end_game()


func on_kill_zone_entered(body: Node3D) -> void:
	if body == player:
		end_game()
	elif body is Enemy:
		body.queue_free()


func end_game() -> void:
	if game_over:
		return
	game_over = true
	label.text = "Game over - press R to restart"
	if is_instance_valid(player):
		player.queue_free()
