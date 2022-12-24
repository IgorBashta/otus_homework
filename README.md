# lesson 18 docker

Образ nginx igorbashta/nginx:nginx собран из dockerfile в корне репозитория.

```
docker build . -t nginx
docker image tag nginx igorbashta/nginx:nginx
docker image push igorbashta/nginx:nginx
docker run -d -p 80:80 nginx
```

Образ - это набор файлов, а контейнер - это процесс, запущевенный в ОС с использованием этих файлов. 
В контейнере можно собрать ядро. https://github.com/a13xp0p0v/kernel-build-containers/blob/master/Dockerfile
