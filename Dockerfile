FROM ubuntu:16.04

WORKDIR /root

RUN set -eux; \
    apt -y update; \
    apt -y install \
        apt-transport-https \
        autoconf2.13 \
        build-essential \
        crossbuild-essential-arm64 \
        ca-certificates \
        cmake \
        curl \
        fuse \
        git \
        gzip \
        imagemagick \
        p7zip-full \
        patchelf \
        qemu \
        qemu-user-static \
        software-properties-common \
        subversion \
        sudo \
        unzip \
        zip \
        libasound2-dev \
        libatspi2.0-dev \
        libcups2-dev \
        libdbus-1-dev \
        libglu1-mesa-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer1.0-dev \
        libgtk-3-dev \
        libicu-dev \
        libncurses5 \
        libpulse-dev \
        libspice-client-glib-2.0-dev \
        libtool \
        libx11-xcb-dev \
        libxcb* \
        libxi-dev \
        libxkbcommon-x11-dev \
        libxrender-dev \
        libxss1 \
        libbz2-dev \
        liblzma-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        llvm \
        tk-dev \
        xz-utils \
        zlib1g-dev

ARG NODE_URL=https://deb.nodesource.com/setup_16.x
RUN set -eux; \
    curl -fsSL $NODE_URL | bash; \
    apt -y install nodejs; \
    npm install -g grunt-cli pkg

RUN set -eux; \
    add-apt-repository -y ppa:openjdk-r/ppa; \
    apt -y update; \
    apt -y install openjdk-11-jdk; \
    update-alternatives --config java; \
    update-alternatives --config javac
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

ARG OPENSSL_URL=https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
RUN set -eux; \
    curl -fsSL $OPENSSL_URL | tar xvzf -; \
    cd $(basename -z $OPENSSL_URL .tar.gz); \
    ./config -static zlib; \
    make -j $(nproc); \
    make install; \
    rm -rf $PWD

ARG PYTHON_URL=https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
RUN set -eux; \
    curl -fsSL $PYTHON_URL | tar xvzf -; \
    cd $(basename -z $PYTHON_URL .tgz); \
    ./configure --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi; \
    make -j $(nproc); \
    make install; \
    rm -rf $PWD; \
    cd /usr/local/bin; \
    ln -sr idle3 idle; \
    ln -sr pip3 pip; \
    ln -sr pydoc3 pydoc; \
    ln -sr python3 python; \
    ln -sr python3-config python-config

ARG QT_URL=https://download.qt.io/new_archive/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz
ADD qt /opt/qt/5.9.9/gcc_64
ENV QT_PATH=/opt/qt/5.9.9

# ENV TZ=Etc/UTC
# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG UNAME=user \
    UID=1000 \
    GID=1000
RUN set -eux; \
    groupadd -g $GID $UNAME; \
    useradd -m -u $UID -g $GID -s /bin/bash $UNAME; \
    echo "$UNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $UNAME
WORKDIR /home/$UNAME

# COPY entrypoint.sh /entrypoint.sh
# ENTRYPOINT ["/entrypoint.sh"]
