FROM amazonlinux:2017.03
MAINTAINER CloudOps Version 1.0

USER root

# Update the yum packages
RUN yum -y update \
        && yum install sudo procps shadow-utils -y \
        && yum clean all \
        && yum install  yum-utils  tar autoconf autogen intltool make -y \
        && yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y \
        && yum install gcc perl-ExtUtils-MakeMaker -y

# Add Jenkins remoting and user
RUN groupadd -g 10000 jenkins \
        && useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins

RUN mkdir /opt/jdk; mkdir /usr/share/jenkins/; mkdir /home/jenkins; 
ADD https://s3-ap-southeast-1.amazonaws.com/jenkins-ecs-slave-depends/remoting-3.19.jar /usr/share/jenkins/slave.jar
RUN chmod 755 /usr/share/jenkins \
	&& chmod 755 /usr/share/jenkins/slave.jar

COPY jenkins-slave /usr/local/bin/jenkins-slave
RUN chmod a+rwx /home/jenkins && chmod a+rwx /usr/local/bin/jenkins-slave
WORKDIR /home/jenkins

#installing aws CLI
RUN yum -y install python \
   && curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" \
   && python get-pip.py \
   && pip install awscli

#installing git
ADD https://s3-ap-southeast-1.amazonaws.com/jenkins-ecs-slave-depends/git-2.17.0.tar.gz /tmp/git-2.17.0.tar.gz
RUN tar -xf /tmp/git-2.17.0.tar.gz  -C /tmp \
   && cd /tmp/git-2.17.0 && make configure && ./configure --prefix=/usr/local && make install

# Copy docker and install
ADD https://s3-ap-southeast-1.amazonaws.com/jenkins-ecs-slave-depends/docker-latest.tgz /tmp/docker-latest.tgz
RUN tar xzf /tmp/docker-latest.tgz -C /tmp \
	&& rm /tmp/docker-latest.tgz \
    && chmod -R +x /tmp/docker/ \
    && mv /tmp/docker/* /usr/bin/

# Copy JDK and install
ADD https://s3-ap-southeast-1.amazonaws.com/jenkins-ecs-slave-depends/jdk-8u161-linux-x64.tar.gz  /tmp/java/jdk-8u161-linux-x64.tar.gz
RUN tar -zxf /tmp/java/jdk-8u161-linux-x64.tar.gz -C /opt/jdk; rm -f /tmp/java/jdk-8u161-linux-x64.tar.gz && update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.8.0_161/bin/java 100; update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.8.0_161/bin/javac 100
ENV JAVA_HOME /opt/jdk/jdk1.8.0_161

# Copy ANT and install
#COPY apache-ant-1.9.6-bin.tar.gz /tmp/ant/
#RUN tar -zxf /tmp/ant/apache-ant-1.9.6-bin.tar.gz && \
#mv apache-ant-1.9.6 /opt/ant && \
#rm -f /tmp/ant/apache-ant-1.9.6-bin.tar.gz
#ENV ANT_HOME /opt/ant
#ENV PATH ${PATH}:${ANT_HOME}/bin

#Copy Maven and install
#COPY apache-maven-3.5.3-bin.tar.gz /tmp/maven/
#RUN tar -zxf /tmp/maven/apache-maven-3.5.3-bin.tar.gz && \
#mv apache-maven-3.5.3 /opt/maven && \
#rm -f /tmp/maven/apache-maven-3.5.3-bin.tar.gz
#ENV MAVEN_HOME /opt/maven
#ENV PATH ${PATH}:${MAVEN_HOME}/bin

USER jenkins
ENV JENKINS_AGENT_WORKDIR=/home/jenkins/agent
RUN mkdir /home/jenkins/.jenkins && mkdir -p /home/jenkins/agent

VOLUME /home/jenkins/.jenkins
VOLUME /home/jenkins/agent
WORKDIR /home/jenkins


ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
