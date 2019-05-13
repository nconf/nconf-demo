FROM centos:7
LABEL maintainer="NConf Team - http://www.nconf.org"

# Run update and install dependencies
RUN yum -y update && yum -y install wget httpd-2* php-5* php-mysql php-ldap mariadb-server-5* perl-5* perl-DBI perl-DBD-MySQL python-setuptools
RUN easy_install supervisor

# Fetch NConf
RUN wget https://sourceforge.net/projects/nconf/files/nconf/1.3.0-0/nconf-1.3.0-0.tgz -O /tmp/NConf.tgz

# Add non-root user "swuser"
#RUN groupadd -r swuser -g 433 && \
#useradd -u 431 -r -g swuser -d /home/swuser -s /sbin/nologin -c "Docker image user" swuser && \
#mkdir /home/swuser && \
#chown -R swuser:swuser /home/swuser
#ENV HOME /home/swuser
ENV HOME /root
WORKDIR $HOME

# Unpack NConf
RUN mv /tmp/NConf.tgz $HOME/NConf.tgz
RUN tar xzvf $HOME/NConf.tgz -C /var/www/html/
RUN chown -R apache:apache /var/www/html/nconf
RUN chmod 755 /var/www/html/nconf
RUN cp /var/www/html/nconf/INSTALL/create_database.sql $HOME/create_database.sql
RUN rm -rf /var/www/html/nconf/INSTALL* /var/www/html/nconf/UPDATE*; rm -rf /var/www/html/nconf/config/; cp -rp /var/www/html/nconf/config.orig/ /var/www/html/nconf/config/

# Configure NConf config variables
RUN sed -ie "11s/^/#/g" /var/www/html/nconf/config/nconf.php
RUN sed -ie "16s|^|define('NCONFDIR', \"/var/www/html/nconf/\")\;|g" /var/www/html/nconf/config/nconf.php

# Switch to non-root user
#USER swuser

# Add files to image
COPY create_db_and_user.sql $HOME
COPY startup_db.sh $HOME
COPY supervisord.conf /etc/supervisord.conf

# Start all processes and expose HTTP port
CMD /usr/bin/supervisord -c /etc/supervisord.conf
EXPOSE 80
