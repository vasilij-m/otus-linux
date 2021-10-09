FROM centos:centos7.7.1908

RUN yum install -y redhat-lsb-core \
rpmdevtools rpm-build createrepo \
yum-utils gcc && rm -rf /var/cache/yum

ADD https://www.openssl.org/source/latest.tar.gz /
ADD https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm /

RUN rpm -i nginx-1.14.1-1.el7_4.ngx.src.rpm \
&& tar -xvf latest.tar.gz && rm -f latest.tar.gz \
&& yum-builddep -y /root/rpmbuild/SPECS/nginx.spec

COPY ./resources/nginxdocker.spec /root/rpmbuild/SPECS/nginx.spec

RUN rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec \
&& yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm \
&& rm -rf /var/cache/yum \
&& mkdir /usr/share/nginx/html/repo \
&& cp /root/rpmbuild/RPMS/x86_64/nginx-1.14.1-1.el7_4.ngx.x86_64.rpm \
/usr/share/nginx/html/repo/ && rm -rf /openssl-1.1.1g \
&& yum clean all

COPY ./resources/percona-release-0.1-6.noarch.rpm /usr/share/nginx/html/repo/

RUN createrepo /usr/share/nginx/html/repo/

COPY ./resources/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]