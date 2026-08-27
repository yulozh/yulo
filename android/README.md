# yulo OS 安卓版

在安卓手机上运行 yulo OS 的完整方案。

## 快速开始

### 1. 安装 Termux
从 F-Droid 下载安装 Termux（不要用 Google Play 版本，已过时）：
- https://f-droid.org/packages/com.termux/

### 2. 安装 VNC 客户端
推荐：
- **VNC Viewer** (RealVNC) - https://play.google.com/store/apps/details?id=com.realvnc.viewer.android
- **bVNC Free** - https://play.google.com/store/apps/details?id=com.iiordanov.freebVNC

### 3. 运行一键安装
打开 Termux，输入：
```bash
pkg install wget -y
wget https://raw.githubusercontent.com/yulozh/yulo/main/android/install-yulo.sh
bash install-yulo.sh
```

### 4. 启动系统
```bash
bash ~/start-yulo.sh
```

### 5. 连接 VNC
打开 VNC 客户端，连接 `localhost:5900`

## 触摸操控规则

### 基础操作
| 手势 | 功能 |
|------|------|
| 单指点击 | 鼠标左键单击 |
| 单指双击 | 鼠标左键双击 |
| 单指长按 | 鼠标右键单击 |
| 单指拖动 | 拖动窗口/选择文本 |

### 滚动操作
| 手势 | 功能 |
|------|------|
| 双指上下滑动 | 鼠标滚轮上下滚动 |
| 双指左右滑动 | 水平滚动 |

### 缩放手势
| 手势 | 功能 |
|------|------|
| 双指捏合 | 缩小 |
| 双指张开 | 放大 |

### 多任务
| 手势 | 功能 |
|------|------|
| 三指上滑 | 显示活动概览 |
| 三指左右滑 | 切换工作区 |
| 三指下滑 | 显示桌面 |

### 系统快捷
| 手势 | 功能 |
|------|------|
| 底部上滑 | 打开应用列表 |
| 顶部下滑 | 通知/快捷设置 |
| 左边缘右滑 | 返回 |

## 底部状态栏说明

- **左下角开始按钮** - 打开应用菜单
- **中间应用图标** - 点击切换/打开应用
- **右下角时间** - 点击打开日历/通知
- **太阳/月亮图标** - 切换日/夜间模式
- **输入法图标** - 切换中英文
- **电源图标** - 关机/重启菜单

## 默认账号
- 用户名: `yulo`
- 密码: `yulo`

## 系统要求
- 安卓 7.0+
- 至少 3GB RAM（推荐 4GB+）
- 至少 8GB 存储空间
- ARM64 架构（绝大多数现代手机）

## 性能优化建议
1. 在 Termux 中允许后台运行（关闭电池优化）
2. VNC 客户端设置画质为"中"以提升流畅度
3. 关闭不必要的后台应用释放内存
4. 使用充电器连接（高负载时耗电较快）

## 文件
- `install-yulo.sh` - 一键安装脚本
- `README.md` - 本说明文档
