#!/bin/bash

sudo -i
yum install httpd -y
cp /vagrant/resources/httpd@.service /etc/systemd/system/httpd@.service
cp /vagrant/resources/httpd-first /etc/sysconfig/httpd-first
cp /vagrant/resources/httpd-second /etc/sysconfig/httpd-second
cp /vagrant/resources/first.conf /etc/httpd/conf/first.conf
cp /vagrant/resources/second.conf /etc/httpd/conf/second.conf
systemctl enable --now httpd@first
systemctl enable --now httpd@second
