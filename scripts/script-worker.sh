#!/bin/sh

# Set the desired network configuration values (change the ip addresses to match your network)
ipv4_address="172.20.9.150/23"
gateway="172.20.8.1"
dns="172.20.9.10"
search_domain="<your domain>"
connection_name="Wired Connection 1"

# Edit the NetworkManager connection using nmcli
sudo nmcli connection edit "$connection_name" << EOF
set ipv4.addresses "$ipv4_address"
set ipv4.gateway "$gateway"
set ipv4.dns "$dns"
set ipv4.dns-search "$search_domain"
save
quit
EOF

# Restart the NetworkManager service
sudo systemctl restart NetworkManager

# Check the ip address
ip a

# Execute the installation command
sudo coreos-installer install /dev/sda -I http://172.20.9.153:8080/okd/worker.ign -u http://172.20.9.153:8080/okd/fcos --insecure --insecure-ignition --copy-network