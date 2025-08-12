#!/bin/bash

# Get current timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Check if .git directory exists
if [ -d ".git" ]; then
  # Create tar.gz archive
  tar -czf "git_backup_$TIMESTAMP.tar.gz" .git
  echo "Successfully created git_backup_$TIMESTAMP.tar.gz"
else
  echo "Error: .git directory not found in current directory"
fi