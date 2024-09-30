#!/bin/bash
# This script is meant to be run at buildtime to install `ffmpeg`
# We need to build the ffmpeg from source to ensure the cuda can be used

# Step 1: Install CUDA toolkit to enable nvcc
wget https://developer.download.nvidia.com/compute/cuda/12.6.1/local_installers/cuda-repo-rhel9-12-6-local-12.6.1_560.35.03-1.x86_64.rpm
rpm -i cuda-repo-rhel9-12-6-local-12.6.1_560.35.03-1.x86_64.rpm
dnf clean all
dnf -y install cuda-toolkit-12-6
nvcc --version # Ensure nvcc is installed

# Step 2: Installed nv-codec-headers
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
sudo make install
cd ..

# Step 3: Install ffmpeg
git clone https://git.ffmpeg.org/ffmpeg.git && cd ./ffmpeg

