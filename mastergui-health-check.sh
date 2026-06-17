#!/usr/bin/env bash

# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_START
if [ -f '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh' ]; then
  . '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh'
fi
# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_END

set -Eeuo pipefail

CONF_DIR="/opt/mastergui-confidential"
THRESHOLD_FILE="$CONF_DIR/threshhold-created-by-chatgpt.txt"
CACHE_DIR="/home/we6jbo/.cache/mastergui"
REPORT="$CACHE_DIR/mastergui-health-report.txt"

mkdir -p "$CACHE_DIR"

tk_related_count="$(
  pgrep -af 'python|wish|tk|mastergui' 2>/dev/null \
  | grep -E 'mastergui|tk|Tk|wish' \
  | grep -v grep \
  | wc -l
)"

mem_percent="$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')"

battery_percent="unknown"
if command -v upower >/dev/null 2>&1; then
  bat_path="$(upower -e 2>/dev/null | grep -m1 BAT || true)"
  if [[ -n "$bat_path" ]]; then
    battery_percent="$(upower -i "$bat_path" 2>/dev/null | awk '/percentage:/ {gsub("%","",$2); print $2; exit}')"
  fi
fi

threshold_age_days="missing"
if [[ -f "$THRESHOLD_FILE" ]]; then
  now_epoch="$(date +%s)"
  file_epoch="$(stat -c %Y "$THRESHOLD_FILE")"
  threshold_age_days="$(( (now_epoch - file_epoch) / 86400 ))"
fi

{
  echo "mastergui health report"
  echo "time=$(date '+%F %T')"
  echo "host=$(hostname)"
  echo "user=$(id -un)"
  echo "tk_related_process_count=$tk_related_count"
  echo "system_memory_percent=$mem_percent"
  echo "battery_percent=$battery_percent"
  echo "threshold_age_days=$threshold_age_days"
  echo "threshold_file=$THRESHOLD_FILE"
  echo

  if [[ "$threshold_age_days" == "missing" ]]; then
    echo "status_threshold=missing"
  elif [[ "$threshold_age_days" -gt 14 ]]; then
    echo "status_threshold=stale"
  else
    echo "status_threshold=ok"
  fi

  if [[ "$mem_percent" -ge 80 ]]; then
    echo "status_memory=critical"
  elif [[ "$mem_percent" -ge 65 ]]; then
    echo "status_memory=warn"
  else
    echo "status_memory=ok"
  fi
} > "$REPORT"

cat "$REPORT"
