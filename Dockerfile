FROM alpine:3.11
LABEL maintainer="NConf Team - http://www.nconf.org"

# Run update and install dependencies
RUN echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/main >> /etc/apk/repositories
RUN echo @repo3_8 http://dl-cdn.alpinelinux.org/alpine/v3.8/community >> /etc/apk/repositories
RUN echo @repo3_0 http://dl-cdn.alpinelinux.org/alpine/v3.0/main >> /etc/apk/repositories
RUN apk update && apk upgrade && apk add wget apache2 php5-apache2@repo3_8 php5-mysql@repo3_8 php5-ldap@repo3_8 mariadb mysql-client perl@repo3_0 perl-dbi@repo3_0 perl-dbd-mysql@repo3_0 supervisor

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
CMD /usr/bin/supervisord -c /etc/supervisord.conf
EXPOSE 80
