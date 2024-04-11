#!/bin/bash
#
# Bootstraps the minecraft server into a tmux session for easy access
#
# ./bootstrap.sh server_path
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1
if [ $# -eq 0 ]; then
    echo "First parameter should be the minecraft server root directory"
    exit 1
fi

# Change to the server root
cd $1

# Create a detached tmux session named "minecraft" and launch the server in it
session_name=minecraft
tmux new-session -s ${session_name} -d
pane=${session_name}:0.0
tmux send-keys -t "$pane" 'sh ./server-start.sh' Enter

echo "Minecraft server launched, attach to it by running:"
echo "tmux attach-session -t ${session_name}"
