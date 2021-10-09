FROM alpine:3.11
RUN apk update && apk add php7 \
php7-fpm php7-opcache \
&& rm -rf /var/cache/apk/*
RUN adduser -D -g 'www' www \
&& mkdir /www \
&& chown -R www:www /www
EXPOSE 9000
ENTRYPOINT ["php-fpm7", "--nodaemonize"]