#!/bin/bash

# Import library
source ./lib.sh

if [[ ! -f .env ]]; then

   echo "Missing .env file"
   exit

fi

# Add .env variables
export $(cat .env | xargs)

assertAllowed HOST_TYPE MYSQL_PASSWORD NAME NETWORK VIRTUAL_HOST PORT


BRANCH=$(git rev-parse --abbrev-ref HEAD)
CONTAINER_PRODUCTION_WEB=$NAME-master-web
CONTAINER_PRODUCTION_DB=$NAME-master-db
CONTAINER_WEB=$NAME-$BRANCH-web
CONTAINER_DB=$NAME-$BRANCH-db
MYSQL_USER=wordpress
MYSQL_NAME=wordpress

if [[ "$HOST_TYPE" = "port" ]]; then

    PORT_WEB="ports:"
    PORT_MAPPING_WEB="- ${PORT}:80"
    VIRTUAL_HOST=""

elif [[ "${HOST_TYPE}" = "virtual-host" ]]; then

    PORT_WEB=""
    PORT_MAPPING_WEB=""

else

    echo "Missing env HOST_TYPE"
    exit 1

fi

if [[ "${BRANCH}" = "develop" ]];then

    assertAllowed URL_DEVELOP URL_MASTER

    read -p "CCopy html from production to develo (Y/n)?" choice
    case $choice in
       Y|y ) htmlMasterToDevelop $NAME $URL_DEVELOP $URL_MASTER $MYSQL_USER $MYSQL_PASSWORD $MYSQL_NAME$;;
       * ) echo "Skipping";;
    esac
fi

cp sample.docker-compose.yml docker-compose.yml

replace "CONTAINER_DB,CONTAINER_WEB,VIRTUAL_HOST,MYSQL_NAME,MYSQL_USER,MYSQL_PASSWORD,NETWORK,PORT_WEB,PORT_MAPPING_WEB,VIRTUAL_HOST" docker-compose.yml



docker rmi $(docker images --quiet --filter "dangling=true")

docker-compose stop
docker-compose rm -f

docker-compose build
docker-compose --compatibility up -d
echo "Wait 10 seconds for db to start"
sleep 10

if [[ "${BRANCH}" = "develop" ]];then
    read -p "Clone production database to develo (Y/n)?" choice
    case ${choice} in
       Y|y ) dbMasterToDevelop;;
       * ) echo "Skipping";;
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
echo "MYSQL_NAME: $MYSQL_NAME"
echo "MYSQL_USER: $MYSQL_USER"
echo "MYSQL_PASSWORD: $MYSQL_PASSWORD"

