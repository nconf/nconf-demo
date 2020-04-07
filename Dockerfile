FROM alpine:3.11
LABEL maintainer="NConf Team - http://www.nconf.org"

# Set Env
ENV HOME=/home/nconf \
    WWWHOME=/var/www \
    USERID=10000 \
    GROUPID=10000

# Run update and install dependencies
RUN echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/main >> /etc/apk/repositories; \
    echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/community >> /etc/apk/repositories; \
    echo @repo3_0 http://dl-cdn.alpinelinux.org/alpine/v3.0/main >> /etc/apk/repositories

RUN apk update && apk upgrade && \
    apk add wget apache2 mariadb mysql-client supervisor \
            php5-apache2@repo3_8 php5-mysql@repo3_8 php5-ldap@repo3_8 \
            perl@repo3_0 perl-dbi@repo3_0 perl-dbd-mysql@repo3_0 nagios@repo3_0

# Create install directories, users and groups
RUN mkdir -p $HOME $WWWHOME; \
    addgroup -g $GROUPID nconf; \
    adduser -D -h $HOME -u $USERID -G nconf nconf

# Set workdir
WORKDIR $HOME

# Fetch NConf release package from Sourceforge
RUN wget --no-check-certificate https://sourceforge.net/projects/nconf/files/nconf/1.3.0-0/nconf-1.3.0-0.tgz -O $HOME/NConf.tgz

# Unpack NConf
RUN tar xzvf $HOME/NConf.tgz -C $WWWHOME; \
    cp $WWWHOME/nconf/INSTALL/create_database.sql $HOME/create_database.sql; \
    rm -rf $WWWHOME/nconf/INSTALL* $WWWHOME/nconf/UPDATE*; \
    rm -rf $WWWHOME/nconf/config/; \
    cp -rp $WWWHOME/nconf/config.orig/ $WWWHOME/nconf/config/

# Configure NConf
RUN sed -i \
        -e "s|^define('NCONFDIR'.*|define('NCONFDIR', \"$WWWHOME/nconf\")\;|" \
        -e "s|^define('NAGIOS_BIN'.*|define('NAGIOS_BIN', \"/usr/sbin/nagios\")\;|" \
        $WWWHOME/nconf/config/nconf.php

# Configure Apache
RUN sed -i \
        -e "s|^Listen.*|Listen 8080|" \
        -e "s|^User apache.*|User nconf|" \
        -e "s|^Group apache.*|Group nconf|" \
        -e "s|/var/www/localhost/htdocs|$WWWHOME/nconf|" \
        /etc/apache2/httpd.conf

# Copy external files into image
COPY create_db_and_user.sql startup_db.sh supervisord.conf $HOME/

# Create missing directories and set permissions
RUN mkdir -p /var/log/apache2; \
    mkdir -p /run/apache2; \
    chown -R $USERID:$GROUPID /var/log/apache2 /run/apache2; \
    mkdir -p /run/mysqld; \
    chown -R $USERID:$GROUPID /var/lib/mysql /run/mysqld; \
    chown -R $USERID:$GROUPID $HOME $WWWHOME; \
    chown -R $USERID:$GROUPID /var/nagios /etc/nagios; \
    chmod 775 /usr/sbin/nagios

# Switch user, start all processes and expose port
USER $USERID
EXPOSE 8080
CMD /usr/bin/supervisord -c $HOME/supervisord.conf
