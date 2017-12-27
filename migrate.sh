#!/bin/bash

USER=$1
DOMAIN=$2
BACKUPDIR=$3

arr=$(echo $BACKUPDIR | tr "/" "\n")

ARRAY=()
for x in $arr
do
    #echo "\"$x\""
    #echo $x
    ARRAY+=($x)
done

NAME=${ARRAY[-1]}
SITE=sites/$NAME
HOST=localhost
WP_CONFIG=html/wp-config.php

echo "Create directory "$SITE
mkdir -p $SITE

if [ ! -f $SITE/html.tar.gz ]; then

   echo "Copy files from $DOMAIN:$BACKUPDIR to $SITE"
   read -p "Press enter to continue"
   scp -r $USER@$DOMAIN:$BACKUPDIR/* $SITE/

fi


if [ ! -f $SITE/docker-compose.yml ]; then

   echo "Generate docker file"
   read -p "Press enter to continue"
   ./generate_docker_compose_file.sh $NAME secret 

   echo "Move docker file"
   read -p "Press enter to continue"
   mv docker-compose.yml $SITE/docker-compose.yml

fi

echo "Enter "$SITE
cd $SITE

if [ ! -d html ]; then

   echo "Extract html.tar.gz"
   read -p "Press enter to continue"
   tar -zxvf html.tar.gz
fi

echo "Ensure www-data is owner"
chown -R www-data:www-data html


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
sed -i "s/$TMP/define('DB_NAME', '$DB_NAME' );/g" $WP_CONFIG

TMP=`grep -r "define('DB_USER'" $WP_CONFIG`
sed -i "s/$TMP/define('DB_USER', '$DB_USER' );/g" $WP_CONFIG

TMP=`grep -r "define('DB_PASSWORD'" $WP_CONFIG`
sed -i "s/$TMP/define('DB_PASSWORD', '$DB_PASS' );/g" $WP_CONFIG

TMP=`grep -r "define('DB_HOST'" $WP_CONFIG`
sed -i "s/$TMP/define('DB_HOST', '$DB_HOST' );/g" $WP_CONFIG
# sed -i "s/$TMP/define('DB_HOST', 'localhost:3007' );/" > $WP_CONFIG
