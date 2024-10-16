#!/bin/bash
#HELM_IMAGE=ghcr.io/vpro/openshift-helm:3.0
HELM_IMAGE=vpro/openshift-helm:dev


docker run -v ~/conf:/conf -v ~:/root -v "$(pwd)":/workspace $HELM_IMAGE
#docker run -it -v ~/conf:/conf -v ~:/root -v "$(pwd)":/workspace $HELM_IMAGE /bin/bash
