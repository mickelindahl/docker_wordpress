#!/bin/bash


##################################################################
# Purpose: Get credentials from wp-config file in wordpress con
# container
# Arguments:
#   $1 -> Container name
#   $2 -> Variable to get []
##################################################################
getCredentialWpConfig(){

   CONTAINER=$1
   VAR=$2

   echo $(docker exec -it $CONTAINER grep -r $VAR /var/www/html/wp-config.php | sed s/"define('${VAR}', '"//g | sed s/"');"//g)

}
