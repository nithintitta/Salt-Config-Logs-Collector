SaltStack & RAAS Diagnostic Bundle Generator
This script is a comprehensive troubleshooting tool designed to collect logs, configurations, and system metadata from Salt Master, Salt Minion, and SaltStack Config (RAAS) nodes. It automatically detects installed components and generates a compressed .tar.gz bundle that mirrors the system's directory structure for easy analysis.

Features
Component Awareness: Automatically detects and collects data for salt-master, salt-minion, salt-api, salt-syndic, and raas.

Full Log Capture: Collects all active and rotated logs (.log, .gz, etc.) from /var/log/salt/ and /var/log/raas/.

Configuration Mirroring: Preserves the original file system hierarchy for /etc/salt/ and /etc/raas/.

Version Reporting: Captures detailed version reports for Salt and RAAS (executed as the appropriate user).

System Diagnostics:

systemd service statuses and the last 1000 lines of journalctl per service.

Network port audits (4505, 4506, 8237).

Process snapshots for Salt and RAAS.

Local Minion grains and Master key lists.

Bundle Structure
The generated archive mirrors the root filesystem to provide context to support teams:

Plaintext

salt_diagnostic_[hostname]_[timestamp].tar.gz
├── etc/
│   ├── salt/            # Full Salt configuration tree
│   └── raas/            # Full RAAS configuration tree
├── var/
│   └── log/
│       ├── salt/        # All Salt logs (including rotated .gz)
│       └── raas/        # All RAAS logs
├── reports/
│   ├── salt_versions.txt
│   ├── raas_versions_report.txt
│   ├── minion_grains.txt
│   └── network_ports.txt
└── systemd/
    ├── salt-master_status.txt
    └── raas_journal.log
Usage
Download the script: curl -O https://path-to-your-repo/salt_diag.sh

Make it executable: chmod +x salt_diag.sh

Run as root: sudo ./salt_diag.sh

The resulting bundle will be located in /tmp/.

Requirements
OS: Linux (Systemd-based distributions like RHEL, Ubuntu, Debian, or SUSE).

Privileges: Root/Sudo access is required to read configuration files and service logs.




Security & Privacy
Before sharing the generated bundle with third parties or support vendors, please consider the following:

Sensitive Data: Configuration files in /etc/salt/ or /etc/raas/ may contain sensitive information such as API keys, passwords, or private encryption keys.

Pillar Data: If you have manually included pillar information, ensure no secrets (like database credentials) are exposed.

IP Addresses: Logs and network reports will contain internal IP addresses and hostnames of your infrastructure.

Recommendation: Use a tool like grep or sed to scrub sensitive strings, or manually inspect the /etc/ directory within the bundle before transmission.

Troubleshooting Architecture
To help you understand how the script interacts with the SaltStack ecosystem, refer to the component diagram below. This illustrates which areas the script probes for logs and metadata.

Automated Scrubbing (Optional)
If you wish to perform a quick "redaction" of the bundle before sending it, you can run the following command on the extracted folder:

Bash

# Example: Replace a known sensitive password with placeholders
find ./tmp/salt_diagnostic_*/ -type f -exec sed -i 's/my-secret-password/REDACTED/g' {} +


