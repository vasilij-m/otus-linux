**Задание:**
1. Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников
* дать конкретному пользователю права работать с докером
и возможность рестартить докер сервис

**Выполнение основного задания**

1. Создадим четырех пользователей: user1 и user2 - обычные пользователи, admin1 и admin2 - пользователи в группе admin. Пароль у пользователей user1 и user2 зададим "user", у admin1 и admin2 - "admin":

[root@pam ~]# useradd user1 && useradd user2 && useradd admin1 && useradd admin2
[root@pam ~]# echo "user" | passwd --stdin user1 && echo "user" | passwd --stdin user2 && echo "admin" | passwd --stdin admin1 && echo "admin" | passwd --stdin admin2
[root@pam ~]# groupadd admin && gpasswd -M admin1,admin2 admin

2. Разрешим вход через ssh по паролю:

[root@pam ~]# sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service

3. Настроить доступ пользователей с учетом времени можно с помощью модуля `pam_time`, но данный модуль не работает с группами linux. Так как перечислять всех пользователей в config-файле для модуля `pam_time` неудобно, воспользуемся модулем 'pam_exec', который позволяет выполнить скрипт при подключении пользователя. Приведем файл `/etc/pam.d/sshd` к следующему виду:

```
[root@pam ~]# cat /etc/pam.d/sshd
#%PAM-1.0
auth	   required	pam_sepermit.so
auth       substack     password-auth
auth       include      postlogin
# Used with polkit to reauthorize users in remote sessions
-auth      optional     pam_reauthorize.so prepare
account    required     pam_nologin.so
account    required	pam_exec.so /usr/local/bin/restrict_login.sh
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin
# Used with polkit to reauthorize users in remote sessions
-session   optional     pam_reauthorize.so prepare
```

Сам скрипт `/usr/local/bin/restrict_login.sh` выглядит следующим образом:
```
[root@pam ~]# cat /usr/local/bin/restrict_login.sh
#!/bin/bash

ugroup=$(id $PAM_USER | grep -ow admin)
uday=$(date +%u)

if [[ -n $ugroup || $uday -lt 6 ]]; then
	exit 0
else
	exit 1
fi
```
Делаем скрипт исполняемым и проверяем подключение по ssh:
```
vasya@Moisey-NB:~/otus-1-9$ ssh user1@192.168.11.101
user1@192.168.11.101's password: 
/usr/local/bin/restrict_login.sh failed: exit code 1
Connection closed by 192.168.11.101 port 22
vasya@Moisey-NB:~/otus-1-9$ ssh user2@192.168.11.101
user2@192.168.11.101's password: 
/usr/local/bin/restrict_login.sh failed: exit code 1
Connection closed by 192.168.11.101 port 22
vasya@Moisey-NB:~/otus-1-9$ ssh admin1@192.168.11.101
admin1@192.168.11.101's password: 
Last login: Sun May 17 19:56:20 2020 from 192.168.11.1
[admin1@pam ~]$ logout
Connection to 192.168.11.101 closed.
vasya@Moisey-NB:~/otus-1-9$ ssh admin2@192.168.11.101
admin2@192.168.11.101's password: 
[admin2@pam ~]$ logout
Connection to 192.168.11.101 closed.
```
Как видим, под пользователями user1 и user2 соединение заркывается, а под пользователями admin1 и admin2 подключение проходит успешно.

4. Также запретим вход всем пользователям, кроме группы admin, в выходные непосредственно с локальной консоли сервера. Для этого приведем файл `/etc/pam.d/login` к следующему виду:
```
[root@pam ~]# cat /etc/pam.d/login 
#%PAM-1.0
auth [user_unknown=ignore success=ok ignore=ignore default=bad] pam_securetty.so
auth       substack     system-auth
auth       include      postlogin
account    required     pam_nologin.so
account    required     pam_exec.so /usr/local/bin/restrict_login.sh
account    include      system-auth
password   include      system-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
session    optional     pam_console.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      system-auth
session    include      postlogin
-session   optional     pam_ck_connector.so
```

**Выполнение задания со \* дать конкретному пользователю права работать с докером и возможность рестартить докер сервис**

