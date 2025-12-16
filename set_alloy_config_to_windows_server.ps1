# ========================================================
# Grafana Alloy Environment Verification and Deployment Script
# PowerShell Conversion (Including Downward Compatibility Fixes)
# ========================================================

# --- Configuration ---
$TemplateFile = Join-Path $PSScriptRoot "alloy_config_templates\config.windows_server.alloy"
$OutputFile = Join-Path $PSScriptRoot "config.alloy"
$TargetDir = "C:\Program Files\GrafanaLabs\Alloy"
$TargetFile = Join-Path $TargetDir "config.alloy"
$DirAlloy = "C:\ProgramData\GrafanaAlloy"
$DirAgent = "C:\Program Files\GrafanaLabs\Alloy"
$ChecksFailed = $false

# --- Color Functions (PowerShell specific) ---
function Write-Color {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [System.ConsoleColor]$Foreground = "White",
        [System.ConsoleColor]$Background = "Black"
    )
    # 確保傳入非空字串
    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }
    Write-Host $Message -ForegroundColor $Foreground -BackgroundColor $Background
}

function Write-Info {
    param([string]$Message)
    Write-Color $Message -Foreground Cyan
}

function Write-OK {
    param([string]$Message)
    Write-Color $Message -Foreground Green
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Color $Message -Foreground Red
    $script:ChecksFailed = $true
}

function Write-WarningMsg {
    param([string]$Message)
    Write-Color $Message -Foreground Yellow
}

