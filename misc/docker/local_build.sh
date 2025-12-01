#!/bin/bash

# Build local Dockerfile and tag it
docker build \
    -t rbmi:local \
    -f misc/docker/Dockerfile \
    --build-arg BUILD_ENV=local \
    --platform linux/amd64 \
    --build-context source=$(pwd) \
    --progress=plain \
    .
    --no-cache \


#
# Debug stuff (please ignore)
#

docker run \
    --rm \
    -it \
    --platform linux/amd64 \
    rbmi:local \
    -v $(pwd):/app \
    bash


apt-get update &&
    apt-get upgrade -y &&
    apt-get install -y wget


# Test that we can pull for posit package manager
wget https://packagemanager.posit.co/cran/latest/src/contrib/Archive/glue/glue_1.7.0.tar.gz

cp /tmp/certs/Certificates.pem  /usr/local/share/ca-certificates/custom-cert.crt
update-ca-certificates

