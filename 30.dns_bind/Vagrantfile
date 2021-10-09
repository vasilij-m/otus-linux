# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |v|
	  v.memory = 256
  end

  config.vm.define "ns01" do |ns01|
    ns01.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "dns"
    #management network
    ns01.vm.network "private_network", ip: "10.10.10.11"
    ns01.vm.hostname = "ns01"
  end

  config.vm.define "ns02" do |ns02|
    ns02.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "dns"
    #management network
    ns02.vm.network "private_network", ip: "10.10.10.12"
    ns02.vm.hostname = "ns02"
  end

  config.vm.define "client1" do |client1|
    client1.vm.network "private_network", ip: "192.168.50.15", virtualbox__intnet: "dns"
    #management network
    client1.vm.network "private_network", ip: "10.10.10.21"
    client1.vm.hostname = "client1"
  end

  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    #management network
    client2.vm.network "private_network", ip: "10.10.10.22"
    client2.vm.hostname = "client2"
  end

  config.vm.provision "dns-bind", type:'ansible' do |ansible|
    ansible.inventory_path = './inventories/all.yml'
    ansible.playbook = "./dns-bind.yml"
  end
end