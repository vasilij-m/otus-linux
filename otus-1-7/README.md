***После команды `vagrant up` для проверки ДЗ минут 5-10 займет скачивание Jira, в это время на экране будут пробегать сообщения от systemd с прогрессом скачивания.***

**1. Создать сервис и unit-файлы для этого сервиса:**
- сервис: bash, python или другой скрипт, который мониторит log-файл на наличие ключевого слова;
- ключевое слово и путь к log-файлу должны браться из /etc/sysconfig/ (.service);
- сервис должен активироваться раз в 30 секунд (.timer).
```
[vagrant@systemd ~]$ sudo -i
```
Создаем для нашего сервиса конфиг-файл следующего содержания:
```
[root@systemd ~]# cat /etc/sysconfig/watchlog
#Config file for my watchlog service

#WORD for find in file LOG
WORD="ALERT"
LOG=/var/log/watchlog.log
```
Создаем лог-файл по пути `/var/log/watchlog.log`, заполняем его рандомными строками, а также словом "ALERT".

Создаем скрипт `/opt/watchlog.sh` для будущего сервиса:
```
[root@systemd ~]# cat /opt/watchlog.sh
#!/bin/bash

WORD=$1
LOG=$2
DATE=$(date)

if grep $WORD $LOG &> /dev/null;then
#logger - enter messages into the system log
	logger "$DATE: I found word, Master!"
else
	exit 0
fi

[root@systemd ~]# chmod +x /opt/watchlog.sh
```
Создаем service unit:
```
[root@systemd ~]# cat /etc/systemd/system/watchlog.service
[Unit]
Description=My wathlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
Создаем timer unit. Для максимальной точности срабатывания таймера добавляем параметр `AccuracySec` со значением `1us`:
```
[root@systemd ~]# cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
#Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
AccuracySec=1us

[Install]
WantedBy=multi-user.target
```
Запустим сервис, таймер и проверим результат:
```
[root@systemd ~]# systemctl daemon-reload
[root@systemd ~]# systemctl start watchlog.service
[root@systemd ~]# systemctl start watchlog.timer
[root@systemd ~]# tail -f /var/log/messages
Mar 23 18:43:23 systemd systemd: Started My wathlog service.
Mar 23 18:43:53 systemd systemd: Starting My wathlog service...
Mar 23 18:43:53 systemd root: Mon Mar 23 18:43:53 UTC 2020: I found word, Master!
Mar 23 18:43:53 systemd systemd: Started My wathlog service.
Mar 23 18:44:23 systemd systemd: Starting My wathlog service...
Mar 23 18:44:23 systemd root: Mon Mar 23 18:44:23 UTC 2020: I found word, Master!
Mar 23 18:44:23 systemd systemd: Started My wathlog service.
Mar 23 18:44:53 systemd systemd: Starting My wathlog service...
Mar 23 18:44:53 systemd root: Mon Mar 23 18:44:53 UTC 2020: I found word, Master!
Mar 23 18:44:53 systemd systemd: Started My wathlog service.
Mar 23 18:45:23 systemd systemd: Starting My wathlog service...
Mar 23 18:45:23 systemd root: Mon Mar 23 18:45:23 UTC 2020: I found word, Master!
Mar 23 18:45:23 systemd systemd: Started My wathlog service.
Mar 23 18:45:53 systemd systemd: Starting My wathlog service...
Mar 23 18:45:53 systemd root: Mon Mar 23 18:45:53 UTC 2020: I found word, Master!
```
**2. Дополнить unit-файл сервиса httpd возможностью запустить несколько экземпляров сервиса с разными конфигурационными файлами.**

Для выполнения этого задания дополним unit-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами.
```
[root@systemd ~]# yum install httpd -y
```
Создаем следующий шаблон для httpd сервиса:
```
[root@systemd ~]# cat /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
В двух файлах окружения (для двух экземпляров сервиса httpd) зададим опцию для запуска веб-сервера с необходимым конфигурационным файлом:
```
[root@systemd ~]# cat /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
[root@systemd ~]# cat /etc/sysconfig/httpd-second 
OPTIONS=-f conf/second.conf
```
Соответственно в директории с конфигами httpd (`/etc/httpd/conf/`) должны лежать два конфига, в нашем случае это будут `first.conf` и `second.conf`. Для создания конфига `first.conf` просто скопируем оригинальный конфиг, а для `second.conf` поправим опции `PidFile` и `Listen`:
```
[root@systemd ~]# grep -E '^PidFile|^Listen' /etc/httpd/conf/second.conf
PidFile "/var/run/httpd-second.pid"
Listen 8008
```
Теперь можно запустить экземпляры сервиса:
```
[root@systemd ~]# systemctl start httpd@first
[root@systemd ~]# systemctl start httpd@second
```
Проверим порты:
```
[root@systemd ~]# ss -tnulp | grep httpd
tcp    LISTEN     0      128      :::8008                 :::*                   users:(("httpd",pid=7561,fd=4),("httpd",pid=7560,fd=4),("httpd",pid=7559,fd=4),("httpd",pid=7558,fd=4),("httpd",pid=7557,fd=4),("httpd",pid=7556,fd=4))
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=7549,fd=4),("httpd",pid=7548,fd=4),("httpd",pid=7547,fd=4),("httpd",pid=7546,fd=4),("httpd",pid=7545,fd=4),("httpd",pid=7544,fd=4))
```
**3. Создать unit-файл(ы) для сервиса:**
- сервис: Kafka, Jira или любой другой, у которого код успешного завершения не равен 0 (к примеру, приложение Java или скрипт с exit 143);
- ограничить сервис по использованию памяти;
- ограничить сервис ещё по трём ресурсам, которые не были рассмотрены на лекции;
- реализовать один из вариантов restart и объяснить почему выбран именно этот вариант.

Для решения данной задачи был выбран сервис Jira.

Скачаем и установим demo-версию Jira:
```
[root@systemd ~]# mkdir /opt/jira && cd /opt/jira
[root@systemd jira]# yum install wget -y 
[root@systemd jira]# wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-8.8.0-x64.bin
[root@systemd jira]# chmod a+x atlassian-jira-software-*
[root@systemd jira]# sudo yes "" | ./atlassian-jira-software-*
```
Создадим файл service unit для запуска Jira:
```
[root@systemd jira]# touch /lib/systemd/system/jira.service
[root@systemd jira]# chmod 664 /lib/systemd/system/jira.service
```
Добавим в service unit следующие строки:
```
[Unit] 
Description=Atlassian Jira
After=network.target

[Service] 
Type=forking
User=jira
PIDFile=/opt/atlassian/jira/work/catalina.pid
ExecStart=/opt/atlassian/jira/bin/start-jira.sh
ExecStop=/opt/atlassian/jira/bin/stop-jira.sh
CPUQuota=70%
LimitNPROC=9000
LimitNOFILE=20000
LimitNICE=15
MemoryLimit=900M
SuccessExitStatus=143
Restart=on-failure

[Install] 
WantedBy=multi-user.target
```
Обновим конфигурацию systemd, включим в автозагрузку и запустим сервис Jira:
```
[root@systemd ~]# systemctl daemon-reload
[root@systemd ~]# systemctl enable --now jira.service 
```





 





