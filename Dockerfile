FROM quay.io/almalinux/almalinux:8 AS ffmpeg-build-stage

ARG TARGETPLATFORM

COPY scripts scripts

# Update the public key
RUN rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-8

# Install base packages that are used across both the application and Vespa
RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
    dnf config-manager --set-enabled powertools

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        bash scripts/install_ffmpeg_cuda.sh; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        bash scripts/install_ffmpeg.sh; \
    else \
        echo "Unsupported platform"; \
        exit 1; \
    fi

FROM quay.io/almalinux/almalinux:8 AS almalinux8

ARG TARGETPLATFORM

# Copy the compiled FFmpeg binaries from the build stage to the runtime stage
COPY --from=ffmpeg-build-stage /usr/local/bin/ffmpeg /usr/local/bin/
COPY --from=ffmpeg-build-stage /usr/local/bin/ffprobe /usr/local/bin/
COPY --from=ffmpeg-build-stage /usr/local/lib/libavdevice* /usr/local/lib
COPY --from=ffmpeg-build-stage /usr/local/share/ffmpeg /usr/local/share/ffmpeg
COPY --from=ffmpeg-build-stage /usr/local/cuda /usr/local/cuda

COPY --from=ffmpeg-build-stage /usr/lib64/libx264* /usr/lib64

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/cuda/lib64:$LD_LIBRARY_PATH
RUN ldconfig
#
## Update the public key
#RUN rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-8
#
## Install base packages that are used across both the application and Vespa
#RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
#    dnf config-manager --set-enabled powertools
#
## Install application specific packages
#RUN dnf install -y \
#        lsof \
#        java-17-openjdk \
#        python38 \
#        python38-devel \
#        gcc \
#        jq \
#        unzip \
#        tmux
#
## Set up Python 3.8 and pip
#RUN alternatives --set python3 /usr/bin/python3.8 && \
#    curl https://bootstrap.pypa.io/get-pip.py | python3
#
## Install pip dependencies
#COPY requirements.txt requirements.txt
#RUN pip3 install --no-cache-dir -r requirements.txt
#
## Setup scripts and execute them
#COPY scripts scripts
#RUN bash scripts/install_onnx_gpu_for_amd.sh && \
#    bash scripts/install_torch_amd.sh && \
#    bash scripts/install_decord.sh && \
#    bash scripts/install_redis.sh && \
#    bash scripts/install_punkt_tokenizers.sh
#
## Install Vespa and pin the version. All versions can be found using `dns list vespa`
## This is installed as a separate docker layer since we need to upgrade vespa regularly
#RUN dnf config-manager --add-repo https://raw.githubusercontent.com/vespa-engine/vespa/master/dist/vespa-engine.repo && \
#    dnf install -y vespa-8.396.18-1.el8
#
#ADD scripts/start_vespa.sh /usr/local/bin/start_vespa.sh
#
## Set Envs for Vespa
#ENV PATH="/opt/vespa/bin:/opt/vespa-deps/bin:${PATH}"
## TODO check if following env vars are required
#ENV VESPA_LOG_STDOUT="true"
#ENV VESPA_LOG_FORMAT="vespa"
#ENV VESPA_CLI_HOME=/tmp/.vespa
#ENV VESPA_CLI_CACHE_DIR=/tmp/.cache/vespa
ENV NVIDIA_DRIVER_CAPABILITIES=all
