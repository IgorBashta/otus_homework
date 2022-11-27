Практические навыки работы с ZFS
1. Клонируем репозиторий 
```
git clone git@github.com:IgorBashta/otus_homework.git -b less-02
```

Проверяем конфиг Vagranta

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'open3'
require 'fileutils'

def get_vm_name(id)
  out, err = Open3.capture2e('VBoxManage list vms')
  raise out unless err.exitstatus.zero?

  path = path = File.dirname(__FILE__).split('/').last
  name = out.split(/\n/)
            .select { |x| x.start_with? "\"#{path}_#{id}" }
            .map { |x| x.tr('"', '') }
            .map { |x| x.split(' ')[0].strip }
            .first

  name
end


def controller_exists(name, controller_name)
  return false if name.nil?

  out, err = Open3.capture2e("VBoxManage showvminfo #{name}")
  raise out unless err.exitstatus.zero?
  out.split(/\n/)
     .select { |x| x.start_with? 'Storage Controller Name' }
     .map { |x| x.split(':')[1].strip }
     .any? { |x| x == controller_name }
end

def create_disks(vbox, name)
  # TODO: check that VM is created first time to avoid double vagrant up
 # unless controller_exists(name, 'SATA Controller')
 #   vbox.customize ['storagectl', :id,
 #                   '--name', 'SATA Controller',
 #                   '--add', 'sata']
 # end

  dir = "../vdisks"
  FileUtils.mkdir_p dir unless File.directory?(dir)

  disks = (1..8).map { |x| ["disk#{x}_", '1024'] }

  disks.each_with_index do |(name, size), i|
    file_to_disk = "#{dir}/#{name}.vdi"
    port = (i + 1).to_s

    unless File.exist?(file_to_disk)
      vbox.customize ['createmedium',
                      'disk',
                      '--filename',
                      file_to_disk,
                      '--size',
                      size,
                      '--format',
                      'VDI',
                      '--variant',
                      'standard']
    end

    vbox.customize ['storageattach', :id,
                    '--storagectl', 'SATA Controller',
                    '--port', port,
                    '--type', 'hdd',
                    '--medium', file_to_disk,
                    '--device', '0']

    vbox.customize ['setextradata', :id,
                    "VBoxInternal/Devices/ahci/0/Config/Port#{port}/SerialNumber",
                    name.ljust(20, '0')]
  end
end

Vagrant.configure("2") do |config|

  config.vm.box = "bento/centos-8"
  config.vm.box_version = "202112.19.0"


config.vm.define "server" do |server|

  server.vm.host_name = 'server'
  server.vm.network :private_network, ip: "192.168.56.102"

  server.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  server.vm.provider 'virtualbox' do |vbx|
      name = get_vm_name('server')
      create_disks(vbx, name)
    end


  server.vm.provision "shell",
    name: "Setup zfs",
    path: "setup_zfs.sh"
  end


  config.vm.define "client" do |client|
    client.vm.host_name = 'client'
    client.vm.network :private_network, ip: "192.168.56.101"
    client.vm.provider :virtualbox do |vb|
      vb.memory = "1024"
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    end
  end

