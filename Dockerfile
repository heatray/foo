FROM ubuntu:16.04

ARG UNAME=user
ARG UID=1000
ARG GID=1000

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN set -eux; \
    groupadd -g $GID $UNAME; \
    useradd -m -u $UID -g $GID -s /bin/bash $UNAME

RUN set -eux; \
    apt-get -y update; \
    apt-get -y install \
        python \
        python3 \
        sudo; \
    ln -sf /usr/bin/python2 /usr/bin/python

COPY entrypoint.sh /entrypoint.sh

USER $UNAME
WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
