## Сценарии iptables

1. реализовать knocking port - centralRouter может попасть на ssh inetRouter через knock скрипт

Реализовать knocking port можно несколькими способами:

- Импорт правил в таблицы iptables. У данного способа есть свои преимущества в виде независимости от других программ
Данный конфиг говорит на следующее - если был перебор портов с последовательностью портов 2222 3333 4444, то открыть порт 22 на 30 секунд. Уже установленные SSH соединения не будут отброшены, так как есть специальная таблица уже установленных соединений conntrack, и если там будет соединение то его файервол сбрасывать не будет 
```
cat <<EOT | iptables-restore
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [12816:43815755]
:OUTPUT ACCEPT [106:11577]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]
:TRAFFIC - [0:0]
-A INPUT -j TRAFFIC
-A SSH-INPUT -m recent --set --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A SSH-INPUTTWO -m recent --set --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p icmp -m icmp --icmp-type any -j ACCEPT
-A TRAFFIC -m state --state RELATED,ESTABLISHED -j ACCEPT
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 --mask 255.255.255.255 --rsource -j ACCEPT
-A TRAFFIC -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH2 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 4444 -m recent --rcheck --name SSH1 --mask 255.255.255.255 --rsource -j SSH-INPUTTWO
-A TRAFFIC -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH1 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 3333 -m recent --rcheck --name SSH0 --mask 255.255.255.255 --rsource -j SSH-INPUT
-A TRAFFIC -p tcp -m state --state NEW -m tcp -m recent --remove --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -p tcp -m state --state NEW -m tcp --dport 2222 -m recent --set --name SSH0 --mask 255.255.255.255 --rsource -j DROP
-A TRAFFIC -j DROP
COMMIT
EOT
```
- Использование таких программ как knock 
Для начала надо прописать правила в iptables и сохранить их:
```sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT; sudo iptables -A INPUT -p tcp --dport 22 -j REJECT; sudo service iptables save```

Затем привести файлы конфигурации к следующему виду:

```/etc/knockd.conf```:

```
options]
	UseSyslog

[opencloseSSH]
	sequence      = 2222:tcp,3333:tcp,4444:tcp
        seq_timeout   = 15
        tcpflags      = syn
        start_command = /sbin/iptables -I INPUT 1 -s %IP% -p tcp --dport 22 -j ACCEPT
        cmd_timeout   = 30
        stop_command  = /sbin/iptables -D INPUT -s %IP% -p tcp --dport ssh -j ACCEPT
```

```/etc/sysconfig/knockd```:

```
OPTIONS="-i eth1"
```

Также необходимо что лучше переделать файл запуска с версии SysV к unit файлу, или в крайнем случае добавить на 23 строку файла ```/etc/init.d/knock``` директиву ```sleep 30``` и далее сделать systemctl daemon-reload. 

Мы своего добились, теперь можно проверить настройку knocking port. Необходимо зайти на centralRouter командой ```vagrant ssh centralRouter``` и выполнить:
```
 for x in 2222 3333 4444; do sudo nmap -Pn --host_timeout 100 --max-retries 0 -p $x 192.168.255.1; done
```
Также можно установить на centalRouter программу knock и выполнить сдедующую команду ```knock 192.168.4.24 2222 3333 4444 -d 500```, где d это delay 500 мс между портами.

2. Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост

Добавлен в вагрант директивой ```box.vm.network "forwarded_port", guest: 8080, host: 1234, host_ip: "127.0.0.1", id: "nginx"``` (смотрите вагрант файл)

3. запустить nginx на centralServer 

Добавлено директивами: ```sudo yum install -y epel-release; sudo yum install -y nginx; sudo systemctl enable nginx; sudo systemctl start nginx``` (смотрите вагрант файл)

4. Пробросить 80й порт на inetRouter2 8080

В данном случае когда мы переходим по адресу 127.0.0.1 порт 1234 то мы попадаем на порт 8080 гостевой машины inetRouter2.
Затем правилами iptables мы управляем пакетами, которые пришли на порт 8080 интерфейса eth0 и отправляем их по адресу 192.168.0.2 порт 80. Исходя из правил маршрутизации компьютер знает куда отправлять дальше данные пакеты, и он их отправляет на 192.168.255.3 (centralRouter), далее они попадают на веб-сервер 192.168.0.2 на порт 80 после чего возвращаются отправителю обратно в той же последовательности. (смотрите схему)

Правила iptables для inetRouter2:
```
sudo iptables -t nat -A PREROUTING -i eth0 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
sudo iptables -t nat -A POSTROUTING --destination 192.168.0.2/32 -j SNAT --to-source 192.168.255.2
```

5. Все гостевые машины по умолчанию ходят в интернет через 192.168.255.1 (inetRouter), для этого сделаны настройки (на примере centralServer):
```
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0 
echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
```
Т.е. мы выключаем маршрут по умолчанию для интерфейса eth0 (10.0.2.15 - это сеть по умолчанию виртуалбокса) и прописываем шлюз по умолчанию для другого интерфейса, который смотрит в centralRouter.

#### Схема:

![image](https://raw.githubusercontent.com/staybox/otus_dz17/master/screenshots/filtration.png)

