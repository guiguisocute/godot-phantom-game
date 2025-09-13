extends CharacterBody2D
class_name ActorBase

signal move_finished
signal drop_finished(will_fail: bool)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null


var cell: Vector2i = Vector2i(0, 0)
var is_moving: bool = false

var _from_px: Vector2
var _to_px: Vector2
var _t: float = 1.0
var _dur: float = Consts.MOVE_DUR

# 两段式掉落控制
var _pending_drop: bool = false
var _drop_to_px: Vector2
var _fail_after_drop: bool = false

func _ready() -> void:
	position = Consts.cell_to_px(cell)
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	set_process(true)

# 直接把角色摆到某格（不动画）
func set_cell(c: Vector2i) -> void:
	cell = c
	position = Consts.cell_to_px(cell)
	is_moving = false
	_t = 1.0
	_play_idle()

# 普通一步：from cell → to cell（水平/竖直皆可）
func move_to_cell(next: Vector2i, dur: float = Consts.MOVE_DUR) -> void:
	_from_px = Consts.cell_to_px(cell)
	_to_px = Consts.cell_to_px(next)
	cell = next
	_dur = dur
	_t = 0.0
	is_moving = true
	_play_move()

# 两段式掉落：先 from→to 水平对齐，再垂直到 drop_px（屏外或下层格）
func move_then_drop(from_c: Vector2i, to_c: Vector2i, drop_px: Vector2, will_fail: bool) -> void:
	_from_px = Consts.cell_to_px(from_c)
	_to_px = Consts.cell_to_px(to_c)
	cell = to_c
	_dur = Consts.DROP_HORIZ_DUR
	_t = 0.0
	is_moving = true
	_pending_drop = true
	_drop_to_px = drop_px
	_fail_after_drop = will_fail
	_play_move()

func _process(delta: float) -> void:
	if not is_moving: return
	_t = min(1.0, _t + delta / _dur)
	var k := Consts.ease_out_quad(_t)
	position = _from_px.lerp(_to_px, k)

	if _t >= 1.0:
		is_moving = false
		if _pending_drop:
			_pending_drop = false
			_from_px = _to_px
			_to_px = _drop_to_px
			_dur = Consts.DROP_VERT_DUR
			_t = 0.0
			is_moving = true
		else:
			_play_idle()
			emit_signal("move_finished")
			if _fail_after_drop:
				var will_fail := _fail_after_drop
				_fail_after_drop = false
				if sfx: sfx.play()
				emit_signal("drop_finished", will_fail)

# --- 内部：动画 ---
func _play_idle() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

func _play_move() -> void:
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("move"):
		anim.play("move")
