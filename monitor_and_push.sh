#!/bin/bash

# Load configuration
source ./config.cfg

# Function to detect file changes using SHA-256 checksum
check_for_changes() {
    local file_to_check="$1"
    local checksum_file="$2"
    
    # Calculate the current checksum
    current_checksum=$(sha256sum "$file_to_check" | awk '{ print $1 }')

    # If checksum file doesn't exist, create it and return false (no previous checksum)
    if [[ ! -f "$checksum_file" ]]; then
        echo "$current_checksum" > "$checksum_file"
        return 1
    fi

    # Read previous checksum
    previous_checksum=$(cat "$checksum_file")
    
    # Compare current and previous checksum
    if [[ "$current_checksum" != "$previous_checksum" ]]; then
        echo "$current_checksum" > "$checksum_file"
        return 0  # Changes detected
    fi
    return 1  # No changes detected
}

# Function to commit and push changes to Git
commit_and_push_changes() {
    # Change to the repository directory
    cd "$REPO_PATH" || { echo "Error: Could not access repository directory."; exit 1; }

    # Stage the changes
    git add "$MONITOR_PATH" || { echo "Error: Could not stage changes."; exit 1; }

    # Commit the changes
    git commit -m "Auto-commit: Changes detected in $MONITOR_PATH" || { echo "Error: Could not commit changes."; exit 1; }

    # Push the changes to the remote repository
    git push "$GIT_REMOTE" "$GIT_BRANCH" || { echo "Error: Git push failed."; exit 1; }
}

# Function to send email notification via SendGrid
send_email_notification() {
    local subject="Repository Update Notification"
    local body="Changes have been detected in the monitored file and pushed to the repository."

    # Prepare the email payload
    payload=$(cat <<EOF
{
    "personalizations": [
        {
            "to": [{"email": "$COLLABORATORS"}],
            "subject": "$subject"
        }
    ],
    "from": {
        "email": "$SENDER_EMAIL"
    },
    "content": [
        {
            "type": "text/plain",
            "value": "$body"
        }
    ]
}
EOF
)

    # Send the email using the SendGrid API
    curl -X POST "https://api.sendgrid.com/v3/mail/send" \
        -H "Authorization: Bearer $SENDGRID_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload" || { echo "Error: Failed to send email."; exit 1; }
}

# Main function to monitor, commit, and send email
monitor_changes() {
    # Temporary checksum file to store the last checksum
    local checksum_file="/tmp/last_checksum.txt"

    # Monitor the specified file for changes
    if check_for_changes "$MONITOR_PATH" "$checksum_file"; then
        echo "Changes detected in $MONITOR_PATH."
        
        # Commit and push the changes
        commit_and_push_changes
        
        # Send an email notification
        send_email_notification
    else
        echo "No changes detected."
    fi
}

# Run the monitoring function
monitor_changes
