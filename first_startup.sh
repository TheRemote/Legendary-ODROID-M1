#!/bin/bash

# Apply netplan configuration
echo "Applying netplan..."
rm -rf /etc/netplan/50-cloud-init.yaml	
touch /etc/netplan/50-cloud-init.yaml	
cat << EOF | tee /etc/netplan/50-cloud-init.yaml >/dev/null	
network:
  ethernets:
      eth0:
          dhcp4: true
          optional: true
  version: 2
  renderer: NetworkManager
EOF
netplan generate
netplan --debug apply