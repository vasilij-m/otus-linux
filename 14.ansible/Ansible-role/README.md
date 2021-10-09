***Цель: В результате выполнения ДЗ студент подготовит стенд на Vagrant.***
Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible

***Задание "\*": Сделать все это с использованием Ansible роли***

Результатом выполнения ДЗ стало развертывание сервера NGINX, слушающего на порту 8080, с помощью Ansible роли:

```
$ ansible-playbook deploy_nginx.yml 

PLAY [Install & configure NGINX] ***********************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************
ok: [ansible-role-nginx]

TASK [deploy_nginx_8080 : Install EPEL Repo] ***********************************************************************************
changed: [ansible-role-nginx]

TASK [deploy_nginx_8080 : Install NGINX] ***************************************************************************************
changed: [ansible-role-nginx]

TASK [deploy_nginx_8080 : Create NGINX config file from template] **************************************************************
changed: [ansible-role-nginx]

RUNNING HANDLER [deploy_nginx_8080 : restart nginx] ****************************************************************************
changed: [ansible-role-nginx]

RUNNING HANDLER [deploy_nginx_8080 : reload nginx] *****************************************************************************
changed: [ansible-role-nginx]

PLAY RECAP *********************************************************************************************************************
ansible-role-nginx         : ok=6    changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Проверка результата:

```
$ curl http://192.168.11.150:8080
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>Welcome to CentOS</title>
  <style rel="stylesheet" type="text/css"> 

        html {
        background-image:url(img/html-background.png);
        background-color: white;
.....................
```
