extends Node
class_name RecorderQueue

signal recording_started
signal recording_finished(run_id: int)

@export var keep_history := 1        # >0 时保留最近 N 段录制给幻影复用
@export var auto_clear_on_start := true

var max_steps := 0
var is_recording := false
var _current_frames: Array = []
var _history: Array = []             # [{id, frames}]
var _run_id := 0

func start_recording() -> void:
	if is_recording:
		return
	if auto_clear_on_start:
		_current_frames.clear()
	is_recording = true
	emit_signal("recording_started")

func stop_recording() -> int:
	if not is_recording:
		return -1
	is_recording = false
	_run_id += 1
	var snapshot := _current_frames.duplicate(true)
	if keep_history <= 0:
		_history = []
	_history.append({"id": _run_id, "frames": snapshot})
	if keep_history > 0 and _history.size() > keep_history:
		_history.pop_front()
	emit_signal("recording_finished", _run_id)
	return _run_id

func enqueue_action(entry: Dictionary) -> void:
	if not is_recording:
		return
	_current_frames.append(entry)

func get_last_run_frames() -> Array:
	return [] if _history.is_empty() else _history.back()["frames"].duplicate(true)

func get_run_frames(run_id: int) -> Array:
	for run in _history:
		if run["id"] == run_id:
			return run["frames"].duplicate(true)
	return []

func clear_all() -> void:
	_current_frames.clear()
	_history.clear()
	_run_id = 0
	is_recording = false
