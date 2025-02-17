#!/bin/bash
# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 
# Define function success
function success {
    echo -e "${GREEN}[+]: $1${NC}"
}
# Define function error
function error {
    echo -e "${RED}[-]: $1${NC}"
}
# check if root
if [ "$EUID" -ne 0 ]; then
   error "Run as ROOT!"
   exit 1
fi
# 1. Backports
UBUNTU_CODENAME=$(lsb_release -sc)

SUPPORTED_VERSIONS=("jammy" "focal" "bionic" "mantic" "oracular")

if [[ " ${SUPPORTED_VERSIONS[@]} " =~ " ${UBUNTU_CODENAME} " ]]; then
    if ! grep -q "deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-backports main restricted universe multiverse" /etc/apt/sources.list; then
        echo "deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list
        echo "Backports added for ${UBUNTU_CODENAME}."
    else
        echo "Backports already enabled for ${UBUNTU_CODENAME}."
    fi
else
    echo "Backports repository for '${UBUNTU_CODENAME}' is not supported in this script."
    exit 1
fi

# 2. Update
apt update -y && apt upgrade -y
if [ $? -eq 0 ]; then
    success "apt update"
else
    error "Error apt update."
    exit 1
fi
# 3. Apache
apt install -y apache2
if [ $? -eq 0 ]; then
    systemctl enable apache2
    systemctl start apache2
    success "Apache2 norm."
else
    error "Apache2 ne norm."
fi
# 4. Python
apt install -y python3 python3-pip
if [ $? -eq 0 ]; then
    success "Python norm."
else
    error "Python ne norm."
fi
# 5. SSH
apt install -y openssh-server
if [ $? -eq 0 ]; then
    systemctl enable ssh
    systemctl start ssh
    success "SSH norm."
else
    error "SSH ne norm."
fi
# 6. UFW + ports
apt install -y ufw
ufw allow 22   # SSH
ufw allow 80   # HTTP
ufw allow 443  # HTTPS
ufw enable
success "UFW norm."
# 7. new sudo user
NEW_USER="newadmin"
useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:password" | chpasswd
usermod -aG sudo $NEW_USER
success "'$NEW_USER' norm."
# 8. Fail2Ban SSH
apt install -y fail2ban
if [ -f /etc/fail2ban/jail.local ]; then
    cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
else
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
fi
systemctl enable fail2ban
systemctl start fail2ban
success "Fail2Ban norm."
# 9. swap
if ! swapon -s | grep -q "/swapfile"; then
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    success "Swap norm."
else
    success "Swap alredy norm."
fi
# 10. Gabrige cleaning
echo "APT::Periodic::Autoremove \"1\";" > /etc/apt/apt.conf.d/20auto-remove
success "Gabrige cleaning norm."
# This is the end
success "All done, relax."
