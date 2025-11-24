# timeline_ui.gd - 时间轴 UI 显示器（动态创建）
extends CanvasLayer
class_name TimelineUI

# =====================================================
# === 配置 ===
# =====================================================
@export var timeline_controller_path: NodePath  # TimelineController 节点路径

# =====================================================
# === 方向符号映射 ===
# =====================================================
const DIRECTION_SYMBOLS := {
	"up": "↑",
	"down": "↓",
	"left": "←",
	"right": "→",
	"attack": "⚔"
}

# =====================================================
# === UI 节点（动态创建） ===
# =====================================================
var _container: VBoxContainer = null
var _status_label: Label = null
var _step_label: Label = null
var _steps_list_label: RichTextLabel = null  # 改用 RichTextLabel 支持富文本
var _progress_bar: ProgressBar = null

var _timeline_controller: Node = null
var _recorder: Node = null
var _playback: Node = null

# =====================================================
# === 初始化 ===
# =====================================================
func _ready() -> void:
	# 创建 UI 结构
	_create_ui()
	
	# 连接到 TimelineController
	_connect_to_timeline_controller()

## 动态创建 UI 元素
func _create_ui() -> void:
	# 主容器（左上角）
	_container = VBoxContainer.new()
	_container.position = Vector2(20, 20)
	add_child(_container)
	
		# 背景面板（增大）
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(450, 150)  # 增加宽度和高度
	_container.add_child(panel)
	
	# 内容容器
	var content = VBoxContainer.new()
	content.position = Vector2(10, 10)
	panel.add_child(content)
	
	# 状态标签（增大字体）
	_status_label = Label.new()
	_status_label.text = "状态: 等待录制..."
	_status_label.add_theme_font_size_override("font_size", 22)
	content.add_child(_status_label)
	
	# 步数标签（增大字体）
	_step_label = Label.new()
	_step_label.text = "步数: 0/5"
	_step_label.add_theme_font_size_override("font_size", 20)
	content.add_child(_step_label)
	
	# 进度条（增大）
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(420, 30)
	_progress_bar.max_value = 5
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	content.add_child(_progress_bar)
	
	# 步骤列表标签（改用 RichTextLabel，增大字体）
	_steps_list_label = RichTextLabel.new()
	_steps_list_label.bbcode_enabled = true  # 启用 BBCode
	_steps_list_label.fit_content = true
	_steps_list_label.scroll_active = false
	_steps_list_label.custom_minimum_size = Vector2(420, 60)
	_steps_list_label.add_theme_font_size_override("normal_font_size", 22)
	_steps_list_label.add_theme_font_size_override("bold_font_size", 22)
	_steps_list_label.text = "步骤: []"
	content.add_child(_steps_list_label)
	
	print("[TimelineUI] ✅ UI 创建完成")

## 连接到 TimelineController
func _connect_to_timeline_controller() -> void:
	if timeline_controller_path.is_empty():
		push_error("[TimelineUI] timeline_controller_path 未设置！")
		return
	
	_timeline_controller = get_node_or_null(timeline_controller_path)
	
	if _timeline_controller == null:
		push_error("[TimelineUI] 找不到 TimelineController：", timeline_controller_path)
		return
	
	# 获取子节点
	_recorder = _timeline_controller.get_node_or_null("RecorderQueue")
	_playback = _timeline_controller.get_node_or_null("Playback")
	
	# 连接信号
	if _timeline_controller.has_signal("recording_started"):
		_timeline_controller.recording_started.connect(_on_recording_started)
	
	if _timeline_controller.has_signal("step_recorded"):
		_timeline_controller.step_recorded.connect(_on_step_recorded)
	
	if _timeline_controller.has_signal("recording_completed"):
		_timeline_controller.recording_completed.connect(_on_recording_completed)
	
	if _playback and _playback.has_signal("playback_started"):
		_playback.playback_started.connect(_on_playback_started)
	
	if _playback and _playback.has_signal("playback_step"):
		_playback.playback_step.connect(_on_playback_step)
	
	if _playback and _playback.has_signal("playback_completed"):
		_playback.playback_completed.connect(_on_playback_completed)
	
	print("[TimelineUI] ✅ 已连接到 TimelineController")

