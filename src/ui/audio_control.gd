extends HSlider

@export var audio_bus_name: String
var audio_bus_id


func _ready():
		audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
		load_saved_volume()
	# 3. 连接值改变信号到处理函数
		value_changed.connect(_on_value_changed)

func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id,db)
	# 3. 立即保存当前的音量设置
	save_volume(value)
	
	# 保存音量设置到文件
func save_volume(volume: float):
		# 创建 ConfigFile 对象来处理配置文件
		var config = ConfigFile.new()

		# 先尝试加载现有的配置文件（如果存在）
		# 这样不会覆盖其他设置
		config.load("user://audio_settings.cfg")

		# 设置音频音量值
		# 参数说明：
		# - "audio": 配置文件的章节(section)
		# - audio_bus_name + "_volume": 键名(key)，比如 "Music_volume"
		# - volume: 要保存的值
		config.set_value("audio", audio_bus_name + "_volume", volume)

		# 保存配置文件到用户数据目录
		# "user://" 是 Godot 的用户数据路径，跨平台兼容
		config.save("user://audio_settings.cfg")
		
		
		# 加载保存的音量设置
func load_saved_volume():
		var config = ConfigFile.new()
		# 尝试加载配置文件
		var err = config.load("user://audio_settings.cfg")
		# 如果文件加载成功 (err == OK)
		if err == OK:
			# 获取保存的音量值，如果没有找到则使用默认值 1.0
			var saved_volume = config.get_value("audio", audio_bus_name + "_volume", 1.0)
		# 设置滑块的值
			value = saved_volume
		# 应用保存的音量到音频总线
			var db = linear_to_db(saved_volume)
			AudioServer.set_bus_volume_db(audio_bus_id, db)
