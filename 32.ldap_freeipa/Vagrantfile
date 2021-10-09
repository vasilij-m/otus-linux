# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 1
  end

  config.vm.define "ipaserver" do |server|
    server.vm.network "private_network", ip: "192.168.10.10"
    server.vm.hostname = "ipaserver"
    server.vm.provider "virtualbox" do |v|
      v.memory = 3072
      v.cpus = 2
    end
  end

  config.vm.define "ws1" do |ws|
    ws.vm.network "private_network", ip: "192.168.10.11"
    ws.vm.hostname = "ws1"
  end

  config.vm.define "ws2" do |ws|
    ws.vm.network "private_network", ip: "192.168.10.12"
    ws.vm.hostname = "ws2"
  end

  config.vm.provision "ldap", type:'ansible' do |ansible|
    ansible.inventory_path = './inventories/all.yml'
    ansible.playbook = './ldap.yml'
  end
end