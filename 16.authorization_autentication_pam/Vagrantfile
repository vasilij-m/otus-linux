# -*- mode: ruby -*-
# vim: set ft=ruby :
MACHINES = {
  :pam => {
        :box_name => "centos/8",
        :ip_addr => '192.168.11.11'
  }
}
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
      config.vbguest.auto_update = false
      config.vm.define boxname do |box|
          box.vm.box = boxconfig[:box_name]
          box.vm.hostname = boxname.to_s
          box.vm.network "private_network", ip: boxconfig[:ip_addr]
          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
          end
      
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
          SHELL

          box.vm.provision "pampolkit", type:'ansible' do |ansible|
            ansible.inventory_path = './inventories/all.yml'
            ansible.playbook = './playbooks/pampolkit.yml'
          end
       end
   end
end

