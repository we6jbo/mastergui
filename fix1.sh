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
BACKUP_DIR="$BACKUP_ROOT/mastergui-fix1-$STAMP"
LOGFILE="$BACKUP_DIR/fix1.log"

mkdir -p "$BACKUP_DIR"

log() {
    echo "[fix1] $*" | tee -a "$LOGFILE"
}

fail() {
    log "ERROR: $*"
    exit 1
}

cd "$PROJECT_DIR" || fail "Cannot cd to $PROJECT_DIR"

[ -d ".git" ] || fail "$PROJECT_DIR is not a git repository"
[ -f "check.txt" ] || fail "check.txt not found"

cp -a check.txt "$BACKUP_DIR/check.txt.before" 2>/dev/null || true
git status --short > "$BACKUP_DIR/git-status-before.txt" 2>&1 || true
git branch -vv > "$BACKUP_DIR/git-branch-before.txt" 2>&1 || true
git remote -v > "$BACKUP_DIR/git-remote-before.txt" 2>&1 || true
git rev-parse --show-toplevel > "$BACKUP_DIR/git-root.txt" 2>&1 || true

BRANCH="$(git branch --show-current 2>/dev/null || true)"
[ -n "$BRANCH" ] || fail "Cannot determine current branch"

REMOTE="origin"
git remote get-url "$REMOTE" >/dev/null 2>&1 || fail "No origin remote configured"

LOCAL_VALUE="$(cat check.txt | tr -d '\r\n')"
[ -n "$LOCAL_VALUE" ] || fail "Local check.txt is empty"

log "Current branch: $BRANCH"
log "Local check.txt: $LOCAL_VALUE"
log "Fetching origin/$BRANCH"

git fetch "$REMOTE" "$BRANCH" --prune >> "$LOGFILE" 2>&1 || fail "git fetch failed"

if ! git diff --quiet -- check.txt; then
    log "check.txt has local changes. Adding and committing check.txt only."
    git add check.txt >> "$LOGFILE" 2>&1 || fail "git add check.txt failed"
    git commit -m "Update mastergui check.txt $STAMP" >> "$LOGFILE" 2>&1 || fail "git commit failed"
else
    log "No unstaged check.txt difference found."
fi

log "Pulling with rebase from origin/$BRANCH"
git pull --rebase "$REMOTE" "$BRANCH" >> "$LOGFILE" 2>&1 || fail "git pull --rebase failed. Conflict, auth, branch, or sync issue needs fallback."

log "Pushing to origin/$BRANCH"
git push "$REMOTE" "$BRANCH" >> "$LOGFILE" 2>&1 || fail "git push failed. Likely auth, branch protection, or remote issue."

log "Verifying remote origin/$BRANCH"
git fetch "$REMOTE" "$BRANCH" --prune >> "$LOGFILE" 2>&1 || fail "post-push fetch failed"

REMOTE_VALUE="$(git show "$REMOTE/$BRANCH:check.txt" 2>/dev/null | tr -d '\r\n' || true)"

log "Remote check.txt after push: $REMOTE_VALUE"

if [ "$REMOTE_VALUE" = "$LOCAL_VALUE" ]; then
    log "SUCCESS: remote origin/$BRANCH check.txt matches local check.txt"
    exit 0
fi

fail "Remote origin/$BRANCH check.txt does not match local check.txt"
