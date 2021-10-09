**1. Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)**

Директория `nginx-alpine` послужила build контекстом для создания образа vasiilij/nginx-alpine:1.0 (ссылка на Docker Hub: <https://hub.docker.com/repository/docker/vasiilij/nginx-alpine>).

Для проверки задания выполнить `docker run -d -p 80:80 --name nginx-alpine vasiilij/nginx-alpine:1.0` и перейти на страницу `localhost` в браузере.

***Ответы на вопросы***

Q: Определите разницу между контейнером и образом.  
A: Образ - это файл, включающий зависимости, сведения, конфигурацию для дальнейшего развертывания и инициализации контейнера. По сути это read-only шаблон с инструкциями для создания контейнера.
   Контейнер - это работающий (выполняющийся) экземпляр образа, который включает в себя все необходимое для запуска внутри какго-либо приложения (код приложения, среду выполнения, библиотеки, настройки и т.д)

Q: Можно ли в контейнере собрать ядро?  
A: Да, можно, как и любую программу из исходников.

**2. Задание \*. Создайте кастомные образы nginx и php, объедините их в docker-compose.После запуска nginx должен показывать php info.Все собранные образы должны быть в docker hub**

В директории `nginx-fpm-alpine` находятся две поддиректории:
`nginx` - послужила build контекстом для создания образа vasiilij/nginx-fpm:1.0 (ссылка на Docker Hub: <https://hub.docker.com/repository/docker/vasiilij/nginx-fpm>);
`php-fpm` - послужила build контекстом для создания образа vasiilij/php-fpm:1.0 (ссылка на Docker Hub: <https://hub.docker.com/repository/docker/vasiilij/php-fpm>).

Для проверки задания перейти в директорию `nginx-fpm-alpine` и выполнить `docker-compose up -d` и перейти в браузере на страницу `localhost/index.html` или `localhost/index.php`.


*В ходе выполнения ДЗ для написания докерфайлов и конфигов пользовался следующими источниками:*

<https://wiki.alpinelinux.org/wiki/Nginx>  
<https://wiki.alpinelinux.org/wiki/Nginx_with_PHP>

