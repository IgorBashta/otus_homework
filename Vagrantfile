# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"


  config.vm.define "web" do |server|
    server.vm.network "private_network", ip: "192.168.11.10"
    server.vm.hostname = "web"
    server.vm.provider "virtualbox" do |v|
      v.name = "web"
      v.memory = 1024
    end
  end

  config.vm.provision "ansible" do |ansible|
#    ansible.verbose = "vvv"
    ansible.playbook = "web.yml"
  end

end
