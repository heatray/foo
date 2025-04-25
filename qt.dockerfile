FROM ubuntu:14.04 as qt-trusty

ARG QT_URL=https://download.qt.io/new_archive/qt/5.9/5.9.9/single/qt-everywhere-opensource-src-5.9.9.tar.xz

RUN set -eux; \
    apt -y update; \
    apt -y install \
        libasound2-dev \
        libatspi2.0-dev \
        libcups2-dev \
        libdbus-1-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libgles2-mesa-dev \
        libglu1-mesa-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer1.0-dev \
        libgtk-3-dev \
        libicu-dev \
        libpulse-dev \
        libwayland-dev \
        libwayland-egl1-mesa \
        libwayland-server0 \
        libx11-xcb-dev \
        libxcb* \
        libxi-dev \
        libxkbcommon-dev \
        libxrender-dev \
        python \
        wget
RUN set -eux; \
    cd ~; \
    wget $QT_URL; \
    tar -xf ${QT_URL##*/} --no-same-owner; \
    echo "97e81709b57e82ab2b279408eaa9270e  ${QT_URL##*/}" | md5sum -c
RUN set -eux; \
    cd ~/qt-everywhere-opensource-src-5.9.9; \
    ./configure \
        -opensource \
        -confirm-license \
        -release \
        -shared \
        -accessibility \
        -prefix /opt/qt/5.9.9/gcc_64 \
        -qt-zlib \
        -qt-libpng \
        -qt-libjpeg \
        -qt-xcb \
        -qt-pcre \
        -no-sql-sqlite \
        -no-qml-debug \
        -gstreamer 1.0 \
        -nomake examples \
        -nomake tests \
        -skip qtenginio \
        -skip qtlocation \
        -skip qtserialport \
        -skip qtsensors \
        -skip qtxmlpatterns \
        -skip qt3d \
        -skip qtwebview \
        -skip qtwebengine; \
    make -e; \
    make install
RUN ls -la /opt/qt/5.9.9/gcc_64
