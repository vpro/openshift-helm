#!/bin/bash


#. /conf/harbor.properties

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