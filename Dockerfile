FROM centos:8-stream

# There is not docker image for CentOS 8 stream, ONNX may not be supported here.

# The TARGETPLATFORM var contains what CPU architecture the image is being built for.
# It needs to be specified after the FROM statement
ARG TARGETPLATFORM

RUN set -x && \
    dnf install -y epel-release dnf-plugins-core && \
    dnf config-manager --set-enabled PowerTools && \
    dnf update -y && \
    dnf groupinstall "Development Tools" -y && \
    dnf install -y \
        ca-certificates \
        curl \
        gnupg \
        lsof \
        redhat-lsb-core \
        jq \
        python38 \
        python38-pip \
        python38-devel \
        ffmpeg \
        libSM \
        libXext \
        unzip && \
    # Set up Python 3.8 and pip
    alternatives --set python3 /usr/bin/python3.8 && \
    curl https://bootstrap.pypa.io/get-pip.py | python3 && \
    # Punkt Tokenizer setup
    mkdir -p /root/nltk_data/tokenizers && \
    curl https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/tokenizers/punkt.zip -o /root/nltk_data/tokenizers/punkt.zip && \
    unzip /root/nltk_data/tokenizers/punkt.zip -d /root/nltk_data/tokenizers/ && \
    echo Target platform is "$TARGETPLATFORM"

# This pip install is quite a heavy operation, but requirements do change from time to time,
# so it has its own layer 
COPY requirements.txt requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt

COPY scripts scripts
RUN set -x && \
    bash scripts/install_onnx_gpu_for_amd.sh && \
    bash scripts/install_torch_amd.sh && \
    # redis installation for throttling
    bash scripts/install_redis.sh && \
    # redis config lines
    echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local && \
    echo "save ''" | tee -a /etc/redis/redis.conf 
