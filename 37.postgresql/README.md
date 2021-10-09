## Задание

Администрирование postgres
1. Установить postgres, сделать базовые настройки доступов
2. С помощью mamonsu подогнать конфиг сервера под ресурсы машины
3. Развернуть Barman и настроить резервное копирование postgres 

## Выполнение задания

Так как по best practices бэкап рекомендуется выполнять с реплики, в данном ДЗ развернем три виртуальных машины:
* master (192.168.10.10)
* slave (192.168.10.20)
* barman (192.168.10.30)

### Установка  PostgreSQL

Выполним установку на серверах master, slave и barman.

***1. Установим репозиторий postgres:***

```
[root@master ~]# yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
```
***2. Установим пакет `postgresql12-server`:***

```
[root@master ~]# yum install -y postgresql12-server
```


Предварительно добавим записи в файл `/etc/hosts` на всех серверах:

```
[root@barman ~]# cat /etc/hosts
192.168.10.10	master	master
192.168.10.20	slave	slave
127.0.0.1	barman	barman
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```
```
[root@master ~]# cat /etc/hosts
192.168.10.20	slave	slave
192.168.10.30	barman	barman
127.0.0.1	master	master
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```
```
[root@slave ~]# cat /etc/hosts
192.168.10.10	master	master
192.168.10.30	barman	barman
127.0.0.1	slave	slave
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
```

### Настройка мастера

***1. Инициализация базы:***

Инициализируем базу в директории `/var/lib/pgsql/12/data` с кодировкой UTF8 от имени пользователя postgres (так как postgresql не любит работать от рута). Если в системе нет локали ru_RU, её нужно будет либо установить, либо выбрать другую локаль, например en_US.UTF8:

```
root@master ~]# su postgres -c '/usr/pgsql-12/bin/initdb -D /var/lib/pgsql/12/data -E UTF8 --locale en_US.UTF8'
```
***2. Стартуем сервер postgres:***

```
[root@master ~]# systemctl enable postgresql-12 --now
```
***3. Отредактируем файл  `/var/lib/pgsql/12/data/pg_hba.conf`, отвечающий за способы подключения к базе:***

```
[root@master ~]# cat /var/lib/pgsql/12/data/pg_hba.conf 
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections
host    all             all             0.0.0.0/0            	md5
# replication privilege
host    replication     repler          192.168.10.20/32        md5
host    replication     barman        192.168.10.30/32        md5
```
***4. В файле `/var/lib/pgsql/12/data/postgresql.conf` изменим директиву `listen_addresses`, чтобы база принимала запросы со всех IPv4 адресов:***
  
```
[root@master ~]# grep 'listen_addresses' /var/lib/pgsql/12/data/postgresql.conf 
listen_addresses = '0.0.0.0'		# what IP address(es) to listen on;
```
***5. Создадим администратора баз данных:***

```
[root@master ~]# psql -U postgres postgres
psql (12.4)
Type "help" for help.

postgres=# create role root password 'MyP@ssw0rd' superuser login;
CREATE ROLE
postgres=# \q
```
***6.  Рестартанем сервер postgres:***

```
[root@master ~]# systemctl restart postgresql-12
```
***7. Для подключения к базе от имени пользователя root без ввода пароля в домашней директории рута создадим файл `.pgpass` с правами `600`:***

```
[root@master ~]# cat /root/.pgpass
*:*:*:root:MyP@ssw0rd
[root@master ~]# chmod 600 /root/.pgpass
```
При подключении к postgres необходимо всегда указывать базу, к которой подключаемся. Для возможности запуска от рута утилиты `psql` без указания базы добавим экспортируем переменную окружения `PGDATABASE=postgres`, а также добавим её в файл `/root/.bashrc`, чтобы она сохранилась для новых сессий рута:

```
[root@master ~]# export PGDATABASE=postgres
[root@master ~]# echo export PGDATABASE=postgres >> .bashrc 
```
Проверим:

```
[root@master ~]# psql
psql (12.4)
Type "help" for help.

postgres=# \c
You are now connected to database "postgres" as user "root".
postgres=#
```
***8. Создадим базу с таблицей:***
   
