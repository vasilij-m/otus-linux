## **Задание**

Настроить стенд Vagrant с двумя виртуальными машинами server и backup. 

Настроить политику бэкапа директории /etc с клиента (server) на бекап сервер (backup): 
1) Бекап делаем раз в час 
2) Политика хранения бекапов: храним все за последние 30 дней, и по одному за предыдущие два месяца. 
3) Настроить логирование процесса бекапа в /var/log/ - название файла на ваше усмотрение 
4) Восстановить из бекапа директорию /etc с помощью опции Borg mount 

Результатом должен быть скрипт резервного копирования (политику хранения можно реализовать в нем же), а так же вывод команд терминала записанный с помощью script (или другой подобной утилиты). 

* Настроить репозиторий для резервных копий с шифрованием ключом. 

## **Выполнение задания**

**Установка borgbackup на обоих хостах**

Скачиваем бинарник и делаем его исполняемым:
```
[root@server ~]# curl -L https://github.com/borgbackup/borg/releases/download/1.1.13/borg-linux64 -o /usr/bin/borg
[root@server ~]# chmod +x /usr/bin/borg
```

На хосте backup создаем пользователя borg:
```

[root@backup ~]# useradd -m borg
```

На хосте server генерируем SSH-ключ и добавляем его в `~borg/.ssh/authorized_keys` на хост backup:
```
[root@server ~]# ssh-keygen
...
[root@backup ~]# mkdir ~borg/.ssh && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDrs25oeVZ6+LH1qHfS0WPxQRGeAGjfR8FQyVkP2929uPu5qCM3Ggoywbifv/fzWilLi+AkvCJUu4tnupV1jMa4DHOcbio60psUxDPr4Hje+8h19BYtkfQN3DEIEHRAhHGLyLJSgvn/grgEkIYmqBrFw2msxnBnAhBEvNmGsnfam11KGJAcfbk6v5Al6ZkWjnK574XzMjC6pv71r7nhjhjk7Y7la0ArPULVJ5frIshOiPrJdgG+OLdKWXWaLpSMiU0MnkcmnuSsP1NH9b9eF7i8sWxTsktXf1J4idHrLMpldkak3+CbL7fNEAZ5KQuBiq4Mw2QYMrPIv2PaS/Uq7nwd root@server" > ~borg/.ssh/authorized_keys
[root@backup ~]# chown -R borg:borg ~borg/.ssh
```

**Шифрование**

Теперь с хоста server (с клиента) инициируем репозиторий с шифрованием (опция --encryption) с именем `EtcRepo` на хосте backup:
```
[root@server ~]# borg init --encryption=repokey-blake2 borg@192.168.10.20:EtcRepo
Using a pure-python msgpack! This will result in lower performance.
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: y
Your passphrase (between double-quotes): "passphrase"
Make sure the passphrase displayed above is exactly what you wanted.

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://borg@192.168.10.20/./EtcRepo

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```

