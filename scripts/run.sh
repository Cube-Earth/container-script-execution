#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

/bin/bash -c "$SCRIPT" && rc=0 || rc=$?
echo
[[ $rc != 0 ]] && echo "ERROR: script failed with exit code $rc!" && exit 1
echo "SUCCESS: script succeeded!"
