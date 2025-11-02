# 手机部署指南

本指南将帮助你将这个Godot游戏项目克隆并部署到Android手机上。

## 前置要求

### 1. 克隆仓库到本地

首先，你需要将这个仓库克隆到你的电脑上：

```bash
git clone https://github.com/guiguisocute/godot-phantom-game.git
cd godot-phantom-game
```

如果你想使用特定的分支（例如dev分支），可以使用：

```bash
git clone -b dev https://github.com/guiguisocute/godot-phantom-game.git
```

### 2. 安装Godot引擎

- 下载并安装 **Godot 4.5 stable** 版本
- 官方下载地址：https://godotengine.org/download
- 确保下载的是支持Android导出的版本

### 3. 安装Android导出模板

在Godot中导出Android应用需要额外的Android导出模板：

1. 打开Godot编辑器
2. 进入 `编辑器` -> `管理导出模板...`
3. 下载并安装Godot 4.5对应的导出模板

### 4. 配置Android SDK

要导出Android应用，你需要安装Android SDK：

#### 方法一：通过Android Studio（推荐）

1. 下载并安装 [Android Studio](https://developer.android.com/studio)
2. 打开Android Studio，安装SDK
3. 记录SDK路径（通常在 `C:\Users\你的用户名\AppData\Local\Android\Sdk` 或 `~/Android/Sdk`）

#### 方法二：仅安装命令行工具

1. 下载 [Android命令行工具](https://developer.android.com/studio#command-tools)
2. 解压到某个目录
3. 使用 `sdkmanager` 安装所需的SDK包

#### 配置Godot中的Android路径

1. 打开Godot编辑器
2. 进入 `编辑器` -> `编辑器设置` -> `导出` -> `Android`
3. 设置以下路径：
   - **Android SDK路径**：SDK的安装目录
   - **Debug密钥库**：可以使用Godot自动生成的，或创建自己的

## 导出到Android

### 步骤1：打开项目

1. 启动Godot 4.5
2. 点击 `导入`，选择克隆的项目文件夹中的 `project.godot` 文件
3. 打开项目

### 步骤2：配置导出设置

项目已经包含了Android导出预设（`export_presets.cfg`），但你可能需要调整一些设置：

1. 在Godot编辑器中，进入 `项目` -> `导出...`
2. 选择 `Android` 预设
3. 检查并配置以下选项：
   - **包名**：修改 `package/unique_name` 为你自己的包名（例如 `com.yourname.goldengoat`）
   - **版本**：可以修改 `version/code` 和 `version/name`
   - **架构**：默认已选择 `arm64-v8a`（适用于大多数现代Android手机）
   - **最小SDK版本**：如果使用Gradle构建，在 `gradle_build/min_sdk` 中设置具体数值（推荐 `21` 或更高，支持Android 5.0+）

### 步骤3：导出APK

#### 导出调试版本（用于测试）

1. 在导出窗口中，确保选中了 `Android` 预设
2. 点击 `导出调试版本`
3. 选择保存位置和文件名（例如 `Goldengoat-debug.apk`）
4. 等待导出完成

#### 导出发布版本（用于正式分发）

1. 首先需要创建或配置发布密钥库
2. 在导出窗口中，点击 `导出发布版本`
3. 选择保存位置和文件名（例如 `Goldengoat-release.apk`）
4. 等待导出完成

## 安装到手机

### 方法一：通过USB数据线安装

1. **启用开发者选项**：
   - 在手机上打开 `设置` -> `关于手机`
   - 连续点击 `版本号` 7次，启用开发者选项
   
2. **启用USB调试**：
   - 进入 `设置` -> `系统` -> `开发者选项`
   - 开启 `USB调试`

3. **连接手机到电脑**：
   - 使用USB数据线连接手机
   - 在手机上授权USB调试

4. **使用ADB安装**：
   ```bash
   adb install Goldengoat-debug.apk
   ```
   
   如果你没有安装ADB，可以通过Android SDK安装，或者：

5. **手动复制安装**：
   - 将APK文件复制到手机存储
   - 在手机上使用文件管理器找到APK文件
   - 点击安装（需要允许安装未知来源应用）

### 方法二：通过无线传输

1. 使用以下任一方式将APK传输到手机：
   - 通过微信/QQ等发送文件
   - 通过云盘（百度网盘、阿里云盘等）
   - 通过局域网文件共享
   - 通过蓝牙传输

2. 在手机上找到APK文件并安装

### 方法三：Godot一键部署（推荐用于开发测试）

如果你的手机已启用USB调试并连接到电脑：

1. 在Godot编辑器中，点击右上角的 `远程调试` 按钮旁边的 `一键部署` 图标
2. 选择 `Android` 设备
3. Godot会自动构建、安装并运行游戏

## 常见问题

### Q: 安装时提示"未知来源应用"或"禁止安装"

A: 需要在手机设置中允许安装未知来源的应用：
- Android 8.0及以上：`设置` -> `应用和通知` -> `特殊应用权限` -> `安装未知应用` -> 选择文件管理器或浏览器并允许
- Android 8.0以下：`设置` -> `安全` -> 开启 `未知来源`

### Q: 游戏在手机上运行很卡

A: 这个项目已经配置为移动端渲染模式，但如果仍然卡顿：
- 可以尝试降低游戏分辨率，在Godot编辑器中进入 `项目` -> `项目设置` -> `显示` -> `窗口`
- 修改 `window/size/viewport_width`（当前为1920）和 `window/size/viewport_height`（当前为1080）为更低的值，如 `1280x720` 或 `960x540`
- 优化游戏资源和代码

### Q: 导出时提示缺少Android构建模板

A: 确保你已经：
1. 安装了正确版本的Godot导出模板（4.5 stable）
2. 正确配置了Android SDK路径
3. SDK包含了所需的构建工具

### Q: 无法找到设备进行一键部署

A: 检查：
1. USB调试是否已开启
2. 电脑是否已安装手机驱动
3. 使用 `adb devices` 命令检查设备是否被识别

### Q: 游戏触摸控制不工作

A: 项目已经启用了触摸模拟（`pointing/emulate_touch_from_mouse=true`），游戏应该支持触摸操作。如果不工作，检查：
- 输入映射是否正确配置
- 游戏脚本是否正确处理触摸事件

## 直接在手机上克隆仓库（高级用法）

如果你想直接在手机上开发，可以使用以下工具：

### 使用Termux（需要一定Linux知识）

1. 在手机上安装 [Termux](https://f-droid.org/packages/com.termux/)
2. 安装git：
   ```bash
   pkg install git
   ```
3. 克隆仓库：
   ```bash
   git clone https://github.com/guiguisocute/godot-phantom-game.git
   ```

注意：手机上无法直接运行Godot编辑器，你仍需要在电脑上使用Godot编辑和导出项目。

### 使用GitHub手机客户端

- 可以使用GitHub官方App查看代码
- 或使用第三方Git客户端如MGit、GitJournal等管理仓库

## 总结

完整流程：
1. ✅ 在电脑上克隆仓库
2. ✅ 安装并配置Godot 4.5
3. ✅ 配置Android SDK和导出模板
4. ✅ 在Godot中打开项目
5. ✅ 导出Android APK
6. ✅ 将APK传输到手机并安装
7. ✅ 在手机上运行游戏

如有问题，可以查看项目的其他文档或提交Issue。祝游戏开发顺利！🎮
