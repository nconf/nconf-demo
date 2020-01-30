FROM alpine:3.5
LABEL maintainer="NConf Team - http://www.nconf.org"

# Run update and install dependencies
RUN echo @oldrepo http://dl-cdn.alpinelinux.org/alpine/v3.0/main >> /etc/apk/repositories
RUN apk update && apk upgrade && apk add bash wget apache2 php5-apache2 php5-mysql php5-ldap mariadb mysql-client perl@oldrepo perl-dbi@oldrepo perl-dbd-mysql@oldrepo supervisor

# Fetch NConf
RUN wget --no-check-certificate https://sourceforge.net/projects/nconf/files/nconf/1.3.0-0/nconf-1.3.0-0.tgz -O /tmp/NConf.tgz

ENV HOME /root
ENV WWWHOME /var/www/localhost/htdocs
WORKDIR $HOME

# Unpack NConf
RUN mv /tmp/NConf.tgz $HOME/NConf.tgz
RUN tar xzvf $HOME/NConf.tgz -C $WWWHOME
RUN chown -R apache:apache $WWWHOME/nconf
RUN chmod 755 $WWWHOME/nconf
RUN cp $WWWHOME/nconf/INSTALL/create_database.sql $HOME/create_database.sql
RUN rm -rf $WWWHOME/nconf/INSTALL* $WWWHOME/nconf/UPDATE*; rm -rf $WWWHOME/nconf/config/; cp -rp $WWWHOME/nconf/config.orig/ $WWWHOME/nconf/config/

# Configure NConf config variables
RUN sed -ie "11s/^/#/g" $WWWHOME/nconf/config/nconf.php
RUN sed -ie "16s|^|define('NCONFDIR', \"$WWWHOME/nconf\")\;|g" $WWWHOME/nconf/config/nconf.php

# Add files to image
COPY create_db_and_user.sql $HOME
COPY startup_db.sh $HOME
COPY supervisord.conf /etc/supervisord.conf

# Start all processes and expose HTTP port
RUN mkdir /run/apache2/
RUN ln -s /run/mysqld/ /var/run/mysqld
CMD /usr/bin/supervisord -c /etc/supervisord.conf
EXPOSE 80