# =====================================================
# === 信号回调 ===
# =====================================================
## 录制开始
func _on_recording_started() -> void:
	_status_label.text = "状态: 🔴 录制中... (按方向键/攻击键)"
	_status_label.add_theme_color_override("font_color", Color.RED)
	_step_label.text = "步数: 0/%d" % _timeline_controller.max_steps
	_progress_bar.max_value = _timeline_controller.max_steps
	_progress_bar.value = 0
	_steps_list_label.text = "步骤: []"
	_steps_list_label.add_theme_color_override("font_color", Color.WHITE)

## 记录一步
func _on_step_recorded(step_name: String) -> void:
	var step_count = _timeline_controller.get_step_count()
	_step_label.text = "步数: %d/%d" % [step_count, _timeline_controller.max_steps]
	_progress_bar.value = step_count
	
	var steps = _timeline_controller.get_recorded_steps()
	_update_steps_display(steps, -1)  # -1 表示不突出显示任何步骤

## 录制完成
func _on_recording_completed(steps: Array) -> void:
	_status_label.text = "状态: ✅ 录制完成"
	_status_label.add_theme_color_override("font_color", Color.GREEN)
	_step_label.text = "步数: %d/%d (完成)" % [steps.size(), _timeline_controller.max_steps]
	_progress_bar.value = steps.size()
	_update_steps_display(steps, -1)  # 显示所有步骤，不突出显示

## 回放开始
func _on_playback_started() -> void:
	_status_label.text = "状态: ▶️ 回放中... (观察幻影)"
	_status_label.add_theme_color_override("font_color", Color.CYAN)
	_progress_bar.value = 0
	# 不要在这里调用 _update_playback_visual，等待第一步信号
	# 显示录制完成时的状态（不突出显示）
	var steps = _timeline_controller.get_recorded_steps()
	_update_steps_display(steps, -1)

## 回放步骤
func _on_playback_step(step_index: int, command: String) -> void:
	_step_label.text = "回放: %d/%d" % [step_index + 1, _progress_bar.max_value]
	_progress_bar.value = step_index + 1
	# step_index 是即将执行的步骤索引，所以直接使用
	_update_playback_visual(step_index)

## 回放完成
func _on_playback_completed() -> void:
	_status_label.text = "状态: 🎉 回放完成"
	_status_label.add_theme_color_override("font_color", Color.YELLOW)
	_step_label.text = "回放完成！"
	# 恢复正常显示（所有步骤都透明显示）
	var steps = _timeline_controller.get_recorded_steps()
	_update_steps_display(steps, steps.size())  # 所有步骤都标记为已完成

# =====================================================
# === 辅助函数 ===
# =====================================================
## 更新步骤显示（支持富文本：红色书名号、透明度）
func _update_steps_display(steps: Array, current_index: int) -> void:
	if steps.is_empty():
		_steps_list_label.text = "步骤: []"
		return
	
	var bbcode_text = "步骤: ["
	
	for i in range(steps.size()):
		var symbol = DIRECTION_SYMBOLS.get(steps[i], steps[i])
		
		if i > 0:
			bbcode_text += ", "
		
		if i == current_index:
			# 当前步骤：红色书名号 + 红色符号
			bbcode_text += "[color=red]【%s】[/color]" % symbol
		elif i < current_index:
			# 已走过的步骤：降低透明度（使用灰色模拟）
			bbcode_text += "[color=#888888]%s[/color]" % symbol
		else:
			# 未走过的步骤：正常显示（白色）
			bbcode_text += symbol
	
	bbcode_text += "]"
	_steps_list_label.text = bbcode_text

## 更新回放视觉（调用统一的显示函数）
func _update_playback_visual(current_index: int) -> void:
	var steps = _timeline_controller.get_recorded_steps()
	_update_steps_display(steps, current_index)

# =====================================================
# === 每帧更新（实时显示） ===
# =====================================================
func _process(_delta: float) -> void:
	# 🔥 实时检测录制状态（修复录制中状态不显示的 bug）
	if _recorder and _recorder.is_recording():
		# 如果正在录制但状态还是"等待录制"，更新为"录制中"
		if _status_label.text.contains("等待"):
			_status_label.text = "状态: 🔴 录制中... (按方向键/攻击键)"
			_status_label.add_theme_color_override("font_color", Color.RED)
		
		# 实时更新步数
		var step_count = _timeline_controller.get_step_count()
		_step_label.text = "步数: %d/%d" % [step_count, _timeline_controller.max_steps]
		_progress_bar.value = step_count
