#!/bin/bash

sudo -i
mkdir /opt/jira && cd /opt/jira
yum install wget -y
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.8.0-x64.bin
chmod a+x atlassian-jira-software-*
sudo yes "" | ./atlassian-jira-software-*
cp /vagrant/resources/jira.service /lib/systemd/system/jira.service
chmod 664 /lib/systemd/system/jira.service
systemctl daemon-reload
systemctl enable --now jira.service
