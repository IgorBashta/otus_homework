# MySQL: Backup + Репликация 

## Задание.

В материалах приложены ссылки на вагрант для репликации и дамп базы bet.dmp
Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
| bookmaker |
| competition |
| market |
| odds |
| outcome

Настроить GTID репликацию
x
варианты которые принимаются к сдаче
рабочий вагрантафайл
скрины или логи SHOW TABLES
конфиги
пример в логе изменения строки и появления строки на реплике

## Решение 
Стенд с вм мастера и реплики разворачивается командой ```vagrant up```

```
igorbashta@NB-BASHTA:~/otus/otus_homework$ vagrant ssh master
Last login: Mon Dec 26 13:39:30 2022 from 10.0.2.2
[vagrant@master ~]$ sudo -i
[root@master ~]# cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
1o_>arufSyse
[root@master ~]# mysql -u root -p
Enter password: 
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.40-43-log

mysql> ALTER USER USER() IDENTIFIED BY '1o_>arufSyse';
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
1 row in set (0.00 sec)

mysql> CREATE DATABASE bet;
Query OK, 1 row affected (0.00 sec)

mysql> Bye
[root@master ~]#  mysql -u root -p -D bet < /vagrant/bet.dmp
Enter password: 
[root@master ~]# mysql -u root -p
Enter password: 

mysql> USE bet;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
7 rows in set (0.00 sec)

mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
1 row in set (0.00 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl' IDENTIFIED BY '!OtusLinux2018';
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');
Query OK, 1 row affected (0.01 sec)

```
Во второй консоли
````
igorbashta@NB-BASHTA:~/otus/otus_homework$ vagrant ssh slave
Last login: Mon Dec 26 13:40:01 2022 from 10.0.2.2
[vagrant@slave ~]$ sudo -i
[root@slave ~]# cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
MMO,6wyHal&I
[root@slave ~]# mysql -u root -p
Enter password: 

mysql> ALTER USER USER() IDENTIFIED BY '1o_>arufSyse';
Query OK, 0 rows affected (0.01 sec)

mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+
1 row in set (0.00 sec)

mysql> CHANGE MASTER TO MASTER_HOST = "192.168.11.150", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2018", MASTER_AUTO_POSITION = 1;
Query OK, 0 rows affected, 2 warnings (0.03 sec)

mysql> START SLAVE;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> show slave status \G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 119848
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 120061
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 119848
              Relay_Log_Space: 120268
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: ba2000b1-8522-11ed-9c9e-5254004d77d3
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: ba2000b1-8522-11ed-9c9e-5254004d77d3:1-40
            Executed_Gtid_Set: ba1b8e90-8522-11ed-9d37-5254004d77d3:1-2,
ba2000b1-8522-11ed-9c9e-5254004d77d3:1-40
                Auto_Position: 1
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
1 row in set (0.00 sec)

ERROR: 
No query specified

```
Проверка insert на мастере select на слейве
```
mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(0,'bashta');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  7 | bashta         |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
6 rows in set (0.00 sec)
```
