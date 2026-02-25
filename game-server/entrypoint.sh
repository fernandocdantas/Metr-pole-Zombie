#!/bin/bash
# Custom entrypoint wrapper for the PZ game server.
# Runs configure-server.sh to apply .env settings, then launches SteamCMD
# with the configured beta branch, and starts the server.

# Apply server configuration from environment variables
bash /home/steam/configure-server.sh

# Determine SteamCMD beta branch
BRANCH="${PZ_STEAM_BRANCH:-public}"
if [ "$BRANCH" = "public" ]; then
  BETA_FLAG=""
else
  BETA_FLAG="-beta $BRANCH"
fi

echo "[entrypoint] Installing/updating PZ server (branch: $BRANCH)..."
FEXBash "/home/steam/Steam/steamcmd.sh +force_install_dir /home/steam/pzserver +login anonymous +app_update 380870 $BETA_FLAG validate +quit"

# Launch the server in a screen session with auto-restart loop
screen -d -m -S zomboid /bin/bash -c " \
  while true; do \
    FEXBash \"/home/steam/pzserver/start-server.sh -servername \${SERVERNAME}\"; \
    echo 'The server will restart in 10 seconds. If you want to stop the server, press Ctrl+C.'; \
    for i in 10 9 8 7 6 5 4 3 2 1; do echo \"\$i...\"; sleep 1; done \
  done \
"
sleep infinity