end
```
Результатом выполнения команды 
vagrant up станет созданная виртуальная машина, 
с 8 дисками и уже установленным и готовым к работе ZFS.

Заходим на сервер: 
```
vagrant ssh
```
Дальнейшие действия выполняются от пользователя root. 
Переходим в root
пользователя: 
```
sudo -i
```
1. Определение алгоритма с наилучшим сжатием
Смотрим список всех дисков, которые есть в виртуальной машине: 
```
lsblk
```
```
[root@zfs ~]# lsblk
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT sda 8:0040G0disk
└─sda1 8:1 0 40G 0 part /
sdb 8:16 0 512M 0 disk
sdc 8:32 0 512M 0 disk
sdd 8:48 0 512M 0 disk
sde 8:64 0 512M 0 disk
sdf 8:80 0 512M 0 disk
sdg 8:96 0 512M 0 disk
sdh 8:112 0 512M 0 disk
sdi 8:128 0 512M 0 disk
```
Создаём пул из двух дисков в режиме RAID 1: 
```
zpool create otus1 mirror /dev/sdb /dev/sdc
```
Создадим ещё 3 пула:
```
[root@zfs ~]# zpool create otus2 mirror /dev/sdd /dev/sde 
[root@zfs ~]# zpool create otus3 mirror /dev/sdf /dev/sdg 
[root@zfs ~]# zpool create otus4 mirror /dev/sdh /dev/sdi
```
Смотрим информацию о пулах: 
```
zpool list
NAME SIZE ALLOC FREE CKPOINT EXPANDSZ FRAG CAP DEDUP
HEALTH ALTROOT
otus1 480M 91.5K 480M - ONLINE -
otus2 480M 91.5K 480M - ONLINE -
otus3 480M 91.5K 480M - ONLINE -
otus4 480M 91.5K 480M - ONLINE -
- 0% - 0% - 0% - 0%
0% 1.00x 0% 1.00x 0% 1.00x 0% 1.00x
```
Команда zpool status показывает информацию о каждом диске, состоянии сканирования и об ошибках чтения, записи и совпадения хэш-сумм. Команда zpool list показывает информацию о размере пула, количеству занятого и свободного места, дедупликации и т.д.

Добавим разные алгоритмы сжатия в каждую файловую систему:
 ```
