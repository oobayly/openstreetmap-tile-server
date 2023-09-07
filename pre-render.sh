#!/bin/bash

ARGS=($@)
HAS_COUNT=0

for p in "${ARGS[@]}"; do
  if [ "$p" == "--count-only" ]; then
    HAS_COUNT=1
  fi
done

sudo -u renderer tirex-batch $@ map=seamark
SUCCESS=$?

if [ $SUCCESS -ne 0 ] || [ $HAS_COUNT -eq 1 ]; then
  exit 0;
fi

tirex-status

