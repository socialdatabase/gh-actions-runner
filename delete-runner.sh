#!/usr/bin/env bash
[ -z "$RUNNER_CFG_PAT" ] && echo "Need to set RUNNER_CFG_PAT" && exit 1;
curl -s https://raw.githubusercontent.com/actions/runner/main/scripts/delete.sh | bash -s socialdatabase $(hostname)