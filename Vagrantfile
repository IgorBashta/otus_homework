# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 512
  end

  config.vm.define "vpn-server" do |server|
    server.vm.network "private_network", ip: "192.168.1.10", virtualbox__intnet: "lan"
    server.vm.network "private_network", ip: "172.20.1.10"
    server.vm.hostname = "vpn-server"
    server.vm.provider "virtualbox" do |v|
      v.name = "vpn-server"
      v.memory = 1024
    end
  end

  config.vm.define "pc1" do |pc1|
    pc1.vm.network "private_network", ip: "192.168.1.20", virtualbox__intnet: "lan"
    pc1.vm.hostname = "pc1"
    pc1.vm.provider "virtualbox" do |v|
      v.name = "pc1"
    end
  end
  
  config.vm.define "pc2" do |pc1|
    pc1.vm.network "private_network", ip: "192.168.1.21", virtualbox__intnet: "lan"
    pc1.vm.hostname = "pc2"
    pc1.vm.provider "virtualbox" do |v|
      v.name = "pc2"
    end
  end

  config.vm.define "vpn-client" do |client|
    client.vm.network "private_network", ip: "172.20.2.10"
    client.vm.hostname = "vpn-client"
    client.vm.provider "virtualbox" do |v|
      v.name = "vpn-client"
      v.memory = 1024
    end
  end

#  config.vm.provision "ansible" do |ansible|
#    ansible.verbose = "vvv"
#    ansible.playbook = "ovpn.yml"
#  end

end
