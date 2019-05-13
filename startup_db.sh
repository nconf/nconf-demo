#!/bin/bash

# Prepare and start MySQL / MariaDB in background
mysql_install_db --user=mysql --basedir=/usr/ --ldata=/var/lib/mysql/
mysqld_safe --basedir=/usr &
sleep 3s

# Create DB user and schema
mysql < $HOME/create_db_and_user.sql
mysql NConf < $HOME/create_database.sql
