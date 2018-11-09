#!/bin/bash

##################################################################
# Purpose: Assert variable is in list
# Arguments:
#   $1 -> List wit strings
#   $2 -> String
##################################################################
assertAllowed() {

  allowed=$1
  var=$2

  contains=$([[ $allowed =~ (^|[[:space:]])$var($|[[:space:]]) ]] && echo "0" || echo "1"))

  if [ "$contains" = "0" ];then
       echo "Not allowed param, variable needs to be on of $alllowed"
       exit(1)
   fi
}

##################################################################
# Purpose: Assert if container exist
# Arguments:
#   $1 -> container name
##################################################################
assertContainer(){

    if [ ! "$(docker ps -a | grep $1)" ];then
       echo "Missing container $1"
       exit(1)
    if
}

##################################################################
# Purpose: Check if variable has value
# Arguments:
#   $1 -> List with varialbe names
##################################################################
assertExists(){

   for arg in "$@"; do

       echo "Checking for existance $arg"

       if [ "${!arg}" = "" ];then
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

   if [ "$1" = "$2" ];then

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

   allowed=("DB_NAME"  "DB_HOST"  "DB_PASSWORD")
   assertAllowed $allowed $VAR

   echo $(docker exec -it $CONTAINER grep -r $VAR /var/www/html/wp-config.php | sed s/"define('${VAR}', '"//g | sed s/"');"//g)
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
##################################################################
replaceUrlInDb(){

   CONTAINER=$1
   DB_USER=$2
   DB_PASS=$3
   DB_NAME=$4
   OLD_URL=$5
   NEW_URL=$6

   assertExits CONTAINER DB_USER DB_PASS DB_NAME OLD_URL NEW_URL;

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
     "UPDATE wp_posts SET guid = replace(guid, 'http$OLD_URL','http$NEW_URL');" \

     "UPDATE wp_posts SET post_content = replace(post_content, 'https$OLD_URL', 'http$OLD_URL');" \
     "UPDATE wp_posts SET post_content = replace(post_content, 'http$OLD_URL', 'http$NEW_URL');" \

     "UPDATE wp_postmeta SET meta_value = replace(meta_value,'https$OLD_URL','http$OLD_URL');" \
     "UPDATE wp_postmeta SET meta_value = replace(meta_value,'http$OLD_URL','http$NEW_URL');" \
   )

   for i in "${cmds[@]}"; do

      echo "Executing in bd: $i"
      docker exec -i $CONTAINER_ID /usr/bin/mysql -u $DB_USER --password=$DB_PASS  $DB_NAME <<< "$i"

   done
}

##################################################################
# Purpose: Migrate database for wordpress instance in master
# container to  develop container
# Arguments:
#   $1 -> Base name of wordpress instance (-master or -develop is
#         added depending on branch)
#   $2 -> Url of wordpress site in master container
#   $3 -> Url of wordpress site in develop container
#   $4 -> Wordpress database user develop
#   $5 -> Wordpress database password develop
#   $6 -> Wordpress database name develop
##################################################################
dbMasterToDevelop(){

   NAME=$1
   MASTER_URL=$2
   DEVELOP_URL=$3
   DEVELOP_DB_USER=$4
   DEVELOP_DB_PASS=$5
   DEVELOP_DB_NAME=$6

   assertExists NAME MASTER_URL DEVELOP_URL

   BACKUP_FILE=tmp-backup.sql # Temporary backup storage
   MASTER_WEB=$NAME-master-web # To get credentials
   MASTER_DB=$NAME-master-db # To retreive db
   DEVELOP_DB=$NAME-develop-db # To update with db

   assertContainer $MASTER_WEB
   assertContainer $MASTER_DB
   assertContainer $DEVELOP_DB

   # Get credentials
   MASTER_DB_NAME=$(getCredentialWpCopnfig $MASTER_WEB DB_NAME)
   MASTER_DB_HOST=$(getCredentialWpConfig $MASTER_WEB DB_HOST)
   MASTER_DB_PASS=$(getCredentialWpConfig $MASTER_WEB DB_PASSWORD)

   # Migrate DB
   docker exec $MASTER_DB /usr/bin/mysqldump -u ${MASTER_DB_USER} --password=${MASTER_DB_PASS} ${MASTER_DB_NAME} > $BACKUP_FILE

   # Make user migration is neccesary
   SKIP=""
   read -p "Add backup to db [Press enter to continue]"
   cat $BACKUP_FILE | docker exec -it $DEVELOP_DB /usr/bin/mysql -u $DEVELOP_DB_USER --password=$DEVELOP_DB_PASS $DEVELOP_DB_NAME;;

   echo "Removing $BACKUP_FILE"
   rm $BACKUP_FILE

   replaceUrlInDb $DEVELOP_DB $DEVELOP_DB_USER $DEVELOP_DB_PASS $DEVELOP_DB_NAME $OLD_URL $NEW_URL

##################################################################
# Purpose: Migrate database for wordpress instance in master
# container to  develop container
# Arguments:
#   $1 -> Base name of wordpress instance (-master or -develop is
#         added depending on branch)
#   $2 -> Url of wordpress site in master container
#   $3 -> Url of wordpress site in develop container
#   $4 -> Wordpress database user develop
#   $5 -> Wordpress database password develop
#   $6 -> Wordpress database name develop
##################################################################
htmlMasterToDevelop(){

   MASTER_WEB=$1
   DB_USER=$2
   DB_PASSWORD=$3
   DB_NAME=$4

   DEVELOP_HTML_PATH=./html
   WP_CONFIG=./html/wp-config.php

   assertExits MASTER_WEB DB_USER DB_PASSWORD DB_NAME

   read -p "Clear html dir $DEVELOP_THML_PATH [Press enter to continue]"
   sudo rm -rf $DEVELP_HTML_PATH

   echo "Copy from html $MASTER_CONTAINER [Press emter to continue]"
   docker cp $MASTER_CONTAINER:/var/www/html $DEVELOP_HTML_PATH

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

}



