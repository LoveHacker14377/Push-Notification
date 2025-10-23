#!/bin/bash
echo "Setting up LOVE HACKER Notification Tool..."
chmod +x main.sh
pkg update && pkg upgrade
pkg install python python-pip wget jq -y
pip install flask requests gunicorn
mkdir -p icons
echo "Setup complete! Run: ./main.sh"
