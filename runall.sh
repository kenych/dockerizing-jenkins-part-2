#!/usr/bin/env bash

jenkins_port=8080
sonar_port=9001
artifactory_port=8081

docker pull jenkins/jenkins:2.164.1
docker pull sonarqube:6.7.6-community

if [ ! -d downloads ]; then
    mkdir downloads
    curl -o downloads/jdk-8u201-linux-x64.tar.gz -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz
    curl -o downloads/apache-maven-3.6.0-bin.tar.gz http://mirrors.gigenet.com/apache/maven/maven-3/3.6.0/binaries/apache-maven-3.6.0-bin.tar.gz
fi

docker stop mysonar myjenkins artifactory 2>/dev/null

docker build -t myjenkins .

docker run -d -p ${sonar_port}:9000 --rm --name mysonar sonarqube:6.7.6-community
docker run  -d --rm -p ${artifactory_port}:8081 --name artifactory  docker.bintray.io/jfrog/artifactory-oss:5.7.4

IP=$(ifconfig en0 | awk '/ *inet /{print $2}')

if [ ! -d m2deps ]; then
    mkdir m2deps
fi

docker run -d -p ${jenkins_port}:8080 -v `pwd`/downloads:/var/jenkins_home/downloads \
    -v `pwd`/jobs:/var/jenkins_home/jobs/ \
    -v `pwd`/m2deps:/var/jenkins_home/.m2/repository/ --rm --name myjenkins \
    -e SONARQUBE_HOST=http://${IP}:${sonar_port} \
    -e ARTIFACTORY_URL=http://${IP}:${artifactory_port}/artifactory/example-repo-local \
    myjenkins:latest

echo "Sonarqube is running at http://${IP}:${sonar_port}"
echo "Artifactory is running at http://${IP}:${artifactory_port}"
echo "Jenkins is running at http://${IP}:${jenkins_port}"
