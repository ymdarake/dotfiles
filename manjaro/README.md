# Manjaro Setup Guide

```sh

sudo pacman -S docker
sudo pacman -S docker-compose

sudo usermod -aG docker `whoami`
tail /etc/group
# sudo systemctl start docker.service
sudo systemctl enable docker.service

```
