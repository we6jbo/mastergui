#!/usr/bin/env bash
set -u

echo "Running first-choice repair: /opt/mastergui/fix1.sh"

if ! /opt/mastergui/fix1.sh; then
    echo "fix1.sh reported an error."
    echo "Running fallback repair: /opt/mastergui/fix2.sh"
    /opt/mastergui/fix2.sh
fi
