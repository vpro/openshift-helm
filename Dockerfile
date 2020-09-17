FROM ubuntu:16.04

RUN cd /tmp \
  && apt-get update \
  && apt-get install curl \
  && apt-get install -y wget \
  && wget https://github.com/openshift/origin/releases/download/v1.3.2/openshift-origin-client-tools-${OPENSHIFT_CLIENT_VERSION}-${OPENSHIFT_TAG}-linux-64bit.tar.gz \
  && tar -xvzf openshift-origin-client-tools-${OPENSHIFT_CLIENT_VERSION}-${OPENSHIFT_TAG}-linux-64bit.tar.gz \
  && mv openshift-origin-client-tools-${OPENSHIFT_CLIENT_VERSION}-${OPENSHIFT_TAG}-linux-64bit/oc /usr/local/bin/ \
  && rm -rf openshift-origin-client-tools-${OPENSHIFT_CLIENT_VERSION}-${OPENSHIFT_TAG}-linux-64bit openshift-origin-client-tools-${OPENSHIFT_CLIENT_VERSION}-${OPENSHIFT_TAG}-linux-64bit.tar.gz

  
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-${HELM_VERSION} && chmod 700 get_helm.sh && ./get_helm.sh
