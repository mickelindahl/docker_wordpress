#!/bin/bash

# Ecample:
# backup.sh container-id/name
# or
# backup.sh container-id/name suffix


CONTAINER_ID=`docker ps -aqf "name=presensimpro_presensimpro_web_1"`
NAME=presensimpro_presensimpro_web_1

TMP=`grep -r WORDPRESS_DB_PASSWORD docker-compose.yml`
DB_PASS=`sed s/'WORDPRESS_DB_PASSWORD: '//g <<< $TMP`

TMP=`grep -r WORDPRESS_DB_USER docker-compose.yml`
DB_USER=`sed s/'WORDPRESS_DB_USER: '//g <<< $TMP`

TMP=`grep -r WORDPRESS_DB_NAME docker-compose.yml`
DB_NAME=`sed s/'WORDPRESS_DB_NAME: '//g <<< $TMP`

# Remove whitespace
DB_PASS=`echo $DB_PASS | xargs`
DB_USER=`echo $DB_USER | xargs`
DB_NAME=`echo $DB_NAME | xargs`

echo "CONTAINER_ID: "$CONTAINER_ID
echo "DB_USER: "$DB_USER
echo "DB_PASS: "$DB_PASS
echo "DB_NAME: "$DB_NAME
#read -p "Press enter to continue"

echo "Enter script dir"
cd $(dirname $0)
echo $(pwd)

BACKUP_DIR=$(pwd)/"backups/migration-180211"

echo "Backupdir: $BACKUP_DIR"
if [ -d "$BACKUP_DIR" ]; then

  echo ${BACKUP_DIR}" found, removing"
  rm -r ${BACKUP_DIR}

fi


echo "Create directory "${BACKUP_DIR}
mkdir -p backups

echo "Copy html"
#read -p "Press enter to continue"
mkdir -p ${BACKUP_DIR}/html
cp -R html/* ${BACKUP_DIR}/html/

echo "Create html.tar.gz"
#read -p "Press enter to continue"
cd ${BACKUP_DIR}
tar -zcvf html.tar.gz html
cd ..
cd ..

echo "Remove html folder"
rm -r ${BACKUP_DIR}/html

echo "Backup mysql from container"
#read -p "Press enter to continue"
#docker exec ${NAME} sh -c 'exec mysqldump --all-databases -uroot -p"$MYSQL_ROOT_PASSWORD"' > ${BACKUP_DIR}/backup.sql
docker exec ${CONTAINER_ID} /usr/bin/mysqldump -u ${DB_USER} --password=${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/backup.sql

echo "Set current user as owner"
chown -R ${USER}:${USER} ${BACKUP_DIR}

echo "Done!"

