FROM ubuntu:26.04

LABEL org.opencontainers.image.description="ubuntu with kubernetes, docker, oc, helm, used in ci/cd tasks"
LABEL maintainer="digitaal-techniek@vpro.nl,michiel@mmprogrami.nl"


RUN apt-get update &&\
  apt-get -y upgrade &&\
  export DEBIAN_FRONTEND=noninteractive &&\
  apt-get -y install curl gnupg libxml2-utils make docker.io ca-certificates sudo gpg  apt-transport-https && \
  apt-get clean && rm -rf /var/lib/apt/lists/*


RUN cd /tmp && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) OC_SUFFIX="" ;; \
      *)     OC_SUFFIX="-${ARCH}" ;; \
    esac && \
    curl -LO https://mirror.openshift.com/pub/openshift-v5/clients/ocp/stable/openshift-client-linux${OC_SUFFIX}.tar.gz && \
    tar -xvf openshift-client-linux${OC_SUFFIX}.tar.gz &&  \
    mv oc /usr/local/bin &&\
    chmod +x /usr/local/bin/oc &&\
    mv kubectl /usr/local/bin &&\
    chmod +x /usr/local/bin/kubectl &&\
    rm -f *


RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null &&\
     echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main"  | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list &&\
     apt-get update &&\
     apt-get -y install helm=4.2.3-1 &&\
     apt-get clean && rm -rf /var/lib/apt/lists/*


ENV KANIKO_SCRIPTS=/
ENV HELM_SCRIPTS=/

COPY --from=ghcr.io/npo-poms/kaniko:13 /dockerfile-functions.sh $KANIKO_SCRIPTS
COPY scripts/* $HELM_SCRIPTS


RUN chmod +x /script.sh && \
    mkdir /workspace

WORKDIR /workspace

# This is default for docker, handy in gitlab when it is like that, so you don't need to specifiy it everytime
SHELL ["/bin/bash", "-c"]


RUN date > /DOCKER.BUILD
