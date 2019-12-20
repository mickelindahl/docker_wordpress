#!/bin/bash

# Import library
source ./lib.sh

if [[ ! -f .env ]]; then

   echo "Missing .env file"
   exit

fi

# Add .env variables
export $(cat .env | xargs)

assertAllowed HOST_TYPE IS_HTTPS MYSQL_PASSWORD NAME NETWORK VIRTUAL_HOST PORT CPUS_WEB MEM_WEB CPUS_DB MEM_DB


BRANCH=$(git rev-parse --abbrev-ref HEAD)
CONTAINER_MASTER_WEB=$NAME-master-web
CONTAINER_MASTER_DB=$NAME-master-db
CONTAINER_WEB=$NAME-$BRANCH-web
CONTAINER_DB=$NAME-$BRANCH-db
MYSQL_USER=wordpress
MYSQL_NAME=wordpress
MYSQL_HOST="$CONTAINER_DB:3306"


if [ "$IS_HTTPS" = "yes" ];then

    HTTP="https"

else

    HTTP="http"

fi

if [[ "$HOST_TYPE" = "port" ]]; then

    PORT_WEB="ports:"
    PORT_MAPPING_WEB="- ${PORT}:80"
    VIRTUAL_HOST=""

elif [[ "${HOST_TYPE}" = "virtual-host" ]]; then

    PORT_WEB=""
    PORT_MAPPING_WEB=""
    VIRTUAL_HOST="VIRTUAL_HOST: $VIRTUAL_HOST"

else

    echo "Missing env HOST_TYPE"
    exit 1

fi

if [[ "${BRANCH}" = "develop" ]];then

    assertAllowed URL_DEVELOP URL_MASTER

    read -p "Copy html from production to develop (Y/n)?" choice
    case $choice in
       "N|n" ) echo "Skipping";;
       * ) htmlMasterToDevelop $CONTAINER_MASTER_WEB $URL_DEVELOP $URL_MASTER $MYSQL_USER $MYSQL_PASSWORD $MYSQL_NAME $MYSQL_HOST;;

    esac
fi

cp sample.docker-compose.yml docker-compose.yml

replace "CONTAINER_DB,CONTAINER_WEB,VIRTUAL_HOST,MYSQL_NAME,MYSQL_USER,MYSQL_PASSWORD" docker-compose.yml
replace "MYSQL_HOST,NETWORK,PORT_WEB,PORT_MAPPING_WEB,VIRTUAL_HOST" docker-compose.yml
replace "CPUS_WEB MEM_WEB CPUS_DB MEM_DB" docker-compose.yml

docker rmi $(docker images --quiet --filter "dangling=true")

docker-compose stop
docker-compose rm -f

docker-compose build
docker-compose --compatibility up -d
echo "Wait 10 seconds for db to start"
sleep 10

if [[ "${BRANCH}" = "develop" ]];then
    read -p "Clone production database to develoo (Y/n)?" choice
    case ${choice} in
        * ) dbMasterToDevelop $CONTAINER_MASTER_WEB $CONTAINER_MASTER_DB $CONTAINER_DB $URL_DEVELOP $URL_MASTER $MYSQL_USER $MYSQL_PASSWORD $MYSQL_NAME $HTTP;;
        N|n ) echo "Skipping";;
    esac
fi

echo ""
echo "DONE!"
echo ""
echo "*************"
echo "Configuration"
echo "*************"
echo ""
echo "CONTAINER WEB:$CONTAINER_WEB"
echo "CONTAINER DB:$CONTAINER_DB"
echo "MYSQL_HOST: $MYSQL_HOST"
echo "MYSQL_NAME: $MYSQL_NAME"
echo "MYSQL_USER: $MYSQL_USER"
echo "MYSQL_PASSWORD: $MYSQL_PASSWORD"

