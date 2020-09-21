FROM ubuntu:16.04

ARG HELM_CHECKSUM_ARG=87d302b754b6f702f4308c2aff190280ff23cc21c35660ef93d78c39158d796f
ARG HELM_VERSION_ARG=3.3.1

ENV HELM_VERSION=$HELM_VERSION_ARG

RUN apt-get update \
  && apt-get -y install curl \
  && curl -fsSL https://downloads-openshift-console.apps.cluster.chp4.io/amd64/linux/oc.tar --output oc.tar \
  && tar xvf oc.tar \
  && mv oc /usr/local/bin \
  && chmod +x /usr/local/bin/oc \
  && rm -f oc.tar

RUN curl -fsSL https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz --output helm.tar.gz \
  && echo "$HELM_CHECKSUM_ARG *helm.tar.gz" | sha256sum -c - \
  && tar xvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin \
  && chmod +x /usr/local/bin/helm \
  && rm -f helm.tar.gz \
  && rm -rf linux-amd64