● Алгоритмlzjb:zfssetcompression=lzjbotus1
● Алгоритм lz4: zfs set compression=lz4 otus2
● Алгоритмgzip:zfssetcompression=gzip-9otus3
● Алгоритм zle: zfs set compression=zle otus4
```
Проверим, что все файловые системы имеют разные методы сжатия:
```
[root@zfs ~]# zfs get all | grep compression otus1 compression lzjb
otus2 compression lz4
otus3 compression gzip-9
otus4 compression zle
```
Сжатие файлов будет работать после включение настройки сжатия.

только с файлами, которые были добавлены Скачаем один и тот же текстовый файл во все пулы:
```
[root@zfs ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2022-11-27 19:07:27-- https://gutenberg.org/cache/epub/2600/pg2600.converter.log Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40750827 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’
100%[=================================================================== ========================================================================= ===========================>] 40,750,827 1.14MB/s in 44s
2022-11-27 19:07:29 (914 KB/s) - ‘/otus1/pg2600.converter.log’ saved [40750827/40750827]
```
 Проверим, что файл был скачан во все пулы:
```
[root@zfs ~]# ls -l /otus* /otus1:
total 22005 -rw-r--r--.
/otus2: total 17966 -rw-r--r--.
/otus3: total 10945 -rw-r--r--.
/otus4: total 39836 -rw-r--r--.
1 root root 40750827 May 21 08:17 pg2600.converter.log
1 root root 40750827 May 21 08:17 pg2600.converter.log
1 root root 40750827 May 21 08:17 pg2600.converter.log
1 root root 40750827 May 21 08:17 pg2600.converter.log 
```
Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3.
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:
```
[root@zfs ~]# zfs list
NAME USED AVAIL REFER MOUNTPOINT otus1 21.6M 330M 21.5M /otus1 otus2 17.7M 334M 17.6M /otus2 otus3 10.8M 341M 10.7M /otus3 otus4 39.0M 313M 38.9M /otus4
```
```
[root@zfs ~]# zfs get all | grep compressratio | grep -v ref
otus1 compressratio 1.80x otus2 compressratio 2.21x otus3 compressratio 3.63x otus4 compressratio 1.00x 
```
Таким образом, у нас получается, что алгоритм gzip-9 самый эффективный по сжатию.

2. Определение настроек пула
Скачиваем архив в домашний каталог:
```
[root@zfs ~]# wget -O archive.tar.gz --no-check-certificate
‘https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg&e xport=download’
[1] 19219
[root@zfs ~]# --2022-11-27 19:37:24-- https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
 Resolving drive.google.com (drive.google.com)... 64.233.162.194, 2a00:1450:4010:c05::c2
Connecting to drive.google.com (drive.google.com)|64.233.162.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily Location: https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc 7l7deffksulhg5h7mbp1/ir5thlkbisl46u69ianbfos2mk06n02f/1635074025000/161 89157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg [following] Warning: wildcards not supported in HTTP.
--2022-11-27 19:37:25-- https://doc-0c-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc 7l7deffksulhg5h7mbp1/ir5thlkbisl46u69ianbfos2mk06n02f/1635074025000/161 89157874053420687/*/1KRBNW33QWqbvbVHa3hLJivOAt60yukkg
Resolving doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)... 142.250.150.132, 2a00:1450:4010:c1c::84
Connecting to doc-0c-bo-docs.googleusercontent.com (doc-0c-bo-docs.googleusercontent.com)|142.250.150.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/x-gzip]
Saving to: ‘archive.tar.gz’
100%[=================================================================== ========================>] 7,275,140 6.83MB/s in 1.0s
2022-11-27 19:37:29 (6.83 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]
[1]+ Done wget -O archive.tar.gz https://drive.google.com/u/0/uc?id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg [root@zfs ~]#
```
Разархивируем его:
```
[root@zfs ~]# tar -xzvf archive.tar.gz zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```
Проверим, возможно ли импортировать данный каталог в пул:
```
[root@zfs ~]# zpool import -d zpoolexport/ pool: otus
id: state: action: config:
6554193320433390805
ONLINE
The pool can be imported using its name or numeric identifier.
otus ONLINE
mirror-0 ONLINE /root/zpoolexport/filea ONLINE /root/zpoolexport/fileb ONLINE
```
Данный вывод показывает нам имя пула, тип raid и его состав. Сделаем импорт данного пула к нам в ОС:
```
[root@zfs ~]# zpool import -d zpoolexport/ otus [root@zfs ~]# zpool status
pool: otus
state: scan: config:
ONLINE
none requested
NAME otus
mirror-0 /root/zpoolexport/filea /root/zpoolexport/fileb
errors: 

No known data errors
```
Команда zpool status выдаст нам информацию о составе импортированного пула
Если у Вас уже есть пул с именем otus, то можно поменять его имя во время импорта: 
```
zpool import -d zpoolexport/ otus newotus
```
Далее нам нужно определить настройки
Запрос сразу всех параметров пула: 
```
zpool get all otus
```
Запрос сразу всех параметром файловой системы: 
```
zfs get all otus 
```
```
[root@zfs ~]# zfs get all otus
NAME PROPERTY
otus type
otus creation
otus used
otus available otus referenced otus compressratio otus mounted
otus quota
otus reservation otus recordsize otus mountpoint otus sharenfs otus checksum otus compression otus atime
otus devices otus exec
otus setuid
otus readonly otus zoned
otus snapdir otus aclinherit otus createtxg
VALUE
filesystem
Sat May 21 9:00 2022 2.04M
350M
24K
1.00x
yes
none
none
128K
/otus
off
sha256
zle
on
on
on
on
off
off
hidden
restricted
1
SOURCE
-
-
-
-
-
-
-
default default local default default local local default default default default default default default default -
STATE
ONLINE
ONLINE
ONLINE
ONLINE
READ WRITE CKSUM
0 0 0 0 0 0 0 0 0 0 0 0

 otus canmount on
otus xattr on
otus copies 1
otus version 5
otus utf8only off
otus normalization none
otus casesensitivity sensitive otus vscan off
otus nbmand off otus sharesmb off otus refquota none otus refreservation none
otus guid
otus primarycache all
otus secondarycache all
otus usedbysnapshots 0B
otus usedbydataset 24K
otus usedbychildren 2.01M otus usedbyrefreservation 0B
otus logbias latency otus objsetid 54
otus dedup off
otus mlslabel none otus sync standard otus dnodesize legacy otus refcompressratio 1.00x otus written 24K
otus logicalused 1020K otus logicalreferenced 12K
otus volmode default otus filesystem_limit none otus snapshot_limit none otus filesystem_count none otus snapshot_count none otus snapdev hidden otus acltype off
otus context none otus fscontext none otus defcontext none otus rootcontext none otus relatime off
otus redundant_metadata all
otus overlay off
otus encryption off
otus keylocation none otus keyformat none otus pbkdf2iters 0
otus special_small_blocks 0 [root@zfs ~]# available
default default default -
-
-
-
default default default default default
14592242904030363272 - default
default
-
-
-
-
default
-
default default default default -
-
-
-
default default default default default default default default default default default default default default default default default default default
```
C помощью команды grep можно уточнить конкретный параметр, Размер: zfs get available otus
```
[root@zfs ~]# zfs get available otus NAME PROPERTY VALUE SOURCE
otus available 350M -
```
например:

 Тип: zfs get readonly otus
