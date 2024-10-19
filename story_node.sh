#!/bin/bash

# Function for logging
log() {
    echo -e "\e[1;32m$1\e[0m"
}

log "Starting installation of Story and Story-Geth node..."

log "Installing dependencies..."
sudo apt update
sudo apt-get update
sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 -y

log "Downloading Story-Geth binary v0.9.4..."
cd $HOME
wget https://github.com/piplabs/story-geth/releases/download/v0.9.4/geth-linux-amd64

log "Setting up directories and environment variables..."
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
fi
chmod +x geth-linux-amd64
mv $HOME/geth-linux-amd64 $HOME/go/bin/story-geth
source $HOME/.bash_profile

log "Checking Story-Geth version..."
story-geth version

log "Downloading Story binary v0.11.0..."
cd $HOME
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.11.0-aac4bfe.tar.gz
tar -xzvf story-linux-amd64-0.11.0-aac4bfe.tar.gz

[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
fi
sudo cp $HOME/story-linux-amd64-0.11.0-aac4bfe/story $HOME/go/bin
source $HOME/.bash_profile

log "Checking Story version..."
story version

log "Initializing Iliad node..."
read -p "Enter your node moniker: " MONIKER
story init --network iliad --moniker "$MONIKER"

log "Creating systemd service for Story-Geth..."
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Step 10: Create systemd service for Story
log "Creating systemd service for Story..."
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

log "Starting and enabling services..."
sudo systemctl daemon-reload

sudo systemctl start story-geth
sudo systemctl enable story-geth
sudo systemctl status story-geth

sudo systemctl start story
sudo systemctl enable story
sudo systemctl status story

log "Checking Story-Geth logs..."
sudo journalctl -u story-geth -f -o cat &

log "Checking Story logs..."
sudo journalctl -u story -f -o cat &
