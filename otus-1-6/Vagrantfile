# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :bootprocess  => {
        :box_name => "centos/7",
	:box_version => "1804.02",
        :ip_addr => '192.168.11.101'
  }
}

Vagrant.configure("2") do |config|
	config.vm.box_version = "1804.02"
  	MACHINES.each do |boxname, boxconfig|
		config.vm.define boxname do |box|
		box.vm.box = boxconfig[:box_name]
		box.vm.host_name = boxname.to_s
		box.vm.network "private_network", ip: boxconfig[:ip_addr]
		box.vm.provider :virtualbox do |vb|
            		vb.customize ["modifyvm", :id, "--memory", "1024", "--cpus", "2"]
          	end
	  	box.vm.synced_folder ".", "/vagrant"
          	box.vm.provision "shell", inline: <<-SHELL
            		mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            		sudo yum install vim -y
          	SHELL
		end
	end
end

