#!/bin/bash

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

echo 'LC_CTYPE="en_US.UTF-8"' >> /etc/environment

### SWAPON
if [ ! -f "/swapfile" ]; then
	dd if=/dev/zero of=/swapfile count=1024 bs=1MiB
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile
	echo "/swapfile swap swap sw 0 0" >> /etc/fstab
fi

### SOME SOFT
yum install epel-release -y
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install nano htop perl pwgen

clear

### VARS
domainname=""
sshd_conf=/etc/ssh/sshd_config
sshstartrange=15000
sshstoprange=22000
sshport=""
username=""
useremail=""
sourceip=""
vestaport=8083

### GET AN IP
sourceip=$(last -in1 | head -n1 | awk '{print $3}')
echo "Acess will be allowed from IP address: $sourceip"
echo "Press any key"
read

### DOMAIN NAME
while ! [[ ${domainname} =~ ^[A-Za-z0-9\\_\\.\\-]+$ ]]; do
        read -p "Domain name:" domainname
done
echo
### USERNAME INPUT
while ! [[ ${username} =~ ^[A-Za-z0-9\\_]+$ ]]; do
        read -p "User name:" username
done

### USER SETUP
password=$(pwgen -Bc 16 1)
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
        echo "User $username exists!"
        exit 1
else
        pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
        useradd -s /bin/bash -m -p $pass $username
        usermod -aG wheel $username
        userhome=$(eval echo ~$username)
        echo "$username created"
        echo
fi

echo "User: $username and sudo password: $password"
echo "Save credentials!"
echo "Press any key"
read

### IPV6 OFF
sed -i 's/net.ipv6.conf.all.disable_ipv6=0/net.ipv6.conf.all.disable_ipv6=1/' /etc/sysctl.conf
sysctl -p

# SSH
echo

