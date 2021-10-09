## **Задание**

В вагранте поднимаем 2 машины web и log. 
На web поднимаем nginx. 
На log настраиваем центральный лог сервер на любой системе на выбор: 
- journald 
- rsyslog 
- elk 
Настраиваем аудит следящий за изменением конфигов нжинкса.

Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.

* развернуть еще машину elk
И таким образом настроить 2 центральных лог системы elk И какую либо еще.
И elk должны уходить только логи нжинкса, во вторую систему все остальное. 


## **Выполнение задания**

**1. Настроить аудит на изменение конфигов нжинкса.**

Добавляем правила (опция -k задает ключ фильтрации, по которому можно будет отследить события при срабатывании данного правила):
```
[root@web ~]# auditctl -a exit,always -F path=/etc/nginx/nginx.conf -F perm=wa -k nginx_conf
[root@web ~]# auditctl -a exit,always -F path=/etc/nginx/default.d/ -F perm=wa -k nginx_conf
```

Проверяем, что правила добавились:
```
[root@web ~]# auditctl -l
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
```

После ребута сервака все правила, созданные выше пропали. Для перманентного добавления их нужно прописывать в файл `/etc/audit/rules.d/audit.rules`:
```
[root@web ~]# cat /etc/audit/rules.d/audit.rules 
## First rule - delete all
-D

## Increase the buffers to survive stress events.
## Make this bigger for busy systems
-b 8192

## Set failure mode to syslog
-f 1

## Audit of nginx configuration files changes
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d/ -p wa -k nginx_conf
```

После редактирования данного файла нужно рестартануть auditd:
```
[root@web ~]# service auditd restart
Stopping logging:                                          [  OK  ]
Redirecting start to /bin/systemctl start auditd.service
```

Проверяем правила:
```
[root@web ~]# auditctl -l
-w /etc/nginx/nginx.conf -p wa -k nginx_conf
-w /etc/nginx/default.d -p wa -k nginx_conf
```

Изменим порт нжинкса в конфиг-файле и проверим логи auditd:
```
[root@web ~]# ausearch -k nginx_conf
```
<details>
  <summary>Получим следующий вывод:</summary>
```
----
time->Fri Jun 26 20:53:02 2020
type=CONFIG_CHANGE msg=audit(1593204782.188:887): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="nginx_conf" list=4 res=1
----
time->Fri Jun 26 20:53:02 2020
type=PROCTITLE msg=audit(1593204782.188:888): proctitle=2F7573722F62696E2F707974686F6E002F686F6D652F76616772616E742F2E616E7369626C652F746D702F616E7369626C652D746D702D313539333230343738312E35392D31303234362D3135363534333139373139313336342F416E736962616C6C5A5F636F70792E7079
type=PATH msg=audit(1593204782.188:888): item=4 name="/etc/nginx/nginx.conf" inode=11681 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1593204782.188:888): item=3 name="/etc/nginx/nginx.conf" inode=100669342 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1593204782.188:888): item=2 name="/home/vagrant/.ansible/tmp/ansible-tmp-1593204781.59-10246-156543197191364/source" inode=11681 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1593204782.188:888): item=1 name="/etc/nginx/" inode=101417663 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1593204782.188:888): item=0 name="/home/vagrant/.ansible/tmp/ansible-tmp-1593204781.59-10246-156543197191364/" inode=11566 dev=08:01 mode=040700 ouid=1000 ogid=1000 rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1593204782.188:888):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1593204782.188:888): arch=c000003e syscall=82 success=yes exit=0 a0=27044c0 a1=26560e0 a2=7f505bb9a1c8 a3=0 items=5 ppid=2690 pid=2691 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=4 comm="python" exe="/usr/bin/python2.7" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
----
time->Fri Jun 26 20:53:02 2020
type=PROCTITLE msg=audit(1593204782.188:889): proctitle=2F7573722F62696E2F707974686F6E002F686F6D652F76616772616E742F2E616E7369626C652F746D702F616E7369626C652D746D702D313539333230343738312E35392D31303234362D3135363534333139373139313336342F416E736962616C6C5A5F636F70792E7079
type=PATH msg=audit(1593204782.188:889): item=0 name="/etc/nginx/nginx.conf" inode=11681 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1593204782.188:889):  cwd="/home/vagrant"
type=SYSCALL msg=audit(1593204782.188:889): arch=c000003e syscall=189 success=yes exit=0 a0=7f50568a16d4 a1=7f505788ef6a a2=26c38c0 a3=24 items=1 ppid=2690 pid=2691 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts1 ses=4 comm="python" exe="/usr/bin/python2.7" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="nginx_conf"
```