1. Установим и запустим docker:
```
[root@pam ~]# yum install -y yum-utils
[root@pam ~]# yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
[root@pam ~]# yum install -y docker-ce docker-ce-cli containerd.io
[root@pam ~]# systemctl enable --now docker
[root@pam ~]# systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Пн 2020-05-18 05:45:22 UTC; 48s ago
     Docs: https://docs.docker.com
 Main PID: 5300 (dockerd)
   CGroup: /system.slice/docker.service
           └─5300 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/contain...
```
2. Дадим права для работы с docker пользователю user1. Процесс описан в официальной [документации](https://docs.docker.com/engine/install/linux-postinstall/):
```
[root@pam ~]# usermod -aG docker user1
[root@pam ~]# newgrp docker
[user1@pam ~]$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
0e03bdcc26d7: Pull complete 
Digest: sha256:6a65f928fb91fcfbc963f7aa6d57c8eeb426ad9a20c7ee045538ef34847f44f1
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

...

```

3. PolKit. Включим логирование. Для этого создадим файл `/etc/polkit-1/rules.d/00-access.rules` со следующим содержимым:
```
[root@pam ~]# cat /etc/polkit-1/rules.d/00-access.rules
polkit.addRule(function(action, subject) {
    polkit.log("action=" + action);
    polkit.log("subject=" + subject);
});
```

4. Теперь попробуем рестартануть docker service и увидим запрос аутентифицироваться под рутом:
```
[user1@pam ~]$ systemctl restart docker
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to manage system services or units.
Authenticating as: root
Password: 
```

5. В логе `/var/log/secure` увидим следующие строки:
```
May 19 11:04:46 pam polkitd[1653]: Registered Authentication Agent for unix-process:5805:364125 (system bus name :1.57 [/usr/bin/pkttyagent --notify-fd 5 --fallback], object path /org/freedesktop/PolicyKit1/AuthenticationAgent, locale en_US.UTF-8)
May 19 11:04:46 pam polkitd[1653]: /etc/polkit-1/rules.d/00-access.rules:2: action=[Action id='org.freedesktop.systemd1.manage-units']
May 19 11:04:46 pam polkitd[1653]: /etc/polkit-1/rules.d/00-access.rules:3: subject=[Subject pid=5805 user='user1' groups=user1,docker seat='' session='5' local=false active=true]
May 19 11:04:48 pam polkitd[1653]: Unregistered Authentication Agent for unix-process:5805:364125 (system bus name :1.57, object path /org/freedesktop/PolicyKit1/AuthenticationAgent, locale en_US.UTF-8) (disconnected from bus)
May 19 11:04:48 pam polkitd[1653]: Operator of unix-process:5805:364125 FAILED to authenticate to gain authorization for action org.freedesktop.systemd1.manage-units for system-bus-name::1.58 [<unknown>] (owned by unix-user:user1)
```
Пользователю user1 не удалось пройти проверку подлинности для получения разрешения на действие org.freedesktop.systemd1.manage-units.

6. Предоставим пользователю user1 право рестартить docker service. Для этого создадим правило /etc/polkit-1/rules.d/01-dockerrestart.rules со следующим содержанием:
```
[root@localhost ~]# cat /etc/polkit-1/rules.d/01-dockerrestart.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "docker.service" &&
        action.lookup("verb") == "restart" &&
	subject.user == "user1") {
        return polkit.Result.YES;
    }
});
```
7. Чтобы данная политика отработала, необходимо обновить systemd, так как в CentOS 7 используется systemd v219, а для функционирования правил `action.lookup("unit")` и `action.lookup("verb")` необходима systemd v226. В CentOS 8 версия systemd удовлетворяет нашим требованиям.

Обновим systemd из репозитория с бэкпортами ([страница руководства](https://copr.fedorainfracloud.org/coprs/jsynacek/systemd-backports-for-centos-7/)):
```
[root@pam ~]# setenforce 0
[root@pam ~]# yum install -y wget
[root@pam ~]#  wget https://copr.fedorainfracloud.org/coprs/jsynacek/systemd-backports-for-centos-7/repo/epel-7/jsynacek-systemd-backports-for-centos-7-epel-7.repo -O /etc/yum.repos.d/jsynacek-systemd-centos-7.repo
[root@pam ~]# yum update systemd -y
[root@pam ~]# setenforce 1
[root@pam ~]# systemctl --version
systemd 234
+PAM +AUDIT +SELINUX +IMA -APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD -IDN2 +IDN default-hierarchy=hybrid
```
8. Теперь можно проверить, имеет ли право user1 рестартить docker.service. Также проверим, может ли он его остановить:
```
[user1@pam ~]$ systemctl restart docker
[user1@pam ~]$ systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: 
   Active: active (running) since Wed 2020-05-20 13:01:22 UTC; 11s ago
     Docs: https://docs.docker.com
 Main PID: 4297 (dockerd)
    Tasks: 10
   Memory: 39.6M
      CPU: 205ms
   CGroup: /system.slice/docker.service
           └─4297 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd
[user1@pam ~]$ systemctl stop docker
==== AUTHENTICATING FOR org.freedesktop.systemd1.manage-units ===
Authentication is required to stop 'docker.service'.
Authenticating as: root
Password: 
```

Как видим, docker.service успешно перезапустился, но при попытке его остановки появилось требование аутентифицироваться в качестве рута.

***Проверка ДЗ***

Выполнить `vagrant up`, зайти по ssh на 192.168.11.11:
1. Пользователям admin1 и admin2 (пароль для обоих admin) разрешено логиниться на сервер в любые дни.
2. Пользователям user1 и user2 (пароль для обоих user) запрещено логиниться на сервер в субботу и воскресенье.
3. Только пользователю user1 разрешено рестартить docker service, но не останавливать его.



 

















