# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :otus => {
        :box_name => "centos/7",
        :ip_addr => '192.168.56.100'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "forwarded_port", guest: 4881, host: 4881

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "256"]
          end
          
          box.vm.provision "shell", inline: <<-SHELL
                mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
		        echo cfq > /sys/block/sda/queue/scheduler
                sudo yum install -y epel-release 
                sudo yum install -y nginx
                sudo yum install -y policycoreutils-python
                sed -i 's/listen       80;/listen       4881;/'  /etc/nginx/nginx.conf /etc/nginx/nginx.conf
                sudo systemctl start nginx
                sudo systemctl status nginx
                sudo ss -tlpn | grep 4881
            
            SHELL

      end
  end
end