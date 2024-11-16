#!/bin/bash
export CHART_PROJECT_NAME=openshift-chart-deployment
export CHART_VERSION=3.2
export TRACE=false

export OS_PROJECT=poms
export OS_ENV=test
export HELM_REPO=oci://registry.npohosting.nl/poms
export HELM_REGISTRY=https://registry.npohosting.nl


export HARBOR_USER
export HARBOR_PASSWORD
. /conf/harbor.properties

cd /workspace || exit 1

if [ -f job.env ] ; then
  echo "Found job.env"
  cat job.env
  . ./job.env
else
  echo "No job.env"
fi

. "$HELM_SCRIPTS"helm-functions.sh

login_oc
setup_oc_helm
deploy_applications