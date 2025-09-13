extends Node
class_name Consts   # 给这个脚本取一个全局可用的类名 Consts，用来存储公共常量与静态工具函数。

# === 游戏格子与移动的通用参数 ===
const CELL_SIZE: float = 96.0
# 每个“格子”的宽度（像素单位）。游戏逻辑是基于网格的，这里规定一格等于 96 像素。

const ORIGIN: Vector2 = Vector2(120, 360)
# 游戏画面里 (0,0) 格子的像素起点位置。越右 x 越大；y = 0 在上层，y = -1 在下层。
# 用它作为坐标映射的基准点，保证角色与平台能对齐。
# 总结：逻辑坐标到屏幕坐标的映射

const MOVE_DUR: float = 0.16
# 玩家或幻影进行一次“普通移动”的动画时长（秒）。越小动作越快，越大动作越慢。

const DROP_HORIZ_DUR: float = 0.10
# 当发生两段式掉落时（先水平、再竖直），水平部分的时长。
# 比普通 MOVE_DUR 要短，因为这里只是小幅水平挪动。

const DROP_VERT_DUR: float = 0.18
# 两段式掉落的第二阶段（竖直下坠）的时长。稍微长一些，给人有个“掉下去”的感觉。

# === 工具函数 ===

static func cell_to_px(c: Vector2i) -> Vector2:
	# 将逻辑上的格子坐标 (x, y) 转换成屏幕上的像素坐标。
	# 逻辑坐标是以格子为单位，像 Vector2i(3, 0) 表示第 3 列第 0 层。
	# 公式：起点 ORIGIN + (格子大小 * x, 格子高度 * y)，再加一点偏移让角色居中。
	return ORIGIN + Vector2(float(c.x) * CELL_SIZE + (CELL_SIZE - 8.0) / 2.0,
							-28.0 + float(-c.y) * 90.0)

static func ease_out_quad(t: float) -> float:
	# 一个缓动函数：输入 t 在 [0,1] 范围内，输出一个非线性的插值系数。
	# 公式含义：起始快，后面慢慢减速（Ease Out）。
	# 用在移动/掉落的插值时，可以让动画看起来更自然，不是匀速走，而是“冲一下再停”。
	return 1.0 - (1.0 - t) * (1.0 - t)
