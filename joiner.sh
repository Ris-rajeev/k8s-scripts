#!/bin/bash

# Step 1: Fetch the private IP of the master node from the file saved during provisioning
MASTER_PRIVATE_IP=$(cat /home/$USER/master_private_ip.txt)  # Assuming the IP is saved in master_private_ip.txt
echo $MASTER_PRIVATE_IP

chmod 400 /home/$USER/k8s-key-pair.pem

# Step 2: SSH into the master node and copy kubeadm_join.sh to the worker
scp -i /home/$USER/k8s-key-pair.pem -o StrictHostKeyChecking=no  $USER@$MASTER_PRIVATE_IP:/home/$USER/kubeadm_join.sh kubeadm_join.sh

# Step 3: Modify the fetched kubeadm_join.sh script to include sudo before the join command
sed -i 's/^/sudo /' kubeadm_join.sh

# Display the content of kubeadm_join.sh after modification
cat kubeadm_join.sh
chmod u+x ./kubeadm_join.sh
sudo ./kubeadm_join.sh


