Предварительные действия

Были установлены и настроены git , vagrant, virtualbox, packer. Завел аккаунты на github.com и vagrantup.com

Выполнение
.
выполнил команды для герерации ключа для ssh доступа к github
ssh-keygen -t rsa -b 4096 -C "pavlik.marozov@gmail.com" 
ввел имя файла и passphrase

ssh-add ~/.ssh/pub_key
запустил ssh агент добавил в него ключ. Так же, отрыл редактором полученный файл и добавил ключ в аккаунт github.

зашел по предложенной ссылке https://github.com/dmitry-lyutenko/manual_kernel_update и сделал форк репозитория. далее в git-bash
git clone git@github.com:marozov/manual_kernel_update.git
ввел passphrase ключа, репозиторий скачался на мой пк. Перешел в скачанную директорию

cd manual_kernel_update
запустил vagrant

vagrant up
далее подключился к созданной виртуальной машине

vagrant ssh
Подключил репозиторий указанный в задании и выполнил команду для установки ядра

sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum --enablerepo elrepo-kernel install kernel-ml -y
Далее настройка загрузчика и выбор по умолчанию загрузки с новым ядром

sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
Перезагружаем VM

sudo reboot
Подключился к по ssh и проверил, что ядро обновилось

vagrant ssh
uname -r
вывод
6.0.10-1.el7.elrepo.x86_64

Обновил конфиг пакер, так как свежая версия выдавала ошибку с centos.json

packer fix centos.json > cent6.json
При выполнении build возникла проблема с правами суперпользователя, в файл vagrant.ks внес изменения добавил

echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
закомментировал строки

#cat > /etc/sudoers.d/vagrant << EOF_sudoers_vagrant
#vagrant        ALL=(ALL)       NOPASSWD: ALL
выполнил команду для сборки box файла

packer build cent5.json
Packer отработал без ошибок за 20 мин. на выходе был получен файл centos-7-kernel-6 centos-7.7.1908-kernel-6.0-x86_64-Minimal.box Добавил его в vagrant

vagrant box add --name centos-7-kernel-6 centos-7.7.1908-kernel-6.0-x86_64-Minimal.box
проверил, что образ добавлен

vagrant box list
в списке образ присутствует. Далее поменял в исходном vagrant файле имя образа на centos-7-kernel-6 выполнил команду

vagrant reload
Через 2 минуты подключился к по ssh и проверил, что образ верный

vagrant ssh
uname -r
Ответ команды

6.0.10-1.el7.elrepo.x86_64
Далее аутентификация в сервисе vagrant

vagrant cloud auth login
В ЛК vagrant на вкладке security появился соотвествующий токен. далее публикация образа

vagrant cloud publish --release bashta/centos-7-kernel-6 1.0 virtualbox centos-7.7.1908-kernel-6.0-x86_64-Minimal.box
Как итог получил образ в облаке https://app.vagrantup.com/marozov/boxes/centos-7-kernel-6.0 Поменял имя в vagrant файле на bashta/centos-7-kernel-6 выполнил команду

vagrant destroy
Очистил кэш packer и удалил box файл. далее протестировал образ.

vagrant up
через 10-15 минут подключился и проверил работу VM. после сделал пуш git через git desctop присвоив имя коммиту. Посмотрел изменения в репозитории на сайте.
