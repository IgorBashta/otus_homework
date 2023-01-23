DNS/DHCP - настройка и обслуживание (Centos 7)

За основу согласно методички взят  https://github.com/erlong15/vagrant-bind 

Для проверки необходимо скачать репозиторий и выполнить vagrant up.
```
https://github.com/IgorBashta/otus_homework/tree/less-35
```
После завершения можно повыполнять dns запросы на client и client2.
```
vagrant ssh client

[vagrant@client ~]$ ping www.newdns.lab
PING www.newdns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.043 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.058 ms
^C
--- www.newdns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 0.043/0.050/0.058/0.010 ms
[vagrant@client ~]$ ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from client (192.168.50.15): icmp_seq=1 ttl=64 time=0.053 ms
64 bytes from client (192.168.50.15): icmp_seq=2 ttl=64 time=0.055 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1006ms
rtt min/avg/max/mdev = 0.053/0.054/0.055/0.001 ms
[vagrant@client ~]$ dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 27146
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Mon Jan 23 19:36:32 UTC 2023
;; MSG SIZE  rcvd: 127

[vagrant@client ~]$ dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 44851
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; AUTHORITY SECTION:
dns.lab.		600	IN	SOA	ns01.dns.lab. root.dns.lab. 2711201407 3600 600 86400 600

;; Query time: 0 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Mon Jan 23 19:36:40 UTC 2023
;; MSG SIZE  rcvd: 87

```

Проверка второго клиента.

```
vagrant ssh client2

[vagrant@client2 ~]$ ping www.newdns.lab
ping: www.newdns.lab: Name or service not known
[vagrant@client2 ~]$ ping web1.dns.lab
PING web1.dns.lab (192.168.50.15) 56(84) bytes of data.
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=1 ttl=64 time=0.564 ms
64 bytes from 192.168.50.15 (192.168.50.15): icmp_seq=2 ttl=64 time=1.02 ms
^C
--- web1.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.564/0.795/1.027/0.233 ms
[vagrant@client2 ~]$ ping web2.dns.lab
PING web2.dns.lab (192.168.50.16) 56(84) bytes of data.
64 bytes from client2 (192.168.50.16): icmp_seq=1 ttl=64 time=0.039 ms
64 bytes from client2 (192.168.50.16): icmp_seq=2 ttl=64 time=0.055 ms
^C
--- web2.dns.lab ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.039/0.047/0.055/0.008 ms
[vagrant@client2 ~]$ dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48818
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.			IN	A

;; ANSWER SECTION:
web1.dns.lab.		3600	IN	A	192.168.50.15

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Mon Jan 23 19:37:54 UTC 2023
;; MSG SIZE  rcvd: 127

[vagrant@client2 ~]$ dig @192.168.50.11 web2.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> @192.168.50.11 web2.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 25667
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web2.dns.lab.			IN	A

;; ANSWER SECTION:
web2.dns.lab.		3600	IN	A	192.168.50.16

;; AUTHORITY SECTION:
dns.lab.		3600	IN	NS	ns02.dns.lab.
dns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10
ns02.dns.lab.		3600	IN	A	192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.11#53(192.168.50.11)
;; WHEN: Mon Jan 23 19:38:01 UTC 2023
;; MSG SIZE  rcvd: 127

```
