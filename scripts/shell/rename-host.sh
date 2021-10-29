#!/bin/bash

echo "Rename hostname to: $1"

hostname $1
echo "$1" >/etc/hostname
sed -i "s/^127\.0\.0\.1.*$/127.0.0.1 localhost $1/g" /etc/hosts
sed -i "s/^127\.0\.1\.1.*$/127.0.1.1 $1.localdomain $1/g" /etc/hosts

