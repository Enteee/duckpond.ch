# Server Installation

* Install CentOS 8 Stream

* Set timezone to UTC:
```sh
timedatectl set-timezone UTC
```

* Install epel:
```sh
dnf install --assumeyes \
  epel-release
```

* Base system installation:
```sh
dnf install --assumeyes \
  openssh-server \
  gpg \
  htop \
  vim \
  git \
  moreutils \
  fail2ban-all \
  fail2ban-selinux \
  dnf-automatic \
  byobu \
  rxvt-unicode-terminfo
```

* Install docker:
```sh
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install --assumeyes \
  docker-ce \
  docker-ce-cli \
  containerd.io
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

* Enable services:
```sh
systemctl enable sshd
systemctl enable fail2ban
systemctl enable docker
systemctl enable dnf-automatic.timer
```

* Activate firewall:
```sh
firewall-cmd --set-default-zone=dmz
```

* Add service user:
```sh
adduser -G docker ente
```

* Install ssh-key:
```sh
mkdir -p /home/ente/.ssh
cp /root/.ssh/authorized_keys /home/ente/.ssh/
chown -R ente:ente /home/ente/.ssh
chmod 600 /home/ente/.ssh/authorized_keys
```

* Set SSH Banner:
```sh
cat >/etc/ssh/sshd_banner <<'EOF'
' ==========='
| Welcome on |
| the pond!  |
'===== .-"""-.   _.---..-;  
      :.)     ;""      \/   
__..--'\      ;-"""-.   ;._ 
`-.___.^.___.'-.____J__/-._J
EOF
sed -i -re 's|#Banner none|Banner /etc/ssh/sshd_banner|' /etc/ssh/sshd_config
```

* Enable byobu:
```sh
byobu-enable
sudo -u ente sh -c 'byobu-enable'
```

* Set up git:
```sh
sudo -u ente sh -c 'git config --global user.email "ducksource@duckpond.ch"'
sudo -u ente sh -c 'git config --global user.name "ente"'
```

* Clone this repo:
```sh
sudo -u ente sh -c 'cd ~;git clone --recurse-submodules https://github.com/Enteee/duckpond.ch.git'
```

* Next Steps:
  1.  Connect to server: `ssh -L 8888:localhost:8384  ente@duckpond.ch`
  2.  Decrypt `.env`: `./up.sh --decrypt PASSWORD noop`
  3.  In .env change `VOLUME_SYNC_MOUNT` to `rw`
  4.  Start syncthing: `./up.sh dev up syncthing`
  5.  Connect to https://localhost:8888
  6.  Setup syncthing password
  7.  Connect to sync network
  8.  Wait for full sync
  9.  Stop syncthing
  10. Start volume-sync: `./up.sh -v dev up volume-sync`
  11. Restore backup: `docker exec -ti duckpondch_volume-sync_1 ./restore.sh [backup-to-restore]`
  12. Stop volume-sync
  13. In .env change `VOLUME_SYNC_MOUNT` to `ro`
  14. Make DNS record for duckpond.ch point to the new server
  15. Init certificates: `./up.sh --decrypt PASSWORD prod run letsencrypt`
  16. Clean build & start all containers: `docker system prune -af && ./up.sh --decrypt PASSWORD prod build`
