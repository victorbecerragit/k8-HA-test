#!/bin/bash

##set -xe
set -x

export API_ADDR=`hostname -i`
export DNS_DOMAIN="k8s.local"
export POD_NET="10.244.0.0/16"

#Setup the node master ip as apiserver and define the pod-network for 10.244.0.0/16.

sudo kubeadm init --apiserver-advertise-address=${API_ADDR} --pod-network-cidr=${POD_NET} --ignore-preflight-errors=all 

#Create admin user that will administer kubernetes
sudo useradd -s /bin/bash -m k8-admin
sudo usermod -aG sudo k8-admin
sudo usermod --password $(openssl passwd -1 password) k8-admin
echo "k8-admin ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/k8-admin

sudo su k8-admin sh -c'touch /home/k8-admin/k8-setup.sh'
sudo su k8-admin sh -c'cat > /home/k8-admin/k8-setup.sh <<EOF
#!/bin/bash
# As regular user 
HOME_USER="/home/k8-admin/"

echo "\n"
mkdir -p /home/k8-admin/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/k8-admin/.kube/config
sudo chown k8-admin:k8-admin /home/k8-admin/.kube/config
  
# add autocomplete permanently to user bash shell.
echo "source <(kubectl completion bash)" >> /home/k8-admin/.bashrc 

#Use "kubeadm token create" on the master node to creating a new valid token #
#Create a new token to join the worker with TTL 0 *not expire

echo " Execute this command to create a new token : [kubeadm token create --ttl 0 --print-join-command]"

EOF'

#Change permission to normal user.
sudo chown k8-admin:k8-admin /home/k8-admin/k8-setup.sh

#Run the k8-setup.sh as regular user k8-admin
sudo su k8-admin sh -c 'bash -x /home/k8-admin/k8-setup.sh'

#Deploy the flannel pod network. 
#The pod network is used for communication between nodes 
sudo su k8-admin sh -c 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml'
sudo systemctl restart kubelet

#Wait 1 minute to check pods creation.
sleep 60

#Validate status of default pods created for kubernetes
echo "Pods created by kubernetes: \n"
sudo su k8-admin sh -c 'kubectl get pod -n kube-system'