</details>

**2. Отправлять все аудит логи на сервер log.**

Чтобы логи auditd писались на удаленный rsyslog сервер, нужно установить пакет `audispd-plugins` как на клиент web, так и на сервер log. Затем изменить следующие опции в конфиг файлах:

- в файле `/etc/audisp/audisp-remote.conf`:
```
	remote_server = 192.168.10.20
	port = 514
```
- в файле `/etc/audisp/plugins.d/au-remote.conf`:
```
	active = yes
```
- в файле /etc/audit/auditd.conf:
```
	write_logs = no # чтобы логи не писались локально, а только на удаленный сервер
```
На самом сервере log разрешить прием логов в файле `/etc/rsyslog.conf`:
```
	# Provides UDP syslog reception
	$ModLoad imudp
	$UDPServerRun 514

	# Provides TCP syslog reception
	$ModLoad imtcp
	$InputTCPServerRun 514
```

Изменим порт нжинкса в конфиг-файле и проверим логи auditd:
```
[root@log ~]# ausearch -i -k nginx_conf
```
<details>
  <summary>Получим следующий вывод:</summary>
```
----
node=web type=CONFIG_CHANGE msg=audit(07/01/20 14:16:13.346:6399) : auid=vagrant ses=12 op=updated_rules path=/etc/nginx/nginx.conf key=nginx_conf list=exit res=yes 
----
node=web type=PROCTITLE msg=audit(07/01/20 14:16:13.346:6400) : proctitle=/usr/bin/python /home/vagrant/.ansible/tmp/ansible-tmp-1593602172.7-30727-97237636773552/AnsiballZ_copy.py 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6400) : item=4 name=/etc/nginx/nginx.conf inode=4990227 dev=08:01 mode=file,644 ouid=root ogid=root rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=CREATE cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6400) : item=3 name=/etc/nginx/nginx.conf inode=33706741 dev=08:01 mode=file,644 ouid=root ogid=root rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6400) : item=2 name=/home/vagrant/.ansible/tmp/ansible-tmp-1593602172.7-30727-97237636773552/source inode=4990227 dev=08:01 mode=file,644 ouid=root ogid=root rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=DELETE cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6400) : item=1 name=/etc/nginx/ inode=67687750 dev=08:01 mode=dir,755 ouid=root ogid=root rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6400) : item=0 name=/home/vagrant/.ansible/tmp/ansible-tmp-1593602172.7-30727-97237636773552/ inode=4990221 dev=08:01 mode=dir,700 ouid=vagrant ogid=vagrant rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=PARENT cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=CWD msg=audit(07/01/20 14:16:13.346:6400) :  cwd=/home/vagrant 
node=web type=SYSCALL msg=audit(07/01/20 14:16:13.346:6400) : arch=x86_64 syscall=rename success=yes exit=0 a0=0xda65e0 a1=0xccf4b0 a2=0x7f5c0adbc1c8 a3=0x0 items=5 ppid=13375 pid=13376 auid=vagrant uid=root gid=root euid=root suid=root fsuid=root egid=root sgid=root fsgid=root tty=pts1 ses=12 comm=python exe=/usr/bin/python2.7 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key=nginx_conf 
----
node=web type=PROCTITLE msg=audit(07/01/20 14:16:13.346:6401) : proctitle=/usr/bin/python /home/vagrant/.ansible/tmp/ansible-tmp-1593602172.7-30727-97237636773552/AnsiballZ_copy.py 
node=web type=PATH msg=audit(07/01/20 14:16:13.346:6401) : item=0 name=/etc/nginx/nginx.conf inode=4990227 dev=08:01 mode=file,644 ouid=root ogid=root rdev=00:00 obj=unconfined_u:object_r:user_home_t:s0 objtype=NORMAL cap_fp=none cap_fi=none cap_fe=0 cap_fver=0 
node=web type=CWD msg=audit(07/01/20 14:16:13.346:6401) :  cwd=/home/vagrant 
node=web type=SYSCALL msg=audit(07/01/20 14:16:13.346:6401) : arch=x86_64 syscall=lsetxattr success=yes exit=0 a0=0x7f5c05ae9a94 a1=0x7f5c06ab0f6a a2=0xce7210 a3=0x24 items=1 ppid=13375 pid=13376 auid=vagrant uid=root gid=root euid=root suid=root fsuid=root egid=root sgid=root fsgid=root tty=pts1 ses=12 comm=python exe=/usr/bin/python2.7 subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key=nginx_conf
```

