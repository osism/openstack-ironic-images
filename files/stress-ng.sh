#!/usr/bin/env bash

NUMBER_OF_CPUS=$(nproc --all)
/usr/bin/stress-ng --cpu $NUMBER_OF_CPUS --timeout 86400s
