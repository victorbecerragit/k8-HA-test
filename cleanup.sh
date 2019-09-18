#!/bin/bash

set -x

#Script to cleanup all VMs created on a specific project with a specific pattern name
#list all vms from the project with the name"k8-*"
#gcloud compute instances list --project=kube-project-223720 --filter="name~^k8" --format="value(name,zone)" 

echo "gcloud --quiet compute instances delete :\n"
gcloud compute instances list --uri --filter="name~'^k8-.*'"

#Delete all the VMS from the project with the name "k8-*"
gcloud --quiet compute instances delete $(gcloud compute instances list --uri --filter="name~'^k8-.*'")
