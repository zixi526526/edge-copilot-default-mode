# Edge Copilot Smart Plus Auto-Switcher

![presentation](https://github.com/user-attachments/assets/0793ed22-27c2-4dd0-ab7b-a2a4012b5355)



[**English**](#english) | [**简体中文**](#简体中文)

---

<a name="english"></a>
## English

In Microsoft Edge, when the Copilot sidebar is opened, it may not default to the "Smart Plus" mode due to default settings. Furthermore, standard browser extensions cannot inject scripts or operate on the Copilot sidebar due to Edge's security policies.

**Edge Copilot Smart Plus Auto-Switcher** is a local background service script based on the Edge Remote Debugging Protocol (CDP). It automatically monitors the Copilot panel within the Edge process and seamlessly, automatically switches it to "Smart Plus" mode.

### ✨ Features
- **Smart Promotion (Non-Intrusive)**: By design, the script only activates when the standard "Smart" mode is selected (or defaulted to), automatically promoting it to "Smart Plus". If you manually switch to other modes (like Work, Web, etc.), the script will gracefully ignore it and will not force you back.
- **Fully Automatic Switching**: Once Copilot is open, the script automatically finds and clicks the Smart Plus mode.
- **Auto-Restart & Seamless Restore**: Automatically detects and safely closes residual Edge processes in the background, restarting the browser while restoring all your previous tabs, eliminating the hassle of manual cleanup.
- **Bypasses Extension Limits**: Communicates directly with the browser via the CDP protocol, requiring no browser extensions.
- **Smart Resource Usage**: Uses an adaptive polling frequency (2s when idle, 0.5s when active), having almost no impact on system performance.
- **Out of the Box**: Provides a convenient `.bat` script, ready to use without configuring a development environment.

### 🚀 Usage

#### Prerequisites
- Windows OS (Scripts are written in PowerShell/Batch)
- Microsoft Edge Browser

#### Steps
1. **Run the startup script**: 
   - Double-click the **`start.bat`** (or `启动.bat` for Chinese environment) in the folder.
2. The script will automatically perform the following:
   - **Force close and clean up** any residual `msedge.exe` processes (to prevent debugging port binding failure).
   - Launch Edge with the `--remote-debugging-port=9222` and `--restore-last-session` arguments, **automatically restoring all your previously opened tabs**.
   - Start a PowerShell daemon process in a terminal window.
3. **Keep the terminal window open**: This is the PowerShell daemon. You can **minimize** it, but do not close it. The automatic switching feature will stop if closed.
4. Open Copilot in Edge and enjoy the default Smart Plus experience!

### 👨‍💻 How it Works (Briefly)
1. `start.bat` launches Edge with the remote debugging port (`9222`) enabled.
2. `copilot-smart-plus-daemon.ps1` constantly polls the local debugging endpoint (`http://localhost:9222/json`) to retrieve all page Targets.
3. When it captures a target with the URL `copilot.microsoft.com`:
   - It uses WebSockets to inject and execute a JavaScript payload into that page instance.
   - This script looks for the `data-testid="composer-chat-mode-smart-button"` and `composer-chat-mode-smart-latest-button` buttons.
   - It simulates a click to switch modes and sets a flag on the page to prevent duplicate injection.

### ⚠️ Notes & FAQ
- **Must launch via script**: If you open Edge directly from the desktop or other shortcuts, the remote debugging port won't be open, and this daemon will wait forever.
- **Browser restore prompts**: Since the script kills the process, Edge may prompt "Restore Pages" upon starting. You can ignore this because the `--restore-last-session` argument will automatically restore them.
- **UI Updates may cause breakage**: The script relies on HTML attributes (like `data-testid`) to click. If Microsoft updates Copilot's frontend structure in the future, the script might break. You'll need to update the `$InjectCode` variable in `.ps1` accordingly.

### 📄 License
MIT License

---

<a name="简体中文"></a>
## 简体中文

在 Microsoft Edge 浏览器中，Copilot 侧边栏打开时可能由于默认设置等原因，并未处于 "Smart Plus" 模式。同时，受限于 Edge 的安全策略，常规的浏览器扩展无法对 Copilot 侧边栏注入脚本和进行操作。

**Edge Copilot Smart Plus Auto-Switcher** 是一个基于 Edge 远程调试协议 (CDP) 实现的本地后台服务脚本程序。它可以自动监控 Edge 进程中打开的 Copilot 面板，并将其无缝、自动地切换到 "Smart Plus" 模式。

### ✨ 特性

- **智能提权 (无感干预)**: 脚本在设计上只会在识别到当前为普通的 "Smart" 模式时，将其自动升级切换至 "Smart Plus" 模式。**如果你手动选择了其他模式 (如工作、网页等)，脚本会自动忽略，不会强行干预你当前的意图。**
- **全自动切换**: 只要开启 Copilot，脚本会自动寻找并点击 Smart Plus 模式。
- **自动重启与无缝恢复**: 自动检测并安全关闭后台残留的 Edge 进程，重启后自动恢复你之前的标签页，免去手动清理的烦恼。
- **突破扩展限制**: 通过 CDP 协议直接与浏览器通信，无需安装任何浏览器插件。
- **智能资源占用**: 采用自适应轮询频率（空闲时 2s 查询一次，发现目标时 0.5s 查询一次），对系统性能几乎无影响。
- **开箱即用**: 提供一键启动 `.bat` 脚本，无需配置开发环境即可使用。

### 🚀 使用方法

#### 前提条件

- Windows 操作系统 (脚本主要基于 PowerShell/Bat 编写)
- Microsoft Edge 浏览器

#### 操作步骤

1. **运行启动脚本**: 
   - 双击运行文件夹中的 **`启动.bat`** (或者使用英文版 `start.bat`)。
2. 脚本会自动进行以下操作：
   - **自动关闭并清理**后台残留的 `msedge.exe` 进程（防止调试端口开服失败）。
   - 携带 `--remote-debugging-port=9222` 与 `--restore-last-session` 参数重新启动 Edge 浏览器，并**自动恢复你关闭前的所有标签页**。
   - 启动一个 PowerShell 后台监控进程窗口。
3. **保持命令行窗口开启**: 该终端窗口为 PowerShell 监控进程，将其**最小化**即可，不要关闭。一旦关闭，自动切换功能将停止。
4. 在 Edge 中打开 Copilot，享受默认就是 Smart Plus 的体验！

### 👨‍💻 工作原理简述

1. `启动.bat` 以附加调试端口（`9222`）的方式启动了 Edge 浏览器。
2. `copilot-smart-plus-daemon.ps1` 脚本会不断轮询本机的调试接口（`http://localhost:9222/json`）获取所有的页面 Target。
3. 当捕获到 URL 为 `copilot.microsoft.com` 的目标时：
   - 使用 WebSockets 协议向该页面实例隐式注入并执行一段 JavaScript 代码。
   - 这段自动运行的 JS 代码会寻找 `data-testid="composer-chat-mode-smart-button"` 和 `composer-chat-mode-smart-latest-button` 按钮。
   - 模拟点击触发模式切换。页面上也会设置防重复注入的标记。

### ⚠️ 注意事项与常见问题

- **必须用脚本启动 Edge**: 如果你直接通过桌面或其他快捷方式打开 Edge，远程调试端口不会开启，本程序也会因连接不到端口而一直等待。
- **退出 Edge 后自动打开**: 由于启动脚本会自动 kill 掉进程，Edge 在重启时会提示“是否恢复页面”，也可以忽略弹窗，脚本的 `--restore-last-session` 参数会自动帮你恢复。
- **页面更新失效**: 脚本依赖页面元素的 HTML 属性 (如 `data-testid`) 进行点击。如果未来微软更新了 Copilot 的前端页面结构，可能导致脚本失效，需要同步修改 `.ps1` 文件中的 `$InjectCode` 变量即可修复。

### 📄 协议 / License

MIT License