```
root@master ~]# psql
psql (12.4)
Type "help" for help.

postgres=# postgres=# CREATE DATABASE cities;
CREATE DATABASE
postgres=# \c cities 
You are now connected to database "cities" as user "root".
cities=# CREATE TABLE capitals (
cities(# city VARCHAR(80),
cities(# ^C
cities=# CREATE TABLE capitals (
cities(# id int,
cities(# country varchar(80),
cities(# city varchar(80)
cities(# );
CREATE TABLE
cities=# \t
Tuples only is off.
cities=# insert into capitals values (1,'Russia','Moscow'),(2,'Germany','Berlin'),(3,'United Kingdom','London');
INSERT 0 3
cities=# select * from capitals;
id |    country     |  city  
----+----------------+--------
  1 | Russia         | Moscow
  2 | Germany        | Berlin
  3 | United Kingdom | London
(3 rows)

cities=#
```

### Подгоним конфиг сервера под ресурсы машиины с помощью утилиты `mamonsu`

***1. Установим репозиторий:***

```
[root@master ~]# rpm -i https://repo.postgrespro.ru/mamonsu/keys/centos.rpm
```
***2. Установим пакет:***

```
[root@master ~]# yum install -y mamonsu
```
***3. Создадим базу `mamonsu` и непривилегированоого пользователя `mamonsu`:***

```
[root@master ~]# psql
psql (12.4)
Type "help" for help.

postgres=# CREATE USER mamonsu WITH PASSWORD 'mamonsu';
CREATE ROLE
postgres=# CREATE DATABASE mamonsu OWNER mamonsu;
CREATE DATABASE
postgres=# \q
```
***4. Поправим секцию `[postgres]` в конфиге mamonsu `/etc/mamonsu/agent.conf`:***

```
[postgres]
enabled = True
user = mamonsu
password = mamonsu
database = mamonsu
host = localhost
port = 5432
application_name = mamonsu
query_timeout = 10
```

***5. Выполним подготовку mamonsu:***

```
[root@master ~]# yum install -y postgresql12-contrib
[root@master ~]# systemctl start mamonsu
[root@master ~]# mamonsu bootstrap -M mamonsu --dbname mamonsu --username root --password MyP@ssw0rd
Bootstrap successfully completed
```
***6. Выведем параметры конфигурации сисетмы и postgres, которые предалагает настроить mamonsu:***

```
[root@master ~]# mamonsu tune --dry-run d mamonsu -U mamonsu -W mamonsu
INFO:root:dry run (write sysctl vars: /etc/sysctl.conf):
# sysctl settings are defined through files in
# /usr/lib/sysctl.d/, /run/sysctl.d/, and /etc/sysctl.d/.
#
# Vendors settings live in /usr/lib/sysctl.d/.
# To override a whole file, create a new file with the same in
# /etc/sysctl.d/ and put new settings there. To override
# only specific settings, add a file with a lexically later
# name in /etc/sysctl.d/ and put new settings there.
#
# For more information, see sysctl.conf(5) and sysctl.d(5).

#### mamonsu auto tune ####
vm.min_free_kbytes = 50738

INFO:PGSQL-(host=/tmp/.s.PGSQL.5432 db=postgres user=mamonsu port=5432):connecting
INFO:PGSQL-(host=/tmp/.s.PGSQL.5432 db=postgres user=mamonsu port=5432):connected
INFO:root:dry run (query):	alter system set shared_buffers to '248MB';
INFO:root:dry run (query):	alter system set effective_cache_size to '743MB';
INFO:root:dry run (query):	alter system set work_mem to '10MB';
INFO:root:dry run (query):	alter system set maintenance_work_mem to '99MB';
INFO:root:dry run (query):	alter system set autovacuum_max_workers to 20;
INFO:root:dry run (query):	alter system set autovacuum_analyze_scale_factor to 0.01;
INFO:root:dry run (query):	alter system set autovacuum_vacuum_scale_factor to 0.02;
INFO:root:dry run (query):	alter system set vacuum_cost_delay to 1;
INFO:root:dry run (query):	alter system set bgwriter_delay to 10;
INFO:root:dry run (query):	alter system set bgwriter_lru_maxpages to 800;
INFO:root:dry run (query):	alter system set checkpoint_completion_target to 0.75
INFO:root:dry run (query):	alter system set logging_collector to on;
INFO:root:dry run (query):	alter system set log_filename to 'postgresql-%a.log';
INFO:root:dry run (query):	alter system set log_checkpoints to on;
INFO:root:dry run (query):	alter system set log_connections to on;
INFO:root:dry run (query):	alter system set log_disconnections to on;
INFO:root:dry run (query):	alter system set log_lock_waits to on;
INFO:root:dry run (query):	alter system set log_temp_files to 0;
INFO:root:dry run (query):	alter system set log_autovacuum_min_duration to 0;
INFO:root:dry run (query):	alter system set track_io_timing to on;
INFO:root:dry run (query):	alter system set log_line_prefix to '%t [%p]: [%l-1] db=%d,user=%u,app=%a,client=%h ';
INFO:root:dry run (query):	select name from pg_catalog.pg_available_extensions
INFO:root:dry run (query):	alter system set synchronous_commit to off;
INFO:root:dry run (query):	select pg_catalog.pg_reload_conf();
```
***7. Применим эти изменения с помощью mamonsu от имени суперпользователя:***

