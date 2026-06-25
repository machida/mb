#!/usr/bin/env bash
#
# Production health monitor + self-heal for the Kamal-deployed app.
#
# Runs ON THE SERVER via cron. It checks the local /up endpoint and, if the app
# is down, attempts to restart the current container and sends a notification.
# This closes the gap that caused the 2026-06 outage: after an OOM kill the
# container failed to auto-restart and nobody was alerted for two weeks.
#
# Install (on the server, as the ubuntu user):
#   sudo install -m 755 health-check.sh /usr/local/bin/mb-health-check
#   sudo tee /etc/default/mb-health-check >/dev/null <<'EOF'
#   HEALTHCHECK_URL=http://localhost/up
#   HEALTHCHECK_WEBHOOK_URL=        # optional: Discord/Slack-compatible incoming webhook
#   EOF
#   ( crontab -l 2>/dev/null; echo '* * * * * /usr/local/bin/mb-health-check >> /var/log/mb-health-check.log 2>&1' ) | crontab -
#
# See docs/operations.md for the full runbook.

set -uo pipefail

# Load optional config (URL + webhook) if present.
[ -f /etc/default/mb-health-check ] && . /etc/default/mb-health-check

HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://localhost/up}"
HEALTHCHECK_WEBHOOK_URL="${HEALTHCHECK_WEBHOOK_URL:-}"
CONTAINER_PREFIX="${CONTAINER_PREFIX:-mb-web-}"

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

notify() {
  local msg="$1"
  log "NOTIFY: ${msg}"
  [ -z "${HEALTHCHECK_WEBHOOK_URL}" ] && return 0
  # "content" is read by Discord, "text" by Slack; other services ignore extras.
  curl -fsS -m 10 -H 'Content-Type: application/json' \
    -d "{\"content\":\"[mb] ${msg}\",\"text\":\"[mb] ${msg}\"}" \
    "${HEALTHCHECK_WEBHOOK_URL}" >/dev/null 2>&1 \
    || log "WARN: webhook notification failed"
}

# Newest app container (docker lists newest first).
current_container() {
  docker ps -a --filter "name=${CONTAINER_PREFIX}" --format '{{.Names}}' | head -1
}

probe() {
  curl -fsS -o /dev/null -m 10 "${HEALTHCHECK_URL}"
}

if probe; then
  # Healthy: opportunistically clean up stray stopped app containers beyond the
  # most recent few so leftovers can't silently eat RAM (see the 2026-06 orphan).
  docker ps -a --filter "name=${CONTAINER_PREFIX}" --filter status=exited \
    --format '{{.Names}}' | tail -n +6 | xargs -r docker rm >/dev/null 2>&1
  exit 0
fi

log "DOWN: ${HEALTHCHECK_URL} did not return success"

container="$(current_container)"
if [ -z "${container}" ]; then
  notify "site DOWN and no ${CONTAINER_PREFIX}* container found — manual intervention needed"
  exit 1
fi

log "Attempting to start container: ${container}"
docker start "${container}" >/dev/null 2>&1

# Give Thruster/Puma time to boot before re-probing.
for i in $(seq 1 12); do
  sleep 5
  if probe; then
    notify "site was DOWN, auto-restarted ${container} — now healthy"
    log "RECOVERED after restart"
    exit 0
  fi
done

notify "site DOWN — auto-restart of ${container} FAILED, manual intervention needed"
log "FAILED to recover"
exit 1
