#!/bin/bash

# Download and install SRPM NGINX
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm
# Download and unzip openssl
wget https://www.openssl.org/source/latest.tar.gz && tar -xvf latest.tar.gz
# Install dependencies
sudo yum-builddep -y /root/rpmbuild/SPECS/nginx.spec
# Replace SPEC file
sudo cp -f /vagrant/resources/nginx.spec /root/rpmbuild/SPECS/nginx.spec
# Build RPM
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
# Install our custom NGINX and enable it
sudo yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm
sudo systemctl enable --now nginx
# Create dir for our repo
sudo mkdir /usr/share/nginx/html/repo
# Copy rpm to repo dir
sudo cp /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm /usr/share/nginx/html/repo/
# Download rpm Percona-Server for our repository
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O \
/usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
# Initiate our repo
sudo createrepo /usr/share/nginx/html/repo/
# Replace default NGINX config
sudo cp -f /vagrant/resources/default.conf /etc/nginx/conf.d/default.conf
# Check and reload config
sudo nginx -t && sudo nginx -s reload
# Create .repo file for our repository
sudo cp -f /vagrant/resources/otus.repo /etc/yum.repos.d/otus.repo

