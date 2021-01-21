#!/bin/bash

# this need to execute at container inside.

sudo su -
cd /tmp/
cp -pf /usr/share/jenkins/jenkins.war /usr/share/jenkins/jenkins.war_20210121
cp -pf /usr/lib/jenkins-plugin-manager.jar /usr/lib/jenkins-plugin-manager.jar_20210121
ls -lt /usr/share/jenkins/jenkins.war* /usr/lib/jenkins-plugin-manager.jar*

export JENKINS_SHA=89d054193d541b8d542f61e13262daf842b13fd5c04bfdc52765c70346f0878e
export JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/2.263.2/jenkins-war-2.263.2.war
curl -fsSL ${JENKINS_URL} -o /tmp/jenkins.war
echo "${JENKINS_SHA} /tmp/jenkins.war" | sha256sum -c -
cp -pf /tmp/jenkins.war /usr/share/jenkins/jenkins.war

export PLUGIN_CLI_URL=https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.2.0/jenkins-plugin-manager-2.2.0.jar
curl -fsSL ${PLUGIN_CLI_URL} -o /usr/lib/jenkins-plugin-manager.jar

echo " - remember to restart this jenkins container."
# --- END --- #
