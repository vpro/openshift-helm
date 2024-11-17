#!/bin/bash
HELM_IMAGE=ghcr.io/vpro/openshift-helm:main
#HELM_IMAGE=vpro/openshift-helm:main


if [ -f ~/conf/harbor.properties ] ; then
  . ~/conf/harbor.properties
fi

docker run -v ~/conf:/conf -v ~/.docker:/root/.docker -v ~/.kube:/root/.kube -v "$(pwd)":/workspace   \
    -e HARBOR_USER="${HARBOR_USER}" \
    -e HARBOR_PASSWORD=${HARBOR_PASSWORD} \
     $HELM_IMAGE /script.sh

rm -rf openshift-chart
#docker run -it -v ~/conf:/conf -v ~/.docker:/.docker -v "$(pwd)":/workspace --entrypoint /bin/bash \
#   -e HARBA$HELM_IMAGE
