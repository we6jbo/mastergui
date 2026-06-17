#!/usr/bin/env bash

# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_START
if [ -f '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh' ]; then
  . '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh'
fi
# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_END

set -Eeuo pipefail

APP_DIR="/opt/mastergui"
CONF_DIR="/opt/mastergui-confidential"
CACHE_DIR="/home/we6jbo/.cache/mastergui"
LOCK_FILE="$CACHE_DIR/mastergui-single-instance.lock"
RUN_LOG="$CACHE_DIR/mastergui-run.log"

mkdir -p "$CACHE_DIR"

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
  {
    echo "============================================================"
    echo "Duplicate mastergui launch blocked safely."
    echo "Time: $(date '+%F %T')"
    echo "Reason: another instance already holds the lock."
  } >> "$RUN_LOG"
  exit 0
fi

export MASTERGUI_SINGLE_INSTANCE=1
export MASTERGUI_SINGLE_TK_WINDOW=1
export MASTERGUI_CONFIDENTIAL_DIR="$CONF_DIR"

{
  echo "============================================================"
  echo "mastergui safe launcher started"
  echo "Time: $(date '+%F %T')"
  echo "APP_DIR=$APP_DIR"
  echo "CONF_DIR=$CONF_DIR"
} >> "$RUN_LOG"

cd "$APP_DIR"

if [[ -x "$APP_DIR/run.sh" ]]; then
  exec "$APP_DIR/run.sh" >> "$RUN_LOG" 2>&1
elif [[ -f "$APP_DIR/run.py" ]]; then
  exec python3 "$APP_DIR/run.py" >> "$RUN_LOG" 2>&1
elif [[ -f "$APP_DIR/main.py" ]]; then
  exec python3 "$APP_DIR/main.py" >> "$RUN_LOG" 2>&1
elif [[ -f "$APP_DIR/mastergui.py" ]]; then
  exec python3 "$APP_DIR/mastergui.py" >> "$RUN_LOG" 2>&1
else
  echo "No known mastergui launcher found. Checked run.sh, run.py, main.py, mastergui.py." >> "$RUN_LOG"
  exit 1
fi
