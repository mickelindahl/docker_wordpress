  GNU nano 2.7.4                                                                             File: lib/replace-url-in-db.sh                                                                              Modified  

#!/bin/bash

CONTAINER=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4
OLD_URL=$5
NEW_URL=$6

for arg in CONTAINER DB_USER DB_PASS DB_NAME OLD_URL NEW_URL; do

     echo $arg

     if [ "${!arg}" = "" ];then
         echo "Missing env $arg"
         exit 1
     fi

done


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

    echo "$i"
#add docker statement from monitor
