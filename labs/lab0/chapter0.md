## Introduction

In this lab, we are going to leverage a process known as [`oc cluster up`](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md). `oc cluster up` leverages the local docker daemon and enables us to quickly stand up a local OpenShift Container Platform to start our evaluation. The key result of `oc cluster up` is a reliable, reproducible OpenShift environment to iterate on.

Expected completion: 5-10 minutes

## Find your AWS Instance
This lab is designed to accommodate many students. As a result, each student will be given a VM running on AWS. The naming convention for the lab VMs is:

**student-\<number\>**.labs.sysdeseng.com

You will be assigned a number by the instructor.

Retrieve the key from the [instructor host](https://instructor.labs.sysdeseng.com/summit/L1108.pem) so that you can _SSH_ into the instances by accessing the password protected directory from the table above. Download the _L1108.pem_ file to your local machine and change the permissions of the file to 600.

```bash
$ PASSWD=<password from instructor>
$ wget --no-check-certificate --user student --password ${PASSWD} https://instructor.labs.sysdeseng.com/summit/L1108.pem
$ chmod 600 L1108.pem
```

## Connecting to your AWS Instance
This lab should be performed on **YOUR ASSIGNED AWS INSTANCE** as `ec2-user` unless otherwise instructed.

**_NOTE_**: Please be respectful and only connect to your assigned instance. Every instance for this lab uses the same public key so you could accidentally (or with malicious intent) connect to the wrong system. If you have any issues please inform an instructor.
```bash
$ ssh -i L1108.pem ec2-user@student-<number>.labs.sysdeseng.com
```

**NOTE**: For Windows users you will have to use a terminal like [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) to SSH using the private key. 

Once installed, use the following instructions to SSH to your VM instance: [http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/putty.html).

TIP: Use the rhte.ppk key located at:  [instructor host](https://instructor.labs.sysdeseng.com/L1108.ppk) as PuTTY uses a different format for its keys.

## Getting Set Up
For the sake of time, some of the required setup has already been taken care of on your AWS VM. For future reference though, the easiest way to get started is to head over to the OpenShift Origin repo on github and follow the "[Getting Started](https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md)" instructions. The instructions cover getting started on Windows, MacOS, and Linux.

Since some of these labs will have long running processes, it is recommended to use something like `tmux` or `screen` in case you lose your connection at some point so you can reconnect:
```bash
$ sudo yum -y install screen
$ screen
```

In case you get disconnected use `screen -x` or `tmux attach` to reattach once you reestablish ssh connectivity. If you are unfamiliar with screen, check out this [quick tutorial](https://www.mattcutts.com/blog/a-quick-tutorial-on-screen/). For tmux here is a [quick tutorial](https://fedoramagazine.org/use-tmux-more-powerful-terminal/).

All that's left to do is run OpenShift by executing the `start-oc.sh` script in your home directory. First, let's take a look at what this script is doing, it's grabbing AWS instance metadata so that it can configure OpenShift to start up properly on AWS:
```bash
$ cat ~/start-oc.sh
```
Now, let's start our local, containerized OpenShift environment:
```bash
$ ~/start-oc.sh
```

The resulting output should be something of this nature
```bash
Using nsenter mounter for OpenShift volumes
Using 127.0.0.1 as the server IP
Starting OpenShift using registry.access.redhat.com/openshift3/ose:v3.9.14 ...
OpenShift server started.

The server is accessible via web console at:
    https://<public hostname>:8443

You are logged in as:
    User:     developer
    Password: <any value>

To login as administrator:
    oc login -u system:admin
```
You should get a lot of feedback about the launch of OpenShift. As long as you don't get any errors you are in good shape.

OK, so now that OpenShift is available, let's ask for a cluster status & take a look at our running containers:
```bash
$ oc version
$ oc cluster status
```

As noted before, `oc cluster up` leverages docker for running
OpenShift. You can see that by checking out the containers and
images that are managed by docker:

```bash
$ sudo docker ps
$ sudo docker images
```
We can also check out the OpenShift console. Open a browser and navigate to `https://<public-hostname>:8443`. Be sure to use http*s* otherwise you will get weird web page. Once it loads (and you bypass the certificate errors), you can log in to the console using the default developer username (use any password).

## Lab Materials

Clone the lab repository from github:
```bash
$ cd ~/
$ git clone https://github.com/dustymabe/summit-2018-container-lab
```

## OpenShift Container Platform

What is OpenShift? OpenShift, which you may remember as a "[PaaS](https://en.wikipedia.org/wiki/Platform_as_a_service)" to build applications on, has evolved into a complete container platform based on Kubernetes. If you remember the "[DIY Cartridges](https://github.com/openshift/origin-server/blob/master/documentation/oo_cartridge_guide.adoc#diy)" from older versions of Openshift, essentially, OpenShift v3 has expanded the functionality to provide complete containers. With OpenShift, you can build from a platform, build from scratch, or anything else you can do in a container, and still get the complete lifecycle automation you loved in the older versions.

You are now ready to move on to the [next lab](../lab1/chapter1.md).
