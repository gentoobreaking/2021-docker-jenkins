FROM jenkinsci/blueocean:latest

USER root

ARG USER=jenkins
ENV HELM_VERSION="v2.14.1"
ENV TERRAFORM_VERSION="0.12.7"
# 20210114 stable verion KUBE_VERSION="v1.20.2"
#ARG KUBE_VERSION="1.15.1"
ARG KUBE_VERSION="v1.20.2"

#### ensure version info as the following lines:
##### kubectl version
### Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-13T13:28:09Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
###
##### helm version
###Client: &version.Version{SemVer:"v2.14.1", GitCommit:"5270352a09c7e8b6e8c9593002a73535276507c0", GitTreeState:"clean"}
###
##### docker version
### Client:
### Version:           19.03.12
### API version:       1.40
### Go version:        go1.13.14
### Git commit:        48a66213fe1747e8873f849862ff3fb981899fc6
### Built:             Fri Jul 24 11:43:16 2020
### OS/Arch:           linux/amd64
### Experimental:      false
###
##### java version
### java -version
### openjdk version "1.8.0_272"
### OpenJDK Runtime Environment (AdoptOpenJDK)(build 1.8.0_272-b10)
### OpenJDK 64-Bit Server VM (AdoptOpenJDK)(build 25.272-b10, mixed mode)
### 
### apk add maven
### maven-3.6.3-r0 x86_64 {maven} (Apache-2.0) [installed]
### 
### mvn -v
### Apache Maven 3.6.3 (cecedd343002696d0abb50b32b541b8a6ba2883f)
### Maven home: /usr/share/java/maven-3
### Java version: 1.8.0_272, vendor: AdoptOpenJDK, runtime: /opt/java/openjdk/jre
### Default locale: en_US, platform encoding: UTF-8
### OS name: "linux", version: "4.19.76-linuxkit", arch: "amd64", family: "unix"

### set timezone
RUN apk add tzdata
RUN cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
RUN echo "Asia/Taipei" >  /etc/timezone
RUN date
RUN apk del tzdata

### install sudo as root
RUN apk update && \
    apk add sudo docker-compose tzdata && \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER} && \
    cp -f /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    echo "Asia/Taipei" > /etc/timezone

### set env
RUN apk add bash vim curl jq git openssh-client ca-certificates

### install kubectl - stable version
#RUN cd /usr/local/bin/;curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl;chmod +x /usr/local/bin/kubectl;kubectl version --client

### install kubectl
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v$KUBE_VERSION/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

### install helm
# ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV BASE_URL="https://get.helm.sh"
ENV TAR_FILE="helm-${HELM_VERSION}-linux-amd64.tar.gz"

RUN curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64 && \
    mkdir /root/.kube

### install terraform & awscli
#RUN apk add -t deps libc6-compat py-pip python3 && \
RUN mv /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /usr/glibc-compat/lib/ld-linux-x86-64.so && \
    ln -s /usr/glibc-compat/lib/ld-linux-x86-64.so /usr/glibc-compat/lib/ld-linux-x86-64.so.2
RUN apk add -t deps py-pip python3 aws-cli
#RUN apk add -t deps py-pip python3 && \
#    pip install awscli

RUN cd /usr/local/bin && \
    curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

### install maven
RUN apk add maven

### clear apk cache
RUN apk del --purge deps && \
    rm -f /var/cache/apk/*

### install jenkins' plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

#EXPOSE 8080
#EXPOSE 50000
USER ${USER}

# --- END --- #
