FROM quay.io/almalinux/almalinux:8 AS almalinux8

ARG TARGETPLATFORM

# Update the public key
RUN rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-8

# Install base packages that are used across both the application and Vespa
RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
    dnf config-manager --set-enabled powertools

# Install application specific packages
RUN dnf install -y \
        lsof \
        java-17-openjdk \
        python39 \
        python39-devel \
        gcc \
        jq \
        unzip \
        tmux

# Set up Python 3.9 and pip
RUN alternatives --set python3 /usr/bin/python3.9 && \
    curl https://bootstrap.pypa.io/get-pip.py | python3

# Install pip dependencies
COPY requirements requirements
# Install requirements based on the architecture
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
      pip3 install --no-cache-dir -r requirements/arm64-requirements.txt; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
      pip3 install --no-cache-dir -r requirements/amd64-gpu-requirements.txt; \
    else \
      echo "Unsupported platform: ${TARGETARCH}" && exit 1; \
    fi

# Setup scripts and execute them
COPY scripts scripts
RUN bash scripts/install_redis.sh && \
    bash scripts/install_punkt_tokenizers.sh

# Install ffmpeg based on the architecture
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
      bash /scripts/install_ffmpeg.sh; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
      bash /scripts/install_ffmpeg_cuda.sh;  \
      # Choose the java version \
      JAVA_BIN=$(ls -d /usr/lib/jvm/java-17-openjdk*/bin/java | head -n 1); \
      update-alternatives --set java "$JAVA_BIN"; \
    else \
      echo "Unsupported platform: ${TARGETARCH}" && exit 1; \
    fi

ENV NVIDIA_DRIVER_CAPABILITIES=utility,compute,video
# expose nltk data to all users
ENV NLTK_DATA=/root/nltk_data