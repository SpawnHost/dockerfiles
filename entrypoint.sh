#!/bin/bash

# Default the TZ environment variable to UTC.
TZ=${TZ:-UTC}
export TZ

# SDKMAN fora do /home/container
export SDKMAN_DIR="/opt/sdkman"
source "$SDKMAN_DIR/bin/sdkman-init.sh"

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Print Java version
printf "\033[1m\033[33mcontainer@pelican~ \033[0mjava -version\n"
echo "$JAVA_HOME"
java -version

# Substituição de variáveis do Pterodactyl
PARSED=$(echo "$STARTUP" | sed -e 's/{{/${/g' -e 's/}}/}/g')

# Exibe e executa o comando
printf "\033[1m\033[33mcontainer@pelican~ \033[0m"
echo "$PARSED"
# shellcheck disable=SC2086
eval "$PARSED"