</details>


**3. Критичные логи оставляем на web и отправляем на log.**

В `/etc/rsyslog.conf` в раздел `#### RULES ####` добавляем следующие строки для отправки всех критических сообщений на сервер log:
```
*.crit action(type="omfwd" target="192.168.10.20" port="514" protocol="tcp"
              action.resumeRetryCount="100"
              queue.type="linkedList" queue.size="10000")
```

**4. Все логи нжинкса отправляем на log, критичные также оставляем на web.**

В конфиг nginx добавляем следующие строки:
```
error_log /var/log/nginx/error.log crit;
error_log syslog:server=192.168.10.20:514,tag=nginx_error;
...
access_log syslog:server=192.168.10.20:514,tag=nginx_access;

```

На сервере log для разделения логов `nginx_access` и `nginx_error` по отдельным директориям в `/etc/rsyslog.conf` доавлены следующие правила:
```
if ($hostname == 'web') and ($programname == 'nginx_access') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_access.log")
    stop
}

if ($hostname == 'web') and ($programname == 'nginx_error') then {
    action(type="omfile" file="/var/log/rsyslog/web/nginx_error.log")
    stop
}
```

## **ELK**

**1. Все логи нжинкса, пришедшие на log, отправляем на elk.**

Установим Java:
```
[root@elk ~]# yum install -y java-1.8.0-openjdk
```

