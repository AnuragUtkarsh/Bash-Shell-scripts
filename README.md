# 🐧 Shell Scripting Challenge

A practical collection of Bash scripts focused on Linux system administration, troubleshooting, security auditing, and operational automation.

This repository demonstrates hands-on scripting for common Linux infrastructure and production support tasks.

## 🎯 Objectives

- Automate repetitive Linux administration tasks.
- Simplify service health checks and recovery workflows.
- Audit users, SSH keys, and file permissions.
- Practice reusable scripts for day-to-day operations.
- Improve troubleshooting and operational efficiency.

## 🛠️ Scripts

| Script | Purpose |
|---|---|
| `backup_automation.sh` | Backup-related automation |
| `config_backup.sh` | Configuration backup |
| `cpu_utilization.sh` | CPU utilization checks |
| `disk_utilization.sh` | Disk utilization checks |
| `dns_check.sh` | DNS connectivity and resolution checks |
| `error_log_analyzer.sh` | Error log analysis |
| `failed_ssh_report.sh` | Failed SSH activity reporting |
| `file_backup.sh` | File backup operations |
| `filesystem_alert.sh` | Filesystem monitoring and alerts |
| `service_recovery.sh` | Service recovery workflows |
| `service_report.sh` | Service status reporting |
| `service_restart.sh` | Service restart operations |
| `ssh_check.sh` | SSH-related checks |
| `ssh_key_audit.sh` | SSH key auditing |
| `suid-sgid.sh` | SUID/SGID permission auditing |
| `user_audit.sh` | User auditing |
| `user_cleanup.sh` | User cleanup operations |
| `user_create.sh` | User creation |
| `usergroup.sh` | User and group administration |
| `worldfileaudit.sh` | World-accessible file auditing |

*Descriptions are indicative based on script names. Refer to each script for its exact behavior and requirements.*

## ⚙️ Prerequisites

- Linux environment
- Bash shell
- Required system utilities for each script
- Appropriate permissions for the operation being tested

## 🚀 Getting Started

Clone the repository:

```bash
git clone https://github.com/AnuragUtkarsh/Bash-Shell-scripts.git
cd Bash-Shell-scripts
```

Inspect a script before running it:

```bash
less ssh_key_audit.sh
bash -n ssh_key_audit.sh
```

Run the script after reviewing its behavior:

```bash
bash ssh_key_audit.sh
```

Replace the filename with the script you want to test.

## 🧪 Safety & Best Practices

- Review scripts before execution.
- Test in a lab environment before production use.
- Verify target paths and required privileges.
- Exercise caution with scripts that modify users, permissions, files, or services.
- Never publish credentials, private keys, or company-confidential configuration.

## 📚 Skills Demonstrated

Bash scripting · Linux administration · Service troubleshooting · User management · SSH auditing · File permissions · Backup automation · Log analysis · System monitoring

## 👨‍💻 Author

**Anurag Utkarsh**

[GitHub Profile](https://github.com/AnuragUtkarsh)
