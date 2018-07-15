#!/bin/bash

export $(cat .env | xargs)

for arg in USER DOMAIN APP_PATH CONTAINER_NAME_WEB CONTAINER_NAME_DB NAME OLD_URL NEW_URL; do

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
sed -i "s#{db-name}#$CONTAINER_NAME_DB#g" migration-backup.sh
sed -i "s#{backup-name}#$BACKUP_NAME#g" migration-backup.sh

read -p "Create backup (Y/n)?" choice
case $choice in
       Y|y ) scp migration-backup.sh $USER@$DOMAIN:$APP_PATH/migrations/migration-backup.sh && ssh $USER@$DOMAIN "cd $APP_PATH/migrations && pwd && ls -la && ./migration-backup.sh";;
       * ) echo "Skipping";;
esac

echo "Create directory "$SITE
mkdir -p $SITE

echo "Copy files from $DOMAIN:$BACKUP_PATH"
echo "to $SITE" 
read -p "(y/N)?" choice
case $choice in
       Y|y ) scp -r $USER@$DOMAIN:$BACKUP_PATH/* $SITE;;
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

read -p "Clear html dir (y/N)?" choice
case $choice in 
       Y|y ) sudo rm -rf html;;
       * ) echo "Skipping";;
esac

if [ ! -d html ]; then

   echo "Extract html.tar.gz"
   read -p "Press enter to continue"
   tar -zxvf html.tar.gz

fi


if [ -d mysql ]; then

   read -p "Remove mysql dir (for clearing db) (y|N)?" choice
   case $choice in
          Y|y ) sudo rm -r mysql/;;
          * ) echo "Skipping";;
   esac

fi

#echo "Ensure www-data is owner"
#sudo chown -R www-data:www-data html


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

docker stop presens-db presens-web presens-phpadmin
docker rm -f presens-db presens-web presens-phpadmin
#docker-compose rm -f
echo "Create container"
read -p "Press enter to continue"
docker-compose up -d
echo "Wait 10 seconds for db to start"
sleep 10

CONTAINER_ID=`docker ps -aqf "name=$NAME-db"`

read -p "Add backup to db (y|N)?" choice
case $choice in
          Y|y ) cat backup.sql | docker exec -i $CONTAINER_ID /usr/bin/mysql -u $DB_USER --password=$DB_PASS $DB_NAME;;
          * ) echo "Skipping";;
esac

#read -p "Press enter to continue"
#CONTAINER_ID=`docker ps -aqf "name=$NAME-db"`
#cat backup.sql | docker exec -i $CONTAINER_ID /usr/bin/mysql -u $DB_USER --password=$DB_PASS $DB_NAME


echo "Change $OLD_URL -> $NEW_URL in db"
read -p "Press enter to continue"
cmds=(\
  "UPDATE wp_links SET link_url = replace(link_url, 'https$OLD_URL', 'http$OLD_URL');"\
  "UPDATE wp_links SET link_url = replace(link_url, 'http$OLD_URL', 'http$NEW_URL');"\

  "UPDATE wp_links SET link_image = replace(link_image, 'https$OLD_URL', 'http$OLD_URL');"\
  "UPDATE wp_links SET link_image = replace(link_image, 'http$OLD_URL', 'http$NEW_URL');"\

  "UPDATE wp_usermeta SET meta_value = replace(meta_value, 'https$OLD_URL', 'http$OLD_URL');"\
  "UPDATE wp_usermeta SET meta_value = replace(meta_value, 'http$OLD_URL', 'http$NEW_URL');"\

  "UPDATE wp_options SET option_value = replace(option_value, 'https$OLD_URL', 'http$OLD_URL') WHERE option_name = 'home' OR option_name = 'siteurl';" \
  "UPDATE wp_options SET option_value = replace(option_value, 'http$OLD_URL', 'http$NEW_URL') WHERE option_name = 'home' OR option_name = 'siteurl';" \

  "UPDATE wp_posts SET guid = replace(guid, 'https$OLD_URL','http$OLD_URL');" \
  "UPDATE wp_posts SET guid = replace(guid, '$OLD_URL','$NEW_URL');" \

  "UPDATE wp_posts SET post_content = replace(post_content, 'https$OLD_URL', 'http$OLD_URL');" \
  "UPDATE wp_posts SET post_content = replace(post_content, '$OLD_URL', '$NEW_URL');" \

  "UPDATE wp_postmeta SET meta_value = replace(meta_value,'https$OLD_URL','http$OLD_URL');" \
  "UPDATE wp_postmeta SET meta_value = replace(meta_value,'$OLD_URL','$NEW_URL');" \
)

for i in "${cmds[@]}"; do
    echo "$i"	
    #docker exec -i $CONTAINER_ID /usr/bin/mysql -u $DB_USER --password=$DB_PASS  $DB_NAME <<< "$i"

done

echo "Change $OLD_URL -> $NEW_URL in in html files"
read -p "Press enter to continue"

sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#https$OLD_URL#http$OLD_URL#g"
sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#$OLD_URL#$NEW_URL#g"

# sed -i "s/$TMP/define('DB_HOST', 'localhost:3007' );/" > $WP_CONFIG
