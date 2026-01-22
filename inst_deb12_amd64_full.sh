#!/bin/bash

##################################################
#             Var / Const Definition             #
##################################################

#okinput=true

NC=$(echo -en '\001\033[0m\002')
GREEN=$(echo -en '\001\033[00;32m\002')
YELLOW=$(echo -en '\001\033[00;33m\002')
#BLUE=$(echo -en '\001\033[00;34m\002')
#RED=$(echo -en '\001\033[00;31m\002')
#MAGENTA=$(echo -en '\001\033[00;35m\002')
#PURPLE=$(echo -en '\001\033[00;35m\002')
CYAN=$(echo -en '\001\033[00;36m\002')
#WHITE=$(echo -en '\001\033[01;37m\002')

#LIGHTGRAY=$(echo -en '\001\033[00;37m\002')
#LRED=$(echo -en '\001\033[01;31m\002')
#LGREEN=$(echo -en '\001\033[01;32m\002')
#LYELLOW=$(echo -en '\001\033[01;33m\002')
#LBLUE=$(echo -en '\001\033[01;34m\002')
#LMAGENTA=$(echo -en '\001\033[01;35m\002')
#LPURPLE=$(echo -en '\001\033[01;35m\002')
#LCYAN=$(echo -en '\001\033[01;36m\002')

##################################################
#                   Functions                    #
##################################################

function print_header() {
    clear
    echo ""
    echo -e "${YELLOW}     Welcome to the Debian 12 System installer!${NC}"
    echo -e "${GREEN}"
    echo "     I need to ask you a few questions before starting the setup."
    echo ""
}

function print_conf() {
    clear
    echo ""
    echo -e "${YELLOW}     Debian 12 System installer${NC}"
    echo -e "${GREEN}"
    echo "     Your input is:"
    echo ""
}

function pre_inst_ssh() {

    cd /root || exit
    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/bashrc.ini

    cp bashrc.ini /root/.bashrc
    cp bashrc.ini /etc/skel/.bashrc
    rm /root/bashrc.ini

    echo "deb http://deb.debian.org/debian/ bookworm-backports main" | tee -a /etc/apt/sources.list

    ###################################
    #### enable mouse support for nano
    ###################################
    sed -i "s|# set mouse|set mouse|g" /etc/nanorc

    ###################################
    #### enable linenumbers for nano
    ###################################
    sed -i "s|# set linenumbers|set linenumbers|g" /etc/nanorc

    ###################################
    #### change file limit for root
    ###################################
    sed -i "s|# End of file||g" /etc/security/limits.conf
    {
        echo "root             soft    nofile          131072"
        echo " "
        echo "# End of file"
    } >>/etc/security/limits.conf

    ###################################
    #### Setup root key file
    ###################################

    if [ -d /root/.ssh ]; then
        echo ".ssh exists"
    else
        mkdir /root/.ssh
    fi

    if [ -f /root/.ssh/authorized_keys ]; then
        echo "file authorized_keys exists"
    else
        cd /root/.ssh || exit
        wget https://raw.githubusercontent.com/fdmgit/virtualmin/main/authorized_keys
    fi

    ###################################
    #### SSH Hardening
    #### https://sshaudit.com
    ###################################

    #### Re-generate the RSA and ED25519 keys
    rm /etc/ssh/ssh_host_*
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

    #### Remove small Diffie-Hellman moduli
    awk '$5 >= 3071' /etc/ssh/moduli >/etc/ssh/moduli.safe
    mv /etc/ssh/moduli.safe /etc/ssh/moduli

    #### Restrict supported key exchange, cipher, and MAC algorithms
    echo -e "# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com\n# hardening guide.\n\nKexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\n\nCiphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\n\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nRequiredRSASize 3072\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\n" >/etc/ssh/sshd_config.d/ssh-audit_hardening.conf

    sed -i "s|\#Port 22|Port 49153|g" /etc/ssh/sshd_config
    sed -i "s|\#LoginGraceTime 2m|LoginGraceTime 1m|g" /etc/ssh/sshd_config
    sed -i "s|PermitRootLogin without-password|PermitRootLogin prohibit-password|g" /etc/ssh/sshd_config
    sed -i "s|\#MaxAuthTries 6|MaxAuthTries 4|g" /etc/ssh/sshd_config
    sed -i "s|X11Forwarding yes|X11Forwarding no|g" /etc/ssh/sshd_config
    sed -i "s|session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale|session    required     pam_env.so envfile=/etc/default/locale|g" /etc/pam.d/sshd
    systemctl restart sshd
    sleep 5

    #################################
    ### default web page index file
    #################################

    cd /etc/skel || exit
    mkdir public_html
    cd public_html || exit
    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/index_web.php
    mv index_web.php index.php
    cd /root || exit
}

