FROM jenkins/jenkins:lts
MAINTAINER Marco Lembo <inglembomarco@gmail.com>

LABEL application=pocjenkins

# DEBIAN_FRONTEND: Suppress apt installation warnings
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.footerURL=https://jenkins.io/" \
    DEBIAN_FRONTEND=noninteractive \
    AZ_REPO="$(lsb_release -cs)"

COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

# We put our requirements about the number of executors we want
COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy

USER root

#install Docker Engine
RUN apt-get update && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce && \
    gpasswd -a jenkins docker

#Install Azure CLI
RUN add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" && \
    apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 && \
    curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
    apt-get update && apt-get install -y azure-cli



USER jenkins

# Add Jenkins plugins
#RUN install-plugins.sh \
#  workflow-aggregator \
#  blueocean \
#  sonar \
#  docker-plugin

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt



# Jenkins' Environment
# These environment variables values that we want to have permanently baked into the image.
# They will be available in any container that is instantiated from this image or any other that inherits it.
# These types of variables make it easy to bring consistency across the environment.

ENV JENKINS_HOME /var/jenkins_home
ENV JENKINS_ROOT /usr/share/jenkins


# Add Jenkins init files
#COPY src/jenkins/ /usr/share/jenkins/ref/

# Entrypoint
#ENV DOCKER_GID=100
#COPY src/entrypoint.sh /usr/local/bin/entrypoint.sh
#ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/sbin/tini","--","/usr/local/bin/jenkins.sh"]

