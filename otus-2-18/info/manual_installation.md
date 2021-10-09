***1. Установка и запуск сервиса mysql:***
```
yum install -y wget
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
yum localinstall -y mysql80-community-release-el7-3.noarch.rpm
yum install -y mysql-server && systemctl enable --now mysqld
```
***2. Установка и запуск сервиса nginx:***
```
yum install -y epel-release && yum install -y nginx
```
***3. Установка пакета конфигурации репозитория:***
```
rpm -Uvh https://repo.zabbix.com/zabbix/4.4/rhel/7/x86_64/zabbix-release-4.4-1.el7.noarch.rpm
```
***4. Веб-интерфейс Zabbix требует дополнительные пакеты, которые отсутствуют в базовой установке. Необходимо активировать репозиторий опциональных rpm пакетов в системе, где запускается веб-интерфейс Zabbix:***
```
yum-config-manager --enable rhel-7-server-optional-rpms
```
***5. Установки сервера с поддержкой MySQL/Nginx:***
```
yum install -y zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf
```
***6. Узнаем рутовый пароль mysql и переназначим его:***
```
grep 'temporary password' /var/log/mysqld.log
```
Получим следующий вывод с временным сгенерированным паролем:
```
2020-05-06T13:41:05.562520Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: a1KQuWqL.aRH
```
Запустим скрипт начальной настройки mysql, зададим пароль, к примеру, 'P@ssw0rd', и ответим утвердительно на все оставшиеся вопросы:
```
mysql_secure_installation
```
***7. Для нормальной работы Zabbix сервера с MySQL базой данных требуются кодировка utf8 и utf8_bin тип сравнения. Также создадим пользователя zabbix с паролем zabbix:***
```
mysql -uroot -pP@ssw0rd
mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'Z@bbixx1';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> ALTER USER 'zabbix'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Z@bbixx1';
mysql> quit;
```
***8. Теперь нужно импортировать изначальную схему и данные сервера на MySQL:***
```
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix
```
После ввода этой команды нужно ввести пароль 'Z@bbixx1' от созданной базы данных.

***9. Изменим zabbix_server.conf для использования соответствующей им базы данных:***
```
vi /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=Z@bbixx1
```
***10. Пакет zabbix-nginx-conf устанавливает отдельный Nginx сервер для Zabbix веб-интерфейса. Его файл конфигурации /etc/nginx/conf.d/zabbix.conf. Чтобы Zabbix веб-интерфейс заработал, нужно раскомментировать и задать директивы listen и/или server_name:***
```
vi /etc/nginx/conf.d/zabbix.conf

# listen 80;
# server_name example.com;
```
***11. Отредактируем файл конфигурации php-fpm /etc/php-fpm.d/zabbix.conf. Некоторые настройки PHP уже выполнены. Также в этом файле необходимо указать корректное значение date.timezone:***
```
user = nginx
group = nginx

php_value[max_execution_time] = 300
php_value[memory_limit] = 128M
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 2M
php_value[max_input_time] = 300
php_value[max_input_vars] = 10000
php_value[date.timezone] = Europe/Moscow
```
***12. По дефолту zabbix использует apache, но так как мы используем nginx, нужно переопределить владельца для следующих каталогов:***
```
chown -R nginx. /etc/zabbix/web/
chown -R nginx. /usr/share/zabbix/
chown -R nginx. /var/lib/php/session
```
***13. Установим в системе верный часовой пояс, чтобы время было точным:***
```
timedatectl set-timezone Europe/Moscow
```
***14. Запуск необходимых сервисов:***
```
systemctl enable --now zabbix-server nginx php-fpm
```
***15. SELinux блокирует создание соккета сервисом zabbix. Для разрешения проблемы установим пакет policycoreutils-python и создадим необходимое разрешающее правило политики SELinux на основе записей в логе /var/log/audit/audit.log:***
```
yum install -y policycoreutils-python
```
На основе лога SELinux создадим разрешающий модуль для zabbix:
```
cat /var/log/audit/audit.log  | grep zabbix_server | grep denied | audit2allow -M zabbix_service
```
Инсталлируем созданный модуль:
```
semodule -i zabbix_service.pp
```
Запустим сервис zabbix:
```
systemctl start zabbix-server
```
***16. Далее отредактируем конфигурационный файл /etc/nginx/nginx.conf (примеры файлов окнфигурации в каталоге configfiles), перечитаем конфигурацию nginx (systemctl reload nginx) и зайдем в вэб-интерфейс: http://192.168.11.200/setup.php для настройки zabbix.***

***17. После начальной настройки zabbix возникла проблема с SELinux и php-fpm при обращении последнего на порт 10051. Проблему решил также с помощью создания разрешающего модуля:***
```
cat /var/log/audit/audit.log | grep php-fpm | grep denied | audit2allow -M php-fpm_service

semodule -i php-fpm_service.pp

systemctl restart php-fpm.service
```
***18. Установим на второй хост zabbix agent и запустим его:***
```
yum install -y zabbix-agent && systemctl enable --now zabbix-agent
```
***19. Установим верный часовой пояс:***
```
timedatectl set-timezone Europe/Moscow
```
***20. Редактируем файл конфигурации агента /etc/zabbix/zabbix_agentd.conf:***
```
Server=192.168.11.200
ListenPort=10050
ListenIP=192.168.11.210
ServerActive=192.168.11.200
Hostname=monagent
```
И перезапустим сервис zabbix-agent

***21. Далее в панели zabbix на серере monserver добавляем хост monagent.***

