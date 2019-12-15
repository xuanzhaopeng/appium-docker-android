### Scrcpy builder
FROM ubuntu:16.04 as scrcpyBuilder

RUN apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
    sudo \
    && rm -rf /var/lib/apt/lists/*
#========================================
# Add normal user with passwordless sudo
#========================================
# Layer size: tiny: 0.3 MB
RUN useradd seluser \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo seluser \
  && echo 'seluser:secret' | chpasswd \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers

#========================================
# Switch to normal user
#========================================
USER seluser
WORKDIR /home/seluser

#========================================
# Install dependencies
#========================================
RUN sudo apt-get -qqy update && \
    sudo apt-get -qqy --no-install-recommends install \
    openjdk-8-jdk \
    make \
    gcc  \
    pkg-config \
    python3-pip \
    python3-setuptools \
    ninja-build \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libsdl2-dev \
    git \
    wget \
    unzip

#=====================
# Install Android SDK
#=====================
ARG SDK_VERSION=sdk-tools-linux-3859397
ARG ANDROID_BUILD_TOOLS_VERSION=27.0.3
ENV ANDROID_HOME=/home/seluser

RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R $ANDROID_HOME
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

RUN echo y | sdkmanager "platform-tools"
RUN echo y | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

#=====================
# Build scrcpy
#=====================
RUN sudo python3 -m pip install -U pip && sudo pip install meson
RUN git clone -b feature/websocket-server https://github.com/xuanzhaopeng/scrcpy.git
RUN cd scrcpy && mkdir -p x && meson x --buildtype release --strip -Db_lto=true
RUN cd scrcpy/x && ninja && sudo ninja install

### Appium Android Docker
FROM ubuntu:16.04

LABEL maintainer "Robin <xuanzhaopeng@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

#=============
# Set WORKDIR
#=============
WORKDIR /root

#==================
# General Packages
#------------------
# openjdk-8-jdk
#   Java
# ca-certificates
#   SSL client
# tzdata
#   Timezone
# unzip
#   Unzip zip file
# curl
#   Transfer data from or to a server
# wget
#   Network downloader
# libqt5webkit5
#   Web content engine (Fix issue in Android)
# libgconf-2-4
#   Required package for chrome and chromedriver to run on Linux
# xvfb
#   X virtual framebuffer
#==================
RUN apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
    openjdk-8-jdk \
    ca-certificates \
    tzdata \
    unzip \
    curl \
    wget \
    libqt5webkit5 \
    libgconf-2-4 \
    xvfb \
  && rm -rf /var/lib/apt/lists/*

#===============
# Set JAVA_HOME
#===============
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre" \
    PATH=$PATH:$JAVA_HOME/bin

#=====================
# Install Android SDK
#=====================
ARG SDK_VERSION=sdk-tools-linux-3859397
ARG ANDROID_BUILD_TOOLS_VERSION=26.0.0
ENV SDK_VERSION=$SDK_VERSION \
    ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION \
    ANDROID_HOME=/root

RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R $ANDROID_HOME && \
    chown -R root:root $ANDROID_HOME
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin

# https://askubuntu.com/questions/885658/android-sdk-repositories-cfg-could-not-be-loaded
RUN mkdir -p ~/.android
RUN touch ~/.android/repositories.cfg

RUN echo y | sdkmanager "platform-tools"
RUN echo y | sdkmanager "build-tools;$ANDROID_BUILD_TOOLS_VERSION"
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

#====================================
# Install latest nodejs, npm, appium
#====================================
ARG APPIUM_VERSION=1.15.1
ENV APPIUM_VERSION=$APPIUM_VERSION

ARG CHROMEDRIVER_VERSION=77.0.3865.40
ENV CHROMEDRIVER_VERSION=$CHROMEDRIVER_VERSION

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} --unsafe-perm=true --allow-root --no-shrinkwrap  && \
    npm cache clean --force && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

#==================================
# Setup ws scrcpy
#==================================
RUN apt-get -qqy update && \
    apt-get -qqy --no-install-recommends install \
    ffmpeg \
    libsdl2-2.0.0 \
  && rm -rf /var/lib/apt/lists/*

COPY --from=scrcpyBuilder /usr/local/bin/scrcpy /usr/local/bin/
COPY --from=scrcpyBuilder /usr/local/share/scrcpy/scrcpy-server.jar /usr/local/share/scrcpy/

#==================================
# Fix Issue with timezone mismatch
#==================================
ENV TZ="US/Pacific"
RUN echo "${TZ}" > /etc/timezone

#===============
# Expose Ports
#---------------
# 4723
#   Appium port
#===============
EXPOSE 4723

#====================================================
# Scripts to run appium and connect to Selenium Grid
#====================================================
COPY \
  Appium/entry_point.sh \
  Appium/generate_config.sh \
  Appium/usbreset \
    /root/
RUN chmod +x /root/entry_point.sh
RUN chmod +x /root/generate_config.sh
RUN chmod +x /root/usbreset

#========================================
# Run xvfb and appium server
#========================================
CMD ["/root/entry_point.sh"]
