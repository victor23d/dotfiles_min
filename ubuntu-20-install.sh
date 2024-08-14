#! /bin/bash

set -ex
apt update -y
apt upgrade -y
mkdir /t || true
mkdir -p /opt/bin || true

echo 'Only run in non-blocked network'

apt install -y make build-essential linux-headers-`uname -r` gcc make perl

echo 'install basic tools'
apt install -y wget curl net-tools git openssh-server vim htop tmux zip unzip plocate

echo 'install advanced tools'
apt install -y iotop iftop nethogs silversearcher-ag libpq-dev zsh

# optional
#apt install -y postgres-client

# apt install openvswitch-switch-dpdk # netplan, 这个要小心, 尽量不要装
# apt install network-manager # 有需要时总比networkd好, 必须reboot解决 device is strictly unmanaged


if ! command -v rg;then
    echo '--------------------install rg--------------------'
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
    dpkg -i ripgrep_13.0.0_amd64.deb
    \rm ripgrep_13.0.0_amd64.deb || true
fi

if [[ ! -e ~/.fzf ]];then
    echo '--------------------install fzf--------------------'
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

if ! command -v fasd;then
    echo '--------------------install fasd--------------------'
    apt install fasd
fi

# oh-my-tmux
if [[ ! -e ~/.tmux.conf.local ]];then
    cd ~
    git clone https://github.com/gpakosz/.tmux.git
    ln -s -f .tmux/.tmux.conf
    cp .tmux/.tmux.conf.local .
fi

if [[ ! -e ~/.vim/autoload/plug.vim ]];then
    echo '--------------------install vim-plug--------------------'
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if ! command -v nvim &>/dev/null;then
    echo '--------------------install nvim--------------------'
    curl -LO https://github.com/neovim/neovim/releases/download/v0.10.1/nvim-linux64.tar.gz
    tar xf nvim-linux64.tar.gz
    \rm -rf nvim-linux64.tar.gz || true
    mv nvim-linux64 /opt/ || true
    \rm nvim-linux64 || true
    chmod 755 /opt/nvim-linux64/bin/nvim
    ln -s /opt/nvim-linux64/bin/nvim /opt/bin
    # in nvim :PlugInstall
    # in nvim :UpdateRemotePlugins
fi

# zsh-completions outdated do not use
# if [[ ! -e ~/.oh-my-zsh/custom/plugins/zsh-completions ]];then
    # cd ~
    # git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions
# fi


if [[ ! -e ~/.oh-my-zsh ]];then
    echo '--------------------install oh-my-zsh--------------------'
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if [[ ! -e ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]];then
    echo '--------------------install zsh-syntax-highlighting--------------------'
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if ! command -v pyenv &>/dev/null;then
    echo 'install pyenv'
    curl https://pyenv.run | bash
    # pyenv install 3.10.10
    # pyenv global 3.10.10
    # pyenv rehash
    # pip install uploadserver
    # pip install pynvim

    # missing pyenv dependencies could cause python installation failure
    apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    apt install curl wget llvm make tk-dev
fi

systemctl disable --now ssh.socket
systemctl enable --now ssh.service

\rm -f /etc/ssh/sshd_config.d/* /t || true
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/KbdInteractiveAuthentication yes/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
\rm -rf /etc/ssh/sshd_config.d/

systemctl restart ssh
systemctl restart sshd

sed -i 's/#MaxRetentionSec=.*/MaxRetentionSec=30d/' /etc/systemd/journald.conf
sed -i 's/#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
journalctl --vacuum-size=500M
journalctl --vacuum-time=30d

timedatectl set-timezone UTC

echo '================================================================================'
echo 'Done, run dot.sh or dot-min.sh and exit then login back...'

exit

################################################################################


if ! command -v docker &>/dev/null;then
    # snap has bug, do not use snap
    echo '--------------------install docker--------------------'
    # Run the following command to uninstall all conflicting packages:
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # solve docker DNS issue in vpn
    # Failed to establish a new connection: [Errno -3] Temporary failure in name resolution')': /simple/pip/
    mkdir -p /etc/docker
    cp ./etc/daemon.json /etc/docker/daemon.json || true
fi

