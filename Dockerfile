FROM quay.io/centos/centos:stream8 as stream8

ARG TARGETPLATFORM="linux/amd64"

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

ADD scripts/start_vespa.sh /usr/local/bin/start_vespa.sh

RUN groupadd -g 1000 vespa && \
    useradd -u 1000 -g vespa -d /opt/vespa -s /sbin/nologin vespa

# Install Vespa
RUN echo "install_weak_deps=False" >> /etc/dnf/dnf.conf && \
    dnf -y install \
      dnf-plugins-core \
      epel-release && \
    dnf config-manager --add-repo https://copr.fedorainfracloud.org/coprs/g/vespa/vespa/repo/epel-8/group_vespa-vespa-epel-8.repo && \
    dnf config-manager --enable powertools && \
    dnf -y install vespa && \
    dnf remove -y dnf-plugins-core && \
    dnf clean all && \
    rm -rf /var/cache/dnf \

# Set Envs for Vespa
ENV PATH="/opt/vespa/bin:/opt/vespa-deps/bin:${PATH}"
ENV VESPA_LOG_STDOUT="true"
ENV VESPA_LOG_FORMAT="vespa"
ENV VESPA_CLI_HOME=/tmp/.vespa
ENV VESPA_CLI_CACHE_DIR=/tmp/.cache/vespa

USER vespa
