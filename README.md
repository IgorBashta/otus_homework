OSPF

Описание/Пошаговая инструкция выполнения домашнего задания:

Поднять три виртуалки Объединить их разными vlan поднять OSPF между машинами на базе Quagga; изобразить ассиметричный роутинг; сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.

Сделан Vagrantfile и ansible плейбуки, раворачиваюшие машины-роутеры router1,router2 и router3. За роутерами есть приватные подсети 192.168.60.1/24, 192.168.70.1/24 и 192.168.80.1/24 соответственно, которые надо объединить с помощью ospf. Для этого соединяем роутеры сетями и настраиваем quagga.

Маршруты получаются следующими:
```
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
```
Роутинг асимметричный:


Поменяв вес пути в подсети 192.168.0.0/30, связывающей r1 и r2, для интерфейса 192.168.0.1 роутера r1, на , например, 1000, получим ассиметричный роутинг:
```
vagrant@router1:~$ tracepath -n 192.168.80.1
 1?: [LOCALHOST]                      pmtu 1500
 1:  10.0.2.2                                              0.630ms 
 1:  10.0.2.2                                              0.543ms 
 2:  192.168.0.1                                           4.729ms asymm 64 
```


Симетричный роутинг
Для поднятия симетричного роутинга в otus_homework/ansible/defaults/main.yaml меняем параметр на "symmetric_routing: true"

```
root@router1:/home/vagrant# vtysh

Hello, this is FRRouting (version 8.4.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/800] is directly connected, enp0s8, weight 1, 00:00:20
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:02:10
O   10.0.12.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:03:20
O   192.168.60.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:03:20
O>* 192.168.70.0/24 [110/300] via 10.0.12.2, enp0s9, weight 1, 00:02:10
O>* 192.168.80.0/24 [110/200] via 10.0.12.2, enp0s9, weight 1, 00:02:10
router1# 
root@router1:/home/vagrant# ping -I 192.168.60.1 192.168.70.1
PING 192.168.70.1 (192.168.70.1) from 192.168.60.1 : 56(84) bytes of data.
^C
--- 192.168.70.1 ping statistics ---
15 packets transmitted, 0 received, 100% packet loss, time 14373ms


vagrant@router2:~$ sudo su
root@router2:/home/vagrant# vtysh

Hello, this is FRRouting (version 8.4.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router2# show ip route ospf
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/800] is directly connected, enp0s8, weight 1, 00:02:31
O   10.0.11.0/30 [110/100] is directly connected, enp0s9, weight 1, 00:01:56
O>* 10.0.12.0/30 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:01:55
O>* 192.168.60.0/24 [110/300] via 10.0.11.1, enp0s9, weight 1, 00:01:31
O   192.168.70.0/24 [110/100] is directly connected, enp0s10, weight 1, 00:02:31
O>* 192.168.80.0/24 [110/200] via 10.0.11.1, enp0s9, weight 1, 00:01:55
router2# 
root@router2:/home/vagrant# tcpdump -i enp0s9
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on enp0s9, link-type EN10MB (Ethernet), capture size 262144 bytes
10:39:53.487431 IP 192.168.60.1 > router2: ICMP echo request, id 1, seq 10, length 64
10:39:53.487502 IP router2 > 192.168.60.1: ICMP echo reply, id 1, seq 10, length 64
10:39:53.857367 IP 10.0.11.1 > ospf-all.mcast.net: OSPFv2, LS-Ack, length 44
10:39:54.519458 IP 192.168.60.1 > router2: ICMP echo request, id 1, seq 11, length 64
10:39:54.520614 IP router2 > 192.168.60.1: ICMP echo reply, id 1, seq 11, length 64
10:39:55.535470 IP 192.168.60.1 > router2: ICMP echo request, id 1, seq 12, length 64
10:39:55.535530 IP router2 > 192.168.60.1: ICMP echo reply, id 1, seq 12, length 64
^C
7 packets captured
7 packets received by filter
0 packets dropped by kernel

```