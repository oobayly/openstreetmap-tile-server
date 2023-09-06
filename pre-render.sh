#!/bin/bash

ZL=7,8

if [ -n "$1" ]; then
  ZL=$1
fi

sudo -u renderer tirex-batch map=default z=$ZL bbox=-180,-90,180,90
tirex-status

