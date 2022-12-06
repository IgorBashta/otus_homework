#!/bin/bash
sudo yum install nfs-utils -y
sudo systemctl start rpcbind
sudo systemctl enable rpcbind
sudo mkdir /mnt/share
sudo mount -t nfs -o nfsvers=3 192.168.10.10:/srv/share /mnt/share
echo -e "192.168.10.10:/srv/share\t/mnt/share\tnfs\tdefaults,vers=3\t0\t0" | sudo tee -a /etc/fstab
exit 0