Добавим репозиторий. Для этого создадим файл `elasticsearch.repo` в директории `/etc/yum.repos.d/` со следующим содержанием:
```
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

***Установка elasticsearch:***
```
[root@elk ~]# yum -y install elasticsearch
```

Исправим конфиг файл `etc/elasticsearch/elasticsearch.yml`:
```
network.host: 127.0.0.1
```

Настройка выделения памяти для работы базы:
```
[root@elk ~]# cat /etc/elasticsearch/jvm.options
-Xms1g
-Xmx1g
```

Проверка работы базы данных (Базу проверял после провиженинга ансиблом, то есть логи с логстэша уже успели прилететь, сформировав индекс со статусом yellow. Если устанавливать все вручную, в порядке, описанном здесь, то логстэш еще не установлен, и индексов со статусом yellow нет):
```
[root@elk ~]# curl -XGET localhost:9200/_cat/health?v
epoch      timestamp cluster       status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1593608268 12:57:48  elasticsearch yellow          1         1      7   7    0    0        1             0                  -                 87.5%
```

Статус `yellow` вызван тем, что в настройках индекса, созданного для логов nginx, установлено количество реплик 1 (по факту у нас нет реплик, хост с elasticsearch  всего один):
```
[root@elk ~]# curl -XGET localhost:9200/_cat/indices?v
health status index                          uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .kibana-event-log-7.8.0-000001 ZIhrxC_EQg2JK9oK_NrO-Q   1   0          1            0      5.3kb          5.3kb
green  open   .apm-custom-link               3YKYTQgrTRySWdWLbZDnvA   1   0          0            0       208b           208b
green  open   .kibana_task_manager_1         80qbvzfoR8GNjpUvetbt0w   1   0          5            5     55.1kb         55.1kb
green  open   .apm-agent-configuration       jwEVmcU0QD66QHMA5eOJgA   1   0          0            0       208b           208b
yellow open   nginx-2020.07.01               euh8qsQgRmmit3gF9_1JYQ   1   1          3            0     58.8kb         58.8kb
green  open   .kibana_1                      HGXsiTPtQcyfQl35jQk2_A   1   0          4            0     28.5kb         28.5kb
```

Чтобы во всех шаблонах, по которым создаются индексы, поменять кол-во реплик на 0, нужно выполнить следующий запрос с указанием параметра `numbers_of_replicas`:
```
curl -XPUT "localhost:9200/_template/all" -H 'Content-Type: application/json' -d'
{
  "template": "*",
  "settings": {
    "number_of_replicas": 0
  }
}'
```

Но так как от logstash'а уже прилетели логи в elasticsearch, индекс создался из дефолтного шаблона с кол-вом реплик 1. Изменим кол-во реплик для индекса `nginx-2020.07.01`:
```
[root@elk ~]# curl -XPUT "localhost:9200/nginx-2020.07.01/_settings" -H 'Content-Type: application/json' -d'
{
  "template": "*",
  "settings": {
    "number_of_replicas": 0
  }
}'
```

Проверим статус индексов:
```
[root@elk ~]# curl -XGET localhost:9200/_cat/indices?v
health status index                          uuid                   pri rep docs.count docs.deleted store.size pri.store.size
green  open   .kibana-event-log-7.8.0-000001 ZIhrxC_EQg2JK9oK_NrO-Q   1   0          1            0      5.3kb          5.3kb
green  open   .apm-custom-link               3YKYTQgrTRySWdWLbZDnvA   1   0          0            0       208b           208b
green  open   .kibana_task_manager_1         80qbvzfoR8GNjpUvetbt0w   1   0          5            5     25.8kb         25.8kb
green  open   .apm-agent-configuration       jwEVmcU0QD66QHMA5eOJgA   1   0          0            0       208b           208b
green  open   nginx-2020.07.01               euh8qsQgRmmit3gF9_1JYQ   1   0          3            0     58.8kb         58.8kb
green  open   .kibana_1                      HGXsiTPtQcyfQl35jQk2_A   1   0          4            0     28.5kb         28.5kb
```

И статус базы:
```
[root@elk ~]# curl -XGET localhost:9200/_cat/health?v
epoch      timestamp cluster       status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
1593608820 13:07:00  elasticsearch green           1         1      7   7    0    0        0             0                  -                100.0%
```

Теперь все green.

***Установка logstash:***
```
[root@elk ~]# yum install -y logstash
```

Конфигурация входных данных logstash `/etc/logstash/conf.d/02-beats-input.conf`:
```
input {
    beats {
        host => "192.168.10.30"
        port => "5044"
    }
}
```

Конфигурация фильтра обработки логов nginx `/etc/logstash/conf.d/10-nginx-filter.conf`:
```
filter {
    if [fields][service] == "nginx_access" {
        grok {
            match => { "message" => "%{SYSLOGTIMESTAMP:syslog_time} %{SYSLOGHOST:syslog_host}+ %{SYSLOGPROG:syslog_program} %{IPORHOST:clientip} %{DATA:user} %{DATA:auth} \[%{HTTPDATE:access_time}\] \"%{WORD:http-method} %{URIPATHPARAM:request} HTTP/%{NUMBER:httpversion}\" %{NUMBER:response_code} %{NUMBER:sent_bytes} \"%{DATA:referrer}\" \"%{DATA:agent}\"" }
        }
    } 
    
    else if [type] == "nginx_error" {
        grok {
            match => { "message" => "%{SYSLOGTIMESTAMP:syslog_time} %{SYSLOGHOST:syslog_host}+ %{SYSLOGPROG:syslog_program} (?<timestamp>%{YEAR}[./-]%{MONTHNUM}[./-]%{MONTHDAY}[- ]%{TIME}) \[%{LOGLEVEL:severity}\] %{POSINT:pid}#%{NUMBER:tid}: %{GREEDYDATA:errormessage}, client: (?<client>%{IP}|%{HOSTNAME}), server: (?<server>%{IP}|%{USERNAME}), request: %{QS:request}, host: %{QS:host}" }
        }
    }

    date {
          match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
    }
}
```

Конфигурация выходного потока logstash `/etc/logstash/conf.d/20-output.conf` (отправляем все в индекс nginx, создающийся каждый день заново):
```
output {
    if [fields][service] == "nginx_access" {
        elasticsearch {
            hosts => "localhost:9200"
            index => "nginx-%{+YYYY.MM.dd}"
        }
    }
    if [fields][service] == "nginx_error" {
        elasticsearch {
            hosts => "localhost:9200"
            index => "nginx-%{+YYYY.MM.dd}"
        }
    }
}
```

Проверка синтаксиса конфигов logstash:
```
[root@elk ~]# /usr/share/logstash/bin/logstash -t -f /etc/logstash/conf.d/ --path.settings /etc/logstash
Sending Logstash logs to /var/log/logstash which is now configured via log4j2.properties
[2020-07-01T16:23:11,827][WARN ][logstash.config.source.multilocal] Ignoring the 'pipelines.yml' file because modules or command line options are specified
[2020-07-01T16:23:13,452][INFO ][org.reflections.Reflections] Reflections took 38 ms to scan 1 urls, producing 21 keys and 41 values 
Configuration OK
[2020-07-01T16:23:13,951][INFO ][logstash.runner          ] Using config.test_and_exit mode. Config Validation Result: OK. Exiting Logstash
```

***Установка filebeat:***

На сервере log добавим репозиторий. Для этого создадим файл `elasticsearch.repo` в директории `/etc/yum.repos.d/` со следующим содержанием:
```
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
```

Установим filebeat:
```
[root@log ~]# yum install -y filebeat
```

Конфиг filebeat'a `/etc/filebeat/filebeat.yml` для отправки логов nginx в logstash на сервере elk:
```
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/rsyslog/web/nginx_access.log
  fields:
    service: nginx_access
    fields_under_root: true
    scan_frequency: 2s

- type: log
  enabled: true
  paths:
    - /var/log/rsyslog/web/nginx_error.log
  fields:
    service: nginx_error
    fields_under_root: true
    scan_frequency: 2s

output.logstash:
  hosts: ["192.168.10.30:5044"]
```

***Установка kibana:***
```
[root@elk ~]# yum install -y kibana
```

Визуализация логов:

![alt text](./kibana.png)


## **Проверка ДЗ**

1. Выполнить `vagrant up`.
2. В `./web/vars/main.yml` изменить порт nginx, выполнить `ansible-playbook logging.yml`. Проверить, что логиги аудита с сервера web (192.168.10.10) попали на сервер log (192.168.10.20) - для этого выполнить `ausearch -i -k nginx_conf`
3. Для проверки визуализации в Kibana выпонить несколько запросов к http://192.168.10.10 (это дефолтная и единственная страница на сервере). Затем зайти в Kibana на http://192.168.10.30:5601/ и добавить индекс nginx-* для просмотра логов nginx с сервера web.






