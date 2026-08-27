# yulo OS 安卓版

在安卓手机上运行 yulo OS 的完整 Android 应用项目。

## 项目结构

```
android-app/
├── app/
│   ├── build.gradle              # 应用构建配置
│   ├── proguard-rules.pro        # 混淆规则
│   └── src/main/
│       ├── AndroidManifest.xml   # 应用清单
│       ├── java/com/yulo/os/
│       │   ├── MainActivity.java     # 主界面（下载/启动/停止）
│       │   ├── VncActivity.java      # VNC 显示界面（触摸操控）
│       │   ├── TouchHandler.java     # 触摸事件处理器
│       │   ├── ProotManager.java     # proot 容器管理
│       │   ├── YuloService.java      # 后台服务
│       │   └── SettingsActivity.java # 设置界面
│       └── res/
│           ├── layout/             # 布局文件
│           ├── values/             # 字符串/颜色/主题
│           ├── xml/                # 设置项
│           └── drawable/           # 图标资源
├── build.gradle                    # 项目构建配置
├── settings.gradle                 # 项目设置
├── gradle.properties               # Gradle 属性
└── README.md                       # 本文件
```

## 功能特性

### 核心功能
- 一键下载 yulo OS ARM64 rootfs
- 一键启动/停止 Linux 容器
- 内置 VNC 客户端显示系统画面
- 后台服务保持运行
- 设置界面（分辨率/性能/触摸）

### 触摸操控规则
| 手势 | 功能 |
|------|------|
| 单指点击 | 鼠标左键单击 |
| 单指双击 | 鼠标左键双击 |
| 单指长按 | 鼠标右键单击 |
| 单指拖动 | 拖动窗口/选择文本 |
| 双指上下滑动 | 鼠标滚轮滚动 |
| 双指左右滑动 | 水平滚动 |
| 双指捏合/张开 | 缩小/放大画面 |
| 三指上滑 | 活动概览（所有窗口） |
| 三指左右滑 | 切换工作区 |
| 三指下滑 | 显示桌面 |
| 底部上滑 | 打开应用列表 |
| 顶部下滑 | 通知/快捷设置 |
| 左边缘右滑 | 返回 |

### 底部状态栏
- 左下角开始按钮 → 应用菜单
- 中间应用图标 → 切换/打开应用
- 右下角时间 → 日历/通知
- 太阳/月亮图标 → 切换日/夜间模式
- 输入法图标 → 切换中英文
- 电源图标 → 关机/重启菜单

## 编译方法

### 1. 环境要求
- Android Studio Hedgehog (2023.1.1) 或更高
- JDK 17
- Android SDK 34
- Android NDK (可选，用于原生库)

### 2. 克隆项目
```bash
git clone https://github.com/yulozh/yulo.git
cd yulo/android-app
```

### 3. 用 Android Studio 打开
1. 打开 Android Studio
2. 选择 "Open an existing project"
3. 选择 `android-app` 目录
4. 等待 Gradle 同步完成
5. 点击 "Build" → "Build Bundle(s) / APK(s)" → "Build APK(s)"

### 4. 命令行编译
```bash
# Linux/Mac
./gradlew assembleDebug

# Windows
gradlew.bat assembleDebug
```

APK 输出位置：`app/build/outputs/apk/debug/app-debug.apk`

## 系统要求

- 安卓 7.0 (API 24) 或更高
- 至少 3GB RAM（推荐 4GB+）
- 至少 8GB 存储空间
- ARM64 架构（绝大多数现代手机）

## 默认账号
- 用户名：`yulo`
- 密码：`yulo`

## 技术架构

- **容器层**：proot (无需 root)
- **显示层**：Xvfb + x11vnc
- **桌面环境**：GNOME
- **客户端**：Android VNC Viewer
- **触摸处理**：自定义 GestureDetector + ScaleGestureDetector

## 注意事项

1. 首次使用需要下载 yulo OS rootfs（约 2-3GB），建议在 WiFi 环境下下载
2. 运行时耗电较快，建议连接充电器
3. 请在系统设置中允许本应用后台运行和忽略电池优化
4. 性能取决于手机配置，高端手机体验更佳

## 相关链接

- yulo OS 主项目：https://github.com/yulozh/yulo
- Release 下载：https://github.com/yulozh/yulo/releases
- Termux：https://termux.dev/
- proot：https://proot-me.github.io/
