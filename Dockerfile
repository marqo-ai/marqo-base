FROM quay.io/almalinux/almalinux:8 AS build-stage

ARG TARGETPLATFORM

# Update the public key
RUN rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-8

# Install base packages that are used across both the application and Vespa
RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
    dnf config-manager --set-enabled powertools

# Install dependencies for CUDA and FFmpeg compilation
RUN dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo && \
    dnf clean all && \
    dnf -y install cuda-toolkit-12-6 libtool glibc glibc-devel numactl numactl-devel openssl yasm pkg-config \
    openssl-devel git gcc make gcc-c++ kernel-headers automake

RUN dnf install -y https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm && \
    dnf install -y x264 x264-devel

RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    git checkout 9934f17316b66ce6de12f3b82203a298bc9351d8 && \
    make && \
    make install

# Set PKG_CONFIG_PATH for pkg-config to find the newly installed nv-codec-headers
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Clone FFmpeg repository and fix the version
RUN git clone https://git.ffmpeg.org/ffmpeg.git && \
    cd ffmpeg && \
    git checkout faa366003b58ba26484070ca408be4b9d5473a73 && \
    ./configure --enable-nonfree \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --enable-libx264 \
    --enable-openssl \
    --enable-nvenc \
    --enable-gpl \
    --extra-cflags=-I/usr/local/cuda/include \
    --extra-ldflags=-L/usr/local/cuda/lib64 \
    --disable-static \
    --enable-shared && \
    make -j $(nproc) && \
    make install

FROM quay.io/almalinux/almalinux:8 AS almalinux8

ARG TARGETPLATFORM

# Copy the compiled FFmpeg binaries from the build stage to the runtime stage
COPY --from=build-stage /usr/local/bin/ffmpeg /usr/local/bin/
COPY --from=build-stage /usr/local/bin/ffprobe /usr/local/bin/
COPY --from=build-stage /usr/local/lib /usr/local/lib
COPY --from=build-stage /usr/local/share/ffmpeg /usr/local/share/ffmpeg

# Set the library path for runtime dependencies
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Update the public key
RUN rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux-8

# Install base packages that are used across both the application and Vespa
RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
    dnf config-manager --set-enabled powertools

# Install application specific packages
RUN dnf install -y \
        lsof \
        java-17-openjdk \
        python38 \
        python38-devel \
        gcc \
        jq \
        unzip \
        tmux

# Set up Python 3.8 and pip
RUN alternatives --set python3 /usr/bin/python3.8 && \
    curl https://bootstrap.pypa.io/get-pip.py | python3

# Install pip dependencies
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Setup scripts and execute them
COPY scripts scripts
RUN bash scripts/install_onnx_gpu_for_amd.sh && \
    bash scripts/install_torch_amd.sh && \
    bash scripts/install_decord.sh && \
    bash scripts/install_redis.sh && \
    bash scripts/install_punkt_tokenizers.sh

# Install Vespa and pin the version. All versions can be found using `dns list vespa`
# This is installed as a separate docker layer since we need to upgrade vespa regularly
RUN dnf config-manager --add-repo https://raw.githubusercontent.com/vespa-engine/vespa/master/dist/vespa-engine.repo && \
    dnf install -y vespa-8.396.18-1.el8

ADD scripts/start_vespa.sh /usr/local/bin/start_vespa.sh

# Set Envs for Vespa
ENV PATH="/opt/vespa/bin:/opt/vespa-deps/bin:${PATH}"
# TODO check if following env vars are required
ENV VESPA_LOG_STDOUT="true"
ENV VESPA_LOG_FORMAT="vespa"
ENV VESPA_CLI_HOME=/tmp/.vespa
ENV VESPA_CLI_CACHE_DIR=/tmp/.cache/vespa
ENV NVIDIA_DRIVER_CAPABILITIES=utility,compute,video
