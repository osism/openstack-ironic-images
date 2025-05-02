#!/usr/bin/env bash

# run docker registry

docker load -i /opt/registry.tar
docker run -d -p 5000:5000 -v registry:/var/lib/registry --name registry registry:3
