# wordpress_security

wp_secure_nossl.sh - Automatic secure wordpress hosting installator

* Without SSL

Compatible : Digital Ocean Droplet, Centos 7 x64

Minimal Droplet Requirements: 1Gb Memory, 25Gb Disk

Only for restriction access by IP

Package Included:
- Swap Setup 
- Disable ipv6
- SSH configuration
- - /etc/ssh/sshd_config сhanges: 
- - - Default port change ( from 15000 to 22000 )
- - - PermitRootLogin no
- - - PasswordAuthentication no
- - Private key generation 
- - Paraphrase setup
- Vesta Control Panel Setup ( Download latest )
- PHP 5.6 - > PHP 7.2 Upgrade
- Wordpress Download & Unpack to domain www directory
- Nginx configuration files security settings
- - move domain.nginx.conf to /etc/nginx/conf.d/
- - remove include vesta nginx confs ( for domain & vesta ) 
- - restrict web via server IP
- - restrict vesta /webmail/,/phpmyadmin/ access only from allowed IP + httpd restriction
- - restrict /wp-admin/ folder and included files via IP
- Allow SSH only for IP
- Allow :8083 vesta port only for IP

This .sh implements part of wordpress security guide https://outsource-trading.com/blog/new-wordpress-secure-installation/
