# Install Google's Stackdriver logging agent, as per
# https://cloud.google.com/logging/docs/agent/installation
#
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
bash install-logging-agent.sh

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

