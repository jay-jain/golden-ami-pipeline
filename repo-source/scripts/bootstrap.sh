#!/bin/bash
sudo -i
echo "Running update....."
sudo apt-get update
echo "Installing apache2....."
sudo apt-get install -f # This seems to fix some sporadic error concerning missing apache2 dependencies
sudo apt-get install -y apache2
echo "Allowing ufw Apache profile....."
sudo ufw allow 'Apache'
echo "Turn on apache on boot..."
sudo systemctl enable apache2
echo "Setting up basic web page....."
cd /var/www/html/
echo "<html><h1>Hello World</h1></html>" > index.html