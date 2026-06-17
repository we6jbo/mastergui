#!/usr/bin/env bash

# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_START
if [ -f '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh' ]; then
  . '/home/we6jbo/.mastergui_languagetools_guard/shell_guard.sh'
fi
# MASTERGUI_LANGUAGETOOLS_GUARD_PATCH_END

set -u

PROJECT_DIR="/opt/mastergui"
BACKUP_ROOT="/home/we6jbo/backup-this"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/mastergui-fix2-$STAMP"
LOGFILE="$BACKUP_DIR/fix2.log"

mkdir -p "$BACKUP_DIR"

log() {
    echo "[fix2] $*" | tee -a "$LOGFILE"
}

fail() {
    log "ERROR: $*"
    log "No force-push, hard-reset, or delete action was performed."
    exit 1
}

cd "$PROJECT_DIR" || fail "Cannot cd to $PROJECT_DIR"

[ -d ".git" ] || fail "$PROJECT_DIR is not a git repository"
[ -f "check.txt" ] || fail "check.txt not found"

cp -a check.txt "$BACKUP_DIR/check.txt.before" 2>/dev/null || true
git status --short > "$BACKUP_DIR/git-status-before.txt" 2>&1 || true
git status > "$BACKUP_DIR/git-status-full-before.txt" 2>&1 || true
git branch -vv > "$BACKUP_DIR/git-branch-before.txt" 2>&1 || true
git remote -v > "$BACKUP_DIR/git-remote-before.txt" 2>&1 || true
git log --oneline --decorate -n 20 > "$BACKUP_DIR/git-log-before.txt" 2>&1 || true

BRANCH="$(git branch --show-current 2>/dev/null || true)"
[ -n "$BRANCH" ] || fail "Cannot determine current branch"

REMOTE="origin"
ORIGIN_URL="$(git remote get-url "$REMOTE" 2>/dev/null || true)"
[ -n "$ORIGIN_URL" ] || fail "No origin remote configured"

LOCAL_VALUE="$(cat check.txt | tr -d '\r\n')"
[ -n "$LOCAL_VALUE" ] || fail "Local check.txt is empty"

log "Current branch: $BRANCH"
log "Origin URL: $ORIGIN_URL"
log "Local check.txt: $LOCAL_VALUE"

log "Creating safety branch pointer before cautious fallback"
git branch "backup/mastergui-before-fix2-$STAMP" >> "$LOGFILE" 2>&1 || true

log "Fetching origin"
git fetch "$REMOTE" --prune >> "$LOGFILE" 2>&1 || fail "git fetch origin failed"

UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
log "Current upstream: ${UPSTREAM:-none}"

if ! git diff --quiet -- check.txt; then
    log "check.txt has local changes. Committing check.txt only."
    git add check.txt >> "$LOGFILE" 2>&1 || fail "git add check.txt failed"
    git commit -m "Update mastergui check.txt fallback $STAMP" >> "$LOGFILE" 2>&1 || fail "git commit failed"
else
    log "No unstaged check.txt difference found."
fi

log "Trying normal non-force push to origin branch $BRANCH"
git push -u "$REMOTE" "HEAD:$BRANCH" >> "$LOGFILE" 2>&1 || fail "normal push failed. This may be authentication, branch protection, or non-fast-forward."

log "Verifying remote branch after fallback push"
git fetch "$REMOTE" "$BRANCH" --prune >> "$LOGFILE" 2>&1 || fail "post-push fetch failed"

REMOTE_VALUE="$(git show "$REMOTE/$BRANCH:check.txt" 2>/dev/null | tr -d '\r\n' || true)"
log "Remote check.txt after fallback: $REMOTE_VALUE"

if [ "$REMOTE_VALUE" = "$LOCAL_VALUE" ]; then
    log "SUCCESS: fallback verified remote origin/$BRANCH check.txt matches local check.txt"
    exit 0
fi

fail "Fallback push completed but remote check.txt still does not match local check.txt"
