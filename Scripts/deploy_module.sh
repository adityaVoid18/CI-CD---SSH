#!/bin/bash

# Ensure correct number of arguments
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <MODULE_NAME> <SSH_KEY> <SERVER_IP> <SERVER_PORT> <REMOTE_PATH>"
  exit 1
fi

# Get the necessary parameters from arguments
MODULE_NAME=$1
SSH_KEY=$2
SERVER_IP=$3
SERVER_PORT=$4
REMOTE_PATH=$5
REMOTE_PATH="$5/$MODULE_NAME"

# Define paths
LOCAL_PATH="./$MODULE_NAME/publish/"
TEMP_PATH="./$MODULE_NAME/temp_publish/"

# Verify if the local directory exists
if [ ! -d "$LOCAL_PATH" ]; then
  echo "Error: Directory $LOCAL_PATH not found!"
  exit 1
fi

# Check if required tools are installed
command -v ssh >/dev/null 2>&1 || { echo >&2 "Error: SSH is not installed."; exit 1; }
command -v sftp >/dev/null 2>&1 || { echo >&2 "Error: SFTP is not installed."; exit 1; }

# Setup SSH key if not already set up
SSH_KEY_PATH=~/.ssh/bitbucket_work
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Setting up SSH key..."
  mkdir -p ~/.ssh
  echo "$SSH_KEY" | base64 --decode > "$SSH_KEY_PATH"
  chmod 600 "$SSH_KEY_PATH"
  ssh-keyscan -p "$SERVER_PORT" "$SERVER_IP" >> ~/.ssh/known_hosts
  if [ $? -ne 0 ]; then
    echo "Error: ssh-keyscan command failed!"
    exit 1
  fi
fi

# Check if appsettings.json exists on the server
FILE_EXISTS=$(ssh -i ~/.ssh/bitbucket_work -p "$SERVER_PORT" sysadmin@"$SERVER_IP" << EOF
test -f "$REMOTE_PATH/appsettings.json" && echo "exists" || echo "not_exists"
EOF
)
if [ $? -ne 0 ]; then
  echo "Error: SSH command failed!"
  exit 1
fi

# Prepare temporary directory
mkdir -p "$TEMP_PATH"

# Deploy files using SFTP with clear messaging
if [ "$FILE_EXISTS" == "not_exists" ]; then
  echo "Deploying all files... including appsettings.json"
  cp -r "$LOCAL_PATH/"* "$TEMP_PATH/"
else
  echo "Deploying files... excluding appsettings.json"
  cp -r "$LOCAL_PATH/"* "$TEMP_PATH/"
  rm -f "$TEMP_PATH/appsettings.json"
fi

# Use SFTP to upload files to the server
sftp -i ~/.ssh/bitbucket_work -P "$SERVER_PORT" username@"$SERVER_IP" << EOF
lcd $TEMP_PATH
cd $REMOTE_PATH
mput *
bye
EOF

if [ $? -ne 0 ]; then
  echo "Error: SFTP command failed!"
  exit 1
fi

echo "Deployment successful!"

# Clean up temporary files and SSH key
rm -rf "$TEMP_PATH"
if [ -f ~/.ssh/bitbucket_work ]; then
  rm -f ~/.ssh/bitbucket_work
fi