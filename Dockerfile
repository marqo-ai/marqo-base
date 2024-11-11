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
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Setup scripts and execute them
COPY scripts scripts
RUN bash scripts/install_redis.sh && \
    bash scripts/install_punkt_tokenizers.sh

# Install ffmpeg based on the architecture
RUN if [ "${TARGETPLATFORM}" = "linux/arm64" ]; then \
      bash /scripts/install_ffmpeg.sh; \
    elif [ "${TARGETPLATFORM}" = "linux/amd64" ]; then \
      bash /scripts/install_ffmpeg_cuda.sh; \
    else \
      echo "Unsupported platform: ${TARGETARCH}" && exit 1; \
    fi

# Install Vespa and pin the version. All versions can be found using `dns list vespa`
# This is installed as a separate docker layer since we need to upgrade vespa regularly
RUN dnf config-manager --add-repo https://raw.githubusercontent.com/vespa-engine/vespa/master/dist/vespa-engine.repo && \
    dnf install -y vespa-8.431.32-1.el8

ADD scripts/start_vespa.sh /usr/local/bin/start_vespa.sh

# Set Envs for Vespa
ENV PATH="/opt/vespa/bin:/opt/vespa-deps/bin:${PATH}"
# TODO check if following env vars are required
ENV VESPA_LOG_STDOUT="true"
ENV VESPA_LOG_FORMAT="vespa"
ENV VESPA_CLI_HOME=/tmp/.vespa
ENV VESPA_CLI_CACHE_DIR=/tmp/.cache/vespa
ENV NVIDIA_DRIVER_CAPABILITIES=utility,compute,video
# expose nltk data to all users
ENV NLTK_DATA=/root/nltk_data