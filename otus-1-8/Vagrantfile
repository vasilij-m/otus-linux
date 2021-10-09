# -*- mode: ruby -*-
# vim: set ft=ruby :
MACHINES = {
  :rpmmachine => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.101'
  }
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
      config.vm.define boxname do |box|
          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s
          box.vm.network "private_network", ip: boxconfig[:ip_addr]
          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
          end

	  box.vm.synced_folder ".", "/vagrant"
          
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sudo yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils gcc
          SHELL
          box.vm.provision "repobuild", type: "shell", path: "./scripts/repobuild.sh"
       end
   end
end