# --- Language Selection and Message Setup ---
function Set-Language {
    Write-Host "Select Language / 選擇語言:"
    Write-Host "1. English"
    Write-Host "2. Traditional Chinese (繁體中文)"

    $LangChoice = Read-Host "Enter choice (1 or 2)"
    if ($LangChoice -eq "2") {
        # Traditional Chinese
        $script:MSG_HEADER_1 = "Grafana Alloy 環境驗證腳本"
        $script:MSG_CHECK_ADMIN = "[檢查] 正在檢查管理員權限..."
        $script:MSG_ADMIN_OK = "[OK] 以管理員身分執行"
        $script:MSG_ADMIN_FAIL = "[錯誤] 此腳本必須以管理員身分執行"
        $script:MSG_INPUT_CRED = "[輸入] 請輸入憑證資訊："
        $script:MSG_LOKI_URL_PROMPT = "請輸入 Loki Base URL: "
        $script:MSG_LOKI_URL_EMPTY = "[錯誤] Loki Base URL 不能為空。"
        $script:MSG_LOKI_USER_PROMPT = "請輸入 Loki 使用者名稱: "
        $script:MSG_USER_EMPTY = "[錯誤] 使用者名稱不能為空。"
        $script:MSG_LOKI_PASS_PROMPT = "請輸入 Loki 密碼:"
        $script:MSG_HIDDEN_INPUT = "(隱藏輸入: 密碼將被隱藏，直接輸入後按 Enter)"
        $script:MSG_PROM_URL_PROMPT = "請輸入 Prometheus Base URL: "
        $script:MSG_PROM_URL_EMPTY = "[錯誤] Prometheus Base URL 不能為空。"
        $script:MSG_PROM_USER_PROMPT = "請輸入 Prometheus 使用者名稱: "
        $script:MSG_PROM_PASS_PROMPT = "請輸入 Prometheus 密碼:"
        $script:MSG_CHECK_DIR = "[檢查] 正在驗證目錄..."
        $script:MSG_ALLOY_DIR_OK = "[OK] Alloy 目錄:"
        $script:MSG_ALLOY_DIR_FAIL = "[失敗] 建立目錄失敗"
        $script:MSG_AGENT_DIR_OK = "[OK] Agent 目錄:"
        $script:MSG_AGENT_DIR_WARN = "[警告] 找不到 Agent 目錄"
        $script:MSG_CHECK_NET = "[檢查] 正在驗證 API 連線..."
        $script:MSG_TEST_PROM = "測試 Prometheus"
        $script:MSG_PROM_READY = "[OK] Prometheus 就緒"
        $script:MSG_PROM_FAIL = "[錯誤] Prometheus 失敗"
        $script:MSG_TEST_LOKI = "測試 Loki"
        $script:MSG_LOKI_READY = "[OK] Loki 就緒"
        $script:MSG_LOKI_FAIL = "[錯誤] Loki 失敗"
        $script:MSG_DEPLOY_START = "[部署] 正在產生並部署設定..."
        $script:MSG_TPL_NOT_FOUND = "[錯誤] 找不到範本檔案："
        $script:MSG_READ_TPL = "正在讀取範本："
        $script:MSG_GEN_OK = "[OK] 設定已產生："
        $script:MSG_GEN_FAIL = "[錯誤] 產生設定失敗。"
        $script:MSG_TARGET_DIR_WARN = "[警告] 找不到目標目錄。正在建立："
        $script:MSG_COPY_START = "正在複製到："
        $script:MSG_DEPLOY_OK = "[OK] 設定部署成功。"
        $script:MSG_DEPLOY_FAIL = "[錯誤] 部署設定失敗。"
        $script:MSG_RESTART_SERVICE = "[服務] 正在重新啟動 Alloy 服務..."
        $script:MSG_SERVICE_RESTARTED = "[OK] 服務已重新啟動。"
        $script:MSG_SERVICE_FAIL = "[錯誤] 重新啟動服務失敗。"
        $script:MSG_CHECK_STATUS = "[服務] 正在檢查 Alloy 服務狀態..."
        $script:MSG_COMPLETE = "[資訊] 驗證與部署完成"
        $script:MSG_CHECKS_FAILED = "[錯誤] 一項或多項檢查失敗。中止部署。"
    } else {
        # English (Default)
        $script:MSG_HEADER_1 = "Grafana Alloy Environment Verification Script"
        $script:MSG_CHECK_ADMIN = "[CHECK] Checking for Administrator privileges..."
        $script:MSG_ADMIN_OK = "[OK] Running as Administrator"
        $script:MSG_ADMIN_FAIL = "[ERROR] This script must be run as Administrator"
        $script:MSG_INPUT_CRED = "[INPUT] Please enter credentials:"
        $script:MSG_LOKI_URL_PROMPT = "Enter Loki Base URL: "
        $script:MSG_LOKI_URL_EMPTY = "[ERROR] Loki Base URL cannot be empty."
        $script:MSG_LOKI_USER_PROMPT = "Enter Loki Username: "
        $script:MSG_USER_EMPTY = "[ERROR] Username cannot be empty."
        $script:MSG_LOKI_PASS_PROMPT = "Enter Loki Password:"
        $script:MSG_HIDDEN_INPUT = "(Hidden Input: Password will be masked, type and press Enter)"
        $script:MSG_PROM_URL_PROMPT = "Enter Prometheus Base URL: "
        $script:MSG_PROM_URL_EMPTY = "[ERROR] Prometheus Base URL cannot be empty."
        $script:MSG_PROM_USER_PROMPT = "Enter Prometheus Username: "
        $script:MSG_PROM_PASS_PROMPT = "Enter Prometheus Password:"
        $script:MSG_CHECK_DIR = "[CHECK] Verifying directories..."
        $script:MSG_ALLOY_DIR_OK = "[OK] Alloy Dir:"
        $script:MSG_ALLOY_DIR_FAIL = "[FAIL] Create Dir Failed"
        $script:MSG_AGENT_DIR_OK = "[OK] Agent Dir:"
        $script:MSG_AGENT_DIR_WARN = "[WARN] Agent Dir not found"
        $script:MSG_CHECK_NET = "[CHECK] Verifying API Connectivity..."
        $script:MSG_TEST_PROM = "Testing Prometheus"
        $script:MSG_PROM_READY = "[OK] Prometheus READY"
        $script:MSG_PROM_FAIL = "[ERROR] Prometheus Failed"
        $script:MSG_TEST_LOKI = "Testing Loki"
        $script:MSG_LOKI_READY = "[OK] Loki READY"
        $script:MSG_LOKI_FAIL = "[ERROR] Loki Failed"
        $script:MSG_DEPLOY_START = "[DEPLOY] Generating and deploying configuration..."
        $script:MSG_TPL_NOT_FOUND = "[ERROR] Template file not found:"
        $script:MSG_READ_TPL = "Reading template from:"
        $script:MSG_GEN_OK = "[OK] Config generated:"
        $script:MSG_GEN_FAIL = "[ERROR] Failed to generate config."
        $script:MSG_TARGET_DIR_WARN = "[WARN] Target directory not found. Creating:"
        $script:MSG_COPY_START = "Copying to:"
        $script:MSG_DEPLOY_OK = "[OK] Config deployed successfully."
        $script:MSG_DEPLOY_FAIL = "[ERROR] Failed to deploy config."
        $script:MSG_RESTART_SERVICE = "[SERVICE] Restarting Alloy service..."
        $script:MSG_SERVICE_RESTARTED = "[OK] Service restarted."
        $script:MSG_SERVICE_FAIL = "[ERROR] Failed to restart service."
        $script:MSG_CHECK_STATUS = "[SERVICE] Checking Alloy service status..."
        $script:MSG_COMPLETE = "[INFO] Verification and Deployment complete"
        $script:MSG_CHECKS_FAILED = "[ERROR] One or more checks failed. Aborting deployment."
    }
}

