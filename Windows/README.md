# Windows Salt-Minion Diagnostic Collector

A PowerShell utility designed to automate the collection of critical logs, configurations, system information, and event data for troubleshooting SaltStack Minions on Windows environments.

This script acts as the Windows equivalent to standard Linux diagnostic bundle generators, packing everything into a single, easy-to-share `.zip` archive.

## 🚀 Features

The script automatically locates your Salt installation (supporting both modern `C:\ProgramData\Salt Project\Salt` and legacy `C:\salt` paths) and collects the following:

1. **Identity & Network Metadata:** Hostname, Minion ID, IPv4 addresses, and configured Salt Master.
2. **System Information:** Full OS build, boot time, memory, and hotfix details (via `systeminfo`).
3. **Version Reports:** Detailed versioning of the installed Salt-Minion and its dependencies.
4. **Service Status:** Current state of the `salt-minion` Windows service, plus a quick-glance text summary of the last 1,000 Salt-related Application events.
5. **Raw Event Logs:** Full exports of the Windows **Application** and **System** event logs as `.evtx` files for deep-dive analysis in Event Viewer.
6. **Networking & Processes:** List of running Salt/Python processes and active connections on Salt ports (4505, 4506).
7. **Configurations:** A complete mirror of the Salt `conf` directory.
8. **Logs:** A complete mirror of the Salt `var\log\salt` directory.
9. **Live Data:** Output of locally compiled Salt grains (`salt-call --local grains.items`).

## 📋 Prerequisites

* **Operating System:** Windows Server or Windows Desktop OS.
* **Privileges:** The script **must** be run as an Administrator to successfully read system logs, copy configurations, and query service states.
* **PowerShell:** Compatible with Windows PowerShell 5.1 and newer.

## ⚙️ Usage

1. Save the script to your Windows machine as `windows-minion-sos.ps1`.
2. Open PowerShell as an **Administrator**.
3. Execute the script:
   ```powershell
   .\windows-minion-sos.ps1
