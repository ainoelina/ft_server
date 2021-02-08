#!/bin/bash

# the autoindex script can turn autoindex on/off 
# by visiting http://localhost/wordpress/wp-admin/js the results can be seen

if [[ $1 == "on" ]]
then
	sed -i 's/autoindex off/autoindex on/g' /etc/nginx/sites-available/localhost
	service nginx reload
	service nginx restart
elif [[ $1 == "off" ]]
then
	sed -i 's/autoindex on/autoindex off/g' etc/nginx/sites-available/localhost
	service nginx reload
	service nginx restart
else
	echo "Please provide a valid value ('on' or 'off') for autoindex"
fi