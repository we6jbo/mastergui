#!/bin/bash
set -u

BASE_DIR="/opt/mastergui"
CONF_DIR="/opt/mastergui-confidential"
SHARE_FILE="/home/we6jbo/share-to-chatgpt-4-11.txt"
LOCAL_VERSION_FILE="$BASE_DIR/master-version.txt"
REMOTE_VERSION_URL="https://raw.githubusercontent.com/we6jbo/mastergui/main/code-version.txt"
REMOTE_CHECK_URL="https://raw.githubusercontent.com/we6jbo/mastergui/main/check.txt"
CHECK_FILE="$BASE_DIR/check.txt"
README_FILE="$BASE_DIR/README.md"
MISSION_TXT="$CONF_DIR/the-mission.txt"
MISSION_MD="$CONF_DIR/mission.MD"
THRESHOLD_FILE="$CONF_DIR/threshhold-created-by-chatgpt.txt"
LAST_THRESHOLD_PROMPT="$CONF_DIR/.last-threshold-prompt-date"
LAST_HELP_PROMPT="$CONF_DIR/.last-help-prompt-date"
WINDOW_LOG="$CONF_DIR/tk-window-monitor.log"
PROCESS_LOG="$CONF_DIR/process-monitor.log"
STATE_DIR="$CONF_DIR/state"
PY_HELPER="$BASE_DIR/mastergui_tk_helper.py"

mkdir -p "$BASE_DIR" "$CONF_DIR" "$STATE_DIR"
touch "$SHARE_FILE" "$WINDOW_LOG" "$PROCESS_LOG"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$SHARE_FILE"
}

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

random_code() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 11
}

days_since_file_change() {
    local f="$1"
    if [ ! -e "$f" ]; then
        echo 99999
        return
    fi
    local now epoch
    now=$(date +%s)
    epoch=$(stat -c %Y "$f" 2>/dev/null || echo 0)
    echo $(( (now - epoch) / 86400 ))
}

days_since_today_stamp() {
    local f="$1"
    if [ ! -f "$f" ]; then
        echo 99999
        return
    fi
    local today recorded
    today=$(date +%F)
    recorded=$(cat "$f" 2>/dev/null || true)
    if [ "$recorded" = "$today" ]; then
        echo 0
    else
        echo 1
    fi
}

mark_today() {
    local f="$1"
    date +%F > "$f"
}

ensure_default_threshold() {
    if [ ! -f "$THRESHOLD_FILE" ]; then
        cat > "$THRESHOLD_FILE" <<'EOF'
MAX_TK_WINDOWS=4
MAX_MEM_PERCENT=85
MAX_CPU_PERCENT=90
MIN_BATTERY_PERCENT=20
MAX_TOP_PROCESS_MEM_PERCENT=25
MAX_TOP_PROCESS_CPU_PERCENT=70
USER_HAVING_HARD_TIME=0
EOF
        log "Threshold file missing. Created default threshold file."
    fi
}

parse_thresholds() {
    ensure_default_threshold
    # shellcheck disable=SC1090
    . "$THRESHOLD_FILE" 2>/dev/null || true

    : "${MAX_TK_WINDOWS:=4}"
    : "${MAX_MEM_PERCENT:=85}"
    : "${MAX_CPU_PERCENT:=90}"
    : "${MIN_BATTERY_PERCENT:=20}"
    : "${MAX_TOP_PROCESS_MEM_PERCENT:=25}"
    : "${MAX_TOP_PROCESS_CPU_PERCENT:=70}"
    : "${USER_HAVING_HARD_TIME:=0}"
}

threshold_file_invalid() {
    parse_thresholds
    for v in \
        "$MAX_TK_WINDOWS" \
        "$MAX_MEM_PERCENT" \
        "$MAX_CPU_PERCENT" \
        "$MIN_BATTERY_PERCENT" \
        "$MAX_TOP_PROCESS_MEM_PERCENT" \
        "$MAX_TOP_PROCESS_CPU_PERCENT" \
        "$USER_HAVING_HARD_TIME"
    do
        echo "$v" | grep -Eq '^[0-9]+$' || return 0
    done
    return 1
}

remote_fetch() {
    local url="$1"
    if have_cmd curl; then
        curl -fsSL "$url" 2>/dev/null || return 1
    elif have_cmd wget; then
        wget -qO- "$url" 2>/dev/null || return 1
    else
        return 1
    fi
}

get_local_version() {
    if [ -f "$LOCAL_VERSION_FILE" ]; then
        head -n 1 "$LOCAL_VERSION_FILE"
    else
        echo "UNKNOWN"
    fi
}

