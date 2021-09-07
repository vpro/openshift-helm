FROM ubuntu:20.04




RUN apt-get update \
  && apt-get upgrade \
  && apt-get -y install curl gnupg libxml2-utils


RUN  echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list \
  && curl -s  https://baltocdn.com/helm/signing.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=no  apt-key add -  \
  && apt-get update \
  && apt-get -y install helm=3.6.3-1


RUN curl -fsSL https://downloads-openshift-console.apps.cluster.chp4.io/amd64/linux/oc.tar --output oc.tar \
  && tar xvf oc.tar \
  && mv oc /usr/local/bin \
  && chmod +x /usr/local/bin/oc \
  && rm -f oc.tar
