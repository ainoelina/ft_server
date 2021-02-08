# OS
FROM 	debian:buster

# maintainer
LABEL 	maintainer = "avuorio <avuorio@student.codam.nl>"

# check and update OS
RUN 	apt update; \
		apt upgrade -y

# install LEMP
RUN		apt install -y nginx; \
		apt install -y mariadb-server; \
		apt install -y php-fpm php-mysql php-mbstring; \
		apt install -y wget

# copy files
COPY	./srcs/nginx.conf ./tmp/nginx.conf
COPY	./srcs/config.inc.php ./tmp/config.inc.php
COPY	./srcs/web/index.html ./tmp/index.html
COPY	./srcs/web/background.jpg ./tmp/background.jpg

# configure access
RUN		chown -R www-data /var/www/*; \
		chmod -R 755 /var/www/*

# generating website folder
RUN		mkdir /var/www/localhost; \
		touch /var/www/localhost/index.php; \
		echo "<?php phpinfo(); ?>" >> /var/www/localhost/index.php

# SSL key and certificate
RUN		mkdir /etc/nginx/ssl; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/ssl/private/localhost.key \
		-out /etc/ssl/certs/localhost.crt \
		-subj "/CN=localhost"

# Nginx configuration
COPY	./srcs/nginx.conf /etc/nginx/sites-available/localhost
RUN		cp ./tmp/index.html /var/www/localhost/
RUN		cp ./tmp/background.jpg /var/www/localhost/
RUN 	ln -s /etc/nginx/sites-available/localhost /etc/nginx/sites-enabled/localhost; \
		rm -rf /etc/nginx/sites-enabled/default

# phpMyAdmin configuration
RUN		wget https://files.phpmyadmin.net/phpMyAdmin/4.9.7/phpMyAdmin-4.9.7-all-languages.tar.gz; \
		tar -xvf phpMyAdmin-4.9.7-all-languages.tar.gz; \
		mv phpMyAdmin-4.9.7-all-languages /var/www/localhost/phpmyadmin
COPY	/srcs/config.inc.php /var/www/localhost/phpmyadmin/config.inc.php

# mysql database setup
RUN		service	mysql start; \
		echo "CREATE DATABASE wordpress;" | mysql -u root; \
		echo "GRANT ALL PRIVILEGES ON wordpress.* TO 'user'@'localhost' IDENTIFIED BY 'password';" | mysql -u root; \
		echo "FLUSH PRIVILEGES;" | mysql -u root

# install wordpress
RUN		service mysql start; \
		wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
		chmod +x wp-cli.phar; \
		mv wp-cli.phar /usr/local/bin/wp; \
		mkdir /var/www/localhost/wordpress; \
		cd /var/www/localhost/wordpress; \
		wp core download --allow-root; \
		wp config create --dbname=wordpress --dbuser=user --dbpass=password --allow-root; \
		wp core install --url=https://localhost/wordpress --title="hello there" --admin_user='user' --admin_password='password' --admin_email='avuorio@student.codam.nl' --allow-root

# enable autoindex changes
COPY	./srcs/autoindex.sh /autoindex.sh
RUN		chmod +x /autoindex.sh

# open ports
EXPOSE	80 443

# start services
CMD 	service mysql start; \
		service php7.3-fpm start; \
		service nginx start; \
		service nginx status; \
		bash