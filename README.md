OSPF

Описание/Пошаговая инструкция выполнения домашнего задания:

Поднять три виртуалки Объединить их разными vlan поднять OSPF между машинами на базе Quagga; изобразить ассиметричный роутинг; сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

Сделан Vagrantfile и ansible плейбуки, раворачиваюшие машины-роутеры router1,router2 и router3. За роутерами есть приватные подсети 192.168.60.1/24, 192.168.70.1/24 и 192.168.80.1/24 соответственно, которые надо объединить с помощью ospf. Для этого соединяем роутеры сетями и настраиваем quagga.

Маршруты получаются следующими:

vagrant@router1:~$ ip r s
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.0.10.0/30 dev enp0s8 proto kernel scope link src 10.0.10.1 
10.0.12.0/30 dev enp0s9 proto kernel scope link src 10.0.12.1 
192.168.60.0/24 dev enp0s10 proto kernel scope link src 192.168.60.1 
192.168.100.0/24 dev enp0s16 proto kernel scope link src 192.168.100.10 

vagrant@router2:~$ ip r s
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.0.10.0/30 dev enp0s8 proto kernel scope link src 10.0.10.2 
10.0.11.0/30 dev enp0s9 proto kernel scope link src 10.0.11.2 
10.0.12.0/30 nhid 32 via 10.0.11.1 dev enp0s9 proto ospf metric 20 
192.168.60.0/24 nhid 34 via 10.0.10.1 dev enp0s8 proto ospf metric 20 
192.168.70.0/24 dev enp0s10 proto kernel scope link src 192.168.70.1 
192.168.100.0/24 dev enp0s16 proto kernel scope link src 192.168.100.11 
    
vagrant@router3:~$ ip r s
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100 
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100 
10.0.10.0/30 nhid 31 via 10.0.11.2 dev enp0s8 proto ospf metric 20 
10.0.11.0/30 dev enp0s8 proto kernel scope link src 10.0.11.1 
10.0.12.0/30 dev enp0s9 proto kernel scope link src 10.0.12.2 
192.168.60.0/24 nhid 32 via 10.0.12.1 dev enp0s9 proto ospf metric 20 
192.168.80.0/24 dev enp0s10 proto kernel scope link src 192.168.80.1 
192.168.100.0/24 dev enp0s16 proto kernel scope link src 192.168.100.12 

Роутинг асимметричный:


Поменяв вес пути в подсети 192.168.0.0/30, связывающей r1 и r2, для интерфейса 192.168.0.1 роутера r1, на , например, 1000, получим ассиметричный роутинг:

vagrant@router1:~$ tracepath -n 192.168.80.1
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.0.2.2                                              0.630ms 
 1:  10.0.2.2                                              0.543ms 
 2:  192.168.0.1                                           4.729ms asymm 64 

