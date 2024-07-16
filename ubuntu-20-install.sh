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

# apt install openvswitch-switch-dpdk # netplan, 这个要小心, 尽量不要装
# apt install network-manager # 有需要时总比networkd好, 必须reboot解决 device is strictly unmanaged

if ! command -v pip;then
    apt install -y python3-pip
    pip install -U pip --break-system-packages
    pip install uploadserver --break-system-packages
fi

if ! command -v rg;then
    echo '--------------------install rg--------------------'
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep_13.0.0_amd64.deb
    dpkg -i ripgrep_13.0.0_amd64.deb
    \rm ripgrep_13.0.0_amd64.deb
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

if ! command -v nvim &>/dev/null;then
    echo '--------------------install nvim--------------------'
    curl -LO https://github.com/neovim/neovim/releases/download/v0.9.4/nvim-linux64.tar.gz
    tar xf nvim-linux64.tar.gz
    \rm -rf nvim-linux64.tar.gz
    mv nvim-linux64 /opt/ || true
    \rm nvim-linux64 || true
    chmod 700 /opt/nvim-linux64/bin/nvim
    ln -s /opt/nvim-linux64/bin/nvim /opt/bin
    pip install -U pynvim --break-system-packages
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
    # https://github.com/pyenv/pyenv/wiki#suggested-build-environment
    git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    cd ~/.pyenv && src/configure && make -C src && cd ~
    # pyenv install 3.10.10
    # pyenv global 3.10.10
    # pyenv rehash

    # 这些是python的依赖, 缺少会导致pyenv install出一些问题以及pip install报错
    apt install -y libncurses5-dev libgdbm-dev libc6-dev libssl-dev openssl libreadline-dev libsqlite3-dev xz-utils tk-dev  zlib1g-dev libbz2-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
    # apt install -y python-dev python-setuptools python-smbus
    cd ~
fi

systemctl disable --now ssh.socket
systemctl enable --now ssh.service

sed -i 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/KbdInteractiveAuthentication yes/KbdInteractiveAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
\rm -rf /etc/ssh/sshd_config.d/

sed -i 's/#MaxRetentionSec=.*/MaxRetentionSec=30d/' /etc/systemd/journald.conf
sed -i 's/#SystemMaxUse=.*/SystemMaxUse=500M/' /etc/systemd/journald.conf
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

systemctl restart ssh
systemctl restart sshd

journalctl --vacuum-size=500M
journalctl --vacuum-time=30d

echo '================================================================================'
echo 'Done, run dot.sh and exit then login back...'

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
    cp ./etc/daemon.json /etc/docker/daemon.json
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


if ! command -v rclone &>/dev/null;then
    echo '--------------------install rclone--------------------'
    curl -LO https://github.com/rclone/rclone/releases/download/v1.67.0/rclone-v1.67.0-linux-amd64.zip
    unzip rclone-v1.67.0-linux-amd64.zip
    chmod 700 rclone-v1.67.0-linux-amd64/rclone
    mv rclone-v1.67.0-linux-amd64/rclone /opt/bin
    \rm -rf rclone-v1.67.0-linux-amd64 rclone-v1.67.0-linux-amd64.zip
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

# disk partition, make filesystem
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/attach-disk-portal

lsblk -o NAME,HCTL,SIZE,MOUNTPOINT | grep -i "sd"

parted /dev/sdc --script mklabel gpt mkpart xfspart xfs 0% 100%
mkfs.xfs /dev/sdc1
partprobe /dev/sdc1

mkdir /datadrive
blkid /dev/sdc1
# get /dev/sdc1: UUID="......" TYPE="xfs" 选前一个不是后一个
vim /etc/fstab
#UUID=33333333-3b3b-3c3c-3d3d-3e3e3e3e3e3e   /datadrive   xfs   defaults,nofail   1   2

mount -a
umount -a
