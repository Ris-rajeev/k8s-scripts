#!/bin/bash

echo "<------------------------------------------>"
echo "<--------------Master Node----------------->"
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

sudo hostnamectl set-hostname k8s-master
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

# Apply sysctl params without reboot
sudo sysctl --system

sudo kubeadm init --control-plane-endpoint=$IPADDR --apiserver-cert-extra-sans=$IPADDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME
# kubeadm init --apiserver-advertise-address=$IPADDR --pod-network-cidr=$POD_CIDR

# Use the following commands from the output to create the kubeconfig in master so that you can use kubectl to interact with cluster API.

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Now, verify the kubeconfig by executing the following kubectl command to list all the pods in the kube-system namespace.

kubectl get po -n kube-system

# You verify all the cluster component health statuses using the following command.

kubectl get --raw='/readyz?verbose'

# You can get the cluster info using the following command.

kubectl cluster-info 

# By default, apps won’t get scheduled on the master node. If you want to use the master node for scheduling apps, taint the master node.

# kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Execute the following commands to install the Calico network plugin operator on the cluster.

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O

kubectl create -f custom-resources.yaml

#// Join Worker Nodes To Kubernetes Master Node

sudo kubeadm token create --print-join-command > kubeadm_join.sh

# Define the file path and content
sudo mkdir /home/rajeev/proxy-script
FILE="/home/rajeev/proxy-script/kubectl-proxy.sh"
CONTENT="#!/bin/bash

# Check if kubectl proxy is already running
if ! pgrep -f 'kubectl proxy' >/dev/null; then
  echo 'kubectl proxy is not running. Starting...'
  # Start kubectl proxy in the background
  kubectl proxy --address='0.0.0.0' --port=8001 --accept-hosts='^*$' & >/dev/null 2>&1 &
else
  echo 'kubectl proxy is already running.'
fi"

# Create the file with the provided content
sudo echo "$CONTENT" > "$FILE"

# Set execution permissions for the script file
sudo chmod +x "$FILE"

# Execute the script once
sudo bash "$FILE"



#// Setup Kubernetes Metrics Server

# To install the metrics server, execute the following metric server manifest file. It deploys metrics server version v0.6.2

kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml

echo "finish install master"
