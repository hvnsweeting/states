# Run me with cat rbts.sh | ssh linode 'bash -s'
# Remote bootstrap salt for 16.04

wget -O - https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main" > /etc/apt/sources.list.d/saltstack.list
apt-get update && apt-get install -y tmux salt-minion git
mkdir -p /root/salt/
cd /root/salt
cp /etc/salt/minion /etc/salt/minion.old
git clone https://github.com/hvnsweeting/states
cp /root/salt/states/test/minion /etc/salt/minion

# copy private key then
# then clone private repo/pillar