function closing_msg() {

    # Closing message
    host_name=$(hostname | awk '{print $1}')
    echo ""
    echo -e "${YELLOW}ATTENTION\\n"
    echo -e "${GREEN}The port for SSH has changed. To login use the following comand:\\n"
    echo -e "${CYAN}        ssh root@${host_name} -p 49153${NC}\\n"
    echo ""
    echo -e "${GREEN} Webmin page is reachable by entering:\\n"
    echo -e "${CYAN}        https://${host_name}:10000"
    echo -e "${NC}\\n"
    echo -e "End Time:" "$(date +"%d.%m.%Y %T")"
    echo ""
    echo ""
}

function inst_logo_styles() {

    ###################################
    #### add logo and styles
    ###################################

    cd /root || exit

    cat >>/root/inst_logo_styles.sh <<'EOF'

wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/logostyle.zip
unzip logostyle.zip
cp logo.png /etc/webmin/authentic-theme/
cp logo_welcome.png /etc/webmin/authentic-theme/
cp styles.css /etc/webmin/authentic-theme/
rm logo.png
rm logo_welcome.png
rm styles.css
rm logostyle.zip
rm inst_logo_styles.sh

cd //home/._default_hostname/public_html/ || exit
wget -O index.html https://raw.githubusercontent.com/fdmgit/install-debian-12/main/index_web.php
sed  -i  "s|<?php echo \$_SERVER\['HTTP_HOST'\]; ?>|$(hostname)|g" index.html
chown _default_hostname:_default_hostname index.html
rm index.php
cd /root || exit

###################################
#### remove bind9, dovecot 
###################################

#systemctl stop named
#systemctl disable named

#apt -y purge bind9
#apt -y purge bind9-utils
#apt -y purge dns-root-data
#rm -r /var/cache/bind/
#rm /etc/apparmor.d/local/*
#apt purge procmail procmail-wrapper -y
#apt purge dovecot-core dovecot-imapd dovecot-pop3d -y
#rm -r /var/lib/dovecot/
#rm -r /etc/dovecot/

printf '\nn\nn\ny\ny\ny\ny\n' | mariadb-secure-installation

apt -y autoremove && apt -y autoclean

reboot

EOF

    chmod +x /root/inst_logo_styles.sh

}

function inst_virtualmin_config() {

    ###################################
    #### add config files to Virtualmin
    ###################################

    cd /etc/webmin/virtual-server/plans || exit
    wget https://raw.githubusercontent.com/fdmgit/virtualmin/main/160880314564582
    cd /etc/webmin/virtual-server/templates || exit
    wget https://raw.githubusercontent.com/fdmgit/virtualmin/main/server-level.tar.gz
    tar -xvzf server-level.tar.gz
    rm server-level.tar.gz

}

function inst_redis() {

    ##############################
    #### Install Redis Server
    ##############################

    apt update
    apt install redis -y
    #systemctl enable --now redis-server
    #systemctl restart redis-server

    cat >>/etc/sysctl.conf <<'EOF'

vm.overcommit_memory = 1

EOF

}

function inst_add_python() {

    ######################################
    #### install additional Python modules
    ######################################

    apt install python3-full -y
    apt install python3-venv -y
    apt install python3-pip -y
    apt install virtualenv -y

}

function inst_f2b() {

    ###################################
    #### new fail2ban and jail
    ###################################

    cd /root || exit
    apt install fail2ban
    virtualmin-config-system -i=Fail2banFirewalld

    #wget -O fail2ban_newest.deb  https://github.com/fail2ban/fail2ban/releases/download/1.1.0/fail2ban_1.1.0-1.upstream1_all.deb
    #dpkg -i --force-confnew fail2ban_newest.deb
    #rm fail2ban_newest.deb

    git clone https://github.com/fail2ban/fail2ban.git
    cd fail2ban || exit
    python3 setup.py install
    cd /root || exit
    rm -r /root/fail2ban

    apt -y install python3-systemd

    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/jail-deb12.local
    cd /etc/fail2ban || exit
    mv jail.local jail.local.orig
    cp /root/jail-deb12.local jail.local
    rm /root/jail-deb12.local
    
    cat >>/etc/fail2ban/fail2ban.local <<'EOF'

[Definition]
allowipv6 = auto

EOF

    touch /var/log/auth.log
    cp -av /usr/local/bin/fail2ban-* /usr/bin/
    rm /usr/local/bin/fail2ban-*

}

