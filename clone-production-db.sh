CONTAINER_NAME_WEB=$1
CONTAINER_NAME_DB=$2

# Migrate DB
cp sample.migration-backup.sh migration-backup.sh
sed -i "s#{name}#$CONTAINER_NAME_WEB#g" migration-backup.sh
sed -i "s#{db-name}#$CONTAINER_NAME_DB#g" migration-backup.sh
sed -i "s#{backup-name}#tmp#g" migration-backup.sh

PATH=$(pwd)

mv migration-backup.sh $PATH_PRODUCTION/migration-backup.sh
cd $PATH_PRODUCTION
./migration-backuo.sh
rm migration-backup.sh
mv tmp $PATH/tmp

# Copy html
docker cp $CONTAINER_NAME_WEB:/var/www/html $PATH/tmp/html
