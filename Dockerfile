FROM ubuntu:24.04

LABEL org.opencontainers.image.description="ubuntu with kubernetes, docker, oc, helm, used in ci/cd tasks"

RUN apt-get update &&\
  apt-get -y upgrade &&\
  export DEBIAN_FRONTEND=noninteractive &&\
  apt-get -y install curl gnupg libxml2-utils make docker.io ca-certificates sudo gpg  apt-transport-https && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl" && \
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl.sha256" &&\
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check &&\
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

RUN curl -fsSL https://downloads-openshift-console.apps.cluster.chp5-prod.npocloud.nl/$(dpkg --print-architecture)/linux/oc.tar --output oc.tar &&\
  tar xvf oc.tar &&\
  mv oc /usr/local/bin &&\
  chmod +x /usr/local/bin/oc &&\
  rm -f oc.tar

RUN curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null &&\
     echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main"  | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list &&\
     apt-get update &&\
     apt-get -y install helm=3.19.0-1 &&\
     apt-get clean && rm -rf /var/lib/apt/lists/*


ENV KANIKO_SCRIPTS=/
ENV HELM_SCRIPTS=/

COPY --from=ghcr.io/npo-poms/kaniko:10 /dockerfile-functions.sh $KANIKO_SCRIPTS
COPY scripts/* $HELM_SCRIPTS


RUN chmod +x /script.sh && \
    mkdir /workspace

WORKDIR /workspace

# This is default for docker, handy in gitlab when it is like that, so you don't need to specifiy it everytime
SHELL ["/bin/bash", "-c"]


RUN date > /DOCKER.BUILD
