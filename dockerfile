# Imagem base
FROM ubuntu:24.04

# Variáveis de ambiente
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    SDKMAN_DIR=/opt/sdkman \
    PATH=/opt/sdkman/candidates/java/current/bin:$PATH

# Instala dependências essenciais e utilitários
RUN apt update -y && apt install -y \
    curl \
    lsof \
    ca-certificates \
    openssl \
    git \
    tar \
    sqlite3 \
    fontconfig \
    tzdata \
    iproute2 \
    libfreetype6 \
    tini \
    zip \
    unzip \
    bash

# Instala SDKMAN e Java fora do /home/container
RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source ${SDKMAN_DIR}/bin/sdkman-init.sh && \
             sdk install java 21.0.2-tem && \
             sdk default java 21.0.2-tem"

# Cria o usuário do container
RUN useradd -m -d /home/container -s /bin/bash container

# Seta permissões adequadas
RUN chown -R container:container /opt/sdkman

# Define variáveis de ambiente para o usuário container
ENV HOME=/home/container USER=container

# Entrypoint e sinal de parada
STOPSIGNAL SIGINT

# Copia o entrypoint
COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Muda para o usuário não-root
USER container
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
