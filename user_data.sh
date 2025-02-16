#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install apache2 -y
sudo systemctl restart apache2
sudo cp index.html /var/www/html/index.html
sudo systemctl install docker.io -y
