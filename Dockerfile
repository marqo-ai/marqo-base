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
        python38 \
        python38-devel \
        gcc \
        jq \
        wget \
        unzip \
        git \
        tmux

## Set up Python 3.8 and pip
#RUN alternatives --set python3 /usr/bin/python3.8 && \
#    curl https://bootstrap.pypa.io/get-pip.py | python3
#
## Install pip dependencies
#COPY requirements.txt requirements.txt
#RUN pip3 install --no-cache-dir -r requirements.txt

# Install ffmpeg

# Step 1: Install cuda toolkit
RUN dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

RUN dnf clean all && \
    dnf -y install cuda-toolkit-12-6

ENV PATH=/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

## Step 2: Install nv-codec-headers
#RUN git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git && \
#    cd nv-codec-headers && \
#    sudo make install && \
#    cd ..

# Finish ffmpeg installatio
