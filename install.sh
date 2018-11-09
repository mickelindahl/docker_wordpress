#!/bin/bash

if [ ! -f .env ]; then

   echo "Missing .env file"
   exit

fi

# Add .env variables
export $(cat .env | xargs)

for arg in VIRTUAL_HOST MYSQL_PASSWORD; do

     echo $arg

     if [ "${!arg}" = "" ];then
         echo "Missing env $arg"
         exit 1
     fi

done

BRANCH=$(git rev-parse --abbrev-ref HEAD)

if [ "${BRANCH}" = "develop" ];then

    for arg in CONTAINER_PRODUCTION_WEB CONTAINER_PRODUCTION_DB; do

        echo $arg

        if [ "${!arg}" = "" ];then
            echo "Missing env $arg"
            exit 1
        fi

    done

    read -p "Clone production database to develo (Y/n)?" choice
    case $choice in
       Y|y ) ./clone-production-db.sh $CONTAINER_PRODUCTION_WEB $CONTAINER_PRODUCTION_DB;;
       * ) echo "Skipping";;
    esac
fi

#NETWORK=$NETWORK-$BRANCH

NAME=presensimpro-$BRANCH
cp sample.docker-compose.yml docker-compose.yml

MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD
WORDPRESS_DB_PASSWORD=$MYSQL_PASSWORD

declare -a arr=(\
  "NAME" \
  "VIRTUAL_HOST" \
  "MYSQL_ROOT_PASSWORD" \
  "MYSQL_PASSWORD" \
  "WORDPRESS_DB_PASSWORD"
)


for var in "${arr[@]}"; do

   sed -i $(eval echo "s#{$var}#\$$var#g") docker-compose.yml

done

if [ "${BRANCH}" = "develop" ];then

    for arg in CONTAINER_PRODUCTION_WEB OLD_URL NEW_URL; do

        echo $arg

        if [ "${!arg}" = "" ];then
            echo "Missing env $arg"
            exit 1
        fi

    done

    read -p "Retrive html from production container $CONTAINER_PRODUCTION_WEB (Y/n)?" choice
    case $choice in
       Y|y ) ./update-html.sh $CONTAINER_PRODUCTION_WEB $OLD_URL $NEW_URL;;
       * ) echo "Skipping";;
    esac
fi

docker rmi $(docker images --quiet --filter "dangling=true")

docker-compose stop
docker-compose rm -f

docker-compose build
docker-compose --compatibility up -d
echo "Wait 10 seconds for db to start"
sleep 10

if [ "${BRANCH}" = "develop" ];then
    read -p "Clone production database to develo (Y/n)?" choice
    case $choice in
       Y|y ) ./update-db.sh;;
       * ) echo "Skipping";;
    esac
fi

echo ""
echo "Done!"

