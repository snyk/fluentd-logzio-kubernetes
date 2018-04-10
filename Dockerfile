# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This Dockerfile will build an image that is configured
# to run Fluentd with an Elasticsearch plug-in and the
# provided configuration file.
# TODO(a-robinson): Use a lighter base image, e.g. some form of busybox.
# The image acts as an executable for the binary /usr/sbin/td-agent.
# Note that fluentd is run with root permssion to allow access to
# log files with root only access under /var/log/containers/*
# Please see http://docs.fluentd.org/articles/install-by-deb for more
# information about installing fluentd using deb package.

FROM gcr.io/google_containers/ubuntu-slim:0.4
MAINTAINER Alex Robinson "arob@google.com"
MAINTAINER Jimmi Dyson "jimmidyson@gmail.com"

#make docker user and set him as sudo
#RUN apt-get update
#RUN apt-get install sudo

#RUN adduser --disabled-password --gecos '' docker
#RUN adduser docker sudo
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

#USER docker

RUN CURRENT_USER=`id`
RUN echo 'current user is '
RUN echo `id`
RUN echo $CURRENT_USER

RUN echo going to run 'apt-get update' 
RUN apt-get update

RUN echo going to run 'apt-get install' 
RUN apt-get install -y -q --no-install-recommends \
  curl ca-certificates make g++ sudo bash

# Ensure there are enough file descriptors for running Fluentd.
RUN ulimit -n 65536

# Disable prompts from apt.
ENV DEBIAN_FRONTEND noninteractive

# Copy the Fluentd configuration file.
COPY td-agent.conf /etc/td-agent/td-agent.conf

#COPY build.sh /tmp/build.sh
#RUN sudo /tmp/build.sh

echo going to run 'Install Fluentd' 
# Install Fluentd.
RUN /usr/bin/curl -sSL https://toolbelt.treasuredata.com/sh/install-ubuntu-xenial-td-agent2.sh | sh

# Change the default user and group to root.
# Needed to allow access to /var/log/docker/... files.
RUN sed -i -e "s/USER=td-agent/USER=root/" -e "s/GROUP=td-agent/GROUP=root/" /etc/init.d/td-agent

# Install the Elasticsearch Fluentd plug-in.
# http://docs.fluentd.org/articles/plugin-management
RUN td-agent-gem install --no-document fluent-plugin-kubernetes_metadata_filter -v 0.24.0
RUN td-agent-gem install --no-document fluent-plugin-logzio

# Remove docs and postgres references
RUN rm -rf /opt/td-agent/embedded/share/doc \
  /opt/td-agent/embedded/share/gtk-doc \
  /opt/td-agent/embedded/lib/postgresql \
  /opt/td-agent/embedded/bin/postgres \
  /opt/td-agent/embedded/share/postgresql

RUN apt-get remove -y make g++
RUN apt-get autoremove -y
RUN apt-get clean -y

RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




ENV LD_PRELOAD /opt/td-agent/embedded/lib/libjemalloc.so

# Run the Fluentd service.
ENTRYPOINT ["td-agent"]
