#!/bin/bash

#
# Minimal example for deploying latest built 'Ansible Service Broker'
# on oc cluster up
#


#
# We deploy oc cluster up with an explicit hostname and routing suffix
# so that pods can access routes internally.
#
# For example, we need to register the ansible service broker route to
# the service catalog when we create the broker resource. The service
# catalog needs to be able to communicate to the ansible service broker.
#
# When we use the default "127.0.0.1.nip.io" route suffix, requests
# from inside the cluster fail with an error like:
#
#    From Service Catalog: controller manager
#    controller.go:196] Error syncing Broker ansible-service-broker:
#    Get https://asb-1338-ansible-service-broker.127.0.0.1.nip.io/v2/catalog:
#    dial tcp 127.0.0.1:443: getsockopt: connection refused
#
# To resolve this, we explicitly set the
#    --public-hostname and --routing-suffix
#
# We use the IP of the docker interface on our host for testing in a
# local environment, or the external listening IP if we want to expose
# the cluster to the outside.
#
# Below will default to grabbing the IP of docker0, typically this is
# 172.17.0.1 if not customized
#
#source ~/cleanup-oc.sh
docker pull docker.io/ansibleplaybookbundle/origin-ansible-service-broker:v3.9
docker tag docker.io/ansibleplaybookbundle/origin-ansible-service-broker:v3.9 docker.io/ansibleplaybookbundle/origin-ansible-service-broker:latest

ASB_VERSION=ansible-service-broker-1.1.17-1
NAMESPACE=ansible-service-broker
#BROKER_IMAGE="registry.access.redhat.com/openshift3/ose-ansible-service-broker:v3.7"
#ETCD_IMAGE="registry.access.redhat.com/rhel7/etcd:latest"
#ETCD_PATH="/usr/bin/etcd"

# REGISTRY_USER <- RHCC user, REGISTRY_PASS <- RHCC password, REGISTRY_TYPE="rhcc", REGISTRY_NAME="rhcc", REGISTRY_URL="https://registry.access.redhat.com"
#metadata_endpoint="http://169.254.169.254/latest/meta-data"
#PUBLIC_HOSTNAME="$( curl -s "${metadata_endpoint}/public-hostname" )"
#PUBLIC_IP="$( curl -s "${metadata_endpoint}/public-ipv4" )"
#DOCKER_IP="$(ip addr show docker0 | grep -Po 'inet \K[\d.]+')"
#DOCKER_IP=${DOCKER_IP:-"127.0.0.1"}
#PUBLIC_IP=${PUBLIC_IP:-$DOCKER_IP}
#HOSTNAME=${PUBLIC_IP}.nip.io
#ROUTING_SUFFIX="${HOSTNAME}"

#oc cluster up --service-catalog=true --routing-suffix=${ROUTING_SUFFIX} --public-hostname=${PUBLIC_HOSTNAME}

#
# Logging in as system:admin so we can create a clusterrolebinding and
# creating ansible-service-broker project
#
oc login -u system:admin
oc new-project $NAMESPACE

#
# A valid dockerhub username/password is required so the broker may
# authenticate with dockerhub to:
#
#  1) inspect the available repositories in an organization
#  2) read the manifest of each repository to determine metadata about
#     the images
#
# This is how the Ansible Service Broker determines what content to
# expose to the Service Catalog
#
# Note:  dockerhub API requirements require an authenticated user only,
# the user does not need any special access beyond read access to the
# organization.
#
# By default, the Ansible Service Broker will look at the
# 'ansibleplaybookbundle' organization, this can be overridden with the
# parameter DOCKERHUB_ORG being passed into the template.
#
TEMPLATE_URL=${TEMPLATE_URL:-"https://raw.githubusercontent.com/openshift/ansible-service-broker/${ASB_VERSION}/templates/deploy-ansible-service-broker.template.yaml"}
DOCKERHUB_ORG=${DOCKERHUB_ORG:-"ansibleplaybookbundle"} # DocherHub org where APBs can be found, default 'ansibleplaybookbundle'
ENABLE_BASIC_AUTH="false"
VARS="-p BROKER_CA_CERT=$(oc get secret -n kube-service-catalog -o go-template='{{ range .items }}{{ if eq .type "kubernetes.io/service-account-token" }}{{ index .data "service-ca.crt" }}{{end}}{{"\n"}}{{end}}' | tail -n 1)"

# Creating openssl certs to use.
mkdir -p /tmp/etcd-cert
openssl req -nodes -x509 -newkey rsa:4096 -keyout /tmp/etcd-cert/key.pem -out /tmp/etcd-cert/cert.pem -days 365 -subj "/CN=asb-etcd.$NAMESPACE.svc"
openssl genrsa -out /tmp/etcd-cert/MyClient1.key 2048 \
&& openssl req -new -key /tmp/etcd-cert/MyClient1.key -out /tmp/etcd-cert/MyClient1.csr -subj "/CN=client" \
&& openssl x509 -req -in /tmp/etcd-cert/MyClient1.csr -CA /tmp/etcd-cert/cert.pem -CAkey /tmp/etcd-cert/key.pem -CAcreateserial -out /tmp/etcd-cert/MyClient1.pem -days 1024

ETCD_CA_CERT=$(cat /tmp/etcd-cert/cert.pem | base64)
BROKER_CLIENT_CERT=$(cat /tmp/etcd-cert/MyClient1.pem | base64)
BROKER_CLIENT_KEY=$(cat /tmp/etcd-cert/MyClient1.key | base64)

 # -p BROKER_IMAGE="$BROKER_IMAGE" -p ETCD_IMAGE="$ETCD_IMAGE" -p ETCD_PATH="$ETCD_PATH" \
 curl -s $TEMPLATE_URL \
  | oc process \
  -n $NAMESPACE \
  -p DOCKERHUB_ORG="$DOCKERHUB_ORG" \
  -p ENABLE_BASIC_AUTH="$ENABLE_BASIC_AUTH" \
  -p ETCD_TRUSTED_CA_FILE=/var/run/etcd-auth-secret/ca.crt \
  -p BROKER_CLIENT_CERT_PATH=/var/run/asb-etcd-auth/client.crt \
  -p BROKER_CLIENT_KEY_PATH=/var/run/asb-etcd-auth/client.key \
  -p ETCD_TRUSTED_CA="$ETCD_CA_CERT" \
  -p BROKER_CLIENT_CERT="$BROKER_CLIENT_CERT" \
  -p BROKER_CLIENT_KEY="$BROKER_CLIENT_KEY" \
  -p NAMESPACE="$NAMESPACE" \
  $VARS -f - | oc create -f -
if [ "$?" -ne 0 ]; then
  echo "Error processing template and creating deployment"
  exit
fi

#
# Then login as 'developer'/'developer' to WebUI
# Create a project
# Deploy mediawiki to new project (use a password other than
#   admin since mediawiki forbids admin as password)
# Deploy PostgreSQL(ABP) to new project
# After they are up
# Click 'Create Binding' on the kebab menu for Mediawiki,
#   select postgres
# Click deploy on mediawiki, after it's redeployed access webui
#
