Shell Scripting Challenge 🐧

A practical collection of Bash scripts developed to strengthen Linux system administration, troubleshooting, security auditing, and operational automation skills.

The repository focuses on real-world tasks commonly encountered in Linux infrastructure and production support environments.

🎯 Objectives

Automate repetitive Linux administration tasks.

Simplify service health checks and recovery workflows.

Audit users, SSH keys, and special file permissions.

Practice writing reusable scripts for day-to-day operations.

Improve Bash scripting, troubleshooting, and operational efficiency.

🛠️ Scripts

Script

Purpose

service_recovery.sh

Service recovery-related automation

service_report.sh

Service reporting

service_restart.sh

Service restart operations

ssh_check.sh

SSH-related checks

ssh_key_audit.sh

SSH key auditing

suid-sgid.sh

SUID/SGID permission auditing

user_audit.sh

User auditing

user_cleanup.sh

User cleanup tasks

user_create.sh

User creation

usergroup.sh

User/group administration

worldfileaudit.sh

World-accessible file auditing

Descriptions are based on script names; see each script's implementation for its exact behavior and requirements.

⚙️ Prerequisites

Linux environment

Bash shell

Appropriate permissions for the operation being tested

Required utilities for the individual scripts

🚀 Getting Started

Clone the repository:

git clone https://github.com/AnuragUtkarsh/Shell-scripting-challenge.git
cd Shell-scripting-challenge

Inspect a script before running it:

less ssh_key_audit.sh
bash -n ssh_key_audit.sh

Run a script after reviewing its behavior and prerequisites:

bash ssh_key_audit.sh

Replace the example filename with the script you want to test.

🧪 Testing & Safety

Review each script before execution.

Test in a lab environment before using it on a production system.

Verify required privileges and target paths.

Take care with scripts that create, delete, modify, or restart system resources.

Do not run scripts with elevated privileges unless necessary and understood.

📚 Learning Outcomes

Bash scripting and command-line automation

Linux user and group management

SSH security auditing

Service administration and troubleshooting

File permission auditing

Practical Linux operational workflows

👨‍💻 About

Created by Anurag Utkarsh as part of a hands-on Bash scripting challenge focused on Linux administration and operational automation.
