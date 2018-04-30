# LAB 2: Analyzing a Monolithic Application

Typically, it is best to break down services into the simplest components and then containerize each of them independently. However, when initially migrating an application it is not always easy to break it up into little pieces but you can start with big containers and work towards breaking them into smaller pieces.

In this lab we will create an all-in-one container image comprised of multiple services. We will also observe several bad practices when composing Dockerfiles and explore how to avoid those mistakes. In lab 3 we will decompose the application into more manageable pieces.

This lab should be performed on **YOUR ASSIGNED AWS VM** as `ec2-user` unless otherwise instructed.

Expected completion: 20-25 minutes

Agenda:

* Overview of monolithic application
* Build podman image
* Run container based on podman image
* Exploring the running container
* Connecting to the application
* Review Dockerfile practices

## Monolithic Application Overview

Our monolithic application we are going to use in this lab is a simple wordpress application. Rather than decompose the application into multiple parts we have elected to put the database and the wordpress application into the same container. Our container image will have:

* mariadb and all dependencies
* wordpress and all dependencies

To perform some generic configuration of mariadb and wordpress there are startup configuration scripts that are executed each time a container is started from the image. These scripts configure the services and then start them in the running container.

## Building the podman Image

View the `Dockerfile` provided for `bigapp` which is not written with best practices in mind:
```bash
$ cd ~/summit-2018-container-lab/labs/lab2/bigapp/
$ cat Dockerfile
```

Build the podman image for this by executing the following command. This can take a while to build. While you wait you may want to peek at the [Review Dockerfile Practices](#review-dockerfile-practices) section at the end of this lab chapter.
```bash
$ sudo podman build -t bigimg .
```

## Run Container Based on podman Image

To run the podman container based on the image we just built use the following command:
```bash
$ sudo podman run -P --name=bigapp -e DBUSER=user -e DBPASS=mypassword -e DBNAME=mydb -d bigimg
$ sudo podman ps
```

Take a look at some of the arguments we are passing to podman. With `-P` we are telling podman to publish all ports the container exposes (i.e. from the Dockerfile) to randomly assigned ports on the host. In this case port 80 will get assigned to a random host port. Next we are providing a ```name``` of ```bigapp```. After that we are setting some environment variables that will be passed into the container and consumed by the configuration scripts to set up the container. Finally, we pass it the name of the image that we built in the prior step.

## Exploring the Running Container

Now that the container is running we will explore the container to see what's going on inside. First off, the processes were started and any output that goes to stdout will come to the console of the container. You can run `podman logs` to see the output. To follow 
or "tail" the logs use the `-f` option.

**__NOTE:__** You are able to use the **name** of the container rather than the container id for most `podman` (or `docker`) commands.
```bash
$ sudo podman logs -f bigapp
```

**__NOTE:__** When you are finished inspecting the log, just CTRL-C out.

If you need to inspect more than just the stderr/stdout of the machine then you can enter into the namespace of the container to inspect things more closely. The easiest way to do this is to use `podman exec`. Try it out:
```bash
$ sudo podman exec -t bigapp /bin/bash
[CONTAINER_NAMESPACE]# pstree
[CONTAINER_NAMESPACE]# cat /var/www/html/wp-config.php | grep '=='
[CONTAINER_NAMESPACE]# tail /var/log/httpd/access_log /var/log/httpd/error_log /var/log/mariadb/mariadb.log
```

Explore the running processes.  Here you will see `httpd` and `MySQL` running.

```bash
[CONTAINER_NAMESPACE]# ps aux
```

Press `CTRL+d` or type `exit` to leave the container shell.

## Connecting to the Application

First detect the host port number that is is mapped to the container's port 80:
```bash
$ sudo podman port bigapp 80
```

Now connect to the port via curl:
```bash
$ curl -L http://localhost:<port>/
```

## Review Dockerfile practices

So we have built a monolithic application using a somewhat complicated Dockerfile. There are a few principles that are good to follow when creating a Dockerfile that we did not follow for this monolithic app.

To illustrate some problem points in our Dockerfile it has been replicated below with some commentary added:
```dockerfile
FROM registry.access.redhat.com/rhel7

>>> No tags on image specification - updates could break things

MAINTAINER Student <student@example.com>

# ADD set up scripts
ADD  scripts /scripts

>>> If a local script changes then we have to rebuild from scratch

RUN chmod 755 /scripts/*

# Common Deps
RUN yum -y install openssl --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN yum -y install psmisc --disablerepo "*" --enablerepo rhel-7-server-rpms

>>> Running a yum clean all in the same statement would clear the yum
>>> cache in our intermediate cached image layer

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

>>> Can group all of the above into one yum statement to minimize 
>>> intermediate layers. However, during development, it can be nice 
>>> to keep them separated so that your "build/run/debug" cycle can 
>>> take advantage of layers and caching. Just be sure to clean it up
>>> before you publish. You can check out the history of the image you
>>> have created by running *podman history bigimg*.

# Add in wordpress sources 
COPY latest.tar.gz /latest.tar.gz

>>> Consider using a specific version of Wordpress to control the installed version

RUN tar xvzf /latest.tar.gz -C /var/www/html --strip-components=1 
RUN rm /latest.tar.gz
RUN chown -R apache:apache /var/www/

>>> Can group above statements into one multiline statement to minimize 
>>> space used by intermediate layers. (i.e. latest.tar.gz would not be 
>>> stored in any image).

EXPOSE 80
CMD ["/bin/bash", "/scripts/start.sh"]
```

More generally:

* Use a specific tag for the source image. Image updates may break things.
* Place rarely changing statements towards the top of the file. This allows the re-use of cached image layers when rebuilding.
* Group statements into multi-line statements. This avoids layers that have files needed only for build.
* Use `LABEL run` instruction to prescribe how the image is to be run.
* Avoid running applications in the container as root user where possible. The final `USER` declaration in the Dockerfile should specify the [user ID (numeric value)](https://docs.openshift.com/container-platform/latest/creating_images/guidelines.html#openshift-specific-guidelines) and not the user name. If the image does not specify a USER, it inherits the USER from the parent image.
* Use `VOLUME` instruction to create a host mount point for persistent storage.

In the [next lab](../lab3/chapter3.md) we will fix these issues and break the application up into separate services.
