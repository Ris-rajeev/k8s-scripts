#!/bin/bash

echo "<------------------------------------------>"
echo "<--------------Worker Node----------------->"
echo "<------------------------------------------>"

# Enable cri-o repositories for version 1.28

sudo apt-get install openssh-server 

sudo apt-get update 
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker

sudo echo '{"exec-opts": ["native.cgroupdriver=systemd"],"log-driver": "json-file","log-opts": {"max-size": "100m"},"storage-driver": "overlay2"}' | sudo tee /etc/docker/daemon.json


# Install the required dependencies.

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Download the GPG key for the Kubernetes APT repository.

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

# Add the Kubernetes APT repository to your system.

sudo echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt repo

sudo apt-get update -y

# You can use the following commands to find the latest versions.

sudo apt update
sudo apt-cache madison kubeadm | tac

# Specify the version as shown below.

sudo apt-get install -y kubelet=1.28.2-00 kubectl=1.28.2-00 kubeadm=1.28.2-00

# Or, to install the latest version from the repo use the following command without specifying any version.

sudo apt-get install -y kubelet kubeadm kubectl

# Add hold to the packages to prevent upgrades.

sudo apt-mark hold kubelet kubeadm kubectl

# Add the node IP to KUBELET_EXTRA_ARGS.

sudo hostnamectl set-hostname k8s-worker
sudo apt-get install -y jq
IPADDR=$(hostname -I | awk '{print $1}') 
  


echo $IPADDR
sudo bash -c 'echo "KUBELET_EXTRA_ARGS=--node-ip='$IPADDR'" >> /etc/default/kubelet'

#// Initialize Kubeadm On Master Node To Setup Control Plane

# Set the following environment variables. Replace 10.0.0.10 with the IP of your master node.

# echo $IPADDR
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"

# Letting Iptables See Bridged Traffic

sudo cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
sudo cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

echo "finish install worker"
