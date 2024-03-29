# Wordpress Security

Detailed Video Manual: https://www.youtube.com/watch?v=1soJFnUJOXo

wp_secure_nossl.sh - Automatic secure wordpress hosting installator 

- Only for restriction access by IP
- Without SSL

Compatible: 

- Digital Ocean Droplet, Centos 7 x64
- Minimal Droplet Requirements: 
- - 1Gb Memory, 25Gb Disk

Attention: 

Run wp_secure_nossl.sh only on new, clean Droplet

Outline: 

- SSH setup
- Vesta Control Panel setup
- System Firewall setup
- Wordpress download & unpack
- Nginx security settings

Detailed:

- Swap setup 
- Disable ipv6
- New system User
- SSH configuration
- - /etc/ssh/sshd_config сhanges: 
- - - Default port change ( from 15000 to 22000 )
- - - PermitRootLogin no
- - - PasswordAuthentication no
- - Private key generation 
- - Passphrase setup
- Vesta Control Panel setup ( Download latest )
- PHP 5.6 - > PHP 7.2 Update
- Wordpress download & unpack to domain www directory
- Nginx configuration files security settings
- - move domain.nginx.conf to /etc/nginx/conf.d/
- - remove include vesta nginx confs ( for domain & vesta ) 
- - restrict web via server IP
- - restrict vesta /webmail/,/phpmyadmin/ access only from allowed IP + httpd restriction
- - restrict /wp-admin/ folder and included files via IP
- Allow SSH only for IP
- Allow :8083 vesta port only for IP

This .sh implements part of wordpress security guide https://outsource-trading.com/blog/new-wordpress-secure-installation/

RUN: 

yum install wget

wget https://raw.githubusercontent.com/outsource-trading/wordpress_security/master/wp_secure_nossl.sh

chmod +x wp_secure_nossl.sh

./wp_secure_nossl.sh

