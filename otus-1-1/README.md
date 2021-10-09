Ниже описан процесс создания образа виртуальной машины для Virtualbox на CentOS7 с обновленным ядром 5.5.1 из исходников с kernel.org.

Создание образа автоматизировано с помощью Packer. После выполнения следующей команды `packer build centos.json` согласно файлу `centos.json` будет скачан и установлен на виртуальную машину исходный образ `CentOS-7-x86_64-Minimal-1908.iso` с ядром 3.10.0. Далее будут выполнены скрипты, имена которых указаны в секции `provisioners`:
```
"scripts" :
            [
              "scripts/stage-1-kernel-update.sh",
              "scripts/stage-2-clean.sh"
            ]
```
Первый скрипт выполнит следующие действия:
1. Установит необходимые для обноления ядра пакеты:
`sudo yum -y install make gcc elfutils-libelf-devel flex bison openssl-devel bc perl`
2. Скачает с kernel.org и распакует исходники ядра:
```
sudo yum -y install make gcc elfutils-libelf-devel flex bison openssl-devel bc perl
cd /usr/src/
sudo curl -O https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.1.tar.xz
sudo tar -xvf linux-5.5.1.tar.xz
```
3. Создаст конфиг для нового ядра на основе старого конфига, скомпилирует ядро, установит модули и само ядро:
```
cd linux-5.5.1/
sudo cp /boot/config-$(uname -r) .config
yes "" | sudo make oldconfig && sudo make -j $(nproc) && sudo make modules_install && sudo make install
```
4. Удалит старое ядро:
`sudo rm -f /boot/*3.10*`
5. Обновит конфигурацию загрузчика с загрузкой нового ядра по умолчанию, очистит каталог `/usr/src/` и перезагрузит виртуальную машину:
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
sudo rm -rf /usr/src/linux*
sudo shutdown -r now
```
Второй скрипт очистит директории с логами, временными файлами и кешами, что позволит уменьшить результирующий образ:
```
#!/bin/bash

# clean all
sudo yum update -y
sudo yum clean all

# Install vagrant default key
mkdir -pm 700 /home/vagrant/.ssh
curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Remove temporary files
sudo rm -rf /tmp/*
sudo rm  -f /var/log/wtmp /var/log/btmp
sudo rm -rf /var/cache/* /usr/share/doc/*
sudo rm -rf /var/cache/yum
sudo rm -rf /vagrant/home/*.iso
sudo rm  -f ~/.bash_history
sudo history -c

sudo rm -rf /run/log/journal/*

# Fill zeros all empty space
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY
sudo sync
sudo grub2-set-default 1
```

Постобработка виртуальной машины при её выгрузке описана в секции `post-processors` файла `centos.json`. Здесь указано имя файла, в который будет сохранен результат:
```
"post-processors": [
    {
      "output": "centos-{{user `artifact_version`}}-kernel-5-x86_64.box",
      "compression_level": "7",
      "type": "vagrant"
    }
  ]
```
Результатом работы packer'а станет файл `centos-7.7.1908-kernel-5-x86_64.box`. Проведем тестрование полученного образа, выполнив его импорт в `vagrant`:
```
vagrant box add --name centos-7-7-5-5-1 centos-7.7.1908-kernel-5-x86_64.box
```
После этого он появится в списке имеющихся образов:
```
vagrant box list
centos-7-7-5-5-1 (virtualbox, 0)
```
Запускаем виртуальную машину и проверяем, что она загрузилась с ядром 5.5.1:
```
vagrant up
...
vagrant ssh
[vagrant@kernel-update-5-5-1 ~]$ uname -r
5.5.1
```
Полученный paccker'ом образ был загружен в `vagrant cloud`, виртуальную машину на его основе можно развернуть с помощью `Vagrantfile` в этом github-репозитории.

