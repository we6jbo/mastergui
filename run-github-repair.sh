#!/usr/bin/env bash

# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_START
if [ -f '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh' ]; then
  . '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh'
fi
# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_END

set -u

echo "Running first-choice repair: /opt/mastergui/fix1.sh"

if ! /opt/mastergui/fix1.sh; then
    echo "fix1.sh reported an error."
    echo "Running fallback repair: /opt/mastergui/fix2.sh"
    /opt/mastergui/fix2.sh
fi
