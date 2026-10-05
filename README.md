# AppData 深度安全清理工具

一个专注于清理 Windows `AppData\Local` 下**可安全重建**的缓存、日志与临时文件的批处理脚本。在最大化释放磁盘空间的同时，严格规避用户数据、账号信息、聊天记录等不可恢复的重要文件。

---

## 目录

- [特性](#特性)
- [安全边界](#安全边界)
- [清理范围](#清理范围)
- [系统要求](#系统要求)
- [使用方法](#使用方法)
- [脚本结构说明](#脚本结构说明)
- [FAQ](#faq)
- [副作用与恢复](#副作用与恢复)
- [禁止事项](#禁止事项)
- [更新日志](#更新日志)
- [许可](#许可)

---

## 特性

- **零依赖**：仅使用 Windows 内置 `cmd` 命令，无需安装任何运行时。
- **管理员权限校验**：启动时自动检测权限，权限不足直接提示退出。
- **只清内容，不删目录**：使用 `del` 而非 `rd` 清空缓存目录，避免程序因找不到目录而异常。
- **静默容错**：被占用的文件会被自动跳过，不会中断脚本。
- **分类清理**：系统临时文件、着色器缓存、浏览器缓存、开发者包缓存、软件日志分模块处理。
- **清晰日志输出**：每条清理项均打印名称和状态（`[清理]` / `[跳过]`）。
- **Roaming 完全隔离**：脚本中不存在任何 `%APPDATA%` 路径。

---

## 安全边界

脚本的设计原则只有一句话：

> **只清理「删掉之后软件能自动重建」的数据；任何「删掉之后需要用户重新配置 / 重新登录 / 无法恢复」的数据一律不碰。**

### 绝对不触碰的红线

| 路径 | 内容 | 后果 |
|---|---|---|
| `%APPDATA%` (Roaming) | 软件配置、账号、插件设置 | 配置重置、账号登出 |
| `%LOCALAPPDATA%\LocalLow` | 低完整性沙箱数据 | 部分插件/浏览器扩展数据丢失 |
| `%LOCALAPPDATA%\Packages\*\LocalState` | UWP 应用数据 | 应用商店应用数据丢失 |
| 浏览器 `User Data\Default\` 下的 `History` / `Bookmarks` / `Login Data` / `Web Data` / `Local Storage` / `IndexedDB` / `Sessions` | 历史记录、书签、密码、登录状态 | **不可恢复** |
| 微信 / QQ / 钉钉 / Telegram 等 IM 的用户目录 | 聊天记录、接收的文件 | **不可恢复** |
| 游戏存档目录（`Documents\My Games` 等） | 存档文件 | **不可恢复** |

脚本对以上路径**没有任何一条清理指令**。

---

## 清理范围

### 1. 系统临时与缓存

| 路径 | 说明 |
|---|---|
| `%LOCALAPPDATA%\Temp` | 用户临时文件 |
| `%LOCALAPPDATA%\Microsoft\Windows\INetCache` | IE/Edge 旧版网页缓存 |
| `%LOCALAPPDATA%\Microsoft\Windows\Temporary Internet Files` | 兼容性缓存 |
| `%LOCALAPPDATA%\Microsoft\Windows\AppCache` | Windows 应用缓存 |
| `%LOCALAPPDATA%\Microsoft\Windows\Caches` | Windows 系统缓存 |
| `%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue` | 错误报告队列 |
| `%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive` | 错误报告存档 |
| `%LOCALAPPDATA%\Microsoft\Windows\WER\Temp` | 错误报告临时文件 |
| `%LOCALAPPDATA%\Microsoft\Terminal Server Client\Cache` | 远程桌面位图缓存 |
| `%LOCALAPPDATA%\ElevatedDiagnostics` | 权限诊断残留 |
| `%LOCALAPPDATA%\CrashDumps` | 崩溃转储文件 |

### 2. 资源管理器缓存

| 路径 | 说明 |
|---|---|
| `%LOCALAPPDATA%\Microsoft\Windows\Explorer` | 缩略图 / 图标缓存数据库 |

### 3. 显卡着色器缓存

| 路径 | 说明 |
|---|---|
| `%LOCALAPPDATA%\D3DSCache` | DirectX 着色器缓存 |
| `%LOCALAPPDATA%\NVIDIA\DXCache` | NVIDIA DX 缓存 |
| `%LOCALAPPDATA%\NVIDIA\GLCache` | NVIDIA GL 缓存 |
| `%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache` | NVIDIA 驱动缓存 |
| `%LOCALAPPDATA%\AMD\DxCache` | AMD DX 缓存 |
| `%LOCALAPPDATA%\AMD\DxcCache` | AMD DXC 缓存 |
| `%LOCALAPPDATA%\AMD\GLCache` | AMD GL 缓存 |
| `%LOCALAPPDATA%\Intel\ShaderCache` | Intel 着色器缓存 |

### 4. 开发者包缓存

| 路径 | 说明 |
|---|---|
| `%LOCALAPPDATA%\pip\cache` | Python 包缓存 |
| `%LOCALAPPDATA%\npm-cache` | Node.js 包缓存 |
| `%LOCALAPPDATA%\NuGet\v3-cache` | .NET 包缓存 |
| `%LOCALAPPDATA%\Yarn\Cache` | Yarn 包缓存 |

### 5. 浏览器缓存（仅 Cache 类目录）

支持：**Chrome / Edge / Brave / Vivaldi / Opera / Firefox**

清理的子目录包括：

- `Cache`
- `Code Cache`
- `GPUCache`
- `ShaderCache`
- `GrShaderCache`
- `GraphiteDawnCache`
- `Service Worker\CacheStorage`
- `Service Worker\ScriptCache`

> 多 Profile（Default、Profile 1、Profile 2 …）会自动遍历。

### 6. 软件日志与缓存

| 路径 | 说明 |
|---|---|
| `%LOCALAPPDATA%\Microsoft\OneDrive\logs` | OneDrive 日志 |
| `%LOCALAPPDATA%\Microsoft\Office\16.0\OfficeFileCache` | Office 文件缓存 |
| `%LOCALAPPDATA%\Microsoft\Office\16.0\Wef` | Office 漫游缓存 |

---

## 系统要求

| 项目 | 要求 |
|---|---|
| 操作系统 | Windows 10 / 11（Windows 8.1 兼容） |
| 权限 | **管理员** |
| 依赖 | 无 |
| 文件编码 | ANSI（推荐）或 UTF-8 无 BOM |

---

## 使用方法

### 1. 保存脚本

将脚本内容保存为 `AppDataClean.bat`。

> **编码建议**：使用记事本「另存为」时，编码选择 **ANSI**。若保存为 UTF-8，务必选 **UTF-8 无 BOM**，否则脚本第一行的 `@echo off` 前可能混入不可见字符，导致输出异常。

### 2. 以管理员身份运行

- **方式 A**：右键脚本 → 「以管理员身份运行」
- **方式 B**：在管理员 CMD 中执行 `AppDataClean.bat`

双击运行会因权限不足直接退出并提示。

### 3. 确认清理

脚本会列出清理范围和红线，输入 `Y` 后开始执行。

### 4. 等待完成

脚本会逐项打印 `[清理]` 或 `[跳过]`，完成后暂停等待按键。

---

## 脚本结构说明

```
AppDataClean.bat
├── 权限检查          net session
├── 范围展示 + 二次确认
├── 6 组清理调用
│   ├── 系统临时与缓存
│   ├── 缩略图/图标
│   ├── 显卡着色器
│   ├── 开发者包缓存
│   ├── 浏览器缓存（Chromium 系 + Firefox）
│   └── 软件日志
└── 子程序
    ├── :Clean          清空任意目录内容，保留根目录
    ├── :CleanBrowser   遍历 Chromium 系 Profile 并清理缓存子目录
    └── :CleanFirefox   遍历 Firefox Profile 并清理缓存子目录
```

### 关键子程序

#### `:Clean <目标路径> <显示名称>`

- 若目标目录不存在 → 打印 `[跳过]`
- 若存在 → `del /f /s /q /a` 清空文件，`rd /s /q` 删除空子目录，**保留根目录本身**

#### `:CleanBrowser <User Data 路径> <浏览器名>`

- 清理 `User Data` 顶层的 ShaderCache / GrShaderCache / GraphiteDawnCache
- 遍历 `User Data\*` 每个 Profile，对每个 Profile 调用 `:Clean` 处理 6 类缓存子目录

#### `:CleanFirefox`

- 仅清理 `%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\` 下的 `cache2` / `startupCache` / `shader-cache` / `thumbnails`
- **不触碰** `%APPDATA%\Mozilla\Firefox\Profiles\`（那里是书签、密码、扩展配置）

---

## FAQ

**Q1：脚本会删掉我的微信 / QQ 聊天记录吗？**

不会。脚本里没有任何微信 / QQ 相关路径。但建议清理前先退出这些软件，避免它们锁定 Temp 文件导致部分临时文件清不掉。

**Q2：运行后浏览器登录状态会掉吗？**

不会。脚本只清理 `Cache` / `Code Cache` / `GPUCache` 等缓存目录，`Login Data`、`Cookies`、`Local Storage`、`IndexedDB`、`Sessions` 一律不碰。

**Q3：为什么有些目录显示 `[跳过]`？**

该路径在本机不存在。例如未装 Chrome 时 `Chrome\User Data` 不存在，会直接跳过。这是正常行为。

**Q4：为什么有些文件没被清掉？**

文件正被程序占用（浏览器开着、OneDrive 在跑、微信在后台）。`del` 会跳过被锁定的文件，脚本用 `>nul 2>&1` 吞掉错误继续执行。想清得更干净，先退出相关程序。

**Q5：清理完游戏变卡了？**

清掉了着色器缓存。首次进入游戏会重新编译，通常几秒到几十秒。之后就恢复正常。

**Q6：清理完 pip / npm 安装变慢了？**

清掉了包缓存，下次安装会重新下载。这是缓存的正常代价，不影响已安装的包。

**Q7：缩略图没了 / 图标变白纸？**

正常。重启资源管理器或重启电脑后系统会自动重建。可在 CMD 中执行：

```cmd
taskkill /f /im explorer.exe & start explorer.exe
```

**Q8：脚本可以放在计划任务里定时跑吗？**

可以。但注意：

- 必须以**管理员身份**运行
- 脚本末尾有 `pause`，计划任务中会卡住 → 建议复制一份删掉 `pause` 和 `set /p` 确认段，做成静默版本
- 建议选在空闲时段（如凌晨），避免与软件更新冲突

**Q9：能清理 `%APPDATA%` 吗？**

不能。Roaming 里是配置和账号数据，删了软件设置会重置、账号会登出、部分软件聊天记录会丢失。**不要对 Roaming 做任何批量清理。**

**Q10：脚本安全吗？有网络行为吗？**

完全离线。没有任何 `curl` / `wget` / `powershell -c` / 下载行为。所有操作都是本地 `del` 和 `rd`。

---

## 副作用与恢复

| 现象 | 原因 | 恢复方式 |
|---|---|---|
| 浏览器首次打开网页慢 | 网页缓存被清 | 自动重建 |
| 游戏首次进入卡顿 | 着色器缓存被清 | 自动重建 |
| 缩略图 / 图标显示异常 | 缩略图缓存被清 | 重启 explorer 或重启系统 |
| pip / npm 安装变慢 | 包缓存被清 | 重新下载 |
| Office 打开文档变慢 | Office 文件缓存被清 | 自动重建 |

以上均为**可逆**副作用，不涉及数据丢失。

---

## 禁止事项

为避免误删，**不要**做以下操作：

1. **不要**手动删除 `%LOCALAPPDATA%\Temp` 文件夹本身（只清内容）。
2. **不要**把 `%APPDATA%`（Roaming）加入任何批量清理脚本。
3. **不要**清理 `%LOCALAPPDATA%\Packages\` —— 那是 UWP 应用数据。
4. **不要**清理 `%LOCALAPPDATA%\LocalLow\` —— 沙箱数据。
5. **不要**清理浏览器 `User Data\Default\` 下的 `History` / `Bookmarks` / `Login Data` / `Web Data` / `Local Storage` / `IndexedDB`。
6. **不要**使用第三方「一键清理大师 / 系统优化工具」对 AppData 全盘扫描 —— 它们常把 Roaming 下的 `.json` / `.db` 配置误判为垃圾。
7. **不要**把脚本里的 `del` 换成 `rd /s /q` 对根目录操作 —— 会删掉目录本身。

---

## 更新日志

### v2.0

- 新增：显卡着色器缓存（D3D / NVIDIA / AMD / Intel）
- 新增：Chromium 系浏览器缓存（Chrome / Edge / Brave / Vivaldi / Opera）
- 新增：Firefox 缓存
- 新增：开发者包缓存（pip / npm / NuGet / Yarn）
- 新增：OneDrive / Office 日志与缓存
- 新增：`Windows\Caches`、`AppCache`、`WER\Temp`、`Terminal Server Client\Cache`
- 优化：子程序化，分类清晰
- 优化：多 Profile 自动遍历

### v1.0

- 初始版本：临时文件、INetCache、Explorer 缩略图、CrashDumps、pip / npm / NuGet 缓存

---

## 许可

本脚本按「原样」提供，供个人使用。运行前请自行确认清理范围符合你的需求。作者不对因误用、修改或环境差异导致的数据丢失承担责任。

**使用前请务必阅读 [安全边界](#安全边界) 与 [禁止事项](#禁止事项)。**