while [[ ! ${sshpassword} =~ ^[0-9a-zA-Z]+$ ]]; do
	read -p "SSH key passphrase (letters and digits only, min 8 symbols) :" sshpassword
	[[ ${#sshpassword} -lt 8 ]] && unset sshpassword
done

while [[ ! ${sshport} =~ ^[0-9]+$ ]]; do
        read -p "Enter Port from $sshstartrange to $sshstoprange : " sshport
        ! [[ ${sshport} -ge $sshstartrange && ${sshport} -le $sshstoprange  ]] && unset sshport
done

sed -i "s/#Port 22/Port $sshport/" $sshd_conf
sed -i '/#PermitRootLogin/ s/#PermitRootLogin yes/PermitRootLogin no/' $sshd_conf
sed -i '/PasswordAuthentication/ s/yes/no/' $sshd_conf
echo "SSHD CONFIG CHANGES:"
grep ^Port $sshd_conf
grep ^Permit $sshd_conf
grep ^Password $sshd_conf
echo

### SSH CLIENT KEYS
mkdir -m 700 $userhome/.ssh
ssh-keygen -t rsa -b 4096 -P$sshpassword -f $userhome/.ssh/id_rsa
cat $userhome/.ssh/id_rsa.pub > $userhome/.ssh/authorized_keys
chown -R $username:$username $userhome/.ssh
chmod 600 $userhome/.ssh/*

### SSH CAT PRIVKEY AND USER CHECK
echo
echo "SSH PRIVATE KEY (COPY-PASTE):"
cat $userhome/.ssh/id_rsa
while [[ ! ${sshinputcheck} =~ ^[yY][eE][sS]$ ]];
do
        read -p "Please confirm you have copied the key (type yes) :" sshinputcheck
done
rm $userhome/.ssh/id_rsa

### VESTA
curl -O http://vestacp.com/pub/vst-install.sh
bash vst-install.sh --nginx yes --apache yes --phpfpm no --named yes --remi yes --vsftpd yes --proftpd no --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous no --mysql yes --postgresql no --hostname $domainname

### PHP 5.6 -> 7.2
echo
echo "PHP 5.6 to 7.2 update... please wait"
service vesta stop
service nginx stop
service httpd stop
yum -y --enablerepo=remi install php72-php
yum -y --enablerepo=remi install php72-php-pear php72-php-bcmath php72-php-pecl-jsond-devel php72-php-mysqlnd
yum -y --enablerepo=remi install php72-php-gd php72-php-common php72-php-intl php72-php-cli php72-php-xml php72-php-opcache php72-php-pecl-apcu php72-php-pecl-jsond
yum -y --enablerepo=remi install php72-php-pdo php72-php-gmp php72-php-process php72-php-pecl-imagick php72-php-devel php72-php-mbstring
mv /usr/bin/php /usr/bin/php56
ln -s /usr/bin/php72 /usr/bin/php

### HTTPD RESTART WITHOUT 5.6 CONF
rm /etc/httpd/conf.modules.d/10-php.conf
service httpd restart

### WORDPRESS INSTALL (VESTA ADMIN WEB DIR)
cd /home/admin/web/$domainname/public_html
wget https://wordpress.org/latest.tar.gz
tar --strip-components=1 -zxf latest.tar.gz
chown -R admin:admin ./*

### CLEANUP
cd ~
rm vst-install-rhel.sh vst-install.sh
rm -rf vst_install_backups

### HIDEAWAY NGINX SITE CONF
mv /home/admin/conf/web/$domainname.nginx.conf /etc/nginx/conf.d

### REMOVE INCLUDE FROM USERSITE CONF
sed -i '/include /d' /etc/nginx/conf.d/$domainname.nginx.conf

### REMOVE INCLUDE __OF__ USERSITE CONF
sed -i 's/include/#include/' /etc/nginx/conf.d/vesta.conf

### IP ACCESS PORT 80 DENY
localip=$(sed -e 's/^"//' -e 's/"$//' <<< `dig @ns1.google.com TXT o-o.myaddr.l.google.com +short`)
echo $localip
sed -i "/server_name/a return 444;" /etc/nginx/conf.d/$localip.conf

### WEBMAIL RESTRICT
#httpd
sed -i "s/Allow from all/Allow from $sourceip/" /etc/httpd/conf.d/roundcubemail.conf
#nginx
read -r -d '' webmail << EOM
location  ^~ /webmail/ {
           proxy_pass http://$localip:8080;
           allow $sourceip;
           deny all;
          }
EOM
sed -i "/error_log/r /dev/stdin" <<< $webmail /etc/nginx/conf.d/$domainname.nginx.conf

### PHPMYADMIN RESTRICT
#httpd
sed -i "s/Allow from All/Allow from $sourceip/" /etc/httpd/conf.d/phpMyAdmin.conf
#nginx
read -r -d '' phpmyadmin << EOM
location  ^~ /phpmyadmin/ {
           proxy_pass http://$localip:8080;
           allow $sourceip;
           deny all;
          }
EOM
sed -i "/error_log/r /dev/stdin" <<< $phpmyadmin /etc/nginx/conf.d/$domainname.nginx.conf

### DIRECT IP/DEFAULT SITE LOCATIONS RESTRICT
echo "allow $sourceip;deny all;" >> /usr/local/vesta/nginx/conf/fastcgi_params

### WP-ADMIN STOP, STATIC CONTENT STOP
sed -i "/try_files/a  allow $sourceip; deny all;" /etc/nginx/conf.d/$domainname.nginx.conf
read -r -d '' wpadmin << EOM
location ~ ^/(wp-admin|wp-login\.php)
        {
            try_files \$uri @fallback;
            allow $sourceip;
            deny all;
        }
EOM
sed -i "/location \/ {/r /dev/stdin" <<< $wpadmin /etc/nginx/conf.d/$domainname.nginx.conf

iptables -I INPUT -p tcp -s 0.0.0.0/0 --dport $sshport -j DROP
iptables -I INPUT -p tcp -s $sourceip --dport $sshport -j ACCEPT
iptables -I INPUT -p tcp -s 0.0.0.0/0 --dport $vestaport -j DROP
iptables -I INPUT -p tcp -s $sourceip --dport $vestaport -j ACCEPT
service iptables save
semanage port -a -t ssh_port_t -p tcp $sshport

service sshd reload
service nginx start
service httpd start
service vesta start
service iptables restart

echo "================================================"
echo "All Done"
echo "================================================"
