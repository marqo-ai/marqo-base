ARG CUDA_VERSION=11.4.3
FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-runtime-ubuntu20.04 as cuda_image
FROM ubuntu:20.04
# this is required for onnx to find cuda. If Onnx becomes unsupported this step may 
#  be removed
COPY --from=cuda_image /usr/local/cuda/ /usr/local/cuda/

# The TARGETPLATFORM var contains what CPU architecture the image is being built for.
# It needs to be specified after the FROM statement
ARG TARGETPLATFORM

RUN set -x && \
    apt-get update && \
    apt-get install wget -y && \
    apt-get update && \
    apt-get install ca-certificates curl  gnupg lsof lsb-release jq -y && \
    apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y && \
    apt-get update && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install python3.8-distutils -y && \
    # pip is 276 MB!
    apt-get  install python3.8 python3-pip -y && \
    # opencv requirements
    apt-get install ffmpeg libsm6 libxext6 -y && \
    # Punkt Tokenizer
    apt-get install unzip -y  && \
    mkdir -p /root/nltk_data/tokenizers  && \
    curl https://raw.githubusercontent.com/nltk/nltk_data/gh-pages/packages/tokenizers/punkt.zip -o /root/nltk_data/tokenizers/punkt.zip && \
    unzip /root/nltk_data/tokenizers/punkt.zip  -d /root/nltk_data/tokenizers/ && \
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
