#!/bin/env bash

# script to publish/upload images to images.osism.io

if [ $CIRRUS_BRANCH == 'main' ]; then
  cd ./images/
  ls ./
  echo $CIRRUS_BRANCH "-"  ${S3CMD_HOST}
  #s3cmd --host="${S3CMD_HOST}" --host-bucket="${S3CMD_HOST}" --access_key="${S3CMD_ACCESS_KEY}" --secret_key="${S3CMD_SECRET_KEY}" sync . "s3://${S3CMD_BUCKET}"
fi
