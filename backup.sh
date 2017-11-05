#:/bash/bin

# Ecample:
# backup.sh container-id database-name database-user database-password 

CONTAINER_ID=$1
DB_NAME=$2
DB_USER=$3
DB_PASS=$4

DATE=`date +%y%m%d`
BACKUP_DIR="backups/backup-"${DATE} 


if [ -d "$BACKUP_DIR" ]; then

  echo ${BACKUP_DIR}" found, rremoving"
  rm -r ${BACKUP_DIR}

fi

echo "Create directory "${BACKUP_DIR}
mkdir -p backups

echo "Copy html"
mkdir -p ${BACKUP_DIR}/html
cp -R html ${BACKUP_DIR}/html

echo "Backup mysql from container"
docker exec ${CONTAINER_ID} /usr/bin/mysqldump -u ${DB_USER} --password=${DB_PASS} ${DB_NAME} > ${BACKUP_DIR}/backup.sql

echo "Set current user as owner"
chown -R ${USER}:${USER} ${BACKUP_DIR}

echo "Done!"
