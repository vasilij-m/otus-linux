# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.box_version = "1905.1"
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |v|
    v.memory = 256
    v.cpus = 1
  end

  config.vm.define "inetRouter" do |inetRouter|
    inetRouter.vm.network "private_network", ip: "", virtualbox__intnet: "router-net"
    inetRouter.vm.network "private_network", ip: "", virtualbox__intnet: "router-net"
    #management network
    inetRouter.vm.network "private_network", ip: "10.11.11.11"
    inetRouter.vm.hostname = "inetRouter"
  end

  config.vm.define "centralRouter" do |centralRouter|
    centralRouter.vm.network "private_network", ip: "", virtualbox__intnet: "router-net"
    centralRouter.vm.network "private_network", ip: "", virtualbox__intnet: "router-net"
    centralRouter.vm.network "private_network", ip: "192.168.2.1", virtualbox__intnet: "test-lan"
    #management network
    centralRouter.vm.network "private_network", ip: "10.11.11.12"
    centralRouter.vm.hostname = "centralRouter"
  end

  config.vm.define "testServer1" do |testServer1|
    testServer1.vm.network "private_network", ip: "192.168.2.2", virtualbox__intnet: "test-lan"
    #management network
    testServer1.vm.network "private_network", ip: "10.11.11.111"
    testServer1.vm.hostname = "testServer1"
  end

  config.vm.define "testClient1" do |testClient1|
    testClient1.vm.network "private_network", ip: "192.168.2.3", virtualbox__intnet: "test-lan"
    #management network
    testClient1.vm.network "private_network", ip: "10.11.11.121"
    testClient1.vm.hostname = "testClient1"
  end

  config.vm.define "testServer2" do |testServer2|
    testServer2.vm.network "private_network", ip: "192.168.2.4", virtualbox__intnet: "test-lan"
    #management network
    testServer2.vm.network "private_network", ip: "10.11.11.112"
    testServer2.vm.hostname = "testServer2"
  end

  config.vm.define "testClient2" do |testClient2|
    testClient2.vm.network "private_network", ip: "192.168.2.5", virtualbox__intnet: "test-lan"
    #management network
    testClient2.vm.network "private_network", ip: "10.11.11.122"
    testClient2.vm.hostname = "testClient2"

    testClient2.vm.provision "vlan-bonding", type:'ansible' do |ansible|
      ansible.limit = 'all'
      ansible.inventory_path = './inventories/all.yml'
      ansible.playbook = './vlan-bonding.yml'
    end

  end

end