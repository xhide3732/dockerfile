#!/bin/sh

# supervisord.conf作成
cat << EOF > supervisord.conf
[supervisord]
nodaemon=true
pidfile=/var/run/supervisord.pid
logfile=/var/log/supervisor/supervisord.log

[include]
files = /etc/supervisor/conf.d/*.conf

EOF

cat << EOF > server.conf
[program:sshd]
command=/usr/sbin/sshd -D

[program:nginx]
command=/usr/sbin/nginx -c /etc/nginx/nginx.conf -g 'daemon off;'

EOF

# nginxテスト用ページ作成
cat << EOF > index.html
Hello, World!!
EOF

# Dockerfile作成
cat << EOF > Dockerfile
FROM centos:centos6
MAINTAINER example 

# host名設定
ENV HOSTNAME webm01

# Supervisor用にディレクトリを作る
RUN mkdir -p /var/log/supervisor /etc/supervisor/conf.d

# Supervisor の設定を Docker イメージ内に転送する
ADD supervisord.conf /etc/supervisord.conf
ADD server.conf /etc/supervisor/conf.d/server.conf

# httpd で公開するファイルを Docker イメージ内に転送する
ADD index.html /usr/share/nginx/html/

# 環境を更新しておく
RUN yum -y update

# yum で python-setuptools を入れるために EPEL をインストールしておく
RUN yum -y install epel-release

# nginx用
RUN rpm -ivh http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm

# 必要なパッケージをインストールする
RUN yum -y groupinstall "Development Tools"
RUN yum -y install vim wget tar sudo passwd
RUN yum -y install openssh openssh-clients openssh-server
RUN yum -y install nginx python-setuptools
RUN yum -y clean all

# プロンプト変数設定
RUN echo "export PS1='[\u@\h \W]# '" >> /etc/profile

# centos 日本語設定
RUN yum -y groupinstall "Japanese Support"
RUN yum -y reinstall glibc-common
RUN sed -ri 's/en_US/ja_JP/' /etc/sysconfig/i18n
RUN localedef -v -c -i ja_JP -f UTF-8 ja_JP.UTF-8; echo "";
ENV LANG=ja_JP.UTF-8

# 日本時刻設定
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# sshd設定
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

# root ユーザでログインできるようにする
RUN sed -ri 's/^#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

# root ユーザのパスワードを 'root' にする
RUN echo 'root:root' | chpasswd

# 使わないにしてもここに公開鍵を登録しておかないとログインできない
RUN ssh-keygen -t rsa -N "" -f /etc/ssh/ssh_host_rsa_key

# Supervisor をインストールする
RUN easy_install supervisor

# sshd: 22, httpd: 80 を公開する
EXPOSE 22 80

# Supervisor を起動する
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor.conf"]

EOF

# dockerfile実行
docker build -t centos6:web1.0 .

exit 0
