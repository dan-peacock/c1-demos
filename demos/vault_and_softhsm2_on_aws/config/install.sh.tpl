#!/bin/bash

set -e
set -o pipefail

sudo -u ubuntu -i <<'EOAA'


echo "install dependencies"
sudo apt update -y
sudo apt install -y softhsm2



echo "enable softhsm usage as regualar user"
mkdir -p $HOME/lib/softhsm/tokens
cd $HOME/lib/softhsm/
echo "directories.tokendir = $PWD/tokens" > softhsm2.conf
export SOFTHSM2_CONF=$HOME/lib/softhsm/softhsm2.conf
echo "export SOFTHSM2_CONF=$HOME/lib/softhsm/softhsm2.conf" >> ~/.bashrc

echo "install Vault Enterprise with HSM"
sudo apt update -y && sudo apt install -y gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install -y vault-enterprise-hsm

echo "init HSM and save the slot into an env  var"
softhsm2-util --init-token --slot 0 --label "hsm_demo" --pin 1234 --so-pin asdf

VAULT_HSM_SLOT=$(softhsm2-util --show-slots | grep "^Slot " | head -1 | cut -d " " -f 2)

mkdir -p $HOME/vault/data

sudo cat << EOF > ~/vault/config.hcl
listener "tcp" {
  address = "{{ GetPrivateIP }}:8200"
  tls_disable = "true"
}

ui = true

storage "file" {
  path = "$HOME/vault/data"
}

seal "pkcs11" {
  lib            = "/usr/lib/softhsm/libsofthsm2.so"
  slot           = "$VAULT_HSM_SLOT"
  pin            = "1234"
  key_label      = "hsm_demo"
  hmac_key_label = "hmac-key"
  generate_key   = "true"
}
EOF

# get internal IP using AWS api
TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
export VAULT_IPV4_ADDR=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/local-ipv4)

echo "export VAULT_ADDR=http://$VAULT_IPV4_ADDR:8200" >> ~/.bashrc

echo "export VAULT_LICENSE=${vault_ent_license}" >> ~/.bashrc
EOAA