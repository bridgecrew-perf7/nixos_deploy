#bash

sudo cp /etc/nixos/configuration.nix ./configuration-copy.nix
git add configuration-copy.nix
eval $(ssh-agent)
sudo ssh-add ~/.ssh/erica_kali_rsa
git commit -m "update"
git push -u origin master
