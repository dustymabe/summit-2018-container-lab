# LAB 1: podman and buildah

In this lab we will explore the podman environment. If you are familiar with podman this may function as a brief refresher. If you are new to podman this will serve as an introduction to podman basics. Don't worry, we will progress rapidly. To get through this lab, we are going to focus on the environment itself as well as walk through some exercises with a couple of podman images/containers to tell a complete story and point out some things that you might have to consider when containerizing your application.

What is [podman](https://github.com/projectatomic/libpod), you may ask? Well, the README explains it in detail but, in short, it is a tool for manipulating OCI compliant containers created by docker or other tools (such as buildah). The docker utility provides build, run, and push functions on docker containers via a docker daemon. We are leveraging three daemonless tools, which support OCI compliant containers, that do each function separately. Namely, [buildah](https://github.com/projectatomic/buildah) for building, [skopeo](https://github.com/projectatomic/skopeo) for pushing/pulling from registries, and podman for verification/run. podman will transparently use the buildah and skopeo technologies for the user to build and push/pull from registries, all without the overhead of a separate daemon running all the time.

This lab should be performed on **YOUR ASSIGNED AWS VM** as `ec2-user` unless otherwise instructed.

Expected completion: 15-20 minutes

Agenda:

* Review podman, buildah and docker
* Review podman and buildah help
* Explore a Dockerfile
* Build an image
* Launch a container
* Inspect a container
* Build image registry

Perform the following commands as `ec2-user` unless instructed otherwise.

## podman and docker

Both podman and docker share configuration files so if you are using docker in your environment these will be useful as well. These files tell podman how the storage and networking should be set up and configured. In the /run/containers/registries.conf file check out the registry settings. You may find it interesting that you can *add a registry* and *block a registry* by modifying /etc/containers/registries.conf. Think about the different use cases for that.

```bash
$ cat /etc/containers/registries.conf #but don't add things here
$ cat /etc/containers/registries.d/default.yaml #instead, duplicate this
$ cat /etc/containers/storage.conf
$ cat /etc/containers/policy.json
```

Unlike docker, podman doesn't need an always running daemon. There are no podman processes running on the system:

```bash
$ pgrep podman | wc -l
```

However, the docker daemon is running. You can see that and also check
the status of the docker daemon:

```bash
$ pgrep docker | wc -l
$ systemctl status docker
```

## podman and buildah Help

Now that we see how the podman startup process works, we should make sure we know how to get help when we need it.  Run the following commands to get familiar with what is included in the podman package as well as what is provided in the man pages. Spend some time exploring here.

Check out the executable provided:
```bash
$ rpm -ql podman | grep bin
$ rpm -ql buildah | grep bin
```

Check out the configuration file(s) that are provided:
```bash
$ rpm -qc podman
$ rpm -qc buildah
```

Check out the documentation that is provided:
```bash
$ rpm -qd podman
$ rpm -qd buildah
```

Run `podman {help,info}` to check out the storage configuration and how to find more information.
```bash
$ podman --help
$ podman run --help
$ sudo podman info
```

Run `buildah help` to check out general options and get detailed information about specific options.
```bash
$ buildah --help
$ buildah copy --help
```

## Let's explore a Dockerfile

Here we are just going to explore a simple Dockerfile. The purpose for this is to have a look at some of the basic commands that are used to construct a podman or docker image. For this lab, we will explore a basic Apache httpd Dockerfile and then confirm functionality.

Change to `~/summit-2018-container-lab/labs/lab1` and `cat` out the Dockerfile
```bash
$ cd ~/summit-2018-container-lab/labs/lab1
$ cat Dockerfile
```
```dockerfile
FROM registry.access.redhat.com/rhel7
MAINTAINER Student <student@example.com>

RUN yum -y install httpd --disablerepo "*" --enablerepo rhel-7-server-rpms
RUN echo "Apache" >> /var/www/html/index.html
RUN echo 'PS1="[apache]#  "' > /etc/profile.d/ps1.sh

EXPOSE 80

# Simple startup script to avoid some issues observed with container restart
ADD run-apache.sh /run-apache.sh
RUN chmod -v +x /run-apache.sh

CMD [ "/run-apache.sh" ]
```

Here you can see in the `FROM` command that we are pulling a RHEL 7 base image that we are going to build on. Containers that are being built inherit the subscriptions of the host they are running on, so you only need to register the host system.

After gaining access to a repository we update the container and install `httpd`. Finally, we modify the index.html file, `EXPOSE` port 80,which allows traffic into the container, and then set the container to start with a `CMD` of `run-apache.sh`.

## Build an Image

Now that we have taken a look at the Dockerfile, let's build this image. We could use the exact same command, swapping podman for docker, to build with docker.
```bash
$ sudo podman build -t redhat/apache .
$ sudo podman images
```

Podman is not actually building this image, technically it is wrapping buildah to do so. If you wanted to use buildah directly you could do the same thing as `sudo podman build -t redhat/apache .` by using `sudo buildah build-using-dockerfile -t redhat/apache .`. You can even see `buildah images` will report the same thing as `podman images`. 

```bash
$ sudo buildah images
```

## Run the Container

Next, let's run the image and make sure it started.
```bash
$ sudo podman run -dt -p 8080:80 --name apache redhat/apache
$ sudo podman ps
```

Here we are using a few switches to configure the running container the way we want it. We are running a `-dt` to run in detached mode with a pseudo TTY. Next we are mapping a port from the host to the container. We are being explicit here. We are telling podman to map port 8080 on the host to port 80 in the container. Now, we could have let podman handle the host side port mapping dynamically by passing a `-p 80`, in which case podman would have randomly assigned a port to the container. Finally, we passed in the name of the image that we built earlier. If you wish, you can swap podman for docker and the exact same commands will work.

Okay, let's make sure we can access the web server.
```bash
$ curl http://localhost:8080
Apache
```

Now that we have built an image, launched a container and confirmed that it is running, lets do some further inspection of the container. We should take a look at the container IP address.  Let's use `podman inspect` to do that.

## Time to Inspect

```bash
$ sudo podman inspect apache
```

We can see that this gives us quite a bit of information in json format. We can scroll around and find the IP address, it will be towards the bottom.

Let's be more explicit with our `podman inspect`
```bash
$ sudo podman inspect --format '{{ .NetworkSettings.IPAddress }}' apache
```

You can see the IP address that was assigned to the container.

We can apply the same filter to any value in the json output. Try a few different ones.

Now lets look inside the container and see what that environment looks like. Execute commands in the namespace with `podman exec <container-name OR container-id> <cmd>`
```bash
$ sudo podman exec -t apache bash
```

Now run some commands and explore the environment. Remember, we are in a slimmed down container at this point - this is by design. You may find surprising restrictions and that not every application you expect is available.
```bash
[apache]# ps aux
[apache]# ls /bin
[apache]# cat /etc/hosts
```

Remember, you can always install what you need while you are debugging something. However, remember it won't be there on the next start of the container unless you add it to your Dockerfile. For example: 
```bash
[apache]# less /run-apache.sh
bash: less: command not found
[apache]# yum install -y less --disablerepo "*" --enablerepo rhel-7-server-rpms
[apache]# less /run-apache.sh
...
```

Exit the container namespace with `CTRL+d` or `exit`.

Whew, so we do have some options. Now, remember that this lab is all about containerizing your existing apps. You will need some of the tools listed above to go through the process of containerizing your apps. Troubleshooting problems when you are in a container is going to be something that you get very familiar with.

Before we move on to the next section let's clean up the apache container so we don't have it hanging around.
```bash
$ sudo podman rm -f apache
```

In the [next lab](../lab2/chapter2.md) we will be analyzing a monolithic application.
