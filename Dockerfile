FROM quay.io/centos/centos:stream8 AS build

ARG TARGETPLATFORM="linux/amd64"
ARG ROOTFS_INSTALL_DIR=/tmp_install

# Add vespa user before installing the Vespa RPMs to get a fixed UID/GID
RUN groupadd -g 1000 vespa && \
    useradd -u 1000 -g vespa -d /opt/vespa -s /sbin/nologin vespa && \
    mkdir -p $ROOTFS_INSTALL_DIR/etc && \
    cp -a /etc/passwd /etc/group /etc/shadow $ROOTFS_INSTALL_DIR/etc

# Install base packages that are used across both the application and Vespa
RUN dnf install -y epel-release dnf-utils ca-certificates curl gnupg && \
    dnf config-manager --set-enabled powertools && \
    dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo

# Install application specific packages
RUN dnf groupinstall "Development Tools" -y && \
    dnf install -y \
        lsof \
        redhat-lsb-core \
        jq \
        python38 \
        python38-pip \
        python38-devel \
        ffmpeg \
        libSM \
        libXext \
        unzip

# Set up Python 3.8 and pip
RUN alternatives --set python3 /usr/bin/python3.8 && \
    curl https://bootstrap.pypa.io/get-pip.py | python3

# Punkt Tokenizer setup
RUN mkdir -p /root/nltk_data/tokenizers && \
    curl https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/tokenizers/punkt.zip -o /root/nltk_data/tokenizers/punkt.zip && \
    unzip /root/nltk_data/tokenizers/punkt.zip -d /root/nltk_data/tokenizers/ && \
    echo Target platform is "$TARGETPLATFORM"

# Install pip dependencies
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

# Setup scripts and execute them
COPY scripts scripts
RUN bash scripts/install_onnx_gpu_for_amd.sh && \
    bash scripts/install_torch_amd.sh && \
    bash scripts/install_redis_centos.sh && \
    mkdir -p /etc/redis && \
    touch /etc/redis/redis.conf && \
    echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local && \
    echo "save ''" >> /etc/redis/redis.conf

# Vespa installation
RUN dnf --assumeyes install dnf-plugins-core && \
    dnf config-manager --add-repo https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/repo/centos-stream-8/group_vespa-vespa-centos-stream-8.repo && \
    dnf --installroot=$ROOTFS_INSTALL_DIR --releasever=8 --setopt=tsflags=nodocs --setopt=install_weak_deps=0 --assumeyes install bind-utils iputils net-tools vespa

# Reset and configure
RUN mkdir -p $ROOTFS_INSTALL_DIR/run/lock && \
    chroot $ROOTFS_INSTALL_DIR truncate --size 0 /etc/machine-id && \
    echo 'LANG=C.utf8' > $ROOTFS_INSTALL_DIR/etc/locale.conf

# Setup Vespa
COPY --from=build /tmp_install /
ADD scripts/start_vespa.sh /opt/vespa/bin/start_vespa.sh

ENV PATH="/opt/vespa/bin:/opt/vespa-deps/bin:${PATH}" \
    VESPA_HOME="/opt/vespa" \
    VESPA_LOG_STDOUT="true" \
    VESPA_LOG_FORMAT="vespa"

USER vespa
