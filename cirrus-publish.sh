#!/bin/env bash

# script to publish/upload images to images.osism.io

if [ $CIRRUS_BRANCH == 'main' ]; then
  cd ./images/
  ls ./
  echo "main -" $CIRRUS_BRANCH
  s3cmd --host="${S3CMD_HOST}" --host-bucket="${S3CMD_HOST}" --access_key="${S3CMD_ACCESS_KEY}" --secret_key="${S3CMD_SECRET_KEY}" sync . "s3://${S3CMD_BUCKET}"
else
  cd ./images/
  ls ./
  echo "not main -" $CIRRUS_BRANCH
fi
