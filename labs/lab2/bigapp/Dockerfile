FROM registry.access.redhat.com/rhel7
MAINTAINER Student <student@example.com>

# ADD set up scripts
ADD scripts /scripts
RUN chmod 755 /scripts/*

# Common Deps
RUN yum -y install openssl --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install psmisc --disablerepo "*" --enablerepo rhel-7-server-rpms

# Deps for wordpress
RUN yum -y install httpd --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install php --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install php-mysql --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install php-gd --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install tar --disablerepo "*" --enablerepo rhel-7-server-rpms

# Deps for mariadb
RUN yum -y install mariadb-server --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install net-tools --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install hostname --disablerepo "*" --enablerepo rhel-7-server-rpms

# Add in wordpress sources 
COPY latest.tar.gz /latest.tar.gz
RUN tar xvzf /latest.tar.gz -C /var/www/html --strip-components=1 
RUN rm /latest.tar.gz
RUN chown -R apache:apache /var/www/

EXPOSE 80
CMD ["/bin/bash", "/scripts/start.sh"]
