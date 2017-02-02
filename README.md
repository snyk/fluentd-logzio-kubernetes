# Collecting Docker Log Files with Fluentd and [Logz.io](https://logz.io)
This directory contains the source files needed to make a Docker image
that collects Docker container log files using [Fluentd](http://www.fluentd.org/)
and sends them to your [Logz.io](https://logz.io) account.

This image is designed to be used as a [daemonset](http://kubernetes.io/docs/admin/daemons) in a [Kubernetes](https://github.com/kubernetes/kubernetes) cluster.

## Usage

Sign in to your logz.io account. Fluentd connection details will be available at https://app.logz.io/#/dashboard/data-sources/Fluentd

### Customize `daemonset.json`
#### Environment variables
* Replace `_YOUR_ENDPOINT_URL_` with your logz.io access endpoint, such as https://listener.logz.io:8071.
* Replace `_YOUR_TOKEN_` with your logz.io account token.
* Replace `_YOUR_LOG_TYPE_` with the type of logs you are shipping. We are using this as a tag to identify the k8s cluster source of the logs.

The logz.io endpoint URL is `${_YOUR_ENDPOINT_URL_}?token=${_YOUR_TOKEN_}&type=${_YOUR_LOG_TYPE_}`

#### Mount points
* The host's `/var/log` path will be used for fluentd symlinks to the container log files. Needs to be writable.
* The host's `$DOCKER_ROOT/containers` path (`$DOCKER_ROOT=/var/lib/docker` in our case, your mileage may vary) is where the docker container log files are placed. This is where the symlinks from `/var/log/containers` point to. Needs to be readable. See caveat below, change according to your docker root path.

#### Docker tag
* Replace `_YOUR_DOCKER_IMAGE_TAG_` with the docker image tag you will build from this repo.

### Build and deploy
* `docker build -t ${_YOUR_DOCKER_IMAGE_TAG_} .`
* `docker push ${_YOUR_DOCKER_IMAGE_TAG_}`
* `kubectl create -f daemonset.json --validate=false` (disable validation over `readOnly` key in one of the volumes)

### Caveats
* Because of an [issue with mounting symlinked directories](https://github.com/kubernetes/kubernetes/issues/13313), you may need to change the mount points in `daemonset.json` to include your kubelet's _actual_ docker root.

## Origin

This repo is based on https://github.com/kubernetes/kubernetes/tree/master/cluster/addons/fluentd-elasticsearch/fluentd-es-image

It was first created by the folks of [DoiT International](https://www.doit-intl.com/)

Used and published by [Snyk](https://snyk.io) for the benefit of [Logz.io](https://logz.io) users
