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

# Seleção do Java com base na versão do Minecraft
echo "Selecionando Java para versão ${MINECRAFT_VERSION}"
case ${MINECRAFT_VERSION} in
    1.8*|1.9*|1.10*|1.11*)
        sdk use java 8.0.382-tem
        ;;
    1.12*|1.13*|1.14*|1.15*|1.16.0|1.16.1|1.16.2|1.16.3|1.16.4)
        sdk use java 11.0.20-tem
        ;;
    1.16.5)
        sdk use java 16.0.2-tem
        ;;
    1.17.1|1.18*|1.19*|1.20*|1.21*)
        sdk use java 21.0.2-tem
        ;;
    *)
        sdk use java 21.0.2-tem
        ;;
esac

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

# Instala o servidor PaperMC
PROJECT=paper

# Baixar a versão do Minecraft e a versão do Paper
echo -e "Baixando servidor PaperMC para a versão ${MINECRAFT_VERSION}"

if [ -n "${DL_PATH}" ]; then
    DOWNLOAD_URL=$(eval echo $(echo ${DL_PATH} | sed -e 's/{{/${/g' -e 's/}}/}/g'))
else
    VER_EXISTS=$(curl -s https://api.papermc.io/v2/projects/${PROJECT} | jq -r --arg VERSION $MINECRAFT_VERSION '.versions[] | contains($VERSION)' | grep -m1 true)
    LATEST_VERSION=$(curl -s https://api.papermc.io/v2/projects/${PROJECT} | jq -r '.versions' | jq -r '.[-1]')

    if [ "${VER_EXISTS}" == "true" ]; then
        echo -e "Version is valid. Using version ${MINECRAFT_VERSION}"
    else
        echo -e "Specified version not found. Defaulting to the latest ${PROJECT} version"
        MINECRAFT_VERSION=${LATEST_VERSION}
    fi

    BUILD_EXISTS=$(curl -s https://api.papermc.io/v2/projects/${PROJECT}/versions/${MINECRAFT_VERSION} | jq -r --arg BUILD ${BUILD_NUMBER} '.builds[] | tostring | contains($BUILD)' | grep -m1 true)
    LATEST_BUILD=$(curl -s https://api.papermc.io/v2/projects/${PROJECT}/versions/${MINECRAFT_VERSION} | jq -r '.builds' | jq -r '.[-1]')

    if [ "${BUILD_EXISTS}" == "true" ]; then
        echo -e "Build is valid for version ${MINECRAFT_VERSION}. Using build ${BUILD_NUMBER}"
    else
        echo -e "Using the latest ${PROJECT} build for version ${MINECRAFT_VERSION}"
        BUILD_NUMBER=${LATEST_BUILD}
    fi

    JAR_NAME=${PROJECT}-${MINECRAFT_VERSION}-${BUILD_NUMBER}.jar
    DOWNLOAD_URL=https://api.papermc.io/v2/projects/${PROJECT}/versions/${MINECRAFT_VERSION}/builds/${BUILD_NUMBER}/downloads/${JAR_NAME}
fi

# Baixar o arquivo JAR do servidor
echo -e "Baixando o arquivo JAR do servidor PaperMC"

if [ -f ${SERVER_JARFILE} ]; then
    mv ${SERVER_JARFILE} ${SERVER_JARFILE}.old
fi

curl -o ${SERVER_JARFILE} ${DOWNLOAD_URL}

# Baixar o arquivo server.properties se não existir
if [ ! -f server.properties ]; then
    echo -e "Baixando o arquivo server.properties"
    curl -o server.properties https://raw.githubusercontent.com/parkervcp/eggs/master/minecraft/java/server.properties
fi

# Aceitar a EULA automaticamente
echo -e "eula=true" > eula.txt
echo -e "EULA aceita automaticamente."

# Definir o valor do online-mode no server.properties
if grep -q "^online-mode=" server.properties; then
    sed -i "s/^online-mode=.*/online-mode=${ONLINE_MODE}/" server.properties
else
    echo "online-mode=${ONLINE_MODE}" >> server.properties
fi

echo -e "Definido online-mode como ${ONLINE_MODE} no server.properties."
