# Determinate Systems with curl
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# Enable flakes
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf

#Download Env
git clone git@github.com:reksadsp/dotnix.git ~/dotnix
cd ~/dotnix

#Switch env
nix run home-manager/master -- switch --flake .#reksa@panasonic

nix flake update
nix run home-manager/master -- switch --flake .#reksa@panasonic
