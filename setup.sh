#!/usr/bin/env bash
set -e

[[ $(sudo dmidecode -s bios-vendor) != *"EC2"* ]] && echo "This script is intended run on (fresh) EC2 instances" && exit 1;
[ -z "$RUNNER_CFG_PAT" ] && echo "Need to set RUNNER_CFG_PAT" && exit 1;
sudo apt -y install curl jq

# MOUNT DISK
LARGEST_DISK="/dev/$(lsblk -x SIZE | tail -1 | awk '{ print $1 }')"  # assuming this is the local disk, make sure that there are no EBS volumes larger than the local SSD
DIR="/data"

sudo mkfs -t xfs -f $LARGEST_DISK
sudo mkdir $DIR
sudo mount $LARGEST_DISK $DIR

# add mount to fstab to survive reboots
sudo cp /etc/fstab /etc/fstab.orig
ROW="$(sudo blkid | grep $LARGEST_DISK  | awk '{ print $2 }' | tr -d '"')  $DIR  xfs  defaults,nofail  0  2"
echo "$ROW" | sudo tee -a /etc/fstab

# INSTALL DOCKER
# install docker using instructions from official website: https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script 
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo chown $(whoami):$(whoami) /var/run/docker.sock

# install docker-compose v1 from source, v2 (using `docker compose` instead of `docker-compose`) is already installed with the installation of docker
sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# USE LARGE PARTITION AS DATA-ROOT FOR DOCKER
echo '{ "data-root": "'"$DIR"'", "features": { "buildkit": true } }' >> deamon.json
sudo mv ./deamon.json /etc/docker/daemon.json  
sudo systemctl restart docker

# INSTALL DEPENDENCIES AND START RUNNER
curl -s https://raw.githubusercontent.com/actions/runner/main/src/Misc/layoutbin/installdependencies.sh | DEBIAN_FRONTEND=noninteractive sudo bash
curl -s https://raw.githubusercontent.com/actions/runner/main/scripts/create-latest-svc.sh | bash -s socialdatabase
sudo chown -R $USER:$USER ./runner/  # https://github.com/actions/checkout/issues/211#issuecomment-611986243

# CONFIGURE ACTIONS_RUNNER_HOOK_JOB_COMPLETED
echo "ACTIONS_RUNNER_HOOK_JOB_COMPLETED='"'[[ ! -z $(docker ps -a -q) ]] && docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'"'" >> "$HOME"/runner/.env