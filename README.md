# LDAP

Стенд с FreeIPA сервером и клиентом разворачивается командой ```vagrant up```

```
igorbashta@NB-BASHTA:~/otus/otus_homework$  vagrant ssh ldapclient
Last login: Mon Dec 26 11:47:51 2022 from 10.0.2.2
[vagrant@ldapclient ~]$ hostname
ldapclient.otusldap.test
[vagrant@ldapclient ~]$ sudo -i
[root@ldapclient ~]# ssh ldapclient@ldapclient.otusldap.test
-sh-4.2$ kinit admin
Password for admin@OTUSLDAP.TEST: 
-sh-4.2$ ipa user-find ldapclient
--------------
1 user matched
--------------
  User login: ldapclient
  First name: ldap
  Last name: client
  Home directory: /home/ldapclient
  Login shell: /bin/sh
  Principal name: ldapclient@OTUSLDAP.TEST
  Principal alias: ldapclient@OTUSLDAP.TEST
  Email address: ldapclient@otusldap.test
  UID: 110400001
  GID: 110400001
  SSH public key fingerprint: SHA256:42VefpNaIoYuYQulDkCeyyDk9Ys0sqcbfvFlmOsU3uw ldapclient@otusldap.test (ssh-rsa)
  Account disabled: False
----------------------------
Number of entries returned 1
----------------------------
```
