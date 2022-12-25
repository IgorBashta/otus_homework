# Logs

Решение первого задания представлено в виде ansible playbook - main.yaml.

После развертывания машин и выполения плейбука логи поступают на сервер. 
Для проверки перехожу по несуществующему пути 192.168.56.101/test в браузере и меняю права на файл nginx.conf ```chmod +x /etc/nginx/nginx.conf```

```
[root@log ~]# cat /var/log/rsyslog/web/nginx_access.log
[root@log vagrant]# cat /var/log/rsyslog/web/nginx_access.log
Dec 25 05:24:24 web nginx_access: 127.0.0.1 - - [25/Dec/2022:05:24:24 +0300] "GET / HTTP/1.1" 200 4833 "-" "ansible-httpget"
Dec 25 05:24:25 web nginx_access: 127.0.0.1 - - [25/Dec/2022:05:24:25 +0300] "GET /pp HTTP/1.1" 404 3650 "-" "ansible-httpget"
Dec 25 05:28:48 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:48 +0300] "GET / HTTP/1.1" 200 4833 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:48 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:48 +0300] "GET /img/centos-logo.png HTTP/1.1" 200 3030 "http://192.168.56.101/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:48 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:48 +0300] "GET /img/html-background.png HTTP/1.1" 200 1801 "http://192.168.56.101/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:48 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:48 +0300] "GET /img/header-background.png HTTP/1.1" 200 82896 "http://192.168.56.101/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:49 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:49 +0300] "GET /favicon.ico HTTP/1.1" 404 3650 "http://192.168.56.101/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:54 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:54 +0300] "GET /test HTTP/1.1" 404 3650 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:54 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:54 +0300] "GET /nginx-logo.png HTTP/1.1" 200 368 "http://192.168.56.101/pp" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
Dec 25 05:28:54 web nginx_access: 192.168.56.1 - - [25/Dec/2022:05:28:54 +0300] "GET /poweredby.png HTTP/1.1" 200 368 "http://192.168.56.101/pp" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36"
[root@log vagrant]# cat /var/log/rsyslog/web/nginx_error.log
Dec 25 05:24:25 web nginx_error: 2022/12/25 05:24:25 [error] 4587#4587: *2 open() "/usr/share/nginx/html/test" failed (2: No such file or directory), client: 127.0.0.1, server: _, request: "GET /pp HTTP/1.1", host: "127.0.0.1"
Dec 25 05:28:49 web nginx_error: 2022/12/25 05:28:49 [error] 4587#4587: *3 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.56.1, server: _, request: "GET /favicon.ico HTTP/1.1", host: "192.168.56.101", referrer: "http://192.168.56.101/"
Dec 25 05:28:54 web nginx_error: 2022/12/25 05:28:54 [error] 4587#4587: *3 open() "/usr/share/nginx/html/test" failed (2: No such file or directory), client: 192.168.56.1, server: _, request: "GET /pp HTTP/1.1", host: "192.168.56.101"

[root@log ~]# grep web /var/log/audit/audit.log
node=web type=SYSCALL msg=audit(1671935677.477:2083): arch=c000003e syscall=268 success=yes exit=0 a0=ffffffffffffff9c a1=ca7420 a2=1a4 a3=7fff1447c620 items=1 ppid=5975 pid=5996 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=6 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1671935677.477:2083):  cwd="/home/vagrant"
node=web type=PATH msg=audit(1671935677.477:2083): item=0 name="/etc/nginx/nginx.conf" inode=33613508 dev=08:01 mode=0100755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1671935677.477:2083): proctitle=63686D6F64002D78002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=SYSCALL msg=audit(1671935680.938:2084): arch=c000003e syscall=268 success=yes exit=0 a0=ffffffffffffff9c a1=8eb420 a2=1ed a3=7ffc329788e0 items=1 ppid=5975 pid=5997 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=6 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1671935680.938:2084):  cwd="/home/vagrant"
node=web type=PATH msg=audit(1671935680.938:2084): item=0 name="/etc/nginx/nginx.conf" inode=33613508 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1671935680.938:2084): proctitle=63686D6F64002B78002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=SYSCALL msg=audit(1671935762.322:2085): arch=c000003e syscall=268 success=yes exit=0 a0=ffffffffffffff9c a1=1d5d420 a2=1ed a3=7ffc12051760 items=1 ppid=5975 pid=5998 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=6 comm="chmod" exe="/usr/bin/chmod" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
node=web type=CWD msg=audit(1671935762.322:2085):  cwd="/home/vagrant"
node=web type=PATH msg=audit(1671935762.322:2085): item=0 name="/etc/nginx/nginx.conf" inode=33613508 dev=08:01 mode=0100755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1671935762.322:2085): proctitle=63686D6F64002B78002F6574632F6E67696E782F6E67696E782E636F6E66

```

Также в плейбук включен этап развертывания еще одной vm с elk. После установки остается только зайти в кибану (пробрасывается порт 5601 на локальную машину) и добавить патерн с логами nginx.



