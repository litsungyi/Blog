#! /bin/bash

rbenv versionz | awk '{print $1}'
echo "${PIPESTATUS[0]} ${PIPESTATUS[1]}"
echo "$RBENV_VERSION"