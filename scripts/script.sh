#!/bin/bash
export CHART_PROJECT_NAME=openshift-chart-deployment
export CHART_VERSION=3.2
export TRACE=false

export OS_PROJECT=poms
export OS_ENV=test
export HELM_REPO=oci://registry.npohosting.nl/poms
export HELM_REGISTRY=https://registry.npohosting.nl
export DOCKER_AUTH_CONFIG_FILE=$HOME/.docker/config-gitlab.json



export HARBOR_USER
export HARBOR_PASSWORD
. /conf/harbor.properties

cd /workspace || exit 1

. /workspace/job.env

. /setup-helm.sh

setup_oc_helm

deploy_application "$(pwd)"