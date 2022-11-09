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
          macaddress: XX:XX:XX:XX:XX:XX
          optional: true
  version: 2
  renderer: NetworkManager
EOF
RandomMAC=$(echo 00:60:2f$(hexdump -n3 -e '/1 ":%02X"' /dev/random))
sed -i "s/XX:XX:XX:XX:XX:XX/$RandomMAC/g" /etc/netplan/50-cloud-init.yaml
netplan generate
netplan --debug apply