```
[root@master ~]# mamonsu tune -d mamonsu -U root -W MyP@ssw0rd
```
После выполнения команды эти значения применятся в файле `/var/lib/pgsql/12/data/postgresql.auto.conf`. Параметры этого файла переопределяют те, что указаны в `/var/lib/pgsql/12/data/postgresql.conf`. Вот содержимое файла `/var/lib/pgsql/12/data/postgresql.auto.conf` после выполнения `mamonsu tune`:

```
[root@master ~]# cat /var/lib/pgsql/12/data/postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by the ALTER SYSTEM command.
shared_buffers = '248MB'
effective_cache_size = '743MB'
work_mem = '10MB'
maintenance_work_mem = '99MB'
autovacuum_max_workers = '20'
autovacuum_analyze_scale_factor = '0.01'
autovacuum_vacuum_scale_factor = '0.02'
vacuum_cost_delay = '1'
bgwriter_delay = '10'
bgwriter_lru_maxpages = '800'
checkpoint_completion_target = '0.75'
logging_collector = 'on'
log_filename = 'postgresql-%%a.log'
log_checkpoints = 'on'
log_connections = 'on'
log_disconnections = 'on'
log_lock_waits = 'on'
log_temp_files = '0'
log_autovacuum_min_duration = '0'
track_io_timing = 'on'
log_line_prefix = '%%t [%%p]: [%%l-1] db=%%d,user=%%u,app=%%a,client=%%h '
shared_preload_libraries = 'pg_stat_statements, pg_buffercache'
synchronous_commit = 'off'
```
# ПРОДОЛЖАТЬ ОТСЮДА
### Настроим потоковую репликацию

***1. На **мастере** в файле `postgresql.conf` установим следующие параметры и перезапустим postgresql-12:***

```
max_wal_senders = 3
max_replication_slots = 10
wal_level = replica
hot_standby = on
wal_keep_segments = 128
```

***2. На **мастере** создадим слот репликации с именем `streaming_replication`. Это необходимо делать от пользователя postgres!***

```
[root@master ~]# su - postgres
Last login: Sun Nov  8 12:05:48 UTC 2020 on pts/0
-bash-4.2$ psql
psql (9.2.24, server 12.4)
WARNING: psql version 9.2, server version 12.0.
         Some psql features might not work.
Type "help" for help.

-bash-4.2$ psql -c "SELECT pg_create_physical_replication_slot('streaming_replication');"
 pg_create_physical_replication_slot 
-------------------------------------
 (streaming_replication,)
(1 row)
```

***3. На **мастере** создадим пользователя `repler` с паролем `replpass` для репликации:***

```
-bash-4.2$ psql -c "CREATE ROLE repler WITH LOGIN REPLICATION PASSWORD 'replpass';" 
CREATE ROLE
```
***4. На **слейве** инициализируем базу в директории от имени пользователя postgres :***

```
root@master ~]# su postgres -c '/usr/pgsql-12/bin/initdb -D /var/lib/pgsql/12/data -E UTF8 --locale en_US.UTF8'
```

***5. На **слейве** удалим содержимое директории `/var/lib/pgsql/12/data`:***

```
[root@slave ~]# rm -rf /var/lib/pgsql/12/data/*
```