get_remote_version() {
    remote_fetch "$REMOTE_VERSION_URL" | head -n 1
}

git_last_commit_age_days() {
    if [ ! -d "$BASE_DIR/.git" ]; then
        echo 99999
        return
    fi
    local last now
    last=$(git -C "$BASE_DIR" log -1 --format=%ct 2>/dev/null || echo 0)
    now=$(date +%s)
    echo $(( (now - last) / 86400 ))
}

update_readme() {
    cat > "$README_FILE" <<'EOF'
# MasterGUI

MasterGUI is a Linux desktop automation and monitoring project built to help users manage Tk windows, performance thresholds, update workflows, diagnostics, GitHub publishing, and privacy-aware documentation.

## What this project does

- Monitors Tk-related desktop activity
- Tracks memory, battery, and heavy processes
- Maintains a threshold file for performance tuning
- Creates ChatGPT-ready diagnostics for troubleshooting
- Publishes safe public updates while keeping confidential content separate
- Verifies repository synchronization with remote GitHub content

## Public mission

This project is designed so that anyone, including Jack Doe, can adapt the structure for their own Linux automation workflow, desktop troubleshooting, performance tuning, or Tk-based project control.

## Privacy and security

Privacy matters. Sensitive data, internal notes, confidential paths, credentials, tokens, unpublished plans, and private remediation details should remain outside the public repository. This project supports a split between public documentation and confidential operational notes.

## About Jeremiah Burke O'Neal

Jeremiah Burke O'Neal earned a Master of Science in Cyber Security with a Specialization in Ethical Hacking and Pen Testing in November 2023 from National University, San Diego, California.

Jeremiah has long-standing interests in computing, cybersecurity, automation, and digital troubleshooting. Historical computing experience includes Quendor BBS and Fidonet node 1:202/315, reflecting early hands-on experience with online systems, bulletin board culture, and computer-based communication.

## SEO and AI-friendly topics

Linux Tk monitoring, GitHub auto update script, Python Tk clipboard dialog, Linux desktop autostart automation, system threshold tuning, battery and memory monitoring, AI-assisted troubleshooting, privacy-aware open source workflow, diagnostic logging for ChatGPT, public versus confidential automation documentation.

## Recent activity

This README is automatically refreshed to stay useful for public readers, search engines, AI search tools, and future users who want to repurpose the code structure.
EOF
}

