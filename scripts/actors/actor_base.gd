extends CharacterBody2D
class_name ActorBase

const Consts = preload("res://scripts/consts.gd")

signal move_finished        # 一次移动/两段掉落结束
signal mid_reached          # 两段掉落的“水平段结束”时发（可选用）

enum State { IDLE, MOVING, FALLING, FROZEN }

@export var sprite_path: NodePath = ^"AnimatedSprite2D"
@onready var sprite: AnimatedSprite2D = get_node(sprite_path)

var state: State = State.IDLE
var cell: Vector2i
var busy := false           # 控制器可用它来“禁用新步”
var face_dir := 1           # 1=面向右，-1=面向左

func _ready() -> void:
	_play_idle()

# ======== 基础工具 ========
func is_busy() -> bool:
	return busy or state == State.MOVING or state == State.FALLING or state == State.FROZEN

func hide_and_freeze() -> void:
	visible = false
	state = State.FROZEN
	busy = false

func show_and_idle() -> void:
	visible = true
	state = State.IDLE
	busy = false
	_play_idle()

func warp_to_cell(c: Vector2i) -> void:
	cell = c
	global_position = Consts.cell_to_px(cell)
	state = State.IDLE
	busy = false
	_play_idle()

# ======== 单段移动（带动画） ========
func move_to_cell(target_cell: Vector2i, dur: float = Consts.MOVE_DUR) -> void:
	busy = true
	state = State.MOVING

	var from_px := global_position
	var to_px := Consts.cell_to_px(target_cell)

	# 面向只在水平移动时更新
	if target_cell.x - cell.x != 0:
		_set_facing(sign(target_cell.x - cell.x))

	_play_move()

	var tw := create_tween()
	tw.tween_property(self, "global_position", to_px, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		cell = target_cell
		state = State.IDLE
		busy = false
		_play_idle()
		move_finished.emit())

# ======== 两段掉落：水平→竖直，到达“下层格” ========
func move_then_drop_to_cell(mid_cell: Vector2i, drop_cell: Vector2i, dur_h: float = Consts.DROP_HORIZ_DUR, dur_v: float = Consts.DROP_VERT_DUR) -> void:
	busy = true
	state = State.MOVING

	# 水平段
	_set_facing(sign(mid_cell.x - cell.x))
	_play_move()

	var mid_px := Consts.cell_to_px(mid_cell)
	var end_px := Consts.cell_to_px(drop_cell)

	var tw := create_tween()
	tw.tween_property(self, "global_position", mid_px, dur_h).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		# 到达桥格（水平段结束）
		cell = mid_cell
		mid_reached.emit()
		# 竖直到下层
		state = State.FALLING
		var tw2 := create_tween()
		tw2.tween_property(self, "global_position", end_px, dur_v).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.finished.connect(func():
			cell = drop_cell
			state = State.IDLE
			busy = false
			_play_idle()
			move_finished.emit()))

# ======== 两段掉落：水平→坠入深渊（到任意像素点，不改最终 cell） ========
func move_then_fall_to_px(mid_cell: Vector2i, abyss_px: Vector2, dur_h: float = Consts.DROP_HORIZ_DUR, dur_v: float = Consts.DROP_VERT_DUR) -> void:
	busy = true
	state = State.MOVING

	_set_facing(sign(mid_cell.x - cell.x))
	_play_move()

	var mid_px := Consts.cell_to_px(mid_cell)
	var tw := create_tween()
	tw.tween_property(self, "global_position", mid_px, dur_h).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		cell = mid_cell
		mid_reached.emit()
		state = State.FALLING
		var tw2 := create_tween()
		tw2.tween_property(self, "global_position", abyss_px, dur_v).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw2.finished.connect(func():
			# 注意：坠落到深渊不更新 cell，交由控制器判定 fail
			state = State.IDLE
			busy = false
			_play_idle()
			move_finished.emit()))

# ======== 动画/朝向 ========
func _set_facing(s: int) -> void:
	if s == 0: return
	face_dir = 1 if s > 0 else -1
	if sprite:
		sprite.flip_h = (face_dir < 0)

func _play_idle() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _play_move() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("move"):
		sprite.play("move")
