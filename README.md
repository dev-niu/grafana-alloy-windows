# Grafana Alloy Windows Server Installation and Configuration Guide

This document explains how to install Grafana Alloy on Windows Server and apply the `config.windows.server.alloy` configuration file to collect Windows Metrics, Windows Event Logs, and IIS Logs.

## 1. Download & Install

1.  **Download Installer**:
    Please download the latest version of `alloy-installer-windows-amd64.exe`:
    [Download Link](https://github.com/grafana/alloy/releases/download/v1.12.0/alloy-installer-windows-amd64.exe)

2.  **Run Installation**:
    - Double-click the installer.
    - It is recommended to keep the default installation path (`C:\Program Files\GrafanaLabs\Alloy`).
    - After installation, the Alloy service will be automatically registered but not yet fully configured.

## 2. Run Configuration Script

We provide an automated script `set_alloy_config_to_windows_server.bat` to help generate the configuration file and verify the environment.

### Execution Steps

1.  **Run as Administrator**:
    - **Method A (GUI)**: Right-click `set_alloy_config_to_windows_server.bat` and select "Run as administrator".
    - **Method B (PowerShell)**: Open PowerShell (as Administrator), switch to the script directory, and run:
      ```powershell
      .\set_alloy_config_to_windows_server.bat
      ```

2.  **Select Language**:
    - Enter `1` for English.
    - Enter `2` for Traditional Chinese.

3.  **Enter Credentials**:
    The script will ask for the following information in order, please have it ready (Please obtain from Loki & Prometheus administrators):

    - **Loki Information (Logs)**:
        - `Loki Base URL`: e.g., `http://loki.example.com` (Do not include `/loki/api/...`)
        - `Loki Username`: Your Loki username
        - `Loki Password`: Your Loki password (Input will be hidden, right-click to paste then press Enter)

    - **Prometheus Information (Metrics)**:
        - `Prometheus Base URL`: e.g., `http://prometheus.example.com`
        - `Prometheus Username`: Your Prometheus username
        - `Prometheus Password`: Your Prometheus password (Input will be hidden, right-click to paste then press Enter)

```powershell
    PS C:\Users\Administrator\Documents\Test\Monitor> .\set_alloy_config_to_windows_server.bat
    Select Language / 選擇語言:
    1. English
    2. Traditional Chinese (繁體中文)
    Enter choice (1 or 2): 1
    ========================================================
    Grafana Alloy Environment Verification Script
    ========================================================

    [CHECK] Checking for Administrator privileges...
    [OK] Running as Administrator

    [INPUT] Please enter credentials:

    --------------------------------------------------------
    Enter Loki Base URL: http://loki-base-url:3101
    Enter Loki Username: loki-username
    Enter Loki Password:
    (Hidden Input: Right-click once to paste, then press Enter)

    --------------------------------------------------------
    Enter Prometheus Base URL: http://prometheus-base-url:9090
    Enter Prometheus Username: prom-username
    Enter Prometheus Password:
    (Hidden Input: Right-click once to paste, then press Enter)

    [CHECK] Verifying directories...
    [OK] Alloy Dir: C:\ProgramData\GrafanaAlloy
    [OK] Agent Dir: C:\Program Files\GrafanaLabs\Alloy
    [OK] IIS Log Dir: C:\inetpub\logs\LogFiles

    [CHECK] Verifying API Connectivity...
    Testing Prometheus (http://prometheus-base-url:9090/-/ready)...
    [OK] Prometheus READY
    Testing Loki (http://loki-base-url:3101/ready)...
    [OK] Loki READY
    [DEPLOY] Generating and deploying configuration...
    Reading template from: C:\Users\Administrator\Documents\Test\Monitor\alloy_config_templates\config.windows_server.alloy
    Reading template from: C:\Users\Administrator\Documents\Test\Monitor\alloy_config_templates\config.windows_server.alloy
    [OK] Config generated: C:\Users\Administrator\Documents\Test\Monitor\config.alloy
    Copying to: C:\Program Files\GrafanaLabs\Alloy\config.alloy
    [OK] Config deployed successfully.

    [SERVICE] Restarting Alloy service...
    [OK] Service restarted.
    [SERVICE] Checking Alloy service status...

    Status   Name               DisplayName
    ------   ----               -----------
    Running  Alloy              alloy



    [INFO] Verification and Deployment complete
    Press any key to continue . . .
    PS C:\Users\Administrator\Documents\Test\Monitor>
```

---
**Note**: If the IIS Log directory is different, please manually modify the configuration file or verify the path.
