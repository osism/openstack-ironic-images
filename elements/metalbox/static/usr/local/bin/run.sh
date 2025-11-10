#!/usr/bin/env bash

docker load -i /opt/registry.tar
docker load -i /opt/alpine.tar

if [[ -e /opt/registry.tar.bz2 ]]; then
    docker volume create registry
    docker run --rm -v registry:/volume -v /opt:/import library/alpine:3 sh -c 'cd /volume && tar xjf /import/registry.tar.bz2'
fi

docker run -d -p 0.0.0.0:5001:5000 -v registry:/var/lib/registry --name registry --restart always library/registry:3
