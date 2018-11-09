#!/bin/bash

CONTAINER_WEB=$1
OLD_URL)$2
NEW_URL=$3
WP_CONFIG=html/wp-config.php

for arg in "CONTAINER_WEB OLD_URL NEW_URL"; do

     echo $arg

     if [ "${!arg}" = "" ];then
         echo "Missing env $arg"
         exit 1
     fi

done

if [ -d html ];then

    read -p "Remove html (y|N)?" choice
    case $choice in
          Y|y ) rm -r html;;
          * ) echo "Skipping html" && exit 1;;
    esac
fi

echo "Copy html from $CONTAINER_WEB"
docker cp $CONTAINER_WEB :/var/www/html html

echo "Get db name, password, user from docker file"
read -p "Press enter to continue"
TMP=`grep -r WORDPRESS_DB_PASSWORD docker-compose.yml`
DB_PASS=`sed s/'WORDPRESS_DB_PASSWORD: '//g <<< $TMP`

TMP=`grep -r WORDPRESS_DB_USER docker-compose.yml`
DB_USER=`sed s/'WORDPRESS_DB_USER: '//g <<< $TMP`

TMP=`grep -r WORDPRESS_DB_NAME docker-compose.yml`
DB_NAME=`sed s/'WORDPRESS_DB_NAME: '//g <<< $TMP`

TMP=`grep -r WORDPRESS_DB_HOST docker-compose.yml`
DB_HOST=`sed s/'WORDPRESS_DB_HOST: '//g <<< $TMP`

# Remove whitespace
DB_PASS=`echo $DB_PASS | xargs`
DB_USER=`echo $DB_USER | xargs`
DB_NAME=`echo $DB_NAME | xargs`
DB_HOST=`echo $DB_HOST | xargs`

echo "DB_HOST: "$DB_HOST
echo "DB_USER: "$DB_USER
echo "DB_PASS: "$DB_PASS
echo "DB_NAME: "$DB_NAME


echo "Edit wp-config $WP_CONFIG"
read -p "Press enter to continue"

TMP=`grep -r "define('DB_NAME'" $WP_CONFIG`
echo "Changing $TM -> define('DB_NAME', '$DB_NAME' );"
sudo sed -i "s/$TMP/define('DB_NAME', '$DB_NAME' );/g" $WP_CONFIG

TMP=`grep -r "define('DB_USER'" $WP_CONFIG`
echo "Changing $TMP -> define('DB_USER', '$DB_USER' );"
sudo sed -i "s/$TMP/define('DB_USER', '$DB_USER' );/g" $WP_CONFIG

echo "Changing $TMP -> define('DB_PASSWORD', '$DB_PASS' );"
TMP=`grep -r "define('DB_PASSWORD'" $WP_CONFIG`
sudo sed -i "s/$TMP/define('DB_PASSWORD', '$DB_PASS' );/g" $WP_CONFIG

echo "Changing $TMP -> define('DB_HOST', '$DB_HOST' );"
TMP=`grep -r "define('DB_HOST'" $WP_CONFIG`
sudo sed -i "s/$TMP/define('DB_HOST', '$DB_HOST' );/g" $WP_CONFIG

echo "Ensure www-data is owner"
sudo chown -R www-data:www-data html

#echo "Make wp-content editable"
#sudo chmod -R 777 ./html/wp-content 


sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#https$OLD_URL#http$OLD_URL#g"
sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#$OLD_URL#$NEW_URL#g"