# --- Main Script Logic ---

# 0. Language Setup
Set-Language

Write-Info ("=" * 60)
Write-Info $MSG_HEADER_1
Write-Info ("=" * 60)
Write-Host ""

# 1. Check Administrator
Write-Info $MSG_CHECK_ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ErrorMsg $MSG_ADMIN_FAIL
    pause
    exit 1
} else {
    Write-OK $MSG_ADMIN_OK
}
Write-Host ""

# ========================================================
# INTERACTIVE CREDENTIAL INPUT
# (使用向下相容方式處理 SecureString 密碼)
# ========================================================
Write-Info $MSG_INPUT_CRED
Write-Host ""

# --- Loki Input ---
Write-Host ("-" * 60)
$LokiBaseUrl = Read-Host $MSG_LOKI_URL_PROMPT
if ([string]::IsNullOrWhiteSpace($LokiBaseUrl)) {
    Write-ErrorMsg $MSG_LOKI_URL_EMPTY
    pause
    exit 1
}
$LokiReadyUrl = "$LokiBaseUrl/ready"
$LokiPushUrl = "$LokiBaseUrl/loki/api/v1/push"

$LokiUser = Read-Host $MSG_LOKI_USER_PROMPT
if ([string]::IsNullOrWhiteSpace($LokiUser)) {
    Write-ErrorMsg $MSG_USER_EMPTY
    pause
    exit 1
}

Write-Host $MSG_LOKI_PASS_PROMPT
Write-WarningMsg $MSG_HIDDEN_INPUT 
$LokiSecurePass = Read-Host -AsSecureString 

# 使用 .NET Marshal 將 SecureString 轉換為明文，相容舊版 PowerShell
$LokiPassPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($LokiSecurePass)
$LokiPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($LokiPassPtr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($LokiPassPtr)
Write-Host "" # 確保密碼輸入後換行

# --- Prometheus Input ---
Write-Host ("-" * 60)
$PromBaseUrl = Read-Host $MSG_PROM_URL_PROMPT
if ([string]::IsNullOrWhiteSpace($PromBaseUrl)) {
    Write-ErrorMsg $MSG_PROM_URL_EMPTY
    pause
    exit 1
}
$PromReadyUrl = "$PromBaseUrl/-/ready"
$PromPushUrl = "$PromBaseUrl/api/v1/write"

$PromUser = Read-Host $MSG_PROM_USER_PROMPT
if ([string]::IsNullOrWhiteSpace($PromUser)) {
    Write-ErrorMsg $MSG_USER_EMPTY
    pause
    exit 1
}

Write-Host $MSG_PROM_PASS_PROMPT
Write-WarningMsg $MSG_HIDDEN_INPUT 
$PromSecurePass = Read-Host -AsSecureString

# 使用 .NET Marshal 將 SecureString 轉換為明文，相容舊版 PowerShell
$PromPassPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PromSecurePass)
$PromPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($PromPassPtr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PromPassPtr)
Write-Host "" # 確保密碼輸入後換行

# 2. Check Directories
Write-Info $MSG_CHECK_DIR
$ChecksFailed = $false # 重設檢查狀態

if (-not (Test-Path $DirAlloy)) {
    try {
        New-Item -Path $DirAlloy -ItemType Directory | Out-Null
        Write-OK "$MSG_ALLOY_DIR_OK $DirAlloy"
    } catch {
        Write-ErrorMsg "$MSG_ALLOY_DIR_FAIL $DirAlloy"
        $ChecksFailed = $true
    }
} else {
    Write-OK "$MSG_ALLOY_DIR_OK $DirAlloy"
}

