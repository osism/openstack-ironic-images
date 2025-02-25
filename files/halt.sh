#!/usr/bin/env bash

modprobe pcspkr
if lsmod | grep -q "^pcspkr"; then
  beep -f 440 -l 500
  beep -f 440 -l 500
  beep -f 440 -l 500
  beep -f 349 -l 350
  beep -f 523 -l 150
  beep -f 440 -l 500
  beep -f 349 -l 350
  beep -f 523 -l 150
  beep -f 440 -l 1000
  beep -f 659 -l 500
  beep -f 659 -l 500
  beep -f 659 -l 500
  beep -f 698 -l 350
  beep -f 523 -l 150
  beep -f 415 -l 500
  beep -f 349 -l 350
  beep -f 523 -l 150
  beep -f 440 -l 1000
fi

shutdown -h now