if ! command -v rclone &>/dev/null;then
    echo '--------------------install rclone--------------------'
    mkdir tmp
    curl -LO https://github.com/rclone/rclone/releases/download/v1.67.0/rclone-v1.67.0-linux-amd64.zip
    unzip rclone-v1.67.0-linux-amd64.zip -d tmp
    mv tmp/rclone-v1.67.0-linux-amd64/rclone /opt/bin
    chmod 755 /opt/bin/rclone
    \rm -rf tmp rclone-v1.67.0-linux-amd64.zip || true
fi

if ! command -v dufs &>/dev/null;then
    echo '--------------------install dufs--------------------'
    mkdir tmp
    curl -LO https://github.com/sigoden/dufs/releases/download/v0.41.0/dufs-v0.41.0-x86_64-unknown-linux-musl.tar.gz
    tar xf dufs-v0.41.0-x86_64-unknown-linux-musl.tar.gz -C tmp
    mv tmp/dufs /opt/bin
    chmod 755 /opt/bin/dufs
    \rm -rf tmp dufs-v0.41.0-x86_64-unknown-linux-musl.tar.gz || true
fi

if ! command -v cockpit &>/dev/null;then
    echo '--------------------install cockpit--------------------'
    . /etc/os-release
    sudo apt install -t ${VERSION_CODENAME}-backports cockpit
    # 9090 浏览器端口, 用户名密码就是serial console登录的用户名密码
    # root 默认禁止登录, 配置在 /etc/pam.d/cockpit , /etc/cockpit/disallowed-users root注释掉即可登录
    # docker plugin
    curl -LO https://github.com/mrevjd/cockpit-docker/releases/download/v2.0.3/cockpit-docker.tar.gz
    tar xf cockpit-docker.tar.gz -C /usr/share/cockpit
fi

if ! command -v go &>/dev/null;then
    echo '--------------------install go--------------------'
fi


# TODO
# Oh-my-zsh exit
# fasd [ENTER]

exit

systemctl disable snapd
systemctl disable snapd.socket
systemctl disable snapd.seeded.service
systemctl stop snapd
systemctl stop snapd.socket
systemctl stop snapd.seeded.service


# remove snap, warning some desktop app depends on the snapd
apt autoremove --purge snapd
# not automatically install snapd as an update.
apt-mark hold snapd
\rm -rf /var/cache/snapd/
\rm -rm ~/snap


# VirtualBox虚拟机，直接配置完成后，不要安装任何多余的软件, 因为ubuntu会用snap, snap之后要卸载掉
# 若是需要share folder功能, 需要安装 VirtualBox guest additions
# https://gist.github.com/estorgio/0c76e29c0439e683caca694f338d4003

# 在VM界面 Devices -> Insert Guest Additions CD image, 之后看到VM storage里出现了光盘
mkdir /media/cdrom
mount -t iso9660 /dev/cdrom /media/cdrom

apt update
apt install -y build-essential linux-headers-`uname -r`

/media/cdrom/VBoxLinuxAdditions.run

reboot

# Virtualbox 界面 VM Settings Shared Folders, Mount Point直接写/mnt/shared
# 不一定需要, 可以直接再virtualbox界面设置, 只要有Mount Point即可
# sudo mount -t vboxsf shared /mnt/shared

####################

# disk partition, make filesystem
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal

lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"

parted /dev/sdb --script mklabel gpt mkpart xfspart xfs 0% 100%
mkfs.xfs /dev/sdb1
partprobe /dev/sdb1

mkdir /datadrive
blkid /dev/sdb1
# get /dev/sdb1: UUID="......" TYPE="xfs" 选前一个不是后一个
vim /etc/fstab
#UUID=33333333-3b3b-3c3c-3d3d-3e3e3e3e3e3e   /datadrive   xfs   defaults,nofail   1   2
#/dev/sdb1 /w/quant/data   xfs   defaults,nofail   1   2

mount -a
umount -a

########################################

#VM swap 虚拟内存

# check /etc/fstab
/swapfile swap swap sw 0 0

# Turn off all running swap processes:
swapoff -a

# Resize swap
fallocate -l 10G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# check swap
free -m
cat /proc/swaps

# Add this line to /etc/fstab
/swapfile swap swap sw 0 0

########################################

# 添加用户, 创建home, 不在sudo组
useradd -m user2 -s /bin/bash
cp -r /root/.ssh /home/user2/
chown -R user2:user2 /home/user2
# 一定要设置passwd 才能用ssh登录, 即使不用password auth
passwd user2

