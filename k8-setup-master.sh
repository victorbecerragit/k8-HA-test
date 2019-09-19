#!/bin/bash

set -x

### Setup the node master0 ###

mkdir /etc/kubernetes/kubeadm
touch /etc/kubernetes/kubeadm/kubeadm-config.yaml
lb_ip=`gcloud compute instances list --project kube-project-223720 --filter="name~^k8-lb" --format='value(INTERNAL_IP)'`

sh -c'cat > /etc/kubernetes/kubeadm/kubeadm-config.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: stable
# REPLACE with `loadbalancer` IP
controlPlaneEndpoint: "${lb_ip}:6443"
networking:
  podSubnet: xx.xx.0.0/18
EOF'

sudo kubeadm init \
    --config=/etc/kubernetes/kubeadm/kubeadm-config.yaml \
    --upload-certs

if [[ $? -eq 0 ]]then;
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

#Deploy the CNI-plugin network. 
#The pods network is used for communication between nodes 
sudo su k8-admin sh -c 'kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml'

#Wait 1 minute to check pods creation.
sleep 60

#Validate status of default pods created for kubernetes
echo "Pods created by kubernetes: \n"
sudo su k8-admin sh -c 'kubectl get pod -n kube-system'

fi
## login to master1 and join the node as controlplane.
#sample:
#kubeadm join 10.128.0.47:6443 --token q3lxwn.ix42lzrlu5czujzc \
#    --discovery-token-ca-cert-hash sha256:47645a7c4930575bed1c2af9339dfe1e2f70bbb70b2e6fb494111e60cdd60d22 \
#        --control-plane --certificate-key ddf116a6a59ad57a329a9d42f90c878cf0d1cec508048f0f769a495bc2424477
