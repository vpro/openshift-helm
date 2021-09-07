FROM frolvlad/alpine-glibc


RUN  apk add --no-cache curl \
  && curl -fsSL https://downloads-openshift-console.apps.cluster.chp4.io/amd64/linux/oc.tar --output oc.tar \
  && apk del curl \
  && tar xvf oc.tar \
  && mv oc /usr/local/bin \
  && chmod +x /usr/local/bin/oc \
  && rm -f oc.tar

ENTRYPOINT ["/bin/sh"]
CMD []
