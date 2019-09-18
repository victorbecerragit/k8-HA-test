# Lab scripts to deploy kubernetes HA on GCP using GCE.

Env:
master0
master1
lb
worker1
worker2

#Deploy GCE VMs - Ubuntu 18.04, with starup-script, install docker & kubernetes, nginx. 
- k8-deploy-vms.sh

#Configure docker and kubernetes on master
- k8-setup-master.sh

#Configure docker cgroup in all nodes
- docker-daemon.sh

This lab assume that you have already a user/service account configured on GCP.
Also, this lab require enable login from gcloud CLI.

1 - Deploy the vms from google CLI desktop

$wget https://raw.githubusercontent.com/victorbecerragit/k8-test/master/k8-deploy-vms.sh

bash -x k8-deploy-vms.sh


2 - Login to master0 & master1 and setup kubernet

login ssh master
$wget https://raw.githubusercontent.com/victorbecerragit/k8-test/master/k8-setup-master.sh

bash -x k8-setup-master.sh


3 - Join each worker to the cluster (valid for 24h)
login as root :

$kubeadm token create --ttl 24h --print-join-command

  - Join each worker to the cluster , login as root:

-Ref:
.https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
.https://octetz.com/posts/ha-control-plane-k8s-kubeadm

