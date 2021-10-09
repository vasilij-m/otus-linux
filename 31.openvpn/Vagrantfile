# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 1
  end

  config.vm.define "ovpn-server" do |server|
    server.vm.network "private_network", ip: "192.168.10.10"
    server.vm.hostname = "ovpn-server"
  end

  config.vm.define "ovpn-client" do |client|
    client.vm.network "private_network", ip: "192.168.10.20"
    client.vm.hostname = "ovpn-client"
  end

  config.vm.provision "open-vpn", type:'ansible' do |ansible|
    ansible.inventory_path = './inventories/all.yml'
    ansible.playbook = './site-to-site.yml'
  end
end