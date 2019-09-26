#!/bin/bash

# This script assume that you have already setup Google CLI "gcloud init" with a project and user authenticated.
# Set debug level for better troubleshooting.
# GCE startup script output shows up in "/var/log/syslog" .
set -x

#Setup project
project_ID=`gcloud projects list --filter="name~'^kube-project-*'" --format='value(projectId)'`

#Self destruct time
delete_vm=1440

#Startup_script that will be executed on each VM during the first boot.
#Install required packages in all VMs, included docker and kubernetes
cat > startup_script.sh <<EOF
# Install Google's Stackdriver logging agent, as per
# https://cloud.google.com/logging/docs/agent/installation
#
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh
sudo bash install-monitoring-agent.sh

# Make sure installed packages are up to date with all security patches.
sudo apt-get -y update  && sudo apt-get -y upgrade

#Install tools packages like apt-add-repository, apt-transport-https , bash-completion
sudo apt-get -y install software-properties-common ca-certificates curl apt-transport-https bash-completion gnupg2

#Download and add the apt-key from google repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Add to the local repository the kubernetes-bionic & kubernetes-xenial
#sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-bionic main"
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" 
sudo apt-add-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

## Install Docker CE.
apt-get update && apt-get install docker-ce=18.06.2~ce~3-0~ubuntu
sudo apt-get -y install docker-ce
sudo systemctl enable docker

#Install kubeadm & kubelet
sudo apt-get -y install kubeadm kubelet kubernetes-cni --allow-unauthenticated

#Disable swap as is not supported on kubernetes
sudo swapoff -a

# Setup docker daemon to use systemd as Cgroup, as default docker use cgroupfs and kubernetes instead recommend to use systemd.
sudo wget https://raw.githubusercontent.com/victorbecerragit/k8-test/master/docker-daemon.sh -O - | bash -x

# self-destruts VM after 24h
# https://github.com/davidstanke/samples/tree/master/self-destructing-vm
sudo wget https://raw.githubusercontent.com/victorbecerragit/k8-test/master/self-destruct.sh -O - | bash -x

#Create ssh key for default user 
sh -c 'echo -e "\n"|ssh-keygen -t rsa -N ""'

EOF

#Check your current configuration of gcloud.
gcloud config list

#Project to use
echo "Default project : $project_ID \n"

#Create Nodes controller
nodes=3

for ((i=0; i<3; i++)); do
echo " Create VM controller-$i \n"
gcloud compute --project=$project_ID instances create k8-controller$i --labels env=kube --custom-extensions --custom-cpu 2 --custom-memory 6  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-central1-a

node=$(gcloud compute instances list --uri --filter="name~'^k8-.*'" |grep controller$i)
#Add tag
gcloud compute instances add-tags $node --tags prod,web
done

#Create VM LoadBalancer
echo " Create Node LB \n"
gcloud compute --project=$project_ID instances create k8-lb --labels env=kube --machine-type f1-micro  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_lb.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-west1-b

lb=$(gcloud compute instances list --uri --filter="name~'^k8-.*'" |grep lb)
#Add tag
gcloud compute instances add-tags $lb --tags prod,web

node=2
#Create VM workers

for ((i=1; i<3; i++)); do
echo " Create Node Worker-$i \n"
gcloud compute --project=$project_ID instances create k8-worker$i --labels env=kube --custom-extensions \
--custom-cpu 1 --custom-memory 4 \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-west2-b

wk=$(gcloud compute instances list --uri --filter="name~'^k8-.*'" |grep worker$i)
#Add tag
gcloud compute instances add-tags $wk --tags prod,web
done

#Enable port 80 for http in "default" network, replace project for "your_project_name".
gcloud compute --project=$project_ID firewall-rules create nginx-allow-https --direction=INGRESS \
--network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0

#List VMs created.
gcloud compute instances list --project $project_ID
