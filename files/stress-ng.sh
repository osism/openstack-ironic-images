#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)
/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout 3600s
/usr/bin/stress-ng --vm 1 --vm-bytes 50% --vm-method all --verify --timeout 600s