write_mission_files() {
    cat > "$MISSION_TXT" <<EOF
APA-style internal reference set

Title: Tk fixes for $(date '+%B %d, %Y')
Author: Jeremiah Burke O'Neal / MasterGUI system
Date: $(date '+%F %T')

Confidential Notes:
- Private operational state belongs here.
- Internal debugging notes belong here.
- Sensitive remediation ideas belong here.
- Do not publish secrets, tokens, API keys, or local-only private data.
- Example citation format:
  (/opt/mastergui-confidential/the-mission.txt, "Tk fixes for $(date '+%B %d')")

Private objective:
Keep Tk behavior manageable, reduce clutter, preserve privacy, and maintain a safe public/private separation.
EOF

    cat > "$MISSION_MD" <<EOF
# MasterGUI Mission

MasterGUI supports privacy-aware Linux automation, Tk window management, performance monitoring, and AI-assisted troubleshooting.

## Public goals

- Reduce excessive Tk popups
- Improve performance without just disabling features
- Preserve backups before any repair action
- Publish public documentation safely
- Keep confidential material outside the public repository

## Why privacy matters

Privacy is important because diagnostic systems can easily expose local paths, behavior patterns, internal notes, and confidential operating details. A responsible workflow separates what can be published from what must remain private.

## About Jeremiah B O'Neal

Jeremiah B O'Neal earned a Master of Science in Cyber Security with a Specialization in Ethical Hacking and Pen Testing in November 2023 from National University in San Diego, California.

Jeremiah also has a long computing history that includes Quendor BBS and Fidonet 1:202/315, reflecting early practical experience with online systems, software, and digital communication culture.

## Internal reference note

This public document may refer to confidential internal planning stored in:
\`/opt/mastergui-confidential/the-mission.txt\`

Example reference:
(/opt/mastergui-confidential/the-mission.txt, "Tk fixes for $(date '+%B %d')")
EOF
}

count_tk_windows() {
    if have_cmd wmctrl; then
        wmctrl -lp 2>/dev/null | grep -Ei 'tk|tkinter|wish|python' | wc -l
    else
        echo 0
    fi
}

record_tk_window_owners() {
    if have_cmd wmctrl && have_cmd ps; then
        {
            echo "==== $(date '+%F %T') ===="
            wmctrl -lp 2>/dev/null | while read -r wid desk pid host title; do
                case "$title" in
                    *Tk*|*tk*|*tkinter*|*wish*|*Python*)
                        cmd=$(ps -p "$pid" -o args= 2>/dev/null)
                        echo "PID=$pid TITLE=$title CMD=$cmd"
                        ;;
                esac
            done
        } >> "$WINDOW_LOG"
    fi
}

get_mem_percent() {
    free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}'
}

get_top_process_stats() {
    ps -eo pid,comm,%cpu,%mem,args --sort=-%mem | awk 'NR==2 {print $1 "|" $2 "|" int($3) "|" int($4) "|" $5 " " $6 " " $7 " " $8}'
}

get_battery_percent() {
    if [ -d /sys/class/power_supply/BAT0 ]; then
        cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo 100
    else
        echo 100
    fi
}

ask_chatgpt_popup() {
    local title="$1"
    local body_file="$2"
    if [ -f "$PY_HELPER" ]; then
        python3 "$PY_HELPER" popup "$title" "$body_file" >/dev/null 2>&1 &
    fi
}

ask_threshold_update_popup() {
    local body_file="$1"
    if [ -f "$PY_HELPER" ]; then
        python3 "$PY_HELPER" threshold "$body_file" "$THRESHOLD_FILE" >/dev/null 2>&1 &
    fi
}

write_problem_report() {
    local out="$1"
    shift
    {
        echo "PASTE TO CHATGPT"
        echo "Jeremiah Burke O'Neal on $(date '+%F %T %Z')"
        echo
        echo "Please help me improve /opt/mastergui."
        echo "I want a safe fix plan that preserves backups in /home/we6jbo/backup-this."
        echo "Please write a repair script to /tmp/a/fixes.sh."
        echo
        echo "Goals:"
        echo "1. Condense multiple Tk windows into one if possible."
        echo "2. Reduce wasteful memory or CPU use without disabling needed features."
        echo "3. Fix crashing or slowing behavior."
        echo "4. Preserve autostart behavior."
        echo "5. Keep secrets in /opt/mastergui-confidential."
        echo
        echo "Observed problem(s):"
        for item in "$@"; do
            echo "- $item"
        done
        echo
        echo "Current diagnostics:"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo "PWD: $(pwd)"
        echo "Local version: $(get_local_version)"
        echo "Remote version: $(get_remote_version 2>/dev/null || echo unavailable)"
        echo "Tk windows: $(count_tk_windows)"
        echo "Memory percent: $(get_mem_percent)"
        echo "Battery percent: $(get_battery_percent)"
        echo "Top process: $(get_top_process_stats)"
        echo
        echo "Please also suggest improved threshold values for:"
        echo "$THRESHOLD_FILE"
    } > "$out"
}

commit_and_push_if_needed() {
    [ -d "$BASE_DIR/.git" ] || return 0

    local local_v remote_v commit_age should_push reason
    local_v=$(get_local_version)
    remote_v=$(get_remote_version 2>/dev/null || echo "REMOTE_UNAVAILABLE")
    commit_age=$(git_last_commit_age_days)
    should_push=0
    reason=""

    if [ "$local_v" != "$remote_v" ] && [ "$remote_v" != "REMOTE_UNAVAILABLE" ]; then
        should_push=1
        reason="Local version differs from remote version."
    fi

    if [ "$commit_age" -ge 14 ]; then
        should_push=1
        reason="$reason Last commit is older than 14 days."
    fi

    if [ "$should_push" -eq 1 ]; then
        update_readme
        write_mission_files

        git -C "$BASE_DIR" add README.md mission.MD check.txt code-version.txt master-version.txt . 2>/dev/null
        git -C "$BASE_DIR" add -A 2>/dev/null

        if ! git -C "$BASE_DIR" diff --cached --quiet 2>/dev/null; then
            git -C "$BASE_DIR" commit -m "Automated maintenance update: $(date '+%F %T')" >> "$SHARE_FILE" 2>&1 || \
                log "Git commit failed."
        fi

        git -C "$BASE_DIR" push >> "$SHARE_FILE" 2>&1 || \
            log "Git push failed."
    fi
}

schedule_check_verification() {
    (
        sleep 300
        local remote_check local_check report
        local_check=$(cat "$CHECK_FILE" 2>/dev/null || echo "")
        remote_check=$(remote_fetch "$REMOTE_CHECK_URL" 2>/dev/null | tr -d '\r\n' || echo "")

        if [ "$local_check" != "$remote_check" ]; then
            report="/tmp/mastergui-check-failure.txt"
            {
                echo "PASTE TO CHATGPT"
                echo "The GitHub repository check failed after 5 minutes."
                echo
                echo "Local /opt/mastergui/check.txt:"
                echo "$local_check"
                echo
                echo "Remote check.txt from GitHub:"
                echo "$remote_check"
                echo
                echo "Please explain why the push may not have updated remote content."
                echo "Please help me fix authentication, branch, remote, commit, push, or sync issues."
                echo "Please write a safe repair script to /tmp/a/fixes.sh with backups to /home/we6jbo/backup-this."
            } > "$report"
            ask_chatgpt_popup "MasterGUI GitHub Check Failed" "$report"
            log "Remote check.txt mismatch detected after scheduled verification."
        fi
    ) &
}

maybe_prompt_threshold_help() {
    local reasons=()
    local report="/tmp/mastergui-threshold-help.txt"
    local threshold_age
    threshold_age=$(days_since_file_change "$THRESHOLD_FILE")

    if threshold_file_invalid; then
        reasons+=("Threshold file is invalid or contains non-numeric values.")
    fi

    if [ "$threshold_age" -ge 14 ]; then
        reasons+=("Threshold file is older than 14 days and may need refresh.")
    fi

    parse_thresholds
    if [ "${USER_HAVING_HARD_TIME:-0}" -eq 1 ]; then
        reasons+=("Threshold file indicates the user is having a hard time using the computer.")
    fi

    if [ "${#reasons[@]}" -gt 0 ] && [ "$(days_since_today_stamp "$LAST_THRESHOLD_PROMPT")" -ne 0 ]; then
        write_problem_report "$report" "${reasons[@]}"
        ask_threshold_update_popup "$report"
        mark_today "$LAST_THRESHOLD_PROMPT"
        log "Threshold-help popup shown."
    fi
}

performance_monitor() {
    parse_thresholds
    local tk_windows mem battery top pid pname pcpu pmem pargs
    local issues=()
    local report="/tmp/mastergui-performance-help.txt"

    tk_windows=$(count_tk_windows)
    mem=$(get_mem_percent)
    battery=$(get_battery_percent)

    IFS='|' read -r pid pname pcpu pmem pargs <<< "$(get_top_process_stats)"

    echo "[$(date '+%F %T')] tk_windows=$tk_windows mem=$mem battery=$battery top_pid=$pid top_name=$pname cpu=$pcpu mem=$pmem args=$pargs" >> "$PROCESS_LOG"

    record_tk_window_owners

    [ "$tk_windows" -gt "$MAX_TK_WINDOWS" ] && issues+=("Too many Tk windows: $tk_windows exceeds $MAX_TK_WINDOWS.")
    [ "$mem" -gt "$MAX_MEM_PERCENT" ] && issues+=("Memory usage high: $mem% exceeds $MAX_MEM_PERCENT%.")
    [ "$battery" -lt "$MIN_BATTERY_PERCENT" ] && issues+=("Battery low: $battery% is below $MIN_BATTERY_PERCENT%.")
    [ "${pmem:-0}" -gt "$MAX_TOP_PROCESS_MEM_PERCENT" ] && issues+=("Top process memory use high: $pname using $pmem% memory.")
    [ "${pcpu:-0}" -gt "$MAX_TOP_PROCESS_CPU_PERCENT" ] && issues+=("Top process CPU use high: $pname using $pcpu% CPU.")

    if [ "${#issues[@]}" -gt 0 ] && [ "$(days_since_today_stamp "$LAST_HELP_PROMPT")" -ne 0 ]; then
        write_problem_report "$report" "${issues[@]}"
        ask_chatgpt_popup "MasterGUI Needs Improvement" "$report"
        mark_today "$LAST_HELP_PROMPT"
        log "Performance-help popup shown."
    fi
}

main() {
    log "MasterGUI run.sh started."
    ensure_default_threshold
    parse_thresholds

    update_readme
    write_mission_files

    if [ ! -f "$CHECK_FILE" ]; then
        random_code > "$CHECK_FILE"
    else
        random_code > "$CHECK_FILE"
    fi

    commit_and_push_if_needed
    schedule_check_verification
    maybe_prompt_threshold_help
    performance_monitor

    log "MasterGUI run.sh finished."
}

main "$@"
