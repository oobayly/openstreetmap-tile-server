FROM ubuntu:22.04

ENV JDK_VERSION=8
ENV ANT_VERSION=1.10.14
ENV ANT_HOME=/opt/ant
ENV SEACHART_REPO=https://github.com/oobayly/josm-plugins.git
ENV SEACHART_BRANCH=seachart-jrender

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      ca-certificates gnupg lsb-release locales \
      wget \
      git-core unzip unrar \
      openjdk-${JDK_VERSION}-jdk-headless \
      libpostgis-java

# change to tmp folder
WORKDIR /tmp

# Download and extract apache ant to opt folder
RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
    && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz.sha512 \
    && echo "$(cat apache-ant-${ANT_VERSION}-bin.tar.gz.sha512) apache-ant-${ANT_VERSION}-bin.tar.gz" | sha512sum -c \
    && tar -zvxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ \
    && ln -s /opt/apache-ant-${ANT_VERSION} /opt/ant \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz \
    && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz.sha512

# add executables to path
RUN update-alternatives --install "/usr/bin/ant" "ant" "/opt/ant/bin/ant" 1 && \
    update-alternatives --set "ant" "/opt/ant/bin/ant" 

# Fetch jsom-plugins
RUN mkdir -p /src \
  && cd /src \
  && git clone --no-checkout --filter=blob:none --sparse ${SEACHART_REPO} \
  && cd josm-plugins \
  && git sparse-checkout add seachart \
  && git checkout ${SEACHART_BRANCH}

WORKDIR /
COPY build.sh /

