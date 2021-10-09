# -*- mode: ruby -*-
# vim: set ft=ruby :
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :"z-server" => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.200'
  },
  :"z-agent" => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.210'
  }
}

Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end
  
  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|

        box.vm.box = boxconfig[:box_name]
        box.vm.host_name = boxname.to_s
        box.vm.network "private_network", ip: boxconfig[:ip_addr]
        
        box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
        SHELL
        
        case boxname.to_s
        when "z-server"
          box.vm.provision "installmysql", type:'ansible' do |ansible|
            ansible.inventory_path = './inventories/all.yml'
            ansible.playbook = './playbooks/installmysql.yml'
          end
          box.vm.provision "installnginx", type:'ansible' do |ansible|
            ansible.inventory_path = './inventories/all.yml'
            ansible.playbook = './playbooks/installnginx.yml'
          end
          box.vm.provision "zabbix-server", type:'ansible' do |ansible|  
            ansible.inventory_path = './inventories/all.yml'
            ansible.playbook = './playbooks/zabbix-server.yml'
          end
        when "z-agent"
          box.vm.provision "zabbix-agent", type:'ansible' do |ansible|
            ansible.inventory_path = './inventories/all.yml'
            ansible.playbook = "./playbooks/zabbix-agent.yml"
          end
        end
    end
  end
end