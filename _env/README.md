# Server Installation

* Install Rocky linux 9

* (user:root) Set timezone to UTC:
```sh
timedatectl set-timezone UTC
```

* (user:root) Install epel:
```sh
dnf install --assumeyes \
  epel-release
```

* (user:root) Base system installation:
```sh
dnf install --assumeyes --enablerepo=crb \
  openssh-server \
  gpg \
  htop \
  net-tools \
  vim \
  git \
  moreutils \
  fail2ban-all \
  fail2ban-selinux \
  dnf-automatic \
  byobu \
  rxvt-unicode-terminfo
```

* (user:root) Install docker:
```sh
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install --assumeyes \
  docker-ce \
  docker-ce-cli \
  containerd.io
curl \
  -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
```

* (user:root) Enable services:
```sh
systemctl enable sshd
systemctl enable fail2ban
systemctl enable docker
systemctl enable dnf-automatic.timer
systemctl enable firewalld
```
* (user:root) Reboot:
```
reboot
```

* (user:root) Activate firewall:
```sh
firewall-cmd --set-default-zone=dmz
```

* (user:root) Add service user:
```sh
adduser -G docker ente
```

* (user:root) Install ssh-key:
```sh
mkdir -p /home/ente/.ssh
cp /root/.ssh/authorized_keys /home/ente/.ssh/
chown -R ente:ente /home/ente/.ssh
chmod 400 /home/ente/.ssh/authorized_keys
```

* (user:root) Set SSH Banner:
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

* (user:root) Enable byobu:
```sh
byobu-enable
sudo -u ente sh -c 'byobu-enable'
```

* (user:root) Set up git:
```sh
sudo -u ente sh -c 'git config --global user.email "ducksource@duckpond.ch"'
sudo -u ente sh -c 'git config --global user.name "ente"'
```

* (user:root) Clone this repo:
```sh
sudo -u ente sh -c 'cd ~;git clone --recurse-submodules https://github.com/Enteee/duckpond.ch.git'
```

* (user:root) Reboot:
```sh
reboot
```

* (user:ente) Container Setup:
  1.  Connect to server: `ssh -L 8888:localhost:8384  ente@duckpond.ch`
  2.  Change working directory: `cd ~/duckpond.ch/_env`
  3.  Decrypt `.env`: `./up.sh --decrypt PASSWORD noop`
  4.  In .env change `VOLUME_SYNC_MOUNT` to `rw`
  5.  Start syncthing: `./up.sh dev up syncthing`
  6.  Start service: `docker exec -ti duckpondch-syncthing-1 ./start.sh`
  7.  Connect to https://localhost:8888
  8.  Setup syncthing password
  9.  Connect to sync network
  10. Wait for full sync
  11. Stop syncthing
  12. Start volume-sync: `./up.sh -v dev up volume-sync`
  13. Restore backup: `docker exec -ti duckpondch-volume-sync-1 ./restore.sh [backup-to-restore]`
  14. Stop volume-sync
  15. In .env change `VOLUME_SYNC_MOUNT` to `ro`
  16. Make DNS record for duckpond.ch point to the new server (also change reverse dns!)
  17. Create cert folder: `mkdir -p mailcow/data/assets/ssl/`
  18. Init certificates: `./up.sh --decrypt PASSWORD prod run letsencrypt`
  19. Clean build & start all containers: `docker system prune -af && ./up.sh --decrypt PASSWORD prod`
