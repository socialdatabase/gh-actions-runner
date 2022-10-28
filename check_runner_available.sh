#!/usr/bin/env bash
[ -z "$RUNNER_CFG_PAT" ] && echo "Need to set RUNNER_CFG_PAT" && exit 1;
STATUSSES=$(curl -s \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $RUNNER_CFG_PAT" \
  https://api.github.com/orgs/socialdatabase/actions/runners | jq '.runners[].status')
if [[ "$STATUSSES" =~ .*"online".* ]]; then
  echo '[self-hosted]'
else echo 'ubuntu-latest'
fi