#:/bash/bin

# Ecample:
# backup.sh container-id database-name database-user database-password
# or
# backup.sh container-id database-name database-user database-password suffix

CONTAINER_ID=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4

if [ -z "$5" ]; then

   SUFFIX=`date +%y%m%d`


else

   SUFFIX=$5

fi

echo "Enter script dir"
cd $(dirname $0)
echo $(pwd)

BACKUP_DIR=$(pwd)/"backups/backup-"${SUFFIX}

#echo $SCRIPT_DIR

if [ -d "$BACKUP_DIR" ]; then

  echo ${BACKUP_DIR}" found, removing"
  rm -r ${BACKUP_DIR}

fi


echo "Create directory "${BACKUP_DIR}
mkdir -p backups

echo "Copy html"
mkdir -p ${BACKUP_DIR}/html
cp -R html ${BACKUP_DIR}/html

echo "Create html.tar.gz"
cd ${BACKUP_DIR}
tar -zcvf html.tar.gz html
cd ..
cd ..

echo "Remove html folder"
rm -r ${BACKUP_DIR}/html

echo "Backup mysql from container"
docker exec ${CONTAINER_ID} /usr/bin/mysqldump -u ${DB_USER} --password=${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/backup.sql

echo "Set current user as owner"
chown -R ${USER}:${USER} ${BACKUP_DIR}

echo "Done!"
