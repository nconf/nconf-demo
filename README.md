# What is NConf?
NConf is a PHP based web-tool for configuring the Nagios monitoring software. It differs from similar tools by offering enterprise-class features like templates, dependencies and the ability to configure a large-scale, distributed Nagios topology. 
Visit http://www.nconf.org

# How to use this image
## Start nconf-demo instance

`$ docker run --name nconf -d -p 80:8080 nconf/nconf-demo:latest`

Then point your browser to http://localhost

The `nconf-demo` image is based on Alpine and contains Apache, PHP, Perl, MariaDB, Nagios etc. It is a fully self-contained runtime environment for NConf. Multiple processes are run an daemons inside the container using `supervisord`. No data is persisted and the DB is recreated every time the container starts. Therefore, `nconf-demo` is intended for demo purposes only and is strictly **NOT FOR PRODUCTION USE.** 
