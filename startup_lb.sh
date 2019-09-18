#!/bin/bash

set -x

#Install nginx
apt-get install nginx -y

master0_ip=`gcloud compute instances list --project kube-project-223720 --filter="name~^k8-master0" --format='value(INTERNAL_IP)'`
master1_ip=`gcloud compute instances list --project kube-project-223720 --filter="name~^k8-master1" --format='value(INTERNAL_IP)'`

cat > config.txt << EOF
stream {
	upstream stream_backend {
		least_conn;
		#REPLACE WITH master0 IP
		server $master0_ip
		#REPLACE WITH master1 IP
		server $master1_ip
	}
	server {
		listen        6443;
		proxy_pass    stream_backend;
		proxy_timeout 3s;
		proxy_connect_timeout 1s;
	}

}
EOF

cat config.txt >> /etc/nginx/nginx.conf

systemctl stop nginx
systemctl start nginx
