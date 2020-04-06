FROM alpine:3.11
LABEL maintainer="NConf Team - http://www.nconf.org"

# Set Env
ENV HOME /home/nconf
ENV WWWHOME /var/www
ENV USERID 10000
ENV GROUPID 10000

# Run update and install dependencies
RUN echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/main >> /etc/apk/repositories
RUN echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/community >> /etc/apk/repositories
RUN echo @repo3_0 http://dl-cdn.alpinelinux.org/alpine/v3.0/main >> /etc/apk/repositories
RUN apk update && apk upgrade && apk add wget apache2 php5-apache2@repo3_8 php5-mysql@repo3_8 php5-ldap@repo3_8 mariadb mysql-client perl@repo3_0 perl-dbi@repo3_0 perl-dbd-mysql@repo3_0 nagios@repo3_0 supervisor

# Create directories & users
RUN mkdir -p $HOME $WWWHOME
RUN addgroup -g $GROUPID nconf;adduser -D -h $HOME -u $USERID -G nconf nconf
WORKDIR $HOME

# Fetch NConf
RUN wget --no-check-certificate https://sourceforge.net/projects/nconf/files/nconf/1.3.0-0/nconf-1.3.0-0.tgz -O $HOME/NConf.tgz

# Unpack NConf
RUN tar xzvf $HOME/NConf.tgz -C $WWWHOME;cp $WWWHOME/nconf/INSTALL/create_database.sql $HOME/create_database.sql
RUN rm -rf $WWWHOME/nconf/INSTALL* $WWWHOME/nconf/UPDATE*; rm -rf $WWWHOME/nconf/config/; cp -rp $WWWHOME/nconf/config.orig/ $WWWHOME/nconf/config/

# Configure NConf
RUN sed -ie "s|^define('NCONFDIR'.*|define('NCONFDIR', \"$WWWHOME/nconf\")\;|" $WWWHOME/nconf/config/nconf.php
RUN sed -ie "s|^define('NAGIOS_BIN'.*|define('NAGIOS_BIN', \"/usr/sbin/nagios\")\;|" $WWWHOME/nconf/config/nconf.php

# Configure Apache
RUN sed -ie "s|^Listen.*|Listen 8080|" /etc/apache2/httpd.conf
RUN sed -ie "s|^User apache.*|User nconf|" /etc/apache2/httpd.conf
RUN sed -ie "s|^Group apache.*|Group nconf|" /etc/apache2/httpd.conf
RUN sed -ie "s|/var/www/localhost/htdocs|$WWWHOME/nconf|" /etc/apache2/httpd.conf
RUN chown -R $USERID:$GROUPID /var/log/apache2 /run/apache2

# Configure MySQL
RUN mkdir -p /run/mysqld
RUN chown -R $USERID:$GROUPID /var/lib/mysql /run/mysqld

# Add files to image
COPY create_db_and_user.sql $HOME
COPY startup_db.sh $HOME
COPY supervisord.conf $HOME

# Set last permissions, switch user, start all processes and expose HTTP port
RUN chown -R $USERID:$GROUPID $HOME $WWWHOME
RUN chmod 775 /usr/sbin/nagios
USER $USERID
EXPOSE 8080
CMD /usr/bin/supervisord -c $HOME/supervisord.conf
