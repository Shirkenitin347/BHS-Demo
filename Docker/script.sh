#! /bin/bash

sudo apt-get remove docker docker-engine docker.io
sudo apt-get update
sudo apt install docker.io -y
sudo snap install docker
sudo systemctl start docker
sudo systemctl enable docker
sudo chmod 777 /var/run/docker.sock
sudo apt-get install git
git clone https://github.com/Shirkenitin347/DevopsDemo
cd DevopsDemo/Docker
docker build -t webserver .
docker run -it --rm -d -p 80:80 --name web webserver