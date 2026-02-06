#!/usr/bin/env bash
# Setup
# whoami ?
#
#
echo "whoami"
ME = (whoami)
SYS = (cat /proc/sys/kernel/hostname)
SH = (which bash)
DNS = "8.8.8.8"
ADROUTE = "198.168.1.0/24"
is_root () {
    return $(id -u)
}
has_sudo() {
    local prompt
    prompt=$(sudo -nv 2>&1)
    if [ $? -eq 0 ]; then
    echo "has_sudo__pass_set"
    elif echo $prompt | grep -q '^sudo:'; then
    echo "has_sudo__needs_pass"
    else
    echo "no_sudo"
    fi
}
elevate_cmd () {
    local cmd=$@
    HAS_SUDO=$(has_sudo)
    case "$HAS_SUDO" in
    has_sudo__pass_set)
        sudo $cmd
        ;;
    has_sudo__needs_pass)
        echo "Please supply sudo password for the following command: sudo $cmd"
        sudo $cmd
        ;;
    *)
        echo "Please supply root password for the following command: su -c \"$cmd\""
        su -c "$cmd"
        ;;
    esac
}
if is_root; then
    echo "Error: need to call this script as a normal user, not as root!"
    exit 1
fi
elevate_cmd which adduser
# Required pkgs
# curl, git, ssh, 
# 
check_dependencies(){
    #Declare list of dependencies
    declare -Ag deps=([curl]='curl' [git]='git' [ssh]='ssh' [lsof]='lsof')
    #Declare list of package managers and their usages
    declare -Ag packman_list=([pacman]='pacman -Sy' [apt]='echo "deb http://deb.debian.org/debian buster-backports main contrib non-free" > /etc/apt/sources.list.d/buster-backports.list; apt update -y; apt install -y' [yum]='yum install -y epel-release; yum repolist -y; yum install -y')
    
    #Find the package manager on the system and install the package
    install_deps(){
        for packman in ${!packman_list[@]}
        do
            which $packman &>/dev/null && eval $(echo ${packman_list[$packman]} "$*")
        done
    }
    #Find the missing packages from list of dependencies
    declare -ag missing_deps=()
    for pack in ${!deps[@]}
    do
        which $pack &>/dev/null || missing_deps+=(${deps[$pack]})
    done
    #Install missing dependencies
    test -z ${missing_deps[0]} || install_deps ${missing_deps[@]} || fail "Dependencies could not provide"
}
# DSys NIX
# flakes, home-manager environment
# 
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
# Enable flakes
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
# Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
#Download Env
git clone git@github.com:reksadsp/dotnix.git ~/dotnix
cd ~/dotnix
#Switch env
nix run home-manager/master -- switch --flake .#reksa@$SYS
nix flake update
nix run home-manager/master -- switch --flake .#reksa@$SYS
# DSys sudo RUN
# cross-platfrom init
# 
systemctl daemon reload
sudo systemctl start tailscaled
sudo tailscale up --accept-dns=true --dns=$DNS --accept-routes --advertise-routes=$ADROUTE
