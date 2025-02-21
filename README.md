# Devops-Automation
# Automated Collaborative Development Workflow

This script automates the process of monitoring changes in a file or directory, committing changes to Git, and notifying collaborators via email using the SendGrid API.

## Prerequisites
- Git must be installed.
- A GitHub repository should be initialized.
- A SendGrid API key should be created.

## Configuration
Edit the `config.cfg` file to specify:
- Path to the local Git repository.
- Path to the file or directory to monitor.
- Git remote and branch.
- List of collaborators' email addresses.
- SendGrid API key and sender email.

## Usage
1. Make the script executable:
   ```bash
   chmod +x monitor_and_push.sh
