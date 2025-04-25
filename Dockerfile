FROM ubuntu:16.04

ARG OPENSSL_URL=https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
ARG PYTHON_URL=https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz

# ARG UNAME=user
# ARG UID=1000
# ARG GID=1000

ENV TZ=Etc/UTC

# RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# RUN set -eux; \
#     groupadd -g $GID $UNAME; \
#     useradd -m -u $UID -g $GID -s /bin/bash $UNAME

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
        git \
        gzip \
        p7zip-full \
        python \
        software-properties-common \
        subversion \
        sudo

RUN set -eux; \
    apt -y install \
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
        libtool \
        libx11-xcb-dev \
        libxcb* \
        libxi-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        libxrender-dev \
        libxss1

RUN set -eux; \
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash; \
    apt -y install nodejs; \
    npm install -g grunt-cli pkg

RUN set -eux; \
    add-apt-repository -y ppa:openjdk-r/ppa; \
    apt -y update; \
    apt -y install openjdk-11-jdk; \
    update-alternatives --config java; \
    update-alternatives --config javac

RUN set -eux; \
    curl -fsSL $OPENSSL_URL | tar xvzf -; \
    cd openssl-1.1.1w; \
    ./config -static zlib; \
    make -j $(nproc); \
    make install

RUN set -eux; \
    apt -y install \
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
        zlib1g-dev; \
    curl -fsSL $PYTHON_URL | tar xvzf -; \
    cd Python-3.10.13; \
    ./configure --enable-optimizations --with-lto --with-computed-gotos --with-system-ffi; \
    make -j $(nproc); \
    make install

RUN set -eux; \
    cd /usr/local/bin; \
    ln -sr idle3 idle; \
    ln -sr pip3 pip; \
    ln -sr pydoc3 pydoc; \
    ln -sr python3 python; \
    ln -sr python3-config python-config

ADD qt /opt/qt/5.9.9/gcc_64

WORKDIR /workspace

# COPY entrypoint.sh /entrypoint.sh
# USER $UNAME
# ENTRYPOINT ["/entrypoint.sh"]
