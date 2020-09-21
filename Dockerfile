FROM ubuntu:16.04

ARG HELM_CHECKSUM_ARG=246d58b6b353e63ae8627415a7340089015e3eb542ff7b5ce124b0b1409369cc
ARG HELM_VERSION_ARG=3.3.3

ENV HELM_VERSION=$HELM_VERSION_ARG

RUN apt-get update \
  && apt-get -y install curl \
  && curl -fsSL https://downloads-openshift-console.apps.cluster.chp4.io/amd64/linux/oc.tar --output oc.tar \
  && tar xvf oc.tar \
  && mv oc /usr/local/bin \
  && chmod +x /usr/local/bin/oc \
  && rm -f oc.tar

RUN curl -fsSL "https://get.helm.sh/helm-v$HELM_VERSION_ARG-linux-amd64.tar.gz" --output helm.tar.gz \
  && echo "$HELM_CHECKSUM_ARG *helm.tar.gz" | sha256sum -c - \
  && tar xvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin \
  && chmod +x /usr/local/bin/helm \
  && rm -f helm.tar.gz \
  && rm -rf linux-amd64
