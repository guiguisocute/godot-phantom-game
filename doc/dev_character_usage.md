# Dev场景角色控制系统使用说明

## 文件说明

### 核心脚本文件

1. **`player_dev.gd`** - 玩家角色的开发版本控制脚本
   - ✅ 流畅的左右移动（持续检测按键，非单次输入）
   - ✅ 跳跃功能
   - ✅ 攻击功能（按E键）
   - ✅ 控制权切换支持

2. **`phantom_dev.gd`** - 幻影角色的开发版本控制脚本
   - ✅ 流畅的左右移动（速度稍快）
   - ✅ 跳跃功能（跳得稍高）
   - ✅ 攻击功能
   - ✅ 控制权切换支持

3. **`character_switcher_dev.gd`** - 角色切换控制器
   - 负责管理两个角色之间的控制权切换
   - 自动检测脚本是否正确配置

### 场景文件

1. **`player_dev.tscn`** - 使用 `player_dev.gd` 的玩家场景
2. **`phantom_dev.tscn`** - 使用 `phantom_dev.gd` 的幻影场景
3. **`level_dev.tscn`** - 预配置好的完整测试场景（推荐使用）

## 快速开始

### 最简单的方法：直接使用测试场景

1. 在 Godot 编辑器中打开 `src/level/level_dev.tscn`
2. 按 **F5** 或点击"运行场景"按钮
3. 开始测试！

### 手动配置到现有场景

1. 在你的场景中添加 Player 和 Phantom：
   - 场景 → 实例化子场景 → 选择 `player_dev.tscn`
   - 场景 → 实例化子场景 → 选择 `phantom_dev.tscn`
2. 添加切换器：
   - 添加一个 Node 节点
   - 附加脚本 `character_switcher_dev.gd`
   - （可选）在检查器中手动设置 Player 和 Phantom 引用

## 操作说明

### 基础移动控制
- **W** / **上箭头** - 跳跃
- **A** / **左箭头** - 向左移动
- **D** / **右箭头** - 向右移动
- **E** - 攻击

### 角色切换
- **Ctrl + R** - 切换控制角色（Player ↔ Phantom）

## 特性说明

### 流畅移动
- 使用持续输入检测，而非单次按键检测
- 支持加速和减速，移动更自然
- 在地面和空中有不同的减速效果

### 视觉反馈
- 当前控制的角色：不透明（alpha = 1.0）
- 未控制的角色：半透明（alpha = 0.5）

### 动画系统
自动根据状态播放对应动画：
- `idle` - 站立不动
- `move` - 奔跑
- `up` - 跳跃上升
- `fall` - 下落
- `attack` - 攻击（仅Player，Phantom如果有此动画也会播放）

## 参数调整

你可以在编辑器中调整以下参数：

### Player 参数
- `SPEED` = 300.0 - 移动速度
- `JUMP_VELOCITY` = -500.0 - 跳跃力度
- `ACCELERATION` = 2000.0 - 加速度
- `FRICTION` = 1500.0 - 地面摩擦力
- `AIR_RESISTANCE` = 100.0 - 空中阻力
- `ATTACK_DURATION` = 0.5 - 攻击持续时间

### Phantom 参数（默认比Player稍强）
- `SPEED` = 350.0
- `JUMP_VELOCITY` = -550.0
- `ACCELERATION` = 2200.0
- `FRICTION` = 1600.0
- `AIR_RESISTANCE` = 120.0

## 注意事项

1. 确保场景中有 `AnimatedSprite2D` 子节点
2. 确保动画资源包含所需的动画名称
3. 如果Phantom没有attack动画，攻击时会跳过动画播放
4. 切换器会自动查找名为 "Player" 和 "Phantom" 的节点（如果未手动设置）

## 调试信息

切换角色时，控制台会输出：
```
切换到控制: Player
```
或
```
切换到控制: Phantom
```

## 后续扩展建议

- 添加双人模式支持
- 添加更多攻击类型
- 添加特殊能力（比如Phantom的穿墙）
- 添加粒子效果
- 添加音效反馈
