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

#Create Node Master
echo " Create VM Master0 \n"
gcloud compute --project=$project_ID instances create k8-master0 --labels env=kube --custom-extensions --custom-cpu 2 --custom-memory 6  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-central1-a

#Remove external IP
#gcloud compute instances delete-access-config https://www.googleapis.com/compute/v1/projects/$project_ID/zones/us-central1-a/instances/k8-master \
#--access-config-name "external-nat"

#Add tag
gcloud compute instances add-tags https://www.googleapis.com/compute/v1/projects/${project_ID}/zones/us-central1-a/instances/k8-master0  --tags prod,web

#Create Control Plane node
echo " Create VM Master1 \n"
gcloud compute --project=$project_ID instances create k8-master1 --labels env=kube --custom-extensions --custom-cpu 2 --custom-memory 6  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-west1-a

#Remove external IP
#gcloud compute instances delete-access-config https://www.googleapis.com/compute/v1/projects/$project_ID/zones/us-west1-a/instances/k8-controlplane1 \
#--access-config-name "external-nat"

#Add tag
gcloud compute instances add-tags https://www.googleapis.com/compute/v1/projects/${project_ID}/zones/us-west1-a/instances/k8-master1  --tags prod,web

#Create VM LoadBalancer
echo " Create Node LB \n"
gcloud compute --project=$project_ID instances create k8-lb --labels env=kube --machine-type f1-micro  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_lb.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-central1-a

#Add tag
gcloud compute instances add-tags https://www.googleapis.com/compute/v1/projects/${project_ID}/zones/us-central1-a/instances/k8-lb  --tags prod,web

#Create VM Worker1
echo " Create Node Worker1 \n"
gcloud compute --project=$project_ID instances create k8-worker1 --labels env=kube --custom-extensions --custom-cpu 1 --custom-memory 4  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-central1-b

#Remove external IP
#gcloud compute instances delete-access-config https://www.googleapis.com/compute/v1/projects/$project_ID/zones/us-central1-b/instances/k8-worker1 \
#--access-config-name "external-nat"

#Add tag
gcloud compute instances add-tags https://www.googleapis.com/compute/v1/projects/${project_ID}/zones/us-central1-b/instances/k8-worker1  --tags prod,web

#Create Node Worker2
echo " Create VM Worker2 \n"
gcloud compute --project=$project_ID instances create k8-worker2 --labels env=kube --custom-extensions --custom-cpu 1 --custom-memory 4  \
--scopes https://www.googleapis.com/auth/devstorage.full_control,https://www.googleapis.com/auth/compute \
--metadata SELF_DESTRUCT_INTERVAL_MINUTES=$delete_vm \
--metadata-from-file startup-script=startup_script.sh \
--image-family ubuntu-minimal-1804-lts  --image-project ubuntu-os-cloud --subnet default --zone us-west1-c

#Remove external IP
#gcloud compute instances delete-access-config https://www.googleapis.com/compute/v1/projects/$project_ID/zones/us-west1-c/instances/k8-worker2 \
#--access-config-name "external-nat"

#Add tag
gcloud compute instances add-tags https://www.googleapis.com/compute/v1/projects/${project_ID}/zones/us-west1-c/instances/k8-worker2  --tags prod,web

#Enable port 80 for http in "default" network, replace project for "your_project_name".
gcloud compute --project=$project_ID firewall-rules create nginx-allow-https --direction=INGRESS \
--network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0

#List VMs created.
gcloud compute instances list --project $project_ID
