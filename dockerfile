FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SDKMAN_DIR="/root/.sdkman"
ENV PATH="${SDKMAN_DIR}/candidates/java/current/bin:${PATH}"

# Instala dependências
RUN apt-get update && apt-get install -y \
    curl zip unzip git bash ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Instala o SDKMAN
RUN curl -s "https://get.sdkman.io" | bash

# Instala múltiplas versões do Java
RUN bash -c "source ${SDKMAN_DIR}/bin/sdkman-init.sh && \
    sdk install java 8.0.382-tem && \
    sdk install java 11.0.20-tem && \
    sdk install java 16.0.2-tem && \
    sdk install java 17.0.8-tem && \
    sdk install java 21.0.2-tem && \
    sdk default java 21.0.2-tem"

# Garante que o sdkman esteja sempre disponível ao entrar no contêiner
RUN echo 'source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> /root/.bashrc

# Diretório de trabalho
WORKDIR /app

# Entrada padrão
CMD ["bash"]
