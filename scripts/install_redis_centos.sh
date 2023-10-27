#!/bin/bash
# This script is meant to be run at buildtime.

# Add the EPEL repository which contains Redis for CentOS
dnf install -y epel-release

# Update packages
dnf update -y

# Install Redis
dnf install -y redis