```
[root@zfs ~]# zfs get readonly otus
NAME PROPERTY VALUE SOURCE
otus readonly off default
```
По типу FS мы можем понять, что позволяет выполнять чтение и запись
Значение recordsize: zfs get recordsize otus 
```
[root@zfs ~]# zfs get recordsize otus
NAME PROPERTY VALUE SOURCE
otus recordsize 128K local
```
Тип сжатия (или параметр отключения): zfs get compression otus 
```
[root@zfs ~]# zfs get compression otus
NAME PROPERTY VALUE SOURCE
otus compression zle local
```
Тип контрольной суммы: zfs get checksum otus 
```
[root@zfs ~]# zfs get checksum otus
NAME PROPERTY VALUE SOURCE
otus checksum sha256 local
```
3. Работа со снапшотом, поиск сообщения от преподавателя
Скачаем файл, указанный в задании:
```
wget -O otus_task2.file --no-check-certificate
‘https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG&e xport=download’
[1] 24521
[root@zfs ~]# --2022-11-27 19:45:09-- https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG Resolving drive.google.com (drive.google.com)... 173.194.220.194, 2a00:1450:4010:c05::c2
Connecting to drive.google.com (drive.google.com)|173.194.220.194|:443... connected.
HTTP request sent, awaiting response... 302 Moved Temporarily Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc 7l7deffksulhg5h7mbp1/839p2prktv7qh7k30c2r5bcjb1q5o26e/1635092850000/161 89157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG [following] Warning: wildcards not supported in HTTP.
--2022-11-27 19:45:12-- https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc 7l7deffksulhg5h7mbp1/839p2prktv7qh7k30c2r5bcjb1q5o26e/1635092850000/161 89157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 209.85.233.132, 2a00:1450:4010:c03::84
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|209.85.233.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: ‘otus_task2.file’
100%[=================================================================== ===================================>] 5,432,736 6.44MB/s in 0.8s

2022-11-27 19:45:16 (6.44 MB/s) - ‘otus_task2.file’ saved [5432736/5432736]
[1]+ Done wget -O otus_task2.file https://drive.google.com/u/0/uc?id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG 
```
Восстановим файловую систему из снапшота: zfs receive otus/test@today < otus_task2.file

Далее, ищем в каталоге /otus/test файл с именем “secret_message”:
```
[root@zfs ~]# find /otus/test -name "secret_message" 
/otus/test/task1/file_mess/secret_message
```
Смотрим содержимое найденного файла:
```
[root@zfs ~]# cat /otus/test/task1/file_mess/secret_message 
https://github.com/sindresorhus/awesome
```
Тут мы видим ссылку на GitHub, можем скопировать её в адресную строку и посмотреть репозиторий.
