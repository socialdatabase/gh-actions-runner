## Self-hosted runner
For running the workflows on our own infrastructure. This is handy because of:
- Speed, docker builds are cached
- Costs, buying minutes from GitHub is more expensive


```
curl -s https://raw.githubusercontent.com/socialdatabase/gh-actions-runner/master/setup-ubuntu-dc-vm.sh | RUNNER_CFG_PAT=ghp_*** DEBIAN_FRONTEND=noninteractive bash
```