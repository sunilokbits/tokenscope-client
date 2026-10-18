#!/usr/bin/env bash
# Temporarily open a private (Premium) registry to THIS runner's public IP so a
# GitHub-hosted runner can push, then close it again.
#
#   infra/scripts/acr-network-window.sh open  <acr>
#   infra/scripts/acr-network-window.sh close <acr>
#
# open: public network access Enabled with default action Deny + one IP rule.
# close: removes the rule and disables public network access (the posture the
# Bicep template applies). Always run close, even after a failed build.
set -euo pipefail

ACTION="${1:?usage: $0 open|close <acr>}"
ACR="${2:?usage: $0 open|close <acr>}"
IP_FILE="${RUNNER_TEMP:-/tmp}/acr-window-ip"

case "$ACTION" in
  open)
    IP=$(curl -fsS --max-time 10 https://api.ipify.org)
    echo "$IP" > "$IP_FILE"
    az acr update -n "$ACR" --public-network-enabled true --default-action Deny -o none
    az acr network-rule add -n "$ACR" --ip-address "$IP" -o none
    # Firewall changes take a short while to reach the registry's data plane.
    for i in $(seq 1 20); do
      if az acr login -n "$ACR" >/dev/null 2>&1; then echo "Registry $ACR open to $IP"; exit 0; fi
      echo "Waiting for the registry firewall ($i)"; sleep 15
    done
    echo "::error::Registry $ACR did not accept $IP"; exit 1
    ;;
  close)
    if [ -s "$IP_FILE" ]; then
      az acr network-rule remove -n "$ACR" --ip-address "$(cat "$IP_FILE")" -o none || true
    fi
    az acr update -n "$ACR" --public-network-enabled false -o none
    echo "Registry $ACR closed to public traffic"
    ;;
  *)
    echo "usage: $0 open|close <acr>" >&2; exit 2 ;;
esac
