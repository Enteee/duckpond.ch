# Server Installation

* Install CentOS 8 Stream

* Install epel:
```sh
# dnf install --assumeyes \
  epel-release
```

* Base system installation:
```sh
# dnf install --assumeyes \
  openssh-server \
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
# dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# dnf install --assumeyes \
  docker-ce \
  docker-ce-cli \
  containerd.io
# curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# chmod +x /usr/local/bin/docker-compose
```

* Enable services:
```
# systemctl enable sshd
# systemctl enable fail2ban
# systemctl enable docker
# systemctl enable dnf-automatic.timer
```

* Activate firewall:
```
# firewall-cmd --set-default-zone=dmz
```

* Add service user:
```sh
# adduser -G docker ente
```

* Install ssh-key:
```sh
# mkdir -p /home/ente/.ssh
# cp /root/.ssh/authorized_keys /home/ente/.ssh/
# chown -R ente:ente /home/ente/.ssh
# chmod 600 /home/ente/.ssh/authorized_keys
```

* Set SSH Banner:
```
cat >/etc/ssh/sshd_banner <<'EOF'
' ==========='
| Welcome on |
| the pond!  |
'===== .-"""-.   _.---..-;  
      :.)     ;""      \/   
__..--'\      ;-"""-.   ;._ 
`-.___.^.___.'-.____J__/-._J
EOF
# sed -i -re 's|#Banner none|Banner /etc/ssh/sshd_banner|' /etc/ssh/sshd_config
```

* Enable byobu:
```
# byobu-enable
# sudo -u ente sh -c 'byobu-enable'
```

* Set up git:
```
# sudo -u ente sh -c 'git config --global user.email "ducksource@duckpond.ch"'
# sudo -u ente sh -c 'git config --global user.name "ente"'
```

* Clone this repo:
```
# sudo -u ente sh -c 'cd ~;git clone --recurse-submodules https://github.com/Enteee/duckpond.ch.git'
```
