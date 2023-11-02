#!/bin/bash
# This script is meant to be run at buildtime to install `ffmpeg` based on the target platform.

# Check if TARGETPLATFORM is defined
if [[ -z "$TARGETPLATFORM" ]]; then
  echo "ERROR: The TARGETPLATFORM environment variable is undefined."
  exit 2  # Exit with an error code indicating undefined TARGETPLATFORM
fi

# Check the target platform and install `ffmpeg` accordingly
if [[ "$TARGETPLATFORM" == "linux/arm64" ]]; then
  # For ARM64 platform, we use static build from https://johnvansickle.com/ffmpeg/
  wget -O ffmpeg.tar.xz https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-arm64-static.tar.xz
  mkdir -p temp/ffmpeg-static
  tar xvf ffmpeg.tar.xz --strip-components=1 -C /temp/ffmpeg-static
  mv /temp/ffmpeg-static/ffmpeg /usr/bin
  mv /temp/ffmpeg-static/ffprobe /usr/bin
  rm -r /temp/ffmpeg-static
  alternatives --set java /usr/lib/jvm/java-17-openjdk-17.0.6.0.9-0.3.ea.el8.aarch64/bin/java
elif [[ "$TARGETPLATFORM" == "linux/amd64" ]]; then
  # For AMD64 platform
  dnf config-manager --add-repo=https://negativo17.org/repos/epel-multimedia.repo
  dnf install -y ffmpeg
  alternatives --set java /usr/lib/jvm/java-17-openjdk-17.0.6.0.9-0.3.ea.el8.x86_64/bin/java
else
  # Handle unsupported platforms here, if needed
  echo "WARNING: Unsupported target platform: $TARGETPLATFORM"
fi