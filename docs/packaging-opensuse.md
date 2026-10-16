# openSUSE Tumbleweed (风滚草) 打包与安装指南

本文档介绍如何在 openSUSE Tumbleweed (风滚草) 环境下构建、打包并安装 Magpie 原生 RPM 软件包。

---

## 1. 软件依赖要求

在 openSUSE Tumbleweed 上构建 Magpie 需要以下开发依赖包：

```bash
sudo zypper install \
    rpm-build \
    go1.26 \
    gcc \
    pkgconf-pkg-config \
    gtk3-devel \
    webkitgtk3-devel \
    desktop-file-utils \
    hicolor-icon-theme
```

> **注意：**
>
> - Magpie Linux 桌面版基于 GTK 3 与 WebKitGTK 4.1（openSUSE 包名为 `gtk3-devel` 和 `webkitgtk3-devel`，运行时依赖 `libwebkit2gtk-4_1-0`）。
> - 本地已有 Go 1.24+ 工具链即可编译，打包脚本会自动检测本地 Go 环境。

---

## 2. 打包文件架构

本项目为 Linux / openSUSE 提供了专门的打包配置（位于 [build/linux](file:///home/hu-hub/Github/magpie/build/linux/) 目录）：

- **[magpie.desktop](file:///home/hu-hub/Github/magpie/build/linux/magpie.desktop)**: XDG 标准桌面快捷方式（包含中英文名称、描述、`magpie://` 协议关联）。
- **[magpie.service](file:///home/hu-hub/Github/magpie/build/linux/magpie.service)**: Systemd 用户服务单元（用于后台常驻服务）。
- **[magpie.spec](file:///home/hu-hub/Github/magpie/build/linux/magpie.spec)**: 符合 openSUSE 规范的 RPM spec 描述文件（包含全套 16x16 ~ 512x512 及矢量 SVG 图标生成、依赖校验与桌面数据库集成）。
- **[build-rpm.sh](file:///home/hu-hub/Github/magpie/build/linux/build-rpm.sh)**: 一键自动化打包脚本，负责版本提取、源码归档、图标生成及 RPM 打包。

---

## 3. 一键构建 RPM 软件包

在仓库根目录下，直接执行以下命令：

```bash
make rpm
```

或者直接运行打包脚本：

```bash
./build/linux/build-rpm.sh
```

构建完成后，生成的软件包位于 `dist/rpm/` 目录：

- **`magpie-<version>-<release>.x86_64.rpm`**: 可直接在 openSUSE 上安装的二进制包。
- **`magpie-<version>-<release>.src.rpm`**: 源码 RPM 包（可直接用于 openSUSE Build Service / OBS 提交构建）。

---

## 4. 安装与卸载

### 安装 RPM 包

使用 `zypper` 本地安装（会自动解析补全系统动态库依赖）：

```bash
sudo zypper install ./dist/rpm/magpie-*.x86_64.rpm
```

### 卸载

```bash
sudo zypper remove magpie
```

---

## 5. 运行与使用

安装完成后，Magpie 将无缝融入 openSUSE 系统：

1. **图形界面**：
   - 可以在应用程序菜单（应用启动器、GNOME 应用列表、KDE 启动菜单）中直接搜索并启动 **Magpie 喜鹊**。
   - 终端启动桌面窗口：
     ```bash
     magpie
     # 或
     magpie app
     ```

2. **协议关联**：
   - 浏览器中的 `magpie://import?...` 链接会自动调用本地已安装的 Magpie 打开并导入供应商配置。

3. **后台网关服务（可选）**：
   - 如果希望以系统服务开机/登录自动运行网关：
     ```bash
     systemctl --user enable --now magpie
     ```
   - 查看运行状态：
     ```bash
     systemctl --user status magpie
     ```
   - 也可以使用 Magpie 自身的 daemon 管理命令：
     ```bash
     magpie daemon install --web
     magpie daemon status
     ```

---

## 6. 在 OBS (openSUSE Build Service) 构建与分发

如需将 Magpie 发布到 openSUSE 官方或社区源：

1. 将 `dist/rpm/magpie-*.src.rpm` 导入到 OBS 项目中。
2. 或将 `build/linux/magpie.spec`、源码包、`magpie.desktop` 和 `magpie.service` 上传到 OBS 仓库即可自动为各类 openSUSE 版本（Tumbleweed、Leap、Slowroll）打包分发。