В borg возможны два Hash/MAC алгоритма для шифрования: SHA-256 и BLAKE2b (подробнее здесь: https://borgbackup.readthedocs.io/en/stable/usage/init.html). Я выбрал BLAKE2b, так как на процессорах Intel/AMD он быстрее, чем SHA-256.

Также borg попросит ввести passphrase (в моем случае я ввел "passphrase").

Ключ шифрования после инициализации репозитория будет храниться на хосте backup в файле `<REPO_DIR>/config`:
```
[borg@backup ~]$ cat /home/borg/EtcRepo/config 
[repository]
version = 1
segments_per_dir = 1000
max_segment_size = 524288000
append_only = 0
storage_quota = 0
additional_free_space = 0
id = 56cd16aaf8b9d44ad318ea861d0eaf1f72a44f4675f8c493ed1d985f0b14d5be
key = hqlhbGdvcml0aG2mc2hhMjU2pGRhdGHaAZ6qI2P8vL9OHJ3Wk4+VdrPMJti2xGF86T5WaX
	vQfnf6gIPc+N4ZwnL9gW5GQVZognBQ9o9XVld9xBY/H9wPJnJ1j2zYiGNMgBVLuS+KC9bx
	a82h7h1zu3DiWIZz73PIijafbqRtRAQ1mcD8L35o+PZSin5KClvZ1q8aoz2NwByaWQzIP8
	FJCnHDC66yQ0qztkLBF/mfg7d0UrqfeqPXevhghYzQNwxLIaniIFFr9ll7l4xB9ES73yZE
	so0ZFlqFN+QPBOWn2Q89jBgvCweGRNqZz9dqkr0pCOnmJzKCgJQr0RXxo11JsYiQORijfe
	yP2oH01kssEBXNj1Izpe2kSgisl++vmB0yVUixpdCW3VnXTY5iEYYvZV5FNZp575BIjQx+
	8CRXwKTLRQUNiv+IV8WC60EsuYtT2j8F6Df7MqKIVdZ9+tgEL8retl4appCrsFpSKiRARK
	SsoiCZw2rrfK3Ne3MxZH9nf0ZNNtO7U2CU6gW69jezzmB8bUbNE+cVQXQLnxzV6APMMsZc
	AXrrE+S0X+GuGMHZ1b3ppo4T/rukaGFzaNoAIJUSu4tVwE2bFpAQlzW/ga+lfSi3G4kl4z
	j1EfsmMSkoqml0ZXJhdGlvbnPOAAGGoKRzYWx02gAgaeGRWW9hW3r8PAjoWw2TxgssETiq
	f1zOymUxagH0qv+ndmVyc2lvbgE=

```

При настроенном шифровании passphrase будет запрашиваться каждый раз при запуске процедуры бэкапа. Поэтому для автоматизации бэкапа в скрипте одним из способов является передача passphrase в переменную окружения BORG_PASSPHRASE: 
`export BORG_PASSPHRASE='passphrase'`.

**Логирование**

Borg пишет свои логи в stderr, поэтому для записи логов в файл, нужно перенаправить в него stderr. В скрипте за это отвечают следующие строки:
```
LOG=/var/log/borg_backup.log

borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-server-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}

borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-daily=7 \
  --keep-weekly=4 2>> ${LOG}
```

**Политика хранения бэкапа**

Политика хранения определяется в скрипте командой `borg prune` - она удаляет из репозитория все архивы, не соответсвующие ни одному из указанных критериев, которые в свою очередь определяются параметрами `--keep-*`. В данном ДЗ определено хранить бэкапы за последние 30 дней и по одному за предыдущие два месяца:
```
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-daily=30 \
  --keep-monthly=2 2>> ${LOG}
```

**Автоматическое выполнение бэкапа**

По заданию бэкап нужно делать каждый час. Для этого создадим systemd service и systemd timer:
```
[root@server ~]# cat /etc/systemd/system/borg-backup.service
[Unit]
Description=Borg /etc backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/borg-backup.sh
```
```
[root@server ~]# cat /etc/systemd/system/borg-backup.timer
[Unit]
Description=Borg backup timer

[Timer]
#run hourly
OnBootSec=5min
OnUnitActiveSec=1h
Unit=borg-backup.service

[Install]
WantedBy=multi-user.target
```

Обновим конфигурацию systemd и запустим таймер:
```
[root@server ~]# systemctl daemon-reload
[root@server ~]# systemctl enable --now borg-backup.timer 
Created symlink from /etc/systemd/system/multi-user.target.wants/borg-backup.timer to /etc/systemd/system/borg-backup.timer.

```

**Работа с архивом**

Создадим `/etc/testdir` с файлами внутри:
```
[root@server ~]# mkdir /etc/testdir && touch /etc/testdir/testfile{01..05}
[root@server ~]# ll /etc/testdir/
total 0
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile01
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile02
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile03
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile04
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile05
```

Выполним задание бэкапа:
```
[root@server ~]# ./borg-backup.sh
```

Выведим список архивов в репозитории EtcRepo:
```
[root@server ~]# borg list borg@192.168.10.20:EtcRepo
Using a pure-python msgpack! This will result in lower performance.
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter passphrase for key ssh://borg@192.168.10.20/./EtcRepo: 
Enter passphrase for key ssh://borg@192.168.10.20/./EtcRepo: 
etc-server-2020-07-05_15:33:36       Sun, 2020-07-05 15:33:37 [05035261c38d4994b7029373b1e72c6084c7e149f758fa099ed305476d7981fe]
```

Видим один единственный архив `etc-server-2020-07-05_15:33:36`, посмотрим его содержимое:
```
[root@server ~]# borg list borg@192.168.10.20:EtcRepo::etc-server-2020-07-05_15:33:36
Using a pure-python msgpack! This will result in lower performance.
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter passphrase for key ssh://borg@192.168.10.20/./EtcRepo: 
drwxr-xr-x root   root          0 Sun, 2020-07-05 13:48:13 etc
-rw-r--r-- root   root        346 Thu, 2020-04-30 22:09:26 etc/fstab
-rw------- root   root          0 Thu, 2020-04-30 22:04:55 etc/crypttab
lrwxrwxrwx root   root         17 Thu, 2020-04-30 22:04:55 etc/mtab -> /proc/self/mounts
-rw-r--r-- root   root        182 Sat, 2020-07-04 07:41:21 etc/hosts
-rw-r--r-- root   root       2388 Thu, 2020-04-30 22:08:36 etc/libuser.conf
-rw-r--r-- root   root       2043 Thu, 2020-04-30 22:08:36 etc/login.defs
-rw-r--r-- root   root         37 Thu, 2020-04-30 22:08:36 etc/vconsole.conf
lrwxrwxrwx root   root         25 Thu, 2020-04-30 22:08:36 etc/localtime -> ../usr/share/zoneinfo/UTC
-rw-r--r-- root   root         19 Thu, 2020-04-30 22:08:36 etc/locale.conf
-rw-r--r-- root   root       1186 Thu, 2020-04-30 22:08:37 etc/passwd
---------- root   root        663 Thu, 2020-04-30 22:08:37 etc/shadow
---------- root   root        433 Thu, 2020-04-30 22:08:37 etc/gshadow
-rw-r--r-- root   root        163 Thu, 2020-04-30 22:05:05 etc/.updated
-rw-r--r-- root   root        543 Thu, 2020-04-30 22:08:37 etc/group
drwxr-xr-x root   root          0 Thu, 2020-04-30 22:06:26 etc/X11
drwxr-xr-x root   root          0 Tue, 2020-04-07 14:38:10 etc/X11/xorg.conf.d
drwxr-xr-x root   root          0 Wed, 2018-04-11 04:59:55 etc/X11/applnk
drwxr-xr-x root   root          0 Wed, 2018-04-11 04:59:55 etc/X11/fontpath.d
drwxr-xr-x root   root          0 Wed, 2020-04-01 04:21:38 etc/rpm
-rw-r--r-- root   root         66 Tue, 2020-04-07 22:01:12 etc/rpm/macros.dist
-rw-r--r-- root   root         37 Tue, 2020-04-07 22:01:12 etc/centos-release
-rw-r--r-- root   root         51 Tue, 2020-04-07 22:01:12 etc/centos-release-upstream
-rw-r--r-- root   root         23 Tue, 2020-04-07 22:01:12 etc/issue
-rw-r--r-- root   root         22 Tue, 2020-04-07 22:01:12 etc/issue.net
lrwxrwxrwx root   root         21 Thu, 2020-04-30 22:05:05 etc/os-release -> ../usr/lib/os-release
lrwxrwxrwx root   root         14 Thu, 2020-04-30 22:05:05 etc/redhat-release -> centos-release
lrwxrwxrwx root   root         14 Thu, 2020-04-30 22:05:05 etc/system-release -> centos-release
-rw-r--r-- root   root         23 Tue, 2020-04-07 22:01:12 etc/system-release-cpe
-rw-r--r-- root   root       1529 Wed, 2020-04-01 04:29:32 etc/aliases
-rw-r--r-- root   root       2853 Wed, 2020-04-01 04:29:31 etc/bashrc

...

[root@server ~]# borg list borg@192.168.10.20:EtcRepo::etc-server-2020-07-05_15:33:36 | grep testdir
Using a pure-python msgpack! This will result in lower performance.
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter passphrase for key ssh://borg@192.168.10.20/./EtcRepo: 
drwxr-xr-x root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir
-rw-r--r-- root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir/testfile01
-rw-r--r-- root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir/testfile02
-rw-r--r-- root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir/testfile03
-rw-r--r-- root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir/testfile04
-rw-r--r-- root   root          0 Sun, 2020-07-05 14:55:58 etc/testdir/testfile05

```

Удалим `/etc/testdir`:
```
[root@server ~]# rm -rf /etc/testdir/
[root@server ~]# ll /etc/testdir
ls: cannot access /etc/testdir: No such file or directory
```

Восстановим `/etc/testdir` из бэкапа. Сначала создадим директорию `/borgbackup` и примонтируем в неё репозиторий с бэкапом:
```
[root@server ~]# mkdir /borgbackup
[root@server ~]# borg mount borg@192.168.10.20:EtcRepo::etc-server-2020-07-05_15:33:36 /borgbackup/
Using a pure-python msgpack! This will result in lower performance.
Remote: Using a pure-python msgpack! This will result in lower performance.
Enter passphrase for key ssh://borg@192.168.10.20/./EtcRepo: 

[root@server ~]# ll /borgbackup/
total 0
drwxr-xr-x. 1 root root 0 Jul  5 14:55 etc

```

Проверим наличие `testdir` в `/borgbackup/etc`:
```
[root@server ~]# ll /borgbackup/etc/testdir/
total 0
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile01
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile02
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile03
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile04
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile05
```

Теперь можно скопировать `testdir` в `/etc`:
```
[root@server ~]# cp -Rp /borgbackup/etc/testdir/ /etc
[root@server ~]# ll /etc/testdir/
total 0
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile01
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile02
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile03
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile04
-rw-r--r--. 1 root root 0 Jul  5 14:55 testfile05
```

Теперь можно отмонтировать репозиторий с бэкапом:
```
[root@server ~]# borg umount /borgbackup/
Using a pure-python msgpack! This will result in lower performance.
[root@server ~]# ll /borgbackup/
total 0
```































