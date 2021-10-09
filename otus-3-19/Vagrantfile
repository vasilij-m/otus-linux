# -*- mode: ruby -*-
# vim: set ft=ruby :
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :inetRouter => {
        :box_name => "centos/7",
        #:public => {:ip => '10.10.10.1', :adapter => 1},
        :net => [
                   {ip: '10.1.1.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                ]
  },
  :centralRouter => {
        :box_name => "centos/7",
        :net => [
                   {ip: '10.1.1.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
                   {ip: '10.2.2.1', adapter: 4, netmask: "255.255.255.252", virtualbox__intnet: "router-net1"},
                   {ip: '10.3.3.1', adapter: 6, netmask: "255.255.255.252", virtualbox__intnet: "router-net2"},
                   {ip: '192.168.0.1', adapter: 3, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
                   {ip: '192.168.0.33', adapter: 5, netmask: "255.255.255.240", virtualbox__intnet: "hw-net"},
                   {ip: '192.168.0.65', adapter: 7, netmask: "255.255.255.192", virtualbox__intnet: "wifi-net"},
                ]
  },
  :office1Router => {
        :box_name => "centos/7",
        :net => [
                   {ip: '10.2.2.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net1"},
                   {ip: '192.168.2.129', adapter: 3, netmask: "255.255.255.192", virtualbox__intnet: "mgmt-net1"},
                   {ip: '192.168.2.65', adapter: 4, netmask: "255.255.255.192", virtualbox__intnet: "test-net1"},
                   {ip: '192.168.2.1', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "dev-net1"},
                   {ip: '192.168.2.193', adapter: 6, netmask: "255.255.255.192", virtualbox__intnet: "hw-net1"},
                ]
  },
  :office2Router => {
        :box_name => "centos/7",
        :net => [
                   {ip: '10.3.3.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net2"},
                   {ip: '192.168.1.193', adapter: 3, netmask: "255.255.255.192", virtualbox__intnet: "hw-net2"},
                   {ip: '192.168.1.1', adapter: 4, netmask: "255.255.255.128", virtualbox__intnet: "dev-net2"},
                   {ip: '192.168.1.129', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "test-net2"},
                ]
  },  
  :centralServer => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.0.40', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "hw-net"},
                ]
  },
  :office1Server => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.2.200', adapter: 2, netmask: "255.255.255.192", virtualbox__intnet: "hw-net1"},
                ]
  },
  :office2Server => {
        :box_name => "centos/7",
        :net => [
                   {ip: '192.168.1.200', adapter: 2, netmask: "255.255.255.192", virtualbox__intnet: "hw-net2"},
                ]
  },
}

Vagrant.configure("2") do |config|
  config.vm.box_check_update = "false"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 256
    vb.cpus = 1
  end
  
  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|
        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s
        
        boxconfig[:net].each do |ipconf|
          box.vm.network "private_network", ipconf
        end
        
      #  if boxconfig.key?(:public)
      #    box.vm.network "public_network", boxconfig[:public]
      #  end

        box.vm.provision "shell", inline: <<-SHELL
          mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
        SHELL
        
        case boxname.to_s
        when "inetRouter"
          box.vm.provision "shell", inline: <<-SHELL
            cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            ip route del default
            systemctl restart network
            #iptables -t nat -A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
            cp -f /vagrant/routes/inetRouter-eth1 /etc/sysconfig/network-scripts/route-eth1
            systemctl restart network
            SHELL
        when "centralRouter"
          box.vm.provision "shell", inline: <<-SHELL
            cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            ip route del default
            systemctl restart network
            echo "GATEWAY=10.1.1.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            cp -f /vagrant/routes/centralRouter-eth3 /etc/sysconfig/network-scripts/route-eth3
            cp -f /vagrant/routes/centralRouter-eth5 /etc/sysconfig/network-scripts/route-eth5
            systemctl restart network
            SHELL
        when "office1Router"
          box.vm.provision "shell", inline: <<-SHELL
            cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            ip route del default
            systemctl restart network
            echo "GATEWAY=10.2.2.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            SHELL
        when "office2Router"
          box.vm.provision "shell", inline: <<-SHELL
            cp -f /vagrant/routes/ip_forwarding.conf /etc/sysctl.d/ip_forwarding.conf
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            ip route del default
            systemctl restart network
            echo "GATEWAY=10.3.3.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            SHELL
  
        when "centralServer"
          box.vm.provision "shell", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            ip route del default
            systemctl restart network
            echo "GATEWAY=192.168.0.33" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            SHELL
        when "office1Server"
          box.vm.provision "shell", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
            ip route del default
            systemctl restart network
            echo "GATEWAY=192.168.2.193" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            SHELL
        when "office2Server"
          box.vm.provision "shell", inline: <<-SHELL
            echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
            ip route del default
            systemctl restart network
            echo "GATEWAY=192.168.1.193" >> /etc/sysconfig/network-scripts/ifcfg-eth1
            systemctl restart network
            SHELL
        end
      end
  end
end