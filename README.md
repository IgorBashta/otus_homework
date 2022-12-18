# Тема: Процессы и ionice

## Задача:
Реализовать 2 (сдемаем 4, чтобы лучше разобраться) конкурирующих процесса по IO. пробовать запустить с разными ionice

## Провиженинг
При провиженинге необходимо задать тип очереди CFQ, иначе ionice не рабоает.
Соответствующая команда прописана в Vagrantfile

## Запуск
После запуска ВМ, необходимо залогинитьcя на ВМ и запустить через sudo скрипт /vagrant/copy.sh

## Описание скрипта
Скрипт создаст сэмпл - файл размером 20 МБ, заполненный нулями.
Далее скрипт копирует через dd 4 файла с разными классами и приоритетами, заданными через ionice.
Время выполнения замеряется с помощью time

## Результат
Вывод результата осуществляется прямо в терминал
```
[vagrant@bash ~]$ sudo sh /vagrant/copy.sh 
creating a 20MB sample file
10+0 records in
10+0 records out
20971520 bytes (21 MB) copied, 0.0225156 s, 931 MB/s
start to copy with class 3 (idle)
start to copy with class 1 (realtime) priority 0
start to copy with class 1 (realtime) priority 7
start to copy with class 2 (best effort - standard) priority 0
40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 5.57379 s, 3.8 MB/s

real	0m5.583s
user	0m0.000s
sys	0m3.457s
ionice with class 1 (realtime) priority 0 finished
====================================
 3488 pts/0    D+     0:00 dd if=/tmp/file.dd of=/tmp/file2-0.dd iflag=direct
 3489 pts/0    D+     0:00 dd if=/tmp/file.dd of=/tmp/file3.dd iflag=direct
 3491 pts/0    D+     0:03 dd if=/tmp/file.dd of=/tmp/file1-7.dd iflag=direct
 3493 pts/0    R+     0:00 grep iflag
[vagrant@bash ~]$ 40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 9.3985 s, 2.2 MB/s

real	0m9.409s
user	0m0.000s
sys	0m3.447s
ionice with class 1 (realtime) priority 7 finished
====================================
40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 14.0193 s, 1.5 MB/s

real	0m14.031s
user	0m0.000s
sys	0m3.418s
ionice with class 2 (best effort) priority 0 finished
====================================
40960+0 records in
40960+0 records out
20971520 bytes (21 MB) copied, 18.6605 s, 1.1 MB/s

real	0m18.670s
user	0m0.003s
sys	0m3.700s

ionice with class 3 (idle) finished
====================================
```
