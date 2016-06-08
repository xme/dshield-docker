#
# Dockerfile to build a DShield SSH Honeypot container
#
# 2016/03/14 - First release
# 
# Docker creation:
# docker build -t dshield/honeypot .
#

# We are based on Ubuntu:latest
FROM ubuntu
MAINTAINER Xavier Mertens <xavier@rootshell.be>

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive
ARG DSHIELD_EMAIL
ARG DSHIELD_UID
ARG DSHIELD_APIKEY

# Upgrade Ubuntu
RUN \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get autoremove -y && \
  apt-get clean

# Install the required packages
RUN \
  apt-get install -y git dialog libswitch-perl libwww-perl python-twisted python-crypto python-pyasn1 python-gmpy2 python-zope.interface python-pip python-gmpy python-gmpy2 python-requests mysql-client randomsound rng-tools python-mysqldb curl openssh-server unzip debconf debconf-utils logrotate sudo

# Clone the DShield software
RUN \
  cd /root && \
  git clone https://github.com/DShield-ISC/dshield.git

# Install Cowrie
RUN pip install python-dateutil
RUN adduser --disabled-password --quiet --home /srv/cowrie --no-create-home cowrie
RUN git clone https://github.com/micheloosterhof/cowrie.git /srv/cowrie
RUN ssh-keygen -t dsa -b 1024 -N '' -f /srv/cowrie/data/ssh_host_dsa_key
RUN cp /root/dshield/etc/logrotate.d/cowrie /etc/logrotate.d

# Add run script
COPY start-docker.sh /srv/cowrie
RUN chmod 755 /srv/cowrie/start-docker.sh
RUN chown -R cowrie:cowrie /srv/cowrie

EXPOSE 2222
ENTRYPOINT ["/srv/cowrie/start-docker.sh"]
