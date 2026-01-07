#!/bin/bash

# --- CONFIGURATION ---
ST_URL="http://localhost:8384"
ST_API_KEY="YOUR_API_KEY_HERE"  # Find in Syncthing > Settings > GUI
FOLDER_ID="YOUR_FOLDER_ID"      # Found in Syncthing folder details
DOCKER_NAME="YOUR_CONTAINER"    # Name or ID of the Docker container

# --- 1. STOP DOCKER CONTAINER ---
echo "Stopping Docker container: $DOCKER_NAME..."
docker stop "$DOCKER_NAME"

# --- 2. UNPAUSE SYNCTHING FOLDER ---
echo "Unpausing Syncthing folder: $FOLDER_ID..."
curl -X PATCH -H "X-API-Key: $ST_API_KEY" \
     -d '{"paused": false}' \
     "$ST_URL/rest/config/folders/$FOLDER_ID"

# --- 3. WAIT FOR SYNC TO COMPLETE ---
echo "Waiting for synchronization to finish..."
# extra sleep to ensure unpause takes effect
sleep 300

while true; do
    # Fetch folder status
    STATUS=$(curl -s -H "X-API-Key: $ST_API_KEY" "$ST_URL/rest/db/status?folder=$FOLDER_ID")
    
    # Check if 'state' is "idle" and 'needBytes' is 0
    STATE=$(echo "$STATUS" | grep -oP '"state":"\K[^"]+')
    NEED_BYTES=$(echo "$STATUS" | grep -oP '"needBytes":\K[0-9]+')
    
    if [[ "$STATE" == "idle" && "$NEED_BYTES" -eq 0 ]]; then
        echo "Sync complete!"
        break
    fi
    
    echo "Still syncing (State: $STATE, Remaining: $NEED_BYTES bytes)..."
    sleep 30
done

# --- 4. PAUSE SYNCTHING FOLDER ---
echo "Pausing Syncthing folder..."
curl -X PATCH -H "X-API-Key: $ST_API_KEY" \
     -d '{"paused": true}' \
     "$ST_URL/rest/config/folders/$FOLDER_ID"

# --- 5. START DOCKER CONTAINER ---
echo "Starting Docker container: $DOCKER_NAME..."
docker start "$DOCKER_NAME"

echo "Done."
