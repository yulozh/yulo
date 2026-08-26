# yulo OS

一个基于 Ubuntu 26.04 LTS 的定制 Linux 发行版，主打樱花粉主题、Win11 式底部状态栏、4K 动态壁纸和流畅动画。

## 特性

- **主题**：白色 + 樱花粉（Sakura Pink），全局圆角，流畅过渡动画
- **暗色模式**：太阳/月亮一键切换，暗色模式下壁纸自动调低亮度
- **底部状态栏**：Win11 风格，居中应用图标，右侧时间/输入法/电源
- **4K 动态壁纸**：无缝循环视频壁纸，无声音
- **窗口动画**：打开/关闭时缩放+淡入淡出
- **品牌**：yulo 名称和 LOGO 全局替换，去除 Ubuntu 标识
- **安全**：禁用遥测、云端后门，sysctl 加固，防火墙配置
- **自由**：无 AI 标识，无云端后门，完全自由使用

## 仓库结构

```
yulo/
├── rootfs/                    # 目标系统文件（覆盖到 /）
│   ├── etc/
│   │   ├── dconf/             # 默认系统配置
│   │   ├── os-release         # 系统品牌信息
│   │   ├── lsb-release
│   │   ├── issue
│   │   └── systemd/system/    # 首次启动/加固服务
│   ├── usr/
│   │   ├── lib/yulo/          # 首次启动脚本、安全加固脚本
│   │   ├── lib/os-release
│   │   └── share/
│   │       ├── backgrounds/yulo/  # 4K 壁纸
│   │       ├── gnome-shell/extensions/yulo-shell@yulo.dev/  # 状态栏扩展
│   │       ├── icons/Yulo/    # 图标主题
│   │       ├── plymouth/themes/yulo/  # 启动画面
│   │       └── themes/        # GTK3/GTK4/GNOME Shell 主题（亮色+暗色）
│   └── ...
├── assets/                    # 原始素材（LOGO、视频源文件）
└── README.md
```

## 安装

### 方式一：应用到现有 Ubuntu 26.04 系统

```bash
# 复制 rootfs 到系统根目录
sudo cp -r rootfs/* /

# 运行首次启动脚本
sudo /usr/lib/yulo/first-boot-setup.sh

# 运行安全加固
sudo /usr/lib/yulo/security-hardening.sh

# 启用扩展
gnome-extensions enable yulo-shell@yulo.dev

# 注销并重新登录
```

### 方式二：重新打包 ISO

使用 `squashfs-tools` 和 `xorriso` 将 rootfs 覆盖到 Ubuntu 26.04 ISO 的 squashfs 中，重新生成可启动 ISO。

## 主题颜色

| 用途 | 亮色 | 暗色 |
|------|------|------|
| 背景 | `#ffffff` | `#1a1a2e` |
| 文字 | `#2d2d2d` | `#e8e8e8` |
| 强调色（樱花粉） | `#ff8fa3` | `#ff8fa3` |
| 按钮背景 | `#ffb7c5` | `#ff8fa3` |
| 边框 | `#ffd6de` | `#333355` |
| 标题栏 | `#fff5f7` | `#20203a` |

## 扩展快捷键

- `Super`：打开/关闭概览（开始菜单）
- `Super + L`：锁屏
- `Ctrl + Alt + Delete`：注销

## 许可证

MIT License
