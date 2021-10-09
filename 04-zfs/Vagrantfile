# -*- mode: ruby -*-
# vim: set ft=ruby :
storage_directory = ENV["PWD"]
ENV["LC_ALL"] = "en_US.UTF-8"

MACHINES = {
    :zfs => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.10',
        :disks => {
            :sata1 => {
                :dfile => storage_directory + '/VirtualDisk/sata1.vdi',
                :size => 5120, # Megabytes
                :port => 1
            },
            :sata2 => {
                :dfile => storage_directory + '/VirtualDisk/sata2.vdi',
                :size => 5120,
                :port => 2
            },
            :sata3 => {
                :dfile => storage_directory + '/VirtualDisk/sata3.vdi',
                :size => 5120,
                :port => 3
            },
            :sata4 => {
                :dfile => storage_directory + '/VirtualDisk/sata4.vdi',
                :size => 5120,
                :port => 4
            }
        }
    }
}

Vagrant.configure("2") do |config|

    config.vbguest.auto_update = false
    config.vm.synced_folder ".", "/vagrant", disabled: true
    
    MACHINES.each do |boxname, boxconfig|
  
        config.vm.define boxname do |box|
  
            box.vm.box = boxconfig[:box_name]
            box.vm.host_name = boxname.to_s
  
            box.vm.network "private_network", ip: boxconfig[:ip_addr]
  
            box.vm.provider :virtualbox do |vb|
                    vb.customize ["modifyvm", :id, "--memory", "4096"]
		    vb.customize ["modifyvm", :id, "--cpus", "2"]
                    needsController = false
            boxconfig[:disks].each do |dname, dconf|
                unless File.exist?(dconf[:dfile])
                  vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                  needsController =  true
                            end
            end
                    if needsController == true
                       vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                       boxconfig[:disks].each do |dname, dconf|
                           vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                       end
                    end
            end
  
        box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh
            cp ~vagrant/.ssh/auth* ~root/.ssh
	    SHELL

        end
    end
end
  
