# Build From: 3.13.0, 3.13, 3, latest
FROM scratch
#ADD http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/x86_64/alpine-minirootfs-3.13.0-x86_64.tar.gz /
ADD alpine-minirootfs-3.13.0-x86_64.tar.gz /

### add i18n - begin
ENV MUSL_LOCALE_DEPS cmake make musl-dev gcc gettext-dev libintl
ENV MUSL_LOCPATH /usr/share/i18n/locales/musl

RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS
RUN apk add --no-cache \
    $MUSL_LOCALE_DEPS \
    && wget https://gitlab.com/rilian-la-te/musl-locales/-/archive/master/musl-locales-master.zip \
    && unzip musl-locales-master.zip \
      && cd musl-locales-master \
      && cmake -DLOCALE_PROFILE=OFF -D CMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install \
      && cd .. && rm -r musl-locales-master
### add i18n - end

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN apk --update add --no-cache tzdata --virtual .build-deps curl binutils zstd && \
    GLIBC_VER="2.31-r0" && \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-10.1.0-2-x86_64.pkg.tar.zst" && \
    GCC_LIBS_SHA256="f80320a03ff73e82271064e4f684cd58d7dbdb07aa06a2c4eea8e0f3c507c45c" && \
    ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" && \
    ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 && \
    curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" && \
    echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk && \
    apk add --no-cache /tmp/glibc-${GLIBC_VER}.apk  && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk && \ 
    apk add --no-cache /tmp/glibc-bin-${GLIBC_VER}.apk && \
    curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    apk add --no-cache /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.zst && \
    echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.zst" | sha256sum -c - && \
    mkdir /tmp/gcc && \
    zstd -d /tmp/gcc-libs.tar.zst --output-dir-flat /tmp && \
    tar -xf /tmp/gcc-libs.tar -C /tmp/gcc && \
    mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib && \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* && \
    curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz && \
    echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - && \
    mkdir /tmp/libz && \
    tar -xf /tmp/libz.tar.xz -C /tmp/libz && \
    mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib && \
    apk del --purge .build-deps glibc-i18n && \
    rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar* /tmp/libz /tmp/libz.tar.xz /var/cache/apk/*

ENV JAVA_VERSION=jdk8u275-b01

