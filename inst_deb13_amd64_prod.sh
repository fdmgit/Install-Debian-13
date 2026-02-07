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

function pre_inst_ssh() {

    cd /root || exit
    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/bashrc.ini

    cp bashrc.ini /root/.bashrc
    cp bashrc.ini /etc/skel/.bashrc
    rm /root/bashrc.ini

    #echo "deb http://deb.debian.org/debian/ bookworm-backports main" | tee -a /etc/apt/sources.list

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
        wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/authorized_keys
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

    #sed -i "s|\#Port 22|Port 49153|g" /etc/ssh/sshd_config
    #sed -i "s|\#LoginGraceTime 2m|LoginGraceTime 1m|g" /etc/ssh/sshd_config
    #sed -i "s|PermitRootLogin without-password|PermitRootLogin prohibit-password|g" /etc/ssh/sshd_config
    #sed -i "s|\#MaxAuthTries 6|MaxAuthTries 4|g" /etc/ssh/sshd_config
    #sed -i "s|X11Forwarding yes|X11Forwarding no|g" /etc/ssh/sshd_config

    cat >>/etc/ssh/sshd_config.d/sshd_hardening.conf <<'EOF'
 Port 49153
 LoginGraceTime 1m
 PermitRootLogin prohibit-password
 MaxAuthTries 4
 AllowTcpForwarding no
 X11Forwarding no
 AllowAgentForwarding no

EOF

    sed -i "s|session    required     pam_env.so user_readenv=1 envfile=/etc/default/locale|session    required     pam_env.so envfile=/etc/default/locale|g" /etc/pam.d/sshd
    systemctl restart sshd
    sleep 5

    #################################
    ### default web page index file
    #################################

    cd /etc/skel || exit
    mkdir public_html
    cd public_html || exit
    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/index_web.php
    mv index_web.php index.php
    cd /root || exit
}

function inst_base() {

    ###################################
    #### Install Debian 13 Base
    ###################################
    apt update
    apt upgrade -y
    #apt install plocate sntp ntpdate software-properties-common curl imagemagick -y
    apt install plocate curl apt-transport-https imagemagick -y
    timedatectl set-timezone Europe/Zurich

    hostnamectl set-hostname "$fqdn"  # set hostname
    echo "root:${rpasswd}" | chpasswd # set root password -

    ###################################
    #### create log files for fail2ban
    ###################################
    touch /var/log/auth.log
    touch /var/log/syslog


}

function inst_smart_nvme() {

    ######################################
    #### Install smartmontools & nvme-cli
    ######################################

    cd /root || exit
    apt install smartmontools -y 
    apt install nvme-cli -y

}

function inst_gat() {

    ###################################
    #### Add gat (replacement for cat)
    ###################################

    cd /usr/local/bin || exit
    wget https://github.com/koki-develop/gat/releases/download/v0.26.0/gat_Linux_x86_64.tar.gz
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
    wget https://github.com/kamiyaa/joshuto/releases/download/v0.9.9/joshuto-v0.9.9-x86_64-unknown-linux-musl.tar.gz
    tar -vxzf joshuto-v0.9.9-x86_64-unknown-linux-musl.tar.gz -C /usr/local/bin --strip-components=1
    chown root:root joshuto
    rm joshuto-v0.9.9-x86_64-unknown-linux-musl.tar.gz
}

function inst_hstr() {

    ###################################
    #### install histery tool
    ###################################

    apt install hstr -y
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

    apt update
    apt install mc -y

}

function inst_virtualmin() {

    ##############################
    #### Install Virtualmin
    ##############################

    apt install gpg-agent -y

    cd /root || exit


    ##### testing
    #wget -O virtualmin-install.sh https://raw.githubusercontent.com/virtualmin/virtualmin-install/master/virtualmin-install.sh
    #yes | sh virtualmin-install.sh --type mini  --branch prerelease #  < full | mini >
    #yes | sh virtualmin-install.sh --type mini  --branch rc #  < full | mini >    
    
    ##### production
    wget -O virtualmin-install.sh https://download.virtualmin.com/virtualmin-install.sh
    yes | sh virtualmin-install.sh --type mini   --branch stable #  < full | mini >

    #############################################
    #### Install fail2ban and configure firewalld
    #############################################
    apt install fail2ban -y
    virtualmin-config-system -i=Fail2banFirewalld
    rm virtualmin-install.sh

}

