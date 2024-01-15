#!/bin/bash
# This script is meant to be run at buildtime.

# Add the EPEL repository which contains Redis for CentOS
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y

dnf module install redis:remi-7.2 -y