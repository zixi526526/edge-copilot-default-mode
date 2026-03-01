# 单实例保护
$mutexName = "Global\CopilotSmartPlusDaemon"
$pidFile = Join-Path $env:TEMP "CopilotSmartPlusDaemon.pid"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

if (-not $mutex.WaitOne(0)) {
    Write-Host "[Smart Plus] 检测到已有实例在运行，正在接管..." -ForegroundColor Yellow
    if (Test-Path $pidFile) {
        $oldPid = (Get-Content $pidFile -ErrorAction SilentlyContinue).Trim()
        if ($oldPid) {
            # 先找到旧 PowerShell 的父进程（cmd.exe 窗口），一起杀掉
            try {
                $oldProc = Get-WmiObject Win32_Process -Filter "ProcessId=$oldPid" -ErrorAction SilentlyContinue
                if ($oldProc -and $oldProc.ParentProcessId) {
                    Stop-Process -Id $oldProc.ParentProcessId -Force -ErrorAction SilentlyContinue
                }
            } catch { }
            Stop-Process -Id ([int]$oldPid) -Force -ErrorAction SilentlyContinue
        }
    }
    Start-Sleep -Milliseconds 500
    try { $mutex.WaitOne() | Out-Null } catch [System.Threading.AbandonedMutexException] { }
}

$PID | Set-Content $pidFile -Force
Write-Host "[Smart Plus] 单实例锁已获取 (PID: $PID)" -ForegroundColor Green

$ErrorActionPreference = "SilentlyContinue"
$DebugPort = 9222
$SlowIntervalMs = 2000   # idle: 2s
$FastIntervalMs = 500    # active: 0.5s
$CurrentIntervalMs = $SlowIntervalMs

$InjectCode = @'
(function() {
    if (window.__copilotSmartPlusInjected) return 'already_injected';
    window.__copilotSmartPlusInjected = true;
    function isAlreadySmartPlus() {
        var btn = document.querySelector('[data-testid="composer-chat-mode-smart-latest-button"]');
        if (btn) {
            var label = (btn.getAttribute('aria-label') || '').toLowerCase();
            if (label.includes('smart plus')) {
                var popover = document.getElementById('popoverPortal');
                if (!popover || !popover.contains(btn)) return true;
            }
        }
        return false;
    }
    function trySelect() {
        if (isAlreadySmartPlus()) return true;
        var popover = document.getElementById('popoverPortal');
        if (popover) {
            var item = popover.querySelector('[data-testid="composer-chat-mode-smart-latest-button"]');
            if (item) { item.click(); return true; }
        }
        var smartBtn = document.querySelector('[data-testid="composer-chat-mode-smart-button"]');
        if (smartBtn) {
            smartBtn.click();
            setTimeout(function() {
                var p = document.getElementById('popoverPortal');
                if (p) {
                    var t = p.querySelector('[data-testid="composer-chat-mode-smart-latest-button"]');
                    if (t) t.click();
                }
            }, 500);
            return true;
        }
        return false;
    }
    var attempts = 0;
    var timer = setInterval(function() {
        attempts++;
        if (trySelect() || attempts >= 20) clearInterval(timer);
    }, 1000);
    var debounce = null, lastTime = 0;
    var obs = new MutationObserver(function() {
        if (debounce) clearTimeout(debounce);
        debounce = setTimeout(function() {
            var now = Date.now();
            if (now - lastTime < 3000) return;
            if (!isAlreadySmartPlus()) {
                if (trySelect()) lastTime = now;
            }
        }, 1500);
    });
    if (document.body) obs.observe(document.body, {childList:true, subtree:true});
    return 'injected_ok';
})();
'@

$EscapedCode = $InjectCode -replace '\\', '\\\\' -replace '"', '\"' -replace "`n", '\n' -replace "`r", ''

$injectedSet = @{}

function Get-CdpTargets {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$DebugPort/json" -TimeoutSec 2
        return $response
    }
    catch {
        return $null
    }
}

function Invoke-CdpEvaluate {
    param([string]$WsUrl, [string]$Code)
    try {
        $ws = New-Object System.Net.WebSockets.ClientWebSocket
        $cts = New-Object System.Threading.CancellationTokenSource
        $cts.CancelAfter(5000)
        $ws.ConnectAsync([Uri]$WsUrl, $cts.Token).Wait()
        if ($ws.State -ne 'Open') {
            $ws.Dispose()
            return $false
        }
        $msg = '{"id":1,"method":"Runtime.evaluate","params":{"expression":"' + $Code + '"}}'
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(, $bytes)
        $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()
        $buffer = New-Object byte[] 4096
        $recvSegment = New-Object System.ArraySegment[byte] -ArgumentList @(, $buffer)
        $result = $ws.ReceiveAsync($recvSegment, $cts.Token).Result
        $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", $cts.Token).Wait()
        $ws.Dispose()
        return $true
    }
    catch {
        if ($ws) { $ws.Dispose() }
        return $false
    }
}

Write-Host "[Smart Plus] Daemon started. Port: $DebugPort" -ForegroundColor Green
Write-Host "[Smart Plus] Adaptive polling: ${SlowIntervalMs}ms idle / ${FastIntervalMs}ms active" -ForegroundColor Green
Write-Host ""

try {
    while ($true) {
        $targets = Get-CdpTargets
        $needsFast = $false

        if ($null -ne $targets) {
            foreach ($target in $targets) {
                $url = $target.url
                $wsUrl = $target.webSocketDebuggerUrl

                if ($url -and $url.StartsWith("https://copilot.microsoft.com") -and $wsUrl) {
                    if (-not $injectedSet.ContainsKey($wsUrl)) {
                        $needsFast = $true
                        $ts = Get-Date -Format 'HH:mm:ss'
                        Write-Host "[$ts] Found Copilot: $url" -ForegroundColor Cyan
                        $ok = Invoke-CdpEvaluate -WsUrl $wsUrl -Code $EscapedCode
                        if ($ok) {
                            Write-Host "[$ts] Inject OK!" -ForegroundColor Green
                            $injectedSet[$wsUrl] = $true
                            $needsFast = $false
                        }
                        else {
                            Write-Host "[$ts] Inject FAILED." -ForegroundColor Red
                        }
                    }
                }
            }

            $currentWsUrls = $targets | Where-Object { $_.webSocketDebuggerUrl } | ForEach-Object { $_.webSocketDebuggerUrl }
            $toRemove = @($injectedSet.Keys | Where-Object { $_ -notin $currentWsUrls })
            foreach ($key in $toRemove) {
                $injectedSet.Remove($key)
                $needsFast = $true
            }
        }

        if ($needsFast) {
            $CurrentIntervalMs = $FastIntervalMs
        }
        else {
            $CurrentIntervalMs = $SlowIntervalMs
        }

        Start-Sleep -Milliseconds $CurrentIntervalMs
    }
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
