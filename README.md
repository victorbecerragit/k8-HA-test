# Lab scripts to deploy kubernetes HA on GCP using GCE.

Env:


-master0
-master1
-lb
-worker1
-worker2

#Deploy GCE VMs - Ubuntu 18.04, with starup-script, install docker & kubernetes, configure nginx load balancer. 
- k8-deploy-vms.sh

#Configure docker and kubernetes on master
- k8-setup-master.sh

#Configure docker cgroup in all nodes
- docker-daemon.sh

This lab assume that you have already a user/service account configured on GCP.
Also, this lab require enable login from gcloud CLI.

1 - Deploy the vms from google CLI desktop

$wget https://raw.githubusercontent.com/victorbecerragit/k8-HA-test/master/k8-deploy-vms.sh

bash -x k8-deploy-vms.sh

2 - Login to master0 & master1 and setup kubernet

login ssh master0
$wget https://raw.githubusercontent.com/victorbecerragit/k8-test/master/k8-setup-master.sh

bash -x k8-setup-master.sh

Login to master1 and join to kubernet the node as controlplane.
kubeadm join x.x.x.x ... --control-plane

3 - Join each worker to the cluster (valid for 24h)

To create a temporal cert run this from the master0.
$kubeadm token create --ttl 24h --print-join-command

  - Join each worker to the cluster , login as root.

-Ref:
.https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/
.https://octetz.com/posts/ha-control-plane-k8s-kubeadm

Sample env deployed:

k8-admin@k8-master0:~$ kubectl get nodes
NAME         STATUS   ROLES    AGE     VERSION
k8-master0   Ready    master   24m     v1.16.0
k8-master1   Ready    master   21m     v1.16.0
k8-worker1   Ready    <none>   8m38s   v1.16.0
k8-worker2   Ready    <none>   6m43s   v1.16.0
k8-admin@k8-master0:~$



