#! /bin/bash
echo "Welcome to TGW Attachment Routing Demo" > /var/www/html/demo.txt
sudo apt update
sudo apt -y upgrade
sudo apt -y install sysstat
sudo apt -y install net-tools
sudo apt -y install iperf3
sudo apt -y install apache2
sudo ufw allow 'Apache'
sudo systemctl start apache2
