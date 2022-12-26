# PostgreSQL. Backup + Репликация

## Задание

настроить hot_standby репликацию с использованием слотов
настроить правильное резервное копирование
Для сдачи работы присылаем ссылку на репозиторий, в котором должны обязательно быть
Vagranfile (2 машины)
плейбук Ansible
конфигурационные файлы postgresql.conf, pg_hba.conf и recovery.conf,
конфиг barman, либо скрипт резервного копирования.
Команда "vagrant up" должна поднимать машины с настроенной репликацией и резервным копированием.
Рекомендуется в README.md файл вложить результаты (текст или скриншоты) проверки работы репликации и резервного копирования.

## Решение

Стенд разворачивается командой ```vagrant up```

Проверяю статус репликации на мастере и создаю тестовую базу.

```
[root@master vagrant]# echo "select * from pg_replication_slots;"|sudo -u postgres psql
 slot_name  | plugin | slot_type | datoid | database | temporary | active | active_pid | xmin | catalog_xmin | restart_lsn | confirmed_flush_lsn | wal_status | safe_wal_size | two_phase 
------------+--------+-----------+--------+----------+-----------+--------+------------+------+--------------+-------------+---------------------+------------+---------------+-----------
 pgstandby1 |        | physical  |        |          | f         | t      |       5085 |  736 |              | 0/E0000C8   |                     | reserved   |               | f
 barman     |        | physical  |        |          | f         | t      |       5089 |      |              | 0/E000000   |                     | reserved   |               | f
(2 rows)
[root@master vagrant]# echo "CREATE DATABASE repltest ENCODING='UTF8';"|sudo -u postgres psql
CREATE DATABASE

```

Проверяю статус WAL на реплике и наличие новой базы.

```
postgres=# select * from pg_stat_wal_receiver;
 pid  |  status   | receive_start_lsn | receive_start_tli | written_lsn | flushed_lsn | received_tli |      last_msg_send_time      |     last_msg_receipt_time     | latest_end_lsn |       latest_end_tim
e        | slot_name  |  sender_host   | sender_port |                                                                                                                                        conninfo     
                                                                                                                                   
------+-----------+-------------------+-------------------+-------------+-------------+--------------+------------------------------+-------------------------------+----------------+---------------------
---------+------------+----------------+-------------+-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
 4678 | streaming | 0/3000000         |                 1 | 0/100000C8  | 0/100000C8  |            1 | 2022-12-26 14:50:07.17523+00 | 2022-12-26 14:50:07.175474+00 | 0/100000C8     | 2022-12-26 14:50:07.
17523+00 | pgstandby1 | 192.168.11.150 |        5432 | user=repluser password=******** channel_binding=prefer dbname=replication host=192.168.11.150 port=5432 fallback_application_name=walreceiver sslmod
e=prefer sslcompression=0 sslsni=1 ssl_min_protocol_version=TLSv1.2 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
(1 row)

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 repltest  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)

```

Проверяю наличие бэкапа и пробую восстановиться.

```
t=# drop database postgres;
DROP DATABASE
t=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 t         | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)

[root@backup ~]# barman recover pg 20221226T151002 /var/lib/pgsql/14/data/ --remote-ssh-comman "ssh postgres@192.168.11.150"
postgres@192.168.11.150's password:
postgres@192.168.11.150's password:
Starting remote restore for server pg using backup 20221226T151002
Destination directory: /var/lib/pgsql/14/data/

[root@master vagrant]# # systemctl restart postgresql-14.service
[root@master vagrant]# # su postgres
bash-4.2$ psql
psql (14.5)
Type "help" for help.
postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+----------+----------+-------------+-------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(3 rows)
```
