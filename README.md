Работа с mdam
изменил Vagrant файл для выполнения всех команд по методичке.
1. добавил диск
```
:sata5 => {
    :dfile => './sata5.vdi',
    :size => 250, # Megabytes
    :port => 5 
}
```
2. описал последовательность команд для создания райдаи продключения в директории.
```	      
yum install -y mdadm smartmontools hdparm gdisk
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 25%
parted /dev/md0 mkpart primary ext4 25% 50%
parted /dev/md0 mkpart primary ext4 50% 75%
parted /dev/md0 mkpart primary ext4 75% 100%
for i in $(seq 1 4); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4}
for i in $(seq 1 4); do mount /dev/md0p$i /raid/part$i; done	
```
3. 
```
vagrant up
vagrant ssh
lsblk
вывод
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda         8:0    0    40G  0 disk  
`-sda1      8:1    0    40G  0 part  /
sdb         8:16   0   250M  0 disk  
`-md0       9:0    0   744M  0 raid6 
  |-md0p1 259:0    0 184.5M  0 md    /raid/part1
  |-md0p2 259:1    0   186M  0 md    /raid/part2
  |-md0p3 259:2    0   186M  0 md    /raid/part3
  `-md0p4 259:3    0 184.5M  0 md    /raid/part4
sdc         8:32   0   250M  0 disk  
`-md0       9:0    0   744M  0 raid6 
  |-md0p1 259:0    0 184.5M  0 md    /raid/part1
  |-md0p2 259:1    0   186M  0 md    /raid/part2
  |-md0p3 259:2    0   186M  0 md    /raid/part3
  `-md0p4 259:3    0 184.5M  0 md    /raid/part4
sdd         8:48   0   250M  0 disk  
`-md0       9:0    0   744M  0 raid6 
  |-md0p1 259:0    0 184.5M  0 md    /raid/part1
  |-md0p2 259:1    0   186M  0 md    /raid/part2
  |-md0p3 259:2    0   186M  0 md    /raid/part3
  `-md0p4 259:3    0 184.5M  0 md    /raid/part4
sde         8:64   0   250M  0 disk  
`-md0       9:0    0   744M  0 raid6 
  |-md0p1 259:0    0 184.5M  0 md    /raid/part1
  |-md0p2 259:1    0   186M  0 md    /raid/part2
  |-md0p3 259:2    0   186M  0 md    /raid/part3
  `-md0p4 259:3    0 184.5M  0 md    /raid/part4
sdf         8:80   0   250M  0 disk  
`-md0       9:0    0   744M  0 raid6 
  |-md0p1 259:0    0 184.5M  0 md    /raid/part1
  |-md0p2 259:1    0   186M  0 md    /raid/part2
  |-md0p3 259:2    0   186M  0 md    /raid/part3
  `-md0p4 259:3    0 184.5M  0 md    /raid/part4
```