function inst_firewalldconf() {

    ###################################
    #### add Firewalld configuration
    ###################################

    cd /etc/firewalld || exit
    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/firewalldconf.tar.gz
    tar -xvzf firewalldconf.tar.gz
    systemctl stop firewalld
    cd /etc/firewalld/firewalldconf/ipsets || exit
    cp ./*.xml /etc/firewalld/ipsets/
    cd /etc/firewalld/firewalldconf/zones || exit
    cp drop.xml /etc/firewalld/zones/
    cd /root || exit
    systemctl start firewalld
    echo ""
    echo "Waiting 60 sec ....."
    echo ""
    sleep 60

    systemctl enable customnft.service
    systemctl stop firewalld
    systemctl start firewalld

}

function inst_pwgen() {

    ###################################
    #### install password generator
    ###################################

    apt install pwgen -y

}

function inst_mc() {

    #################################
    #### Install Midnight Commander
    #################################

    cd /usr/share/keyrings || exit
    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/tataranovich-keyring.gpg
    echo "# Repository for Midnight Commander" >/etc/apt/sources.list.d/mc.list
    echo "deb [signed-by=/usr/share/keyrings/tataranovich-keyring.gpg] http://www.tataranovich.com/debian bookworm main" >>/etc/apt/sources.list.d/mc.list

    apt update
    apt install mc -y

}

function inst_smart_nvme() {

    ######################################
    #### Install smartmontools & nvme-cli
    ######################################

    cd /root || exit
    wget https://raw.githubusercontent.com/fdmgit/install-debian-12/main/smartmontools_7.4-2~bpo12+1_amd64.deb
    dpkg -i smartmontools_7.4-2~bpo12+1_amd64.deb
    rm smartmontools_7.4-2~bpo12+1_amd64.deb
    apt install nvme-cli -y

}

function inst_mariadb() {

    ##################################
    #### Install MariaDB Repository
    ##################################

    curl -o /etc/apt/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'

    cd /etc/apt/sources.list.d || exit
    touch mariadb.list

    cat >>/etc/apt/sources.list.d/mariadb.list <<'EOF'

# deb.mariadb.org is a dynamic mirror if your preferred mirror goes offline. See https://mariadb.org/mirrorbits/ for details.
# deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://deb.mariadb.org/10.11/debian bookworm main

deb [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://mirror.mva-n.net/mariadb/repo/10.11/debian bookworm main
# deb-src [signed-by=/etc/apt/keyrings/mariadb-keyring.pgp] https://mirror.mva-n.net/mariadb/repo/10.11/debian bookworm main

EOF

    apt update
    echo "N" | apt upgrade -y
    cd /etc/mysql/mariadb.conf.d || exit
    #ls provider*.cnf | xargs -I{} mv {} {}.orig
    find provider*.cnf -print0 | xargs -0 -I{} mv {} {}.orig
    apt autoremove -y

}

function inst_kernel() {

    ##############################
    #### Install new Linux Kernel
    ##############################

    apt install linux-image-6.12.30+bpo-amd64 -y
    # apt install linux-headers-6.12.12+bpo-amd64 -y # development

}

function inst_sury_repo() {

    ##############################
    #### install new PHP versions
    ##############################

    apt -y install lsb-release apt-transport-https ca-certificates

    echo | curl -sSL https://packages.sury.org/apache2/README.txt | sudo bash -xe
 
    echo | curl -sSL https://packages.sury.org/php/README.txt | sudo bash -xe
    
    apt update
    apt upgrade -y

}

function inst_php74() {


    apt-get install php7.4-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,json,ldap,mbstring} -y
    apt-get install php7.4-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/7.4/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600

EOF

    cat >>/etc/php/7.4/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600

EOF

    cat >>/etc/php/7.4/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600

EOF

}

function inst_php80() {

    apt-get install php8.0-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.0-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.0/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.0/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.0/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

}

function inst_php81() {

    apt-get install php8.1-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.1-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.1/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.1/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.1/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

}

function inst_php82() {


    apt-get install php8.2-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.2-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.2/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.2/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.2/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

}

function inst_php83() {


    apt-get install php8.3-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.3-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.3/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.3/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.3/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

}

function inst_php84() {


    apt-get install php8.4-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.4-{mysql,odbc,opcache,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.4/cgi/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.4/cli/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

    cat >>/etc/php/8.4/fpm/php.ini <<'EOF'

[PHP]
output_buffering = Off
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
post_max_size = 1024M
upload_max_filesize = 1024M
date.timezone = Europe/Zurich
max_input_vars = 10000
[Session]
session.gc_maxlifetime = 3600     
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.jit_buffer_size=256M

EOF

}

function enable_apache_mod() {

    #####################################
    #### Enable additional Apache modules
    #####################################

    a2enmod http2
    a2enmod headers
    a2enmod expires
    a2enmod include
    a2enmod proxy_http2

}

function dis_services() {

    ##############################
    #### Disable Services     ####
    ##############################

    #systemctl disable named
    systemctl disable usermin
    systemctl disable dovecot
    systemctl disable proftpd
    #systemctl disable clamav-freshclam
    #systemctl disable clamav-daemon
    #systemctl disable postgrey
    systemctl disable postfix


}

function post_inst() {

    ##############################
    #### Update locate DB
    ##############################

    cd /root || exit
    touch .bash_aliases
    {
        echo "alias jos='joshuto'"
        echo "alias gc='gat'"
        echo "alias ed=nano"
        echo "alias hh=hstr"
    } >>.bash_aliases
    cp .bash_aliases /etc/skel/.bash_aliases
    #rm -R .spamassassin
    rm inst_deb12_amd64_full.sh

    ################################
    ### remove default apache2 files
    ################################
    rm /var/www/html/index.html
    rm /etc/apache2/sites-available/000-default.conf
    rm /etc/apache2/sites-available/default-ssl.conf
    ################################################

    apt update
    apt upgrade -y
    updatedb

}

function inst_virtualmin() {

    ##############################
    #### Install Virtualmin
    ##############################

    apt install gpg-agent -y

    cd /root || exit

    #wget -O virtualmin-install.sh https://raw.githubusercontent.com/virtualmin/virtualmin-install/master/virtualmin-install.sh
    wget -O virtualmin-install.sh https://software.virtualmin.com/gpl/scripts/virtualmin-install.sh
    #yes | sh virtualmin-install.sh --type full  #  < full | mini >
    sh virtualmin-install.sh  -y
    #apt install fail2ban -y
    #virtualmin-config-system -i=Fail2banFirewalld
    rm virtualmin-install.sh


}

function inst_gat() {

    ###################################
    #### Add gat (replacement for cat)
    ###################################

    cd /usr/local/bin || exit
    wget https://github.com/koki-develop/gat/releases/download/v0.19.3/gat_Linux_x86_64.tar.gz
    tar -xvzf gat_Linux_x86_64.tar.gz
    chown root:root gat
    chmod +x gat
    rm gat_Linux_x86_64.tar.gz
    rm LICENSE
    rm README.md

}

function inst_jos() {

    ###################################
    #### Add joshuto (cli filemanager)
    ###################################

    cd /usr/local/bin || exit
    wget https://github.com/kamiyaa/joshuto/releases/download/v0.9.8/joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz
    tar -vxzf joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin --strip-components=1
    chown root:root joshuto
    rm joshuto-v0.9.8-x86_64-unknown-linux-musl.tar.gz
}

function inst_base() {

    ###################################
    #### Install Debian 12 Base
    ###################################
    apt update
    apt upgrade -y
    apt install plocate sntp ntpdate software-properties-common curl imagemagick -y
    timedatectl set-timezone Europe/Zurich

    hostnamectl set-hostname "$fqdn"  # set hostname
    echo "root:${rpasswd}" | chpasswd # set root password -

}

function enh_nft() {

    ###################################
    #### add some NFT tools
    ###################################

    apt install netfilter-persistent -y

    mkdir /etc/nftables

    cat >>/etc/nftables/customnft.nft <<'EOF'

table inet blockedip {
    chain input {
        type filter hook ingress device "eth_device" priority filter; policy accept;
    }
}

table inet allowedip {
    chain input {
        type filter hook ingress device "eth_device" priority filter; policy accept;
    }
}

table ip rejectip {
    chain input {
        type filter hook input priority filter; policy accept;
# INSERT BELOW

    }
}

EOF

    eth_device='device "'$(ip -o -4 route show to default | awk '{print $5}')'"'
    sed -i "s|device \"eth_device\"|$eth_device|g" /etc/nftables/customnft.nft

    cat >>/etc/systemd/system/customnft.service <<'EOF'

[Unit]
Description=Custom NFTABLES Service
After=network.target firewalld.service nftables.service fail2ban.service

[Service]
Type=simple
ExecStart=/usr/sbin/nft -f /etc/nftables/customnft.nft

[Install]
WantedBy=multi-user.target

EOF

}

inst_bip() {

    ###################################
    #### add some BIP tool
    ###################################

    cat >>/usr/local/bin/bip <<'EOF'

#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

if [ -z  "$1" ]
 then
   echo -e ""
   echo -e "${RED}      Missing input. Enter IP Addr || Subnet !${NC}"
   echo -e "${RED}      Usage: bip <ipaddr || ip subnet>${NC}"
   echo -e ""
   exit
else
   BANIPADDR=$1
fi

IPDETECT=0

if [[ "$BANIPADDR" =~ ^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
    IPDETECT=1
fi

if [[ "$BANIPADDR" =~ ^([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])/([1-9]|[12][0-9]|3[0-2])$ ]]; then
    IPDETECT=1
fi

if [ $IPDETECT -eq 0 ] ; then
    clear
    echo ""
    echo ""
    echo -e "${RED}      The IP Address or Subnet ${YELLOW}${BANIPADDR}${RED} is wrong. Enter IP address / subnet again${NC}" 
    echo ""
    echo ""
    exit
fi

sed -i "/^# INSERT BELOW/a \ \t\tip saddr $BANIPADDR counter packets 0 bytes 0 reject" /etc/nftables/customnft.nft
nft insert rule ip rejectip input ip saddr $BANIPADDR counter packets 0 bytes 0 reject
echo -e ""
echo -e "${GREEN}      IP Addr || subnet blocked permanently${NC}"
echo -e ""

EOF

    chmod +x /usr/local/bin/bip

}

function inst_motd() {

    ###################################
    #### add new motd text
    ###################################

    cd /root || exit
    echo "" >/etc/motd
    apt install figlet -y
    apt install boxes -y
    apt install lolcat -y
    cp /usr/games/lolcat /usr/local/bin/

    cat >>/etc/update-motd.d/10-header <<'EOF'
#!/bin/bash

hname=$(hostname | awk '{print $1}')
hname=$(echo ${hname^^} | cut -d"." -f 1)
echo -e " "
echo -e " "
# figlet -c -k -f big $hname | lolcat -f | boxes -d boy
figlet -c -k -f big $hname | lolcat -f
echo ""
EOF

    chmod +x /etc/update-motd.d/10-header

}

function inst_hstr() {

    ###################################
    #### install histery tool
    ###################################

    apt install hstr -y
}

function inst_composer() {

    ###################################
    #### install composer
    ###################################

    cd /root || exit
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer --quiet
    php -r "unlink('composer-setup.php');"

}

##################################################
#               Start Installation               #
##################################################

#apt install dialog -y # add dialog program

rpasswd=""
fqdn=""

print_header

until [ ${#rpasswd} -gt 11 ]; do
    echo -en "${GREEN}     Enter new root password [min. length is 12 char]: ${YELLOW} "
    read -e -i "${rpasswd}" rpasswd
    if [ ${#rpasswd} -lt 12 ]; then
        print_header
        echo -e "${LRED}     Password has too few characters"
    fi
done

print_header
echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"

until [[ "$fqdn" =~ ^.*\..*\..*$ ]]; do
    #   print_header
    #   echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"
    echo -en "${GREEN}     Enter a full qualified domain name:               ${YELLOW} "
    read -e -i "${fqdn}" fqdn
    if [[ "$fqdn" =~ ^.*\..*\..*$ ]]; then
        print_conf
        echo -e "${GREEN}     New root password:           ${YELLOW}${rpasswd}"
        echo -e "${GREEN}     Full qualified domain name:  ${YELLOW}${fqdn}"
    else
        print_header
        echo -e "${GREEN}     Enter new root password [min. length is 12 char]:  ${YELLOW}${rpasswd}"
        echo ""
        echo -e "${LRED}     The FQDN is not correct"
    fi
done

echo -e "${NC}"
read -r -p "     Ready to start installation [Y/n] ? " start_inst
if [[ "$start_inst" = "" ]]; then
    start_inst="Y"
fi
if [[ "$start_inst" != [yY] ]]; then
    clear
    exit
fi

############################################################################
############################################################################

pre_inst_ssh           # function
inst_base              # function
inst_smart_nvme        # function
inst_gat               # function
inst_jos               # function
inst_hstr              # function
inst_virtualmin        # function
inst_add_python        # function
#dis_services           # function
inst_sury_repo         # function
inst_php74             # function
inst_php80             # function
inst_php81             # function
inst_php82             # function
inst_php83             # function
inst_php84             # function
enable_apache_mod      # function
inst_redis             # function
inst_virtualmin_config # function
inst_pwgen             # function
#inst_mc                # function
inst_kernel            # function
inst_mariadb           # function
inst_bip               # function
post_inst              # function
inst_motd              # function
inst_composer          # function
inst_f2b               # function
enh_nft                # function
inst_logo_styles       # function
inst_firewalldconf     # function
closing_msg            # function

reboot

############################################################################
