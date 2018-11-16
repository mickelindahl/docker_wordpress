##!/bin/bash

##################################################################
# Purpose: Assert variable is in list
# Arguments:
#   $1 -> List wit strings
#   $2 -> String
##################################################################
assertAllowed() {

  allowed=$1
  var=$2

  contains=$([[ $allowed =~ (^|[[:space:]])$var($|[[:space:]]) ]] && echo "0" || echo "1")

  if [[ "$contains" = "0" ]];then
       echo "Not allowed param, variable needs to be on of $allowed"
       exit 1
  fi
}

##################################################################
# Purpose: Assert if container exist
# Arguments:
#   $1 -> container name
##################################################################
assertContainer(){

    if [[ ! "$(docker ps -a | grep $1)" ]];then
       echo "Missing container $1"
       exit 1
    fi
}

##################################################################
# Purpose: Check if variable has value
# Arguments:
#   $1 -> List with varialbe names
##################################################################
assertExists(){

   for arg in "$@"; do

#       echo "Checking for existance $arg"

       if [[ "${!arg}" = "" ]];then
           echo "Missing env $arg"
           exit 1
       fi
   done
}

##################################################################
# Purpose: Assert two variables are not equal
# Arguments:
#   $1 -> first variable
#   $2 -> second variable
##################################################################
asserNotEqual(){

   if [[ "$1" = "$2" ]];then

       echo "Not allowed variables equal $1=$2"
       exit 1

   fi

}

