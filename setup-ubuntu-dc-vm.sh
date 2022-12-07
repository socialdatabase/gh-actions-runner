#!/usr/bin/env bash
set -e

[ -z "$RUNNER_CFG_PAT" ] && echo "Need to set RUNNER_CFG_PAT" && exit 1;
echo "\$nrconf{restart} = 'a';" | sudo tee -a /etc/needrestart/needrestart.conf  # automatically accept prompts
sudo apt -y install curl jq

# INSTALL DOCKER
# install docker using instructions from official website: https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script 
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo chown $USER:$USER /var/run/docker.sock

# install docker-compose v1 from source, v2 (using `docker compose` instead of `docker-compose`) is already installed with the installation of docker
sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# INSTALL DEPENDENCIES AND START RUNNER
curl -s https://raw.githubusercontent.com/actions/runner/main/src/Misc/layoutbin/installdependencies.sh | sudo --preserve-env=RUNNER_CFG_PAT bash
curl -s https://raw.githubusercontent.com/actions/runner/main/scripts/create-latest-svc.sh | bash -s socialdatabase
sudo chown -R $USER:$USER ./runner/  # https://github.com/actions/checkout/issues/211#issuecomment-611986243

# CONFIGURE ACTIONS_RUNNER_HOOK_JOB_COMPLETED
sudo tee $HOME/cleanup.sh <<"EOF"
#!/usr/bin/env bash
echo "completed hook"
if [[ ! -z $(docker ps -a -q) ]]
then
     docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q) && docker volume rm $(docker volume ls -qf dangling=true)
fi
EOF
echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED=$HOME/cleanup.sh" >> "$HOME"/runner/.env
sudo chmod +x cleanup.sh

sudo tee $HOME/startup.sh <<"EOF"
#!/usr/bin/env bash
echo "startup hook"
sudo chown -R mysd:mysd /home/mysd/runner/
EOF
echo "ACTIONS_RUNNER_HOOK_JOB_STARTED=$HOME/startup.sh" >> "$HOME"/runner/.env
sudo chmod +x $HOME/startup.sh

# RESTART SERVICE
cd runner && \
     sudo ./svc.sh stop && \
     sudo ./svc.sh start && \
     cd ..