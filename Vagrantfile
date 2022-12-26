# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisioning/main.yaml"
    ansible.become = "true"
  end
  config.vm.provider "virtualbox" do |v|
	  v.memory = 2048
  end

  config.vm.define "ldapserver" do |ldapserver|
    ldapserver.vm.network "private_network", ip: "192.168.50.10", virtualbox__intnet: "local"
    ldapserver.vm.hostname = "ldapserver"
    ldapserver.vm.network "forwarded_port", guest: 443, host: 443
  end

  config.vm.define "ldapclient" do |ldapclient|
    ldapclient.vm.network "private_network", ip: "192.168.50.11", virtualbox__intnet: "local"
    ldapclient.vm.hostname = "ldapclient"
  end

end