***6. На **слейве** под пользователем `postgres` создаем файл `.pgpass` (так как homedir'ом для пользователя postgres является /`var/lib/pgsql`, файл создастся здесь) с логином/паролем пользователя `repler` и выполняем копирование базы с мастера:***

```
[root@slave ~]# su - postgres
Last login: Sun Nov  8 13:33:57 UTC 2020 on pts/0
-bash-4.2$ echo "192.168.10.10:5432:*:repler:replpass" > .pgpass
-bash-4.2$ chmod 600 .pgpass
-bash-4.2$ pg_basebackup -h 192.168.10.10 -U repler -D /var/lib/pgsql/12/data -R --slot=streaming_replication -X stream -v
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
pg_basebackup: write-ahead log start point: 0/2000028 on timeline 1
pg_basebackup: starting background WAL receiver
pg_basebackup: write-ahead log end point: 0/2000138
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: syncing data to disk ...
pg_basebackup: base backup completed
```
Так как мы использовали ключ `-R`, все необходимые для репликации параметры на слейве добавились в файл `/var/lib/pgsql/12/data/postgresql.auto.conf`, иначе их пришлось бы прописать вручную. Вот эти параметры:

```
primary_conninfo = 'user=repler passfile=''/var/lib/pgsql/.pgpass'' host=192.168.10.10 port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any'
primary_slot_name = 'streaming_replication'
```

***7. На **слейве** запустим postgres:***

Сначала установим пакет `postgresql12-contrib`, который устанавливали ранее на мастере, без него сервер не стартанет:

```
[root@slave ~]# yum install -y postgresql12-contrib
```

Теперь запустим сервер:

```
[root@slave ~]# systemctl enable postgresql-12.service --now
```

***8. Проверим статус репликации:***

На слейве:

```
[root@slave ~]# su - postgres
Last login: Sun Nov  8 13:43:44 UTC 2020 on pts/0
-bash-4.2$ psql
psql (12.4)
Type "help" for help.

postgres=# \x
Expanded display is on.
postgres=# SELECT * FROM pg_stat_wal_receiver;
-[ RECORD 1 ]---------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pid                   | 4033
status                | streaming
receive_start_lsn     | 0/5000000
receive_start_tli     | 1
received_lsn          | 0/5000148
received_tli          | 1
last_msg_send_time    | 2020-11-08 13:54:08.302126+00
last_msg_receipt_time | 2020-11-08 13:54:08.302402+00
latest_end_lsn        | 0/5000148
latest_end_time       | 2020-11-08 13:50:07.906262+00
slot_name             | streaming_replication
sender_host           | 192.168.10.10
sender_port           | 5432
conninfo              | user=repler passfile=/var/lib/pgsql/.pgpass dbname=replication host=192.168.10.10 port=5432 fallback_application_name=walreceiver sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any
```

На мастере:

```
-bash-4.2$ psql
psql (9.2.24, server 12.4)
WARNING: psql version 9.2, server version 12.0.
         Some psql features might not work.
Type "help" for help.
postgres=# \x
Expanded display is on.
postgres=# SELECT * FROM pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 7914
usesysid         | 16449
usename          | repler
application_name | walreceiver
client_addr      | 192.168.10.20
client_hostname  | 
client_port      | 44928
backend_start    | 2020-11-08 13:50:07.90204+00
backend_xmin     | 
state            | streaming
sent_lsn         | 0/5000148
write_lsn        | 0/5000148
flush_lsn        | 0/5000148
replay_lsn       | 0/5000148
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async
reply_time       | 2020-11-08 13:55:38.426183+00
```

***8. Проверим репликацию:***

**На мастере** в базу `cities` в таблицу `capitals` добавим строку:

```
cities=# SELECT * FROM capitals;
 id |    country     |  city  
----+----------------+--------
  1 | Russia         | Moscow
  2 | Germany        | Berlin
  3 | United Kingdom | London
(3 rows)

ities=# INSERT INTO capitals VALUES (4, 'France', 'Paris');
INSERT 0 1
cities=# SELECT * FROM capitals;
 id |    country     |  city  
----+----------------+--------
  1 | Russia         | Moscow
  2 | Germany        | Berlin
  3 | United Kingdom | London
  4 | France         | Paris
(4 rows)
```

**На слейве** проверим эту таблицу:

```
cities=# SELECT * FROM capitals;
 id |    country     |  city  
----+----------------+--------
  1 | Russia         | Moscow
  2 | Germany        | Berlin
  3 | United Kingdom | London
  4 | France         | Paris
(4 rows)
```
Видим, что репликация отрабатывает нормально.

### Настроим резервное копирование с Barman

***1. **На сервере barman** установим barman:***

```
[root@barman ~]# yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
[root@barman ~]# curl https://dl.2ndquadrant.com/default/release/get/12/rpm | sudo bash
[root@barman ~]# yum install -y barman
```
Основной конфиг barman находится в файле `/etc/barman.conf`:
```
[root@barman ~]# cat /etc/barman.conf | egrep -v '^;|^$'
[barman]
barman_user = barman
configuration_files_directory = /etc/barman.d
barman_home = /var/lib/barman
log_file = /var/log/barman/barman.log
log_level = INFO
compression = gzip
```
Конфиги для бэкапа находятся в директории `/etc/barman.d`, по одному конфигу на каждый сервер, который нужно бэкапить.

Создадим файл `/etc/barman.d/slave.conf` для бэака базы с сервера `slave`. 

***2. **На мастере** создадим пользователя barman с правами суперпользователя и паролем `barmanpass`:***

```
[root@master ~]# su - postgres
Last login: Sun Nov  8 12:28:51 UTC 2020 on pts/0
-bash-4.2$ createuser -s -P barman
Enter password for new role: 
Enter it again:  
```
***3. **На barman** создадим файл `~barman/.pgpass`, куда внесем данные для подключения к мастеру:***

```
[root@barman ~]# su - barman
-bash-4.2$ echo "master:5432:*:barman:barmanpass" > .pgpass
-bash-4.2$ echo "slave:5432:*:barman:barmanpass" >> .pgpass
-bash-4.2$ chmod 600 .pgpass
```
Проверим, что можем подключиться с сервера barman на мастер и слэйв:

```
-bash-4.2$ psql -c '\t' -c 'SELECT version()' -h 192.168.10.10 postgres
Tuples only is on.
 PostgreSQL 12.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red 
Hat 4.8.5-39), 64-bit

-bash-4.2$ psql -c '\t' -c 'SELECT version()' -h 192.168.10.20 postgres
Tuples only is on.
 PostgreSQL 12.4 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red 
Hat 4.8.5-39), 64-bit
```
Как видим, подключение проходит.

***4. **На мастере** создадим пользователя streaming_barman с правами на репликацию и паролем `barmanpass` для возможности резервного копирования с использованием WAL streaming:***

```
-bash-4.2$ createuser -P --replication streaming_barman 
Enter password for new role: 
Enter it again: 
```
***5. **На barman** добавим пользователя в `~barman/.pgpass`:***

```
-bash-4.2$ echo "master:5432:*:streaming_barman:barmanpass" >> .pgpass
-bash-4.2$ echo "slave:5432:*:streaming_barman:barmanpass" >> .pgpass
```

***6. **На мастере и слейве** добавим разрешение на репликацию пользоватлею `streaming_barman`:***

```
[root@master ~]# echo "host    replication     streaming_barman        192.168.10.30/32        md5" >> /var/lib/pgsql/12/data/pg_hba.conf
[root@master ~]# systemctl reload postgresql-12.service
```

Проверим **с barman**, что streaming connection работает:

```
-bash-4.2$ psql -U streaming_barman -h 192.168.10.10 -c "IDENTIFY_SYSTEM" replication=1
      systemid       | timeline |  xlogpos  | dbname 
---------------------+----------+-----------+--------
 6892338350428720853 |        1 | 0/5001EC0 | 
(1 row)

-bash-4.2$ psql -U streaming_barman -h 192.168.10.20 -c "IDENTIFY_SYSTEM" replication=1
      systemid       | timeline |  xlogpos  | dbname 
---------------------+----------+-----------+--------
 6892338350428720853 |        1 | 0/5001EC0 | 
(1 row)
```

***7. Настроим SSH для выполнения WAL archiving через rsync:***

Сгенерируем ssh ключ для пользователя `postgres` **на мастере:**

```
[root@master ~]# su - postgres
Last login: Sun Nov  8 18:38:17 UTC 2020 on pts/0
-bash-4.2$ ssh-keygen -t rsa
```
Сгенерируем ssh ключ для пользователя `postgres` **на слейве:**

```
root@slave ~]# su - postgres
Last login: Sun Nov  8 13:53:32 UTC 2020 on pts/0
-bash-4.2$ ssh-keygen -t rsa
```

Сгенерируем ssh ключ для пользователя `barman` **на barman:**

```
[root@barman ~]# su - barman
Last login: Sun Nov  8 17:40:37 UTC 2020 on pts/0
-bash-4.2$ ssh-keygen -t rsa
```

Далее нужно добавить публичные ключи пользователя `postgres` **с мастера и слейва** в файл `~barman/.ssh/authorized_keys` **на barman**, задав на файл `~barman/.ssh/authorized_keys` права `600`.

Теперь добавим публичный ключ пользователя `barman` **с barman** в файл `~postgres/.ssh/authorized_keys` **на мастере и слейве**, задав на файл `~postgres/.ssh/authorized_keys` права `600`.

При попытке подключения по ssh к серверам **мастер и слейв** под пользователем `postgres` получил ошибку SELinux:

```
type=USER_LOGIN msg=audit(1604865832.079:1530): pid=26847 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:sshd_t:s0-s0:c0.c1023 msg='op=login acct="postgres" exe="/usr/sbin/sshd" hostname=? addr=192.168.10.30 terminal=ssh res=failed'
```

Видимо, это связано с тем, что homedir пользователя postgres расположена по нестандартному для SELinux пути. Проблему решил изменением контекста SELinux директории `/var/lib/pgsql/.ssh/` на `ssh_home_t` (до этого был контекст `postgresql_db_t`):
```
[root@slave ~]# yum install -y policycoreutils-python
[root@slave ~]# semanage fcontext -a -t ssh_home_t '/var/lib/pgsql/.ssh(/.*)?'
[root@slave ~]# restorecon -R -v /var/lib/pgsql/.ssh/
```
***8. Создадим конфигурационный файл barman'а для сервера `slave`:***

Скопируем готовый шаблон и исправим его:

```
[root@barman ~]# cp /etc/barman.d/streaming-server.conf-template /etc/barman.d/slave.conf
[root@barman ~]# cat /etc/barman.d/slave.conf 
[slave]
description =  "Streaming backup with WAL archiving)"
conninfo = host=slave user=barman dbname=postgres
streaming_conninfo = host=slave user=streaming_barman
backup_method = postgres
;streaming_backup_name = barman_streaming_backup
streaming_archiver = on
slot_name = barman
;create_slot = auto
;streaming_archiver_name = barman_receive_wal
;streaming_archiver_batch_size = 50

; PATH setting for this server
;path_prefix = "/usr/pgsql-12/bin"
```

***9.  Создадим слоты репликации с сервера barman:***

Создадим слот для слейва:

```
[root@barman ~]# su - barman
Last login: Sun Nov  8 21:03:45 UTC 2020 on pts/0
-bash-4.2$ barman receive-wal --create-slot slave
Creating physical replication slot 'barman' on server 'slave'
Replication slot 'barman' created
```

Создадим слот для мастера:

```
-bash-4.2$ barman receive-wal --create-slot master
Creating physical replication slot 'barman' on server 'master'
Replication slot 'barman' created
```

Посмотрим **на слейве**, что слот действительно создался:

```
postgres=# SELECT * FROM pg_replication_slots;
-[ RECORD 1 ]-------+---------
slot_name           | barman
plugin              | 
slot_type           | physical
datoid              | 
database            | 
temporary           | f
active              | f
active_pid          | 
xmin                | 
catalog_xmin        | 
restart_lsn         | 
confirmed_flush_lsn | 
```

***10. Выполним архивацию***

Установим пакет `barman-cli` **на мастере и слейве**:

```
[root@slave ~]# yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
[root@slave ~]# curl https://dl.2ndquadrant.com/default/release/get/12/rpm | sudo bash
[root@slave ~]# yum install -y barman-cli
```

**На слейве** проверим, что `barman-wal-archive` может подключиться к серверу `barman`:

```
[root@slave ~]# barman-wal-archive --test barman slave DUMMY

[root@slave ~]# echo $?
0
```

**На слейве** изменим параметры в `postgresql.conf` и перезапустим серевер postgres:

```
archive_mode = on
archive_command = 'barman-wal-archive barman slave %p' 
```

**На мастере** изменим параметры в `postgresql.conf` и перезапустим серевер postgres:

```
archive_mode = on
archive_command = 'barman-wal-archive barman master %p' 
```

**На barman** проверим корректность конфигурации WAL archiving **с мастера**:

```

ssh -o StrictHostKeyChecking=no barman@barman true && /bin/barman-wal-archive barman master %p














команды по реплике/бэкапу (pg_basebackup) в постгресе делаем от имени юзера постгрес! в ансибл это become_user: postgres









  




  










