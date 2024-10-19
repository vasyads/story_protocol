log "Downloading and extracting Story and Geth snapshots"

sudo apt-get install wget lz4 aria2 pv -y

sudo systemctl stop story
sudo systemctl stop story-geth

cd $HOME
rm -f Story_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://story.josephtran.co/Story_snapshot.lz4

rm -f Geth_snapshot.lz4
aria2c -x 16 -s 16 -k 1M https://story.josephtran.co/Geth_snapshot.lz4

cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup

log "Cleaning up old data and restoring state"
rm -rf $HOME/.story/story/data
rm -rf $HOME/.story/geth/iliad/geth/chaindata

log "Decompress snapshot"
sudo mkdir -p $HOME/.story/story/data
lz4 -d -c Story_snapshot.lz4 | pv | sudo tar xv -C $HOME/.story/story/ > /dev/null

sudo mkdir -p $HOME/.story/geth/iliad/geth/chaindata
lz4 -d -c Geth_snapshot.lz4 | pv | sudo tar xv -C $HOME/.story/geth/iliad/geth/ > /dev/null

cp $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

sudo systemctl start story
sudo systemctl start story-geth

log "Done"
