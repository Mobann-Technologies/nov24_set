#!/bin/bash
sudo apt update && sudo apt upgrade -y
sudo apt install apache2 -y
sudo systemctl restart apache2
sudo echo "Hello World" >> /var/www/html/index.html
