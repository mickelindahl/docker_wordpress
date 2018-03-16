#!/bin/bash

export $(cat .env | xargs)

for arg in USER DOMAIN APP_PATH CONTAINER_NAME_WEB NAME; do

     echo $arg

     if [ "${!arg}" = "" ];then
         echo "Missing env $arg"
         exit 1
     fi

done

SUFFIX=`date +%y%m%d`
PASSWORD=secret
WP_CONFIG=html/wp-config.php

BACKUP_NAME="migration-$SUFFIX"
BACKUP_PATH=$APP_PATH/migrations/$BACKUP_NAME
SITE=sites/$NAME-$BACKUP_NAME
#HOST=localhost

cp sample.migration-backup.sh migration-backup.sh
sed -i "s#{name}#$CONTAINER_NAME_WEB#g" migration-backup.sh
sed -i "s#{backup-name}#$BACKUP_NAME#g" migration-backup.sh

read -p "Create backup (Y/n)?" choice
case $choice in
       Y|y ) scp backup.sh $USER@$DOMAIN:$APP_PATH/migrations/migration-backup.sh && ssh $USER@$DOMAIN "cd $APP_PATH/migrations && pwd && ls -la && ./migration-backup.sh";;
       * ) echo "Skipping";;
esac

echo "Create directory "$SITE
mkdir -p $SITE

read -p "Copy files from $DOMAIN:$BACKUP_PATH (Y/n)?" choice
case $choice in
       Y|y ) scp -r $USER@$DOMAIN:BACKUP_PATH/ $SITE/;;
       * ) echo "Skipping";;
esac

echo "Generate docker file"
read -p "Press enter to continue"
./generate_docker_compose_file.sh $NAME $PASSWORD

echo "Move docker file"
read -p "Press enter to continue"
mv docker-compose.yml $SITE/docker-compose.yml


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

echo "Wait 10 seconds"
sleep 10

echo "Add backup sql to db"
read -p "Press enter to continue"
CONTAINER_ID=`docker ps -aqf "name=$NAME_db"`
cat backup.sql | docker exec -i CONTAINER_ID /usr/bin/mysql -u $DB_USER --password=$DB_PASS $DB_NAME

# sed -i "s/$TMP/define('DB_HOST', 'localhost:3007' );/" > $WP_CONFIG
