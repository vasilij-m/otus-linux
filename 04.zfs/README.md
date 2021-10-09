
### Установка zfs.

```
[root@zfs ~]# yum install -y yum-utils
[root@zfs ~]# yum -y install http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
[root@zfs ~]# gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
[root@zfs ~]# yum-config-manager --enable zfs-kmod
[root@zfs ~]# yum-config-manager --disable zfs
[root@zfs ~]# yum install -y zfs
```

Проверим, загружен ли модуль zfs, есл инет, загрузим его:

```
[root@zfs ~]# lsmod | grep zfs
[root@zfs ~]# modprobe zfs
[root@zfs ~]# lsmod | grep zfs
zfs                  3986613  0 
zunicode              331170  1 zfs
zlua                  147429  1 zfs
zcommon                89551  1 zfs
znvpair                94388  2 zfs,zcommon
zavl                   15167  1 zfs
icp                   301854  1 zfs
spl                   104299  5 icp,zfs,zavl,zcommon,znvpair
```

Создадим striped mirror (RAID10) пул из 4х дисков:

```
[root@zfs ~]# lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0   5G  0 disk 
sdc      8:32   0   5G  0 disk 
sdd      8:48   0   5G  0 disk 
sde      8:64   0   5G  0 disk
[root@zfs ~]# zpool create striped_mirror_pool mirror sdb sdc mirror sdd sde
```

Проверим статус пула:

```
[root@zfs ~]# zpool status
  pool: striped_mirror_pool
 state: ONLINE
  scan: none requested
config:

	NAME                 STATE     READ WRITE CKSUM
	striped_mirror_pool  ONLINE       0     0     0
	  mirror-0           ONLINE       0     0     0
	    sdb              ONLINE       0     0     0
	    sdc              ONLINE       0     0     0
	  mirror-1           ONLINE       0     0     0
	    sdd              ONLINE       0     0     0
	    sde              ONLINE       0     0     0

errors: No known data errors
[root@zfs ~]# zpool list
NAME                  SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
striped_mirror_pool     9G   114K  9.00G        -         -     0%     0%  1.00x    ONLINE  -
```

### 1. Определить алгоритм с наилучшим сжатием (gzip, gzip-N, zle, lzjb, lz4).

Создадим 5 файловыx систем c указанными алшоритмами сжатия:

```
[root@zfs ~]# zfs create -o compression=gzip striped_mirror_pool/fs1
[root@zfs ~]# zfs create -o compression=gzip-9 striped_mirror_pool/fs2
[root@zfs ~]# zfs create -o compression=zle striped_mirror_pool/fs3
[root@zfs ~]# zfs create -o compression=lzjb striped_mirror_pool/fs4
[root@zfs ~]# zfs create -o compression=lz4 striped_mirror_pool/fs5
```

Посмотрим, что получилось:

```
[root@zfs ~]# zfs list
NAME                      USED  AVAIL     REFER  MOUNTPOINT
striped_mirror_pool       232K  8.72G     30.5K  /striped_mirror_pool
striped_mirror_pool/fs1    24K  8.72G       24K  /striped_mirror_pool/fs1
striped_mirror_pool/fs2    24K  8.72G       24K  /striped_mirror_pool/fs2
striped_mirror_pool/fs3    24K  8.72G       24K  /striped_mirror_pool/fs3
striped_mirror_pool/fs4    24K  8.72G       24K  /striped_mirror_pool/fs4
striped_mirror_pool/fs5    24K  8.72G       24K  /striped_mirror_pool/fs5
```

Скачаем файл архива ядра Linux в каждую файловую систему:

```
[root@zfs ~]# curl -L -o /tmp/linux-5.8.9.tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.8.9.tar.xz
[root@zfs ~]# ls /striped_mirror_pool/ | xargs -I FS /bin/bash -c "cp /tmp/linux-5.8.9.tar.xz /striped_mirror_pool/FS/linux-5.8.9.tar.xz && tar -xvf /striped_mirror_pool/FS/linux-5.8.9.tar.xz -C /striped_mirror_pool/FS/"
```

Проверим, что получилось:

```
[root@zfs ~]# zfs list -o name,used,available,referenced,compression,compressratio
NAME                      USED  AVAIL     REFER  COMPRESS  RATIO
striped_mirror_pool      2.72G  6.00G     30.5K       off  2.05x
striped_mirror_pool/fs1   358M  6.00G      358M      gzip  3.24x
striped_mirror_pool/fs2   356M  6.00G      356M    gzip-9  3.25x
striped_mirror_pool/fs3  1.02G  6.00G     1.02G       zle  1.07x
striped_mirror_pool/fs4   538M  6.00G      538M      lzjb  2.12x
striped_mirror_pool/fs5   483M  6.00G      483M       lz4  2.37x
```

Видим, что лучшие результаты по сжатию дали алгоритмы gzip и gzip-9.

(про сжатие в zfs в документации: https://docs.oracle.com/cd/E53394_01/html/E54801/gpxis.html)


### 2.Определить настройки pool’a.

Импортируем пул:

```
[root@zfs tmp]# zpool import -d ./zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                        ONLINE
	  mirror-0                  ONLINE
	    /tmp/zpoolexport/filea  ONLINE
	    /tmp/zpoolexport/fileb  ONLINE
[root@zfs tmp]# zpool import -d ./zpoolexport/ otus
```

Проверим доступные пулы:

```
[root@zfs tmp]# zpool list
NAME                  SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus                  480M  2.09M   478M        -         -     0%     0%  1.00x    ONLINE  -
striped_mirror_pool     9G  2.72G  6.28G        -         -     0%    30%  1.00x    ONLINE  -
```

<details>
  <summary>Список свойств пула otus:</summary>

```
[root@zfs ~]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

</details>

Выведем те которые требуются по заданию:

```
[root@zfs ~]# zfs get available,type,recordsize,compression,checksum otus
NAME  PROPERTY     VALUE       SOURCE
otus  available    350M        -
otus  type         filesystem  -
otus  recordsize   128K        local
otus  compression  zle         local
otus  checksum     sha256      local
```

### 3. Найти сообщение от преподавателей.

Восстановим снапшот из скачанного файла:

```
[root@zfs tmp]# zfs receive otus/snap < otus_task2.file
[root@zfs tmp]# zfs list 
NAME                      USED  AVAIL     REFER  MOUNTPOINT
otus                     4.90M   347M       25K  /otus
otus/hometask2           1.88M   347M     1.88M  /otus/hometask2
otus/snap                2.83M   347M     2.83M  /otus/snap
striped_mirror_pool      2.72G  6.00G     30.5K  /striped_mirror_pool
striped_mirror_pool/fs1   358M  6.00G      358M  /striped_mirror_pool/fs1
striped_mirror_pool/fs2   356M  6.00G      356M  /striped_mirror_pool/fs2
striped_mirror_pool/fs3  1.02G  6.00G     1.02G  /striped_mirror_pool/fs3
striped_mirror_pool/fs4   538M  6.00G      538M  /striped_mirror_pool/fs4
striped_mirror_pool/fs5   483M  6.00G      483M  /striped_mirror_pool/fs5
```

Найдем зашифрованное сообщение в файле secret_message:

```
[root@zfs tmp]# cat /otus/snap/task1/file_mess/secret_message 
https://github.com/sindresorhus/awesome
```











