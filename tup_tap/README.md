### TUN & TAP

1. Выполнить `vagrant up`, и автоматически поднимает Server и Client с установленным VPN соединением (через tun).

2. Для установления VPN соединения (через tap), выполнить `ansible-playbook vpn-tap.yml`

-- -
Установим пакеты
```
[root@vpn-server ~]# yum install -y epel-release
[root@vpn-server ~]# yum install -y openvpn
```

Включим forwarding, пересылка пакетов между интерфейсами
```
[root@vpn-server ~]# echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf | sysctl -p
```

Сгенерируем секретный ключ:
```
[root@vpn-server ~]# openvpn --genkey --secret /etc/openvpn/server/ta.key
```
Сгенерирующий секретный ключ скопируем на клиент сервер `vpn-client` в каталог `/etc/openvpn/client`.
Создадим каталог для логов:
```
[root@vpn-server ~]# mkdir -p /var/log/openvpn
```

Создадим конфигурационный файл (tap режим) на сервере `vpn-server`:
```
[root@server-ovpn ~]# vi /etc/openvpn/server/server.conf

#
# OpenVPN Server Config
#

dev tun

secret ta.key

ifconfig 10.10.1.1 255.255.255.0
route 192.168.2.0 255.255.255.0 10.10.1.2

topology subnet

compress lzo

status /var/log/openvpn-status.log
log /var/log/openvpn/openvpn.log
verb 3
```

Запускаем сервис и добавляем в автозагрузку:
```
[root@vpn-server ~]# systemctl enable --now openvpn-server@server
```

Проверим статус сервиса `openvpn-server@server`:
```
[root@vpn-server ~]# systemctl status openvpn-server@server
```

### OpenVPN client

Установим пакеты
```
[root@vpn-client ~]# yum install -y epel-release
[root@vpn-client ~]# yum install -y openvpn
```

Включим forwarding, пересылка пакетов между интерфейсами
```
[root@vpn-client ~]# echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf | sysctl -p
```

Создадим конфигурационный файл (tap режим) на клиент сервере `vpn-client`:
```
[root@vpn-client ~]# vi /etc/openvpn/client/server.conf

#
# OpenVPN Client Config
#

dev tun

secret ta.key

remote 172.20.1.10

ifconfig 10.10.1.2 255.255.255.0
route 192.168.1.0 255.255.255.0 10.10.1.1

topology subnet

compress lzo

status /var/log/openvpn-status.log
log /var/log/openvpn.log
verb 3
```
Запускаем сервис и добавляем в автозагрузку:
```
[root@vpn-client ~]# systemctl enable --now openvpn-client@server
```
Проверим статус сервиса `openvpn-client@server`:
```
[root@vpn-client ~]# systemctl status openvpn-client@server
```

### Проверка

Протестируем созданный канал с помощью инструмента `iperf3`:
На машине `PC1` запустим утилиту `iperf3` в режиме сервер, а на `PC2` в режиме клиент:
```
[root@pc1 ~]# iperf3 -s
[root@pc2 ~]# iperf3 -c 192.168.1.20 -t 10 -i 5 -b 1000M -u
```
Результат тестирования показал:
```
[vagrant@pc2 ~]$ iperf3 -c 192.168.1.20 -t 10 -i 5 -b 1000M -u
Connecting to host 192.168.1.20, port 5201
[  4] local 192.168.2.20 port 54553 connected to 192.168.1.20 port 5201
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-5.00   sec   146 MBytes   245 Mbits/sec  112961  
[  4]   5.00-10.00  sec   167 MBytes   281 Mbits/sec  129747  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-10.00  sec   313 MBytes   263 Mbits/sec  0.892 ms  193977/242520 (80%)  
[  4] Sent 242520 datagrams

```
Изменим в конфигах /etc/openvpn/server.conf на сервере и клиенте режим с tun на tap.
Сново протестируем.
```
[vagrant@pc2 ~]$ iperf3 -c 192.168.1.20 -t 10 -i 5 -b 1000M -u
Connecting to host 192.168.1.20, port 5201
[  4] local 192.168.2.20 port 51270 connected to 192.168.1.20 port 5201
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-5.00   sec   123 MBytes   206 Mbits/sec  97599  
[  4]   5.00-10.00  sec   107 MBytes   179 Mbits/sec  84616  
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-10.00  sec   230 MBytes   193 Mbits/sec  0.214 ms  127937/182215 (70%)  
[  4] Sent 182215 datagrams

```

Hежим `tun` быстрее по сравнению с `tap`. Устройство `tap` ведет себя как полноценный сетевой адапптер.
