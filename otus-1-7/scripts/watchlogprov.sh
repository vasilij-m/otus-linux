#!/bin/bash

sudo -i
cp /vagrant/resources/watchlog /etc/sysconfig/watchlog
cp /vagrant/resources/watchlog.log /var/log/watchlog.log
cp /vagrant/resources/watchlog.sh /opt/watchlog.sh
chmod +x /opt/watchlog.sh
cp /vagrant/resources/watchlog.service /etc/systemd/system/watchlog.service
cp /vagrant/resources/watchlog.timer /etc/systemd/system/watchlog.timer
systemctl daemon-reload
#systemctl start watchlog.service
systemctl enable --now watchlog.timer
