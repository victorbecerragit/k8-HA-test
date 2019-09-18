#!/bin/bash

# Setup docker daemon to use systemd as Cgroup, as default docker use cgroupfs and kubernetes instead recommend to use systemd.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
     "log-opts": {
        "max-size": "100m"
     },
  "storage-driver": "overlay2"
}
EOF
#Restart docker.
sudo systemctl daemon-reload
sudo systemctl restart docker