RUN set -eux; \
    apk add --no-cache --virtual .fetch-deps curl; \
    ARCH="$(apk --print-arch)"; \
    case "${ARCH}" in \
      aarch64|arm64) \
        ESUM='aeade06192ce4544f998b4957cd2c0ed3f9f8eac08b0de5d2ed55c55283364af'; \
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_aarch64_linux_hotspot_8u275b01.tar.gz'; \
      ;; \
      armhf|armv7l) \
        ESUM='e2e41a8705061dfcc766bfb6b7edd4c699e94aac68e4deeb28c8e76734a46fb7'; \
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_arm_linux_hotspot_8u275b01.tar.gz'; \
      ;; \
      ppc64el|ppc64le) \
        ESUM='a7b1c803e581f226216f73aca878bfd1b149c422b63e42e64eeeecda78c2253b'; \
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_ppc64le_linux_hotspot_8u275b01.tar.gz'; \
      ;; \
      s390x) \
        ESUM='f513b895d28bdc2011b698e4a9ee3ea524d0e7bb62d87b0f53814a326573ec04'; \
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_s390x_linux_hotspot_8u275b01.tar.gz'; \
      ;; \
      amd64|x86_64) \
        ESUM='06fb04075ed503013beb12ab87963b2ca36abe9e397a0c298a57c1d822467c29'; \
        BINARY_URL='https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_hotspot_8u275b01.tar.gz'; \
      ;; \
      *) \
        echo "Unsupported arch: ${ARCH}"; \
        exit 1; \
      ;; \
    esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/java/openjdk; \
    cd /opt/java/openjdk; \
    tar -xf /tmp/openjdk.tar.gz --strip-components=1; \
    apk del --purge .fetch-deps; \
    rm -rf /var/cache/apk/*; \
    rm -rf /tmp/openjdk.tar.gz;

ENV JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/java/openjdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apk add --no-cache bash coreutils curl git git-lfs openssh-client tini ttf-dejavu tzdata unzip

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000

ARG JENKINS_HOME=/var/jenkins_home
ARG REF=/usr/share/jenkins/ref
ENV JENKINS_SLAVE_AGENT_PORT=50000

RUN mkdir -p $JENKINS_HOME && \
    chown ${uid}:${gid} $JENKINS_HOME && \
    addgroup -g ${gid} ${group} && \
    adduser -h "$JENKINS_HOME" -u ${uid} -G ${group} -s /bin/bash -D ${user}

VOLUME [/var/jenkins_home]

RUN mkdir -p ${REF}/init.groovy.d

ARG JENKINS_VERSION
ENV JENKINS_VERSION=2.263.2

ARG JENKINS_SHA=89d054193d541b8d542f61e13262daf842b13fd5c04bfdc52765c70346f0878e
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/2.263.2/jenkins-war-2.263.2.war

RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war && \
    echo "${JENKINS_SHA} /usr/share/jenkins/jenkins.war" | sha256sum -c -

ENV JENKINS_UC=https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals

RUN chown -R ${user} "$JENKINS_HOME" "$REF"

ARG PLUGIN_CLI_URL=https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.2.0/jenkins-plugin-manager-2.2.0.jar

RUN curl -fsSL ${PLUGIN_CLI_URL} -o /usr/lib/jenkins-plugin-manager.jar

EXPOSE 8080
EXPOSE 50000

ENV COPY_REFERENCE_FILE_LOG=/var/jenkins_home/copy_reference_file.log
USER jenkins

COPY ./jenkins-support /usr/local/bin/jenkins-support
COPY ./jenkins.sh /usr/local/bin/jenkins.sh
COPY ./tini /bin/tini
COPY ./jenkins-plugin-cli /bin/jenkins-plugin-cli

### customize part - begin
ARG DOCKER_VERSION=18.09.0
USER root
ENV HELM_VERSION="v2.14.1"
ENV TERRAFORM_VERSION="0.12.7"
# 20210114 stable verion KUBE_VERSION="v1.20.2"
#ARG KUBE_VERSION="1.15.1"
ARG KUBE_VERSION="v1.20.2"

# set timezone
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
RUN echo "Asia/Taipei" >  /etc/timezone
RUN date
RUN apk del tzdata

# install sudo as root
RUN apk update && apk add sudo docker-compose tzdata && \
    echo "$user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${user} && \
    chmod 0440 /etc/sudoers.d/${user} && \
    cp -f /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    echo "Asia/Taipei" > /etc/timezone

# set env
RUN apk add bash vim curl jq git openssh-client ca-certificates

# install kubectl - stable version
#RUN cd /usr/local/bin/;curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl;chmod +x /usr/local/bin/kubectl;kubectl version --client

# install kubectl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v$KUBE_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# install helm
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-${HELM_VERSION}-linux-amd64.tar.gz"

RUN curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    mkdir /root/.kube

# install terraform & awscli
#RUN apk add -t deps libc6-compat py-pip python3 && \
RUN mv /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /usr/glibc-compat/lib/ld-linux-x86-64.so && \
    ln -s /usr/glibc-compat/lib/ld-linux-x86-64.so /usr/glibc-compat/lib/ld-linux-x86-64.so.2
RUN apk add -t deps py-pip python3 && \
    pip install awscli

RUN cd /usr/local/bin && \
    curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# install maven
RUN apk add maven

# clear apk cache
RUN apk del --purge deps && \
    rm -f /var/cache/apk/*

USER ${user}
### customize part - end

ENTRYPOINT ["/sbin/tini" "--" "/usr/local/bin/jenkins.sh"]
COPY ./install-plugins.sh /usr/local/bin/install-plugins.sh 

### customize part - begin
# install jenkins' plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
### customize part - end

USER root
RUN apk -U add docker
USER jenkins
RUN install-plugins.sh antisamy-markup-formatter matrix-auth blueocean:$BLUEOCEAN_VERSION

### customize part - begin
# clear apk cache
RUN apk del --purge deps && \
    rm -f /var/cache/apk/*
### customize part - end

# --- END --- #