function inst_add_python() {

    ######################################
    #### install additional Python modules
    ######################################

    apt install python3-full -y
    apt install python3-venv -y
    apt install python3-pip -y
    apt install virtualenv -y
    apt install python3-systemd -y

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

function inst_sury_repo() {

    ##############################
    #### install new PHP versions
    ##############################

    apt -y install lsb-release ca-certificates

    echo | curl -sSL https://packages.sury.org/apache2/README.txt | sudo bash -xe
 
    echo | curl -sSL https://packages.sury.org/php/README.txt | sudo bash -xe
    
    apt update
    apt upgrade -y

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

function inst_php85() {


    apt-get install php8.5-{bcmath,bz2,cgi,curl,dba,fpm,gd,gmp,igbinary,imagick,imap,intl,ldap,mbstring} -y
    apt-get install php8.5-{mysql,odbc,pspell,readline,redis,soap,sqlite3,tidy,xml,xmlrpc,xsl,zip} -y

    cat >>/etc/php/8.5/cgi/php.ini <<'EOF'

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

    cat >>/etc/php/8.5/cli/php.ini <<'EOF'

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

    cat >>/etc/php/8.5/fpm/php.ini <<'EOF'

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

function enable_apache_modules() {

    #####################################
    #### Enable additional Apache modules
    #####################################

    a2enmod http2
    a2enmod headers
    a2enmod expires
    a2enmod include
    a2enmod proxy_http2

}

function inst_wsgi_apache_module() {

    #####################################
    #### Install WSGI Apache module
    #####################################

    apt install libapache2-mod-wsgi-py3 -y

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

function inst_virtualmin_config() {

    ###################################
    #### add config files to Virtualmin
    ###################################

    cd /etc/webmin/virtual-server/plans || exit
    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/1769190256443380
    cd /etc/webmin/virtual-server/templates || exit
    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/server-level.tar.gz
    tar -xvzf server-level.tar.gz
    rm server-level.tar.gz

}

function inst_iliascripts() {

    ##############################
    #### ILIAS Scripts
    ##############################

    cd /usr/local/bin || exit
    wget -O apache-log-stats https://raw.githubusercontent.com/iliaross/script-stash/refs/heads/main/bash/apache-log-stats.bash
    wget -O net-ip-lookup https://raw.githubusercontent.com/iliaross/script-stash/refs/heads/main/perl/net-ip-lookup.pl
    wget -O apache-check-vhosts https://raw.githubusercontent.com/iliaross/script-stash/refs/heads/main/perl/apache-check-vhosts.pl
    chmod +x apache-log-stats
    chmod +x net-ip-lookup
    chmod +x apache-check-vhosts    

}

function post_inst() {

    ##############################
    #### Update .bash_aliases
    ##############################

    cd /root || exit
    touch .bash_aliases
    {
        echo "alias jos='joshuto'"
        echo "alias gc='gat'"
        echo "alias ed=nano"
        echo "alias hh=hstr"
        echo "alias apt='PAGER= apt'"
        echo "alias apache-stats='apache-log-stats'"
        echo "alias iplookup='net-ip-lookup'"
        echo "alias check-vhosts='apache-check-vhosts'"
    } >>.bash_aliases
    cp .bash_aliases /etc/skel/.bash_aliases
    rm -R .spamassassin
    rm inst_deb13_amd64.sh

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

function inst_motd() {

    ###################################
    #### add new motd text
    ###################################

    cd /root || exit
    echo "" >/etc/motd
    apt install figlet -y
    apt install lolcat -y
    cp /usr/games/lolcat /usr/local/bin/

    cat >>/etc/update-motd.d/10-header <<'EOF'
 #!/bin/bash

 hname=$(hostname | awk '{print $1}')
 hname=$(echo ${hname^^} | cut -d"." -f 1)
 echo -e " "
 echo -e " "
 figlet -c -k -w 90 -f big $hname | lolcat -f
 echo ""
 EOF

    chmod +x /etc/update-motd.d/10-header
    mv /etc/update-motd.d/10-uname /etc/update-motd.d/20-uname
    sed -i "s|uname -snrvm|uname -snv|g" /etc/update-motd.d/20-uname    
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

function inst_f2b() {

    ###################################
    #### new fail2ban and jail
    ###################################

    cd /root || exit

    #git clone https://github.com/fail2ban/fail2ban.git
    #cd fail2ban || exit
    #python3 setup.py install
    #cd /root || exit
    #rm -r /root/fail2ban

    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/jail-deb13.local
    cd /etc/fail2ban || exit
    mv jail.local jail.local.orig
    cp /root/jail-deb13.local jail.local
    rm /root/jail-deb13.local
    
    cat >>/etc/fail2ban/fail2ban.local <<'EOF'

 [Definition]
 allowipv6 = auto

EOF

    #cp -av /usr/local/bin/fail2ban-* /usr/bin/
    #rm /usr/local/bin/fail2ban-*

}

function inst_logo_styles() {

    ###################################
    #### add logo and styles
    ###################################

    cd /root || exit

    cat >>/root/inst_logo_styles.sh <<'EOF'

 wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/logostyle.zip
 unzip logostyle.zip
 cp logo.png /etc/webmin/authentic-theme/
 cp logo_welcome.png /etc/webmin/authentic-theme/
 cp styles.css /etc/webmin/authentic-theme/
 cd /usr/share/webmin/authentic-theme/images/favicons/virtualmin/ || exit
 mv favicon-16x16.png favicon-16x16.png.orig
 mv favicon-32x32.png favicon-32x32.png.orig
 mv apple-touch-icon.png apple-touch-icon.png.orig
 cd /usr/share/webmin/authentic-theme/images/favicons/webmin/ || exit
 mv favicon-16x16.png favicon-16x16.png.orig
 mv favicon-32x32.png favicon-32x32.png.orig
 mv apple-touch-icon.png apple-touch-icon.png.orig
 cd /usr/share/webmin/authentic-theme/images/favicons/usermin/ || exit
 mv favicon-16x16.png favicon-16x16.png.orig
 mv favicon-32x32.png favicon-32x32.png.orig
 mv apple-touch-icon.png apple-touch-icon.png.orig
 cd /root || exit
 cp favicon-16x16.png /usr/share/webmin/authentic-theme/images/favicons/virtualmin/
 cp favicon-32x32.png /usr/share/webmin/authentic-theme/images/favicons/virtualmin/
 cp apple-touch-icon.png /usr/share/webmin/authentic-theme/images/favicons/virtualmin/
 cp favicon-16x16.png /usr/share/webmin/authentic-theme/images/favicons/webmin/
 cp favicon-32x32.png /usr/share/webmin/authentic-theme/images/favicons/webmin/
 cp apple-touch-icon.png /usr/share/webmin/authentic-theme/images/favicons/webmin/
 cp favicon-16x16.png /usr/share/webmin/authentic-theme/images/favicons/usermin/
 cp favicon-32x32.png /usr/share/webmin/authentic-theme/images/favicons/usermin/
 cp apple-touch-icon.png /usr/share/webmin/authentic-theme/images/favicons/usermin/

 rm logo.png
 rm logo_welcome.png
 rm styles.css
 rm favicon*.png
 rm apple-touch-icon.png
 rm logostyle.zip

 cd /home/._hostname/public_html/ || exit
 wget -O index.html https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/index_web.php
 sed  -i  "s|<?php echo \$_SERVER\['HTTP_HOST'\]; ?>|$(hostname)|g" index.html
 chown _hostname:_hostname index.html
 rm index.php

 hname=$(sed 's/\.*[^\.]*\.[^\.]*$//g'  <<< $(hostname))
 subdom=$(echo "$hname" | awk '{print toupper($0)}')
 sed -i "s/session_header=Login to Webmin/session_header=Login to $subdom/g" /usr/share/webmin/lang/en

 cd /root || exit

 ###################################
 #### remove bind9, dovecot 
 ###################################

 systemctl stop named
 systemctl disable named

 apt -y purge bind9
 apt -y purge bind9-utils
 apt -y purge dns-root-data
 rm -r /var/cache/bind/
 rm /etc/apparmor.d/local/*
 apt purge procmail procmail-wrapper -y
 apt purge dovecot-core dovecot-imapd dovecot-pop3d -y
 rm -r /var/lib/dovecot/
 rm -r /etc/dovecot/

 printf '\nn\nn\ny\ny\ny\ny\n' | mariadb-secure-installation

 apt -y autoremove && apt -y autoclean

 cd /root || exit
 rm inst_logo_styles.sh
 rm virtualmin-install.log

 reboot

EOF

    chmod +x /root/inst_logo_styles.sh

}

function inst_geoip() {

    mkdir /root/geoip 
    cd /root/geoip || exit
    # get geoip-shell source; newest release
    curl -L "$(curl -s https://api.github.com/repos/friendly-bits/geoip-shell/releases | grep -m1 -o 'https://api.github.com/repos/friendly-bits/geoip-shell/tarball/[^"]*')" > geoip-shell.tar.gz
    tar -zxvf geoip-shell.tar.gz
    cd friendly* || exit
    mv * /root/geoip/
    mv .* /root/geoip/
    cd /root/geoip || exit
    rm -rf friendly*
    rm geoip-shell.tar.gz

    sh geoip-shell-install.sh -z

    # copy files to configuration directory
    mkdir /etc/geoip-shell/install
    cd /etc/geoip-shell/install || exit
    wget https://raw.githubusercontent.com/fdmgit/Install-Debian-13/main/geoipconf.zip
    unzip geoipconf.zip
    
    #get WAN interface
    all_ifaces="$([ -r "/proc/net/dev" ] && sed -n '/^[[:space:]]*[^[:space:]]*:/{s/^[[:space:]]*//;s/:.*//p}' < /proc/net/dev | grep -vx 'lo')"
    sed -i "s/ifaces=/ifaces=$all_ifaces/g" geoip-shell.conf

    cp /etc/geoip-shell/install/geoip-shell.conf /etc/geoip-shell/geoip-shell.conf
    cp /etc/geoip-shell/install/setupdone /etc/geoip-shell/setupdone
       
    mkdir /tmp/geoip-shell-run
    mkdir /tmp/geoip-shell-run/iplists
    mkdir /tmp/geoip-shell-tmp
    mkdir /tmp/geoip-shell-tmp/fetch
    
    geoip-shell restore

    geoip-shell configure -B "/etc/geoip-Shell/install/local_block_ipv4.net
    
    # Setup cron jobs

    (crontab -l 2>/dev/null || true; echo "15 4 * * * /usr/bin/geoip-shell-run.sh update -a 1>/dev/null 2>/dev/null # geoip-shell-update") | crontab -
    (crontab -l 2>/dev/null || true; echo "@reboot /usr/bin/geoip-shell-run.sh restore -a 1>/dev/null 2>/dev/null # geoip-shell-persistence") | crontab -

    rm -rf geoipconf.zip
    rm -rf /root/geoip
}

function inst_bip() {

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

 echo $BANIPADDR >> /etc/geoip-shell/install/local_block_ipv4.net
 geoip-shell configure -B "/etc/geoip-shell/install/local_block_ipv4.net"

 echo -e ""
 echo -e "${GREEN}      IP Addr || subnet blocked permanently${NC}"
 echo -e ""

EOF

    chmod +x /usr/local/bin/bip

}

function inst_mariadb() {

    ##################################
    #### Install MariaDB Repository
    ##################################

    curl -o /usr/share/keyrings/mariadb-keyring.pgp 'https://mariadb.org/mariadb_release_signing_key.pgp'
    cd /usr/share/keyrings || exit
    ln -s mariadb-keyring.pgp mariadb-keyring.gpg
    cd /etc/apt/sources.list.d || exit
    touch mariadb.sources

    cat >>/etc/apt/sources.list.d/mariadb.sources <<'EOF'
 Types: deb deb-src
 URIs: https://dlm.mariadb.com/repo/mariadb-server/11.rolling/repo/debian
 Suites: trixie
 Components: main
 Signed-By: /usr/share/keyrings/mariadb-keyring.gpg

EOF

    cat >>/etc/apt/sources.list.d/mariadb.list <<'EOF'
 deb [signed-by=/usr/share/keyrings/mariadb-keyring.gpg] https://dlm.mariadb.com/repo/mariadb-server/11.rolling/repo/debian/ trixie main 
 
EOF

    sed -i 's/\[mariadb-11.8\]/\[mariadb-11.8\]\n\nfeedback=off/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    systemctl restart mariadb
    sleep 10

    #apt update
    #echo "N" | apt upgrade -y
    cd /etc/mysql/mariadb.conf.d || exit
    #ls provider*.cnf | xargs -I{} mv {} {}.orig
    find provider*.cnf -print0 | xargs -0 -I{} mv {} {}.orig
    apt autoremove -y

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

################################
### support functions
################################

function print_header() {
    clear
    echo ""
    echo -e "${YELLOW}     Welcome to the Debian 13 System installer!${NC}"
    echo -e "${GREEN}"
    echo "     I need to ask you a few questions before starting the setup."
    echo ""
}

function print_conf() {
    clear
    echo ""
    echo -e "${YELLOW}     Debian 13 System installer${NC}"
    echo -e "${GREEN}"
    echo "     Your input is:"
    echo ""
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

pre_inst_ssh             # function
inst_base                # function
inst_smart_nvme          # function
inst_gat                 # function
inst_jos                 # function
inst_hstr                # function
inst_pwgen               # function
inst_mc                  # function
inst_virtualmin          # function
inst_add_python          # function
dis_services             # function
inst_sury_repo           # function
inst_php82               # function
inst_php83               # function
inst_php84               # function
inst_php85               # function
enable_apache_modules    # function
inst_wsgi_apache_module  # function
inst_redis               # function
inst_virtualmin_config   # function
inst_iliascripts         # function
post_inst                # function
inst_motd                # function
inst_composer            # function
inst_f2b                 # function
inst_logo_styles         # function
inst_geoip               # function
inst_bip                 # function
inst_mariadb             # function
closing_msg              # function

reboot

############################################################################