##################################################################
# Purpose: Get credentials from wp-config file in wordpress con
# container
# Arguments:
#   $1 -> Container name
#   $2 -> Variable to get DB_NAME or DB_HOST or DB_PASSWORD
# Echo: Value of credential
##################################################################
getCredentialWpConfig(){

   CONTAINER=$1
   VAR=$2

   assertExists CONTAINER VAR

   OUT=$(docker exec -it $CONTAINER grep -r $VAR /var/www/html/wp-config.php | sed s/"define('${VAR}', '"//g | sed s/"');"//g)

   # Remove trailing hidden characters
   echo $(tr -dC '[:print:]\t\n' <<< $OUT)


}

##################################################################
# Purpose: Replace one url in wordpress db with another url
# Arguments:
#   $1 -> container with wordpress db
#   $2 -> wordpress db user
#   $3 -> wordpress db password
#   $4 -> wordpress db name
#   $5 -> url to be replaced
#   $6 -> url to replace with
#   $7 +> http or https on final site
##################################################################
replaceUrlInDb(){

   CONTAINER=$1
   DB_USER=$2
   DB_PASS=$3
   DB_NAME=$4
   OLD_URL=$5
   NEW_URL=$6
   HTTP=$7

   assertExists CONTAINER DB_USER DB_PASS DB_NAME OLD_URL NEW_URL;

   echo "Change $OLD_URL -> $NEW_URL in db"
   read -p "Press enter to continue"
   cmds=(\
     "UPDATE wp_links SET link_url = replace(link_url, 'https://$OLD_URL', 'http://$OLD_URL');"\
     "UPDATE wp_links SET link_url = replace(link_url, 'http://$OLD_URL', '$HTTP://$NEW_URL');"\

     "UPDATE wp_links SET link_image = replace(link_image, 'https://$OLD_URL', 'http://$OLD_URL');"\
     "UPDATE wp_links SET link_image = replace(link_image, 'http://$OLD_URL', '$HTTP://$NEW_URL');"\

     "UPDATE wp_usermeta SET meta_value = replace(meta_value, 'https://$OLD_URL', 'http://$OLD_URL');"\
     "UPDATE wp_usermeta SET meta_value = replace(meta_value, 'http://$OLD_URL', '$HTTP://$NEW_URL');"\

     "UPDATE wp_options SET option_value = replace(option_value, 'https://$OLD_URL', 'http://$OLD_URL') WHERE option_name = 'home' OR option_name = 'siteurl';" \
     "UPDATE wp_options SET option_value = replace(option_value, 'http://$OLD_URL', '$HTTP://$NEW_URL') WHERE option_name = 'home' OR option_name = 'siteurl';" \

     "UPDATE wp_posts SET guid = replace(guid, 'https://$OLD_URL','http://$OLD_URL');" \
     "UPDATE wp_posts SET guid = replace(guid, 'http://$OLD_URL','$HTTP://$NEW_URL');" \

     "UPDATE wp_posts SET post_content = replace(post_content, 'https://$OLD_URL', 'http://$OLD_URL');" \
     "UPDATE wp_posts SET post_content = replace(post_content, 'http://$OLD_URL', '$HTTP://$NEW_URL');" \

     "UPDATE wp_postmeta SET meta_value = replace(meta_value,'https://$OLD_URL','http://$OLD_URL');" \
     "UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://$OLD_URL','$HTTP://$NEW_URL');" \
   )

   for i in "${cmds[@]}"; do

      echo "Executing in bd: $i"
      docker exec -i $CONTAINER /usr/bin/mysql -u $DB_USER --password=$DB_PASS  $DB_NAME <<< "$i"

   done
}

##################################################################
# Purpose: Migrate database for wordpress instance in master
# container to  develop container
# Arguments:
#   $1 -> Container master web
#   $2 -> Container master db
#   $3 -> Container develop db
#   $4 -> Url of wordpress site in develop container
#   $5 -> Url of wordpress site in master container
#   $6 -> Wordpress database user develop
#   $7 -> Wordpress database password develop
#   $8 -> Wordpress database name develop
#   $9 +> http or https on final site
##################################################################
dbMasterToDevelop(){

   CONTAINER_MASTER_WEB=$1
   CONTAINER_MASTER_DB=$2
   CONTAINER_DEVELOP_DB=$3
   URL_DEVELOP=$4
   URL_MASTER=$5
   DEVELOP_DB_USER=$6
   DEVELOP_DB_PASS=$7
   DEVELOP_DB_NAME=$8
   HTTP=$9
   BACKUP_FILE=tmp-backup.sql # Temporary backup storage

   assertExists CONTAINER_MASTER_WEB CONTAINER_MASTER_DB CONTAINER_DEVELOP_DB
   assertExists URL_MASTER URL_DEVELOP DEVELOP_DB_USER DEVELOP_DB_PASS DEVELOP_DB_NAME

   assertContainer $CONTAINER_MASTER_WEB
   assertContainer $CONTAINER_MASTER_DB
   assertContainer $CONTAINER_DEVELOP_DB

   # Get credentials
#   getCredentialWpConfig $CONTAINER_MASTER_WEB DB_NAME
   MASTER_DB_NAME=$(getCredentialWpConfig $CONTAINER_MASTER_WEB DB_NAME)
   MASTER_DB_USER=$(getCredentialWpConfig $CONTAINER_MASTER_WEB DB_USER)
   MASTER_DB_PASS=$(getCredentialWpConfig $CONTAINER_MASTER_WEB DB_PASSWORD)

   if [ -f $BACKUP_FILE ];then

       echo "Old $BACKUP_FILE, removing..."
       rm $BACKUP_FILE

   fi

   read -p "Migrate db from $CONTAINER_MASTER_DB [Press enter to continue]"

   # Migrate master DB
   docker exec ${CONTAINER_MASTER_DB} /usr/bin/mysqldump -u ${MASTER_DB_USER} --password=${MASTER_DB_PASS} ${MASTER_DB_NAME} > ${BACKUP_FILE}

   SKIP=""
   read -p "Add backup to $CONTAINER_DEVELOP_DB [Press enter to continue]"
   cat $BACKUP_FILE | docker exec -i $CONTAINER_DEVELOP_DB /usr/bin/mysql -u $DEVELOP_DB_USER --password=$DEVELOP_DB_PASS $DEVELOP_DB_NAME

   echo "Removing $BACKUP_FILE"
   read -p "[Press enter to continue]"
   rm $BACKUP_FILE

   echo "$DEVELOP_DB $DEVELOP_DB_USER $DEVELOP_DB_PASS $DEVELOP_DB_NAME $URL_MASTER $URL_DEVELOP"

   replaceUrlInDb $CONTAINER_DEVELOP_DB $DEVELOP_DB_USER $DEVELOP_DB_PASS $DEVELOP_DB_NAME $URL_MASTER $URL_DEVELOP $HTTP
}

##################################################################
# Purpose: Migrate database for wordpress instance in master
# container to  develop container
# Arguments:
#   $1 -> Container web master
#   $2 -> Url of wordpress site in develop container
#   $3 -> Url of wordpress site in master container
#   $4 -> Wordpress database user develop
#   $5 -> Wordpress database password develop
#   $6 -> Wordpress database name develop
#   $7 -> Wordpress host develop
##################################################################
htmlMasterToDevelop(){

   CONTAINER_MASTER_WEB=$1
   URL_DEVELOP=$2
   URL_MASTER=$3
   DB_USER=$4
   DB_PASS=$5
   DB_NAME=$6
   DB_HOST=$7

   DEVELOP_HTML_PATH=./html
   WP_CONFIG=./html/wp-config.php

   assertExists CONTAINER_MASTER_WEB DB_USER DB_PASS DB_NAME URL_DEVELOP URL_MASTER

   read -p "Clear html dir $DEVELOP_THML_PATH [Press enter to continue]"
   sudo rm -rf $DEVELP_HTML_PATH

   echo "Copy from html $CONTAINER_MASTER_WEB [Press emter to continue]"
   docker cp $CONTAINER_MASTER_WEB:/var/www/html $DEVELOP_HTML_PATH

   echo "Edit wp-config $WP_CONFIG"
   read -p "Press enter to continue"

   TMP=`grep -r "define('DB_NAME'" $WP_CONFIG`
   echo "Changing $TMP -> define('DB_NAME', '$DB_NAME' );"
   sudo sed -i "s/$TMP/define('DB_NAME', '$DB_NAME' );/g" $WP_CONFIG

   TMP=`grep -r "define('DB_USER'" $WP_CONFIG`
   echo "Changing $TMP -> define('DB_USER', '$DB_USER' );"
   sudo sed -i "s/$TMP/define('DB_USER', '$DB_USER' );/g" $WP_CONFIG

   TMP=`grep -r "define('DB_PASSWORD'" $WP_CONFIG`
   echo "Changing $TMP -> define('DB_PASSWORD', '$DB_PASS' );"
   sudo sed -i "s/$TMP/define('DB_PASSWORD', '$DB_PASS' );/g" $WP_CONFIG

   TMP=`grep -r "define('DB_HOST'" $WP_CONFIG`
   echo "Changing $TMP -> define('DB_HOST', '$DB_HOST' );"
   sudo sed -i "s/$TMP/define('DB_HOST', '$DB_HOST' );/g" $WP_CONFIG

   echo "Ensure www-data is owner"
   sudo chown -R www-data:www-data html

    sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#https$URL_MASTER#http$URL_MASTER#g"
    sudo find ./html -type f -print0 | sudo xargs -0 sed -i "s#$URL_MASTER#$URL_DEVELOP#g"

}

##################################################################
# Replace env in a file {ENV_NAME} woth value of ENV_NAME in shell
# Arguments:
#   $1 -> Array with environment variables
#   $2 -> File name to replace variables in
##################################################################
replace(){

   echo ${1//,/ }

   arr=$(echo ${1//,/ })
   file=$2

   for var in ${arr}; do

       val=$(echo $(eval echo \$$var))
       sed -i "s#{$var}#${val}#g" docker-compose.yml

   done
}