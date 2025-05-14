#!/usr/bin/env bash

# run docker registry

docker load -i /opt/registry.tar

if [[ -e /opt/registry.tar.bz2 ]]; then
    docker load -i /opt/alpine.tar
    docker volume create registry
    docker run --rm -v registry:/volume -v /opt:/import registry.osism.tech/dockerhub/library/alpine:3 sh -c 'cd /volume && tar xjf /import/registry.tar.bz2'
fi

docker run -d -p 127.0.0.1:5000:5000 -v registry:/var/lib/registry --name registry registry.osism.tech/dockerhub/library/registry:3
