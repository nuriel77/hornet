FROM alpine:latest

ARG REPO="gohornet/hornet"
ARG TAG=latest
ARG ARCH=x86_64
ARG OS=Linux

LABEL org.label-schema.description="HORNET - The IOTA community node"
LABEL org.label-schema.name="gohornet/hornet"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vcs-url="https://github.com/gohornet/hornet"
LABEL org.label-schema.usage="https://github.com/gohornet/hornet/blob/master/DOCKER.md"

WORKDIR /app

RUN apk --no-cache add curl jq tini tar\
 && if [ "$TAG" = "latest" ];\
    then\
      HORNET_TAG=$(curl --retry 3 -f -s https://api.github.com/repos/${REPO}/releases/latest | jq -r .tag_name | tr -d 'v');\
    else\
      HORNET_TAG="${TAG//v}";\
    fi\
 && echo "Downloading from https://github.com/${REPO}/releases/download/v${HORNET_TAG}/HORNET-${HORNET_TAG}_${OS}_${ARCH}.tar.gz ..."\
 && curl -f -L --retry 3 "https://github.com/${REPO}/releases/download/v${HORNET_TAG}/HORNET-${HORNET_TAG}_${OS}_${ARCH}.tar.gz" -o /tmp/hornet.tgz\
 && tar --wildcards --strip-components=1 -xf /tmp/hornet.tgz -C /app/ */hornet */config.json */neighbors.json\
 && if [ "$ARCH" = "x86_64" ];\
    then\
      curl -f -L --retry 3 -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub;\
      curl -f -L --retry 3 -o glibc-2.30-r0.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.30-r0/glibc-2.30-r0.apk;\
      apk add glibc-2.30-r0.apk;\
      rm glibc-2.30-r0.apk;\
    fi\
 && addgroup --gid 39999 hornet\
 && adduser -h /app -s /bin/sh -G hornet -u 39999 -D hornet\
 && chmod +x /app/hornet\
 && chown hornet:hornet -R /app\
 && rm /tmp/hornet.tgz\
 && apk del jq curl

# Not exposing ports, as it might be more efficient to run this on host network because of performance gain.
# | Host mode networking can be useful to optimize performance, and in situations where a container needs
# | to handle a large range of ports, as it does not require network address translation (NAT), and no
# | “userland-proxy” is created for each port.
# Source: https://docs.docker.com/network/host/

USER hornet
ENTRYPOINT ["/sbin/tini", "--", "/app/hornet"]
