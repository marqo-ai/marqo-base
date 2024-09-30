#!/bin/bash
# This script is meant to be run at buildtime to install `ffmpeg`
# We need to build the ffmpeg from source to ensure the cuda can be used

# Install CUDA toolkit to enable nvcc
wget https://developer.download.nvidia.com/compute/cuda/12.6.1/local_installers/cuda-repo-rhel9-12-6-local-12.6.1_560.35.03-1.x86_64.rpm
rpm -i cuda-repo-rhel9-12-6-local-12.6.1_560.35.03-1.x86_64.rpm
dnf clean all
dnf -y install cuda-toolkit-12-6
