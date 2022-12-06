#!/bin/bash
sudo yum install nfs-utils -y
sudo yum install firewalld -y
sudo systemctl enable rpcbind
sudo systemctl enable nfs --now
sudo systemctl enable firewalld --now
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-port=111/udp
sudo firewall-cmd --permanent --add-port=111/tcp
sudo firewall-cmd --permanent --add-port=2049/udp
sudo firewall-cmd --permanent --add-port=2049/tcp
sudo firewall-cmd --permanent --add-port=20048/udp
sudo firewall-cmd --permanent --add-port=20048/tcp
sudo firewall-cmd --permanent --zone=public --add-service="nfs3"
sudo firewall-cmd --permanent --zone=public --add-service="mountd"
sudo firewall-cmd --permanent --zone=public --add-service="rpc-bind"
sudo firewall-cmd --reload
sudo mkdir /srv/share
sudo mkdir /srv/share/upload
sudo chown -R nfsnobody:nfsnobody /srv/share
sudo chmod -R 777 /srv/share
echo -e "/srv/share \t192.168.10.11(ro,fsid=0,sync,no_root_squash,no_subtree_check)\n/srv/share/upload \t192.168.10.11(rw,fsid=1,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -r
echo -e "[exportfs]\ndebug=all\n[mountd]\ndebug=all\n[nfsd]\ndebug=all\nudp=y\ntcp=n\nvers3=y\nvers4=n\nvers4.0=n\nvers4.1=n\nvers4.2=n" | sudo tee -a /etc/nfs.conf
sudo systemctl restart firewalld
sudo systemctl start rpcbind
sudo systemctl start nfs-server
exit 0