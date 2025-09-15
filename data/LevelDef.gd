extends Resource
class_name LevelDef

@export var name: String = "Level"
@export var record_n: int = 4

# 可站立格
@export var cells: Array[Vector2i] = []         # e.g. [Vector2i(1,0), Vector2i(2,0) ...]
# x 轴有梯子的列（y=-1 与 y=0 之间连通）
@export var ladders_x: Array[int] = []          # e.g. [1, 2]

# 关键点（格坐标）
@export var spawn:  Vector2i = Vector2i(0, 0)
@export var altar:  Vector2i = Vector2i(5, 0)
@export var button: Vector2i = Vector2i(3, 0)
@export var bridge: Vector2i = Vector2i(6, 0)

func has_cell(c: Vector2i) -> bool:
	return c in cells

func ladder_at_x(x: int) -> bool:
	return x in ladders_x