if (Test-Path $DirAgent) {
    Write-OK "$MSG_AGENT_DIR_OK $DirAgent"
} else {
    Write-WarningMsg "$MSG_AGENT_DIR_WARN $DirAgent" # 加上 DirAgent 變數以示警
}
Write-Host ""

# 3. Check Network
Write-Info $MSG_CHECK_NET

# --- 函數：建立 PSCredential 物件 ---
function Get-PSCredential {
    param(
        [string]$Username,
        [string]$Password
    )
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
}

# --- Test Prometheus ---
Write-Host "$MSG_TEST_PROM ($PromReadyUrl)..."
try {
    # 這裡我們需要使用 $PromPass (明文密碼) 建立 PSCredential
    $Cred = Get-PSCredential -Username $PromUser -Password $PromPass
    $PromResult = Invoke-RestMethod -Uri $PromReadyUrl -Method Get -Credential $Cred -TimeoutSec 10 -ErrorAction Stop
    Write-OK $MSG_PROM_READY
} catch {
    Write-ErrorMsg "$MSG_PROM_FAIL (Details: $($_.Exception.Message))"
}

# --- Test Loki ---
Write-Host "$MSG_TEST_LOKI ($LokiReadyUrl)..."
try {
    # 這裡我們需要使用 $LokiPass (明文密碼) 建立 PSCredential
    $Cred = Get-PSCredential -Username $LokiUser -Password $LokiPass
    $LokiResult = Invoke-RestMethod -Uri $LokiReadyUrl -Method Get -Credential $Cred -TimeoutSec 10 -ErrorAction Stop
    if ($LokiResult -match "ready") {
        Write-OK $MSG_LOKI_READY
    } else {
        Write-ErrorMsg "$MSG_LOKI_FAIL (Response not 'ready')"
    }
} catch {
    Write-ErrorMsg "$MSG_LOKI_FAIL (Details: $($_.Exception.Message))"
}
Write-Host ""


# 4. Generate and Deploy Config
if ($ChecksFailed) {
    Write-ErrorMsg $MSG_CHECKS_FAILED
    pause
    exit 1
}

Write-Info $MSG_DEPLOY_START

if (-not (Test-Path $TemplateFile)) {
    Write-ErrorMsg "$MSG_TPL_NOT_FOUND $TemplateFile"
    pause
    exit 1
}

Write-Host "$MSG_READ_TPL $TemplateFile"

# --- Configuration Replacement (PowerShell Native) ---
try {
    # 使用 Get-Content 讀取模板，並使用 -replace 運算子替換變數
    (Get-Content $TemplateFile -Encoding UTF8) `
    -replace '\[your_prometheus_username\]', $PromUser `
    -replace '\[your_prometheus_password\]', $PromPass `
    -replace '\[your_loki_username\]', $LokiUser `
    -replace '\[your_loki_password\]', $LokiPass `
    -replace '\[your_prometheus_url\]', $PromPushUrl `
    -replace '\[your_loki_url\]', $LokiPushUrl | Set-Content $OutputFile -Encoding UTF8

    Write-OK "$MSG_GEN_OK $OutputFile"
} catch {
    Write-ErrorMsg "$MSG_GEN_FAIL ($($_.Exception.Message))"
    pause
    exit 1
}

if (-not (Test-Path $TargetDir)) {
    Write-WarningMsg "$MSG_TARGET_DIR_WARN $TargetDir"
    New-Item -Path $TargetDir -ItemType Directory | Out-Null
}

Write-Host "$MSG_COPY_START $TargetFile"
try {
    Copy-Item -Path $OutputFile -Destination $TargetFile -Force -ErrorAction Stop
    Write-OK $MSG_DEPLOY_OK
} catch {
    Write-ErrorMsg "$MSG_DEPLOY_FAIL ($($_.Exception.Message))"
}
Write-Host ""

# 5. Restart and Verify Service
Write-Info $MSG_RESTART_SERVICE
try {
    Restart-Service -Name "alloy" -Force -ErrorAction Stop
    Write-OK $MSG_SERVICE_RESTARTED
} catch {
    Write-ErrorMsg "$MSG_SERVICE_FAIL (Restart failed. Is 'alloy' service installed?)"
}

Write-Info $MSG_CHECK_STATUS
Get-Service -Name "alloy" | Select-Object Name, Status, DisplayName, StartType
Write-Host ""

Write-Info $MSG_COMPLETE
pause
# End